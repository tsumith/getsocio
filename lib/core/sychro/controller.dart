import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:getsocio/core/sychro/client_net_service.dart';
import 'package:getsocio/core/sychro/host_net_service.dart';
import 'package:getsocio/home/music_lib/player_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../models/local_song.dart';
import '../app_mode.dart';
import '../protocol/sync_message.dart';
import '../streaming/mime_helper.dart';
import '../streaming/streaming_source.dart';

class SyncController {
  final PlayerProvider player;
  // --- app mode ---
  AppMode _mode = AppMode.solo;
  AppMode get mode => _mode;

  // --- host and client ----
  HostNetService? _hostService;
  ClientNetService? _clientService;

  // -- clients info --
  int get clientCount => _hostService?.clientCount ?? 0;

  // --- file  transfer----
  StreamingBufferSource? _currentStreamSource;
  // -- offset --
  int _clockOffset = 0;

  int _expectedSize = 0;
  int _receivedBytes = 0;
  bool _isReceivingFile = false;

  // -- playback flag --
  bool _playbackStarted = false;

  // --- file transferring getters ---
  double _transferProgress = 0.0;
  double get transferProgress => _transferProgress;
  bool get isReceivingFile => _isReceivingFile;

  // -- track clients--
  int _readyClients = 0;

  // -- callbackfunction while transferring ---
  VoidCallback? onTransferProgress;

  SyncController({required this.player});

  Future<void> startHost({VoidCallback? onClientChange}) async {
    _hostService = HostNetService();
    await _hostService?.start(onClientChange: onClientChange);
    // -- listen to client count --
    _hostService?.clientCountStream.listen((count) {
      debugPrint("Client count updated: $count");
      if (count < _readyClients) {
        _readyClients = count;
      }
    });
    //-- listen to incoming messages --
    _hostService?.onMessage.listen(
      _handleIncoming,
      onError: (err) {
        debugPrint("Host Stream Error: $err");
        stop();
      },
    );
    _mode = AppMode.host;
  }

  Future<void> joinHost(String ip) async {
    _clientService = ClientNetService();
    await _clientService!.connect(ip);

    _clientService!.onMessage.listen(
      _handleIncoming,
      onError: (err) => stop(),
      onDone: () => stop(),
    );

    _mode = AppMode.client;
    Future.delayed(const Duration(milliseconds: 500), () {
      print("🚀 Client sending initial SyncTime request...");
      send(
        SyncTime(
          clientTransmitTime: DateTime.now().millisecondsSinceEpoch,
        ).encode(),
      );
    });
  }

  Future<void> stop() async {
    try {
      _currentStreamSource = null;
    } catch (e) {
      debugPrint("Sink closure error: $e");
    } finally {
      _isReceivingFile = false;
      _expectedSize = 0;
      _receivedBytes = 0;
    }
    try {
      await _hostService?.dispose();
      await _clientService?.dispose();
    } catch (e) {
      debugPrint("Disposal error: $e");
    } finally {
      _hostService = null;
      _clientService = null;
      _mode = AppMode.solo;
      _readyClients = 0;
    }
  }

  // -- handle both host and client data transfer with single method
  void send(dynamic data) {
    if (_mode == AppMode.host) {
      _hostService?.send(data);
    } else if (_mode == AppMode.client) {
      _clientService?.send(data);
    }
  }

  void _handleIncoming(dynamic data) {
    if (data is String) {
      _handleTextMessage(data);
    } else if (data is List<int>) {
      _handleBinaryMessage(data);
    }
  }

  // ---------------------------------- handle string data (commands) ---------------------------
  void _handleTextMessage(String data) async {
    final SyncMessage message = SyncMessage.decode(data);
    if (message is FileInfo) {
      await _onFileInfo(message);
    } else if (message is SyncTime) {
      _handleTimeSync(message);
    } else if (message is Play) {
      _handleScheduledPlay(message);
    } else if (message is Pause) {
      player.player.pause();
    } else if (message is Seek) {
      await player.seek(Duration(milliseconds: message.positionMs));
    } else if (message is Ready) {
      _onClientReady();
    } else if (message is FileEnd) {
      _currentStreamSource?.finish();
      debugPrint("File transfer complete");
    }
  }

  // ------onFileInfo triggers file transfer flag ------
  Future<void> _onFileInfo(FileInfo info) async {
    _expectedSize = info.size;
    _receivedBytes = 0;
    _isReceivingFile = true;

    final mediaItem = MediaItem(
      id: 'remote_${info.name}', // Unique ID for background service
      title: info.name,
      artist: "Syncing...",
    );

    _currentStreamSource = StreamingBufferSource(
      totalSize: info.size,
      contentType: info.mimeType,
      tag: mediaItem,
    );
    final song = LocalSong(
      path: "stream://incoming", // Dummy path
      title: info.name,
      artist: "Syncing...",
    );
    await player.loadStreamSource(_currentStreamSource!, song);
  }

  Future<void> _onClientReady() async {
    if (_mode != AppMode.host || _hostService == null) return;

    _readyClients++;

    if (_readyClients == _hostService!.clientCount) {
      await player.seek(Duration.zero);
      await Future.delayed(const Duration(milliseconds: 200));
      //  Pick a time 600ms in the future
      final scheduledTime = DateTime.now().millisecondsSinceEpoch + 600;
      send(Play(0, scheduledTime: scheduledTime).encode());

      _playbackStarted = true;
      print("⏳ Host waiting for 500ms window...");
      await Future.delayed(const Duration(milliseconds: 600));
      await player.player.play();
      print("🎶 Host playback started.");
    }
  }

  //------------------------------------------------------------------------------------------
  void _handleScheduledPlay(Play msg) async {
    if (msg.scheduledTime == null) {
      // Fallback if no time was sent
      await player.seek(Duration(milliseconds: msg.positionMs));
      player.player.play();
      return;
    }
    final localStartTime = msg.scheduledTime! - _clockOffset;
    final now = DateTime.now().millisecondsSinceEpoch;
    final delay = localStartTime - now;
    print('🎯 Scheduled start in ${delay}ms');
    await player.seek(Duration(milliseconds: msg.positionMs));
    if (delay > 0) {
      // 4. Wait for the exact millisecond
      await Future.delayed(Duration(milliseconds: delay));
      player.player.play();
    } else {
      // If the message arrived too late, start immediately
      // (and maybe seek slightly ahead to catch up)
      player.player.play();
    }
  }
  // ----------------------------------------------------------------------------------------

  // --- handle incoming file ---
  Future<void> _handleBinaryMessage(List<int> chunk) async {
    if (_mode != AppMode.client || !_isReceivingFile) return;

    _currentStreamSource?.feed(chunk);
    _receivedBytes += chunk.length;

    _transferProgress =
        (_expectedSize == 0)
            ? 0.0
            : (_receivedBytes / _expectedSize).clamp(0.0, 0.999);
    onTransferProgress?.call();
    // Send "Ready" signal once we have 400KB of the song
    bool isLossless =
        _currentStreamSource?.contentType.contains('flac') ??
        false || _currentStreamSource!.contentType.contains('wav') ??
        false;
    // We reduce 200KB down to 64KB for MP3 for "instant" feel.
    // For FLAC/WAV, we use 150KB.
    final int minBuffer = isLossless ? 256 * 1024 : 64 * 1024;
    if (_receivedBytes >= minBuffer &&
        (_receivedBytes - chunk.length) < minBuffer) {
      send(Ready().encode());
      print(" Buffer threshold reached. Sending READY to host.");
    }
    if (_receivedBytes >= _expectedSize) {
      _isReceivingFile = false;
    }
  }

  // --- host file transfer ---
  Future<void> sendFile(File file) async {
    if (_mode != AppMode.host) return;
    _readyClients = 0;
    _playbackStarted = false;

    final fileName = file.uri.pathSegments.last;
    final mime = getMimeType(fileName);
    final song = LocalSong(
      path: file.path,
      title: file.uri.pathSegments.last,
      artist: "Host",
    );

    await player.playLoadSong(song, [song], autoPlay: false);

    // --- send file to client ---
    final size = await file.length();

    send(
      FileInfo(
        name: file.uri.pathSegments.last,
        size: size,
        mimeType: mime,
      ).encode(),
    );

    final stream = file.openRead();
    int bytesSent = 0;
    const int initialThreshold = 400 * 1024; //4kb of threshold

    await for (final chunk in stream) {
      _hostService?.send(chunk);
      bytesSent += chunk.length;

      if (bytesSent >= initialThreshold) {
        print(
          "⏸ Initial buffer sent ($bytesSent bytes). Stalling to prioritize Play command.",
        );
        break;
      }
    }
    // -- Send remaining file chunks ---
    while (!_playbackStarted) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    print("▶ Playback started on clients. Resuming remaining file transfer...");
    final remainingStream = file.openRead(bytesSent);
    await for (final chunk in remainingStream) {
      _hostService?.send(chunk);
    }
    // -- send EOF signal ---
    send(FileEnd().encode());
    print("✅ File sent. Waiting for Client 'Ready' signals...");
  }

  Future<void> _handleTimeSync(SyncTime msg) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_mode == AppMode.host) {
      // HOST: send with receive and transmit time
      send(
        SyncTime(
          clientTransmitTime: msg.clientTransmitTime,
          serverReceiveTime: now,
          serverTransmitTime: now,
        ).encode(),
      );
    } else {
      // CLIENT:Calculate the offset
      int roundTripTime = now - msg.clientTransmitTime;
      // Assuming the network delay is symmetrical (RTT / 2)
      _clockOffset =
          ((msg.serverReceiveTime! - msg.clientTransmitTime) +
              (msg.serverTransmitTime! - now)) ~/
          2;
      print(
        "🕒 Clock Offset calculated: $_clockOffset ms | RTT: $roundTripTime ms",
      );
    }
  }
}
