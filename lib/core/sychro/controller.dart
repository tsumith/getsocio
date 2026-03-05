import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:getsocio/core/sychro/client_net_service.dart';
import 'package:getsocio/core/sychro/host_net_service.dart';
import 'package:getsocio/home/music_lib/player_provider.dart';

import '../../models/local_song.dart';
import '../app_mode.dart';
import '../protocol/sync_message.dart';

class SyncController{
  final PlayerProvider player;
  // --- app mode ---
  AppMode _mode=AppMode.solo;
  AppMode get mode=> _mode;

  // --- host and client ----
  HostNetService? _hostService;
  ClientNetService? _clientService;

  // -- clients info --
  int get clientCount=>  _hostService?.clientCount??0;

  // --- file  transfer----
  File? _incomingFile;
  IOSink? _fileSink;
  int _expectedSize = 0;
  int _receivedBytes = 0;
  bool _isReceivingFile = false;

  // --- file transferring getters ---
  double _transferProgress = 0.0;
  double get transferProgress => _transferProgress;
  bool get isReceivingFile => _isReceivingFile;

  // -- track clients--
  int _readyClients = 0;

  // -- callbackfunction while transferring ---
  VoidCallback? onTransferProgress;

  SyncController({required this.player});

  Future<void> startHost({VoidCallback? onClientChange}) async{
    _hostService=HostNetService();
    await _hostService?.start(onClientChange: onClientChange);
    _hostService?.onMessage.listen(_handleIncoming,onError: (err){
      debugPrint("Host Stream Error: $err");
      stop();
    });
    _mode=AppMode.host;
  }

  Future<void> joinHost(String ip)async{
    _clientService=ClientNetService();
    await _clientService!.connect(ip);
    _clientService!.onMessage.listen(_handleIncoming,
      onError: (err) => stop(),
      onDone: () => stop(),);
    _mode=AppMode.client;
  }

  Future<void> stop() async{
    try{
      if (_fileSink != null) {
        await _fileSink!.flush(); // Try to clear buffer
        await _fileSink!.close();
      }
    }catch(e){
      debugPrint("Sink closure error: $e");
    }finally{
      _fileSink = null;
      _incomingFile = null;
      _isReceivingFile = false;
      _expectedSize = 0;
      _receivedBytes = 0;
    }
    try{
      await _hostService?.dispose();
      await _clientService?.dispose();
    }catch(e){
      debugPrint("Disposal error: $e");
    }finally{
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
  void _handleTextMessage(String data) async{
    final SyncMessage message = SyncMessage.decode(data);
    if (message is FileInfo){
      await _onFileInfo(message);
    }
    else if(message is Play){
      print('🎯 Client received Play at ${message.positionMs}ms');
      await player.seek(Duration(milliseconds: message.positionMs));
      player.player.play();
    }
    else if(message is Pause){
      player.player.pause();
    }else if(message is Seek){
      await player.seek(Duration(milliseconds: message.positionMs));
    }else if(message is Ready){
      _onClientReady();
    }
    else if (message is FileEnd) {
      await _finalizeFile();
    }
  }
  // ------onFileInfo triggers file transfer flag ------
  Future<void> _onFileInfo(FileInfo info) async {
    final dir = await Directory.systemTemp.createTemp();
    _incomingFile = File('${dir.path}/${info.name}');
    _fileSink = _incomingFile!.openWrite();

    _expectedSize = info.size;
    _receivedBytes = 0;
    _isReceivingFile = true;
  }

  Future<void> _onClientReady() async {
    if (_mode != AppMode.host || _hostService == null) return;

    _readyClients++;

    if (_readyClients == _hostService!.clientCount) {
      await player.seek(Duration.zero);
      send(Play(0).encode());
      await player.player.play();
      print("All clients ready.");
    }
  }
  // ----------------------------------------------------------------------------------------

  // --- handle incoming file ---
  void _handleBinaryMessage(List<int> chunk) async {
    if(_mode!=AppMode.client) return;
    if(!_isReceivingFile) return;

    _fileSink?.add(chunk);
    _receivedBytes+=chunk.length;

    _transferProgress =
    (_expectedSize == 0) ? 0.0 : (_receivedBytes / _expectedSize).clamp(0.0, 0.999);
    onTransferProgress?.call();
  }

  // --- close sink and play the song ---
  Future<void> _finalizeFile() async {
    if (_mode != AppMode.client) return;
    if (!_isReceivingFile) return;

    await _fileSink?.flush();
    await _fileSink?.close();

    _isReceivingFile = false;
    _transferProgress = 1.0;
    onTransferProgress?.call();

    final song = LocalSong(
      path: _incomingFile!.path,
      title: _incomingFile!.uri.pathSegments.last,
      artist: "Synced",
    );

    await player.playLoadSong(song, [song], autoPlay: false);

     // -- send ready signal to host --
    send(Ready().encode());

    _fileSink = null;
    _incomingFile = null;
    _expectedSize = 0;
    _receivedBytes = 0;
  }
  // --- host file transfer ---
  Future<void> sendFile(File file) async{
    if (_mode != AppMode.host) return;
    _readyClients=0;
    // --- song loading on host side ---
    final song = LocalSong(
      path: file.path,
      title: file.uri.pathSegments.last,
      artist: "Host",
    );
    await player.playLoadSong(song, [song], autoPlay: false);
    // --- send file to client ---
    final size=await file.length();
    send(
      FileInfo(
        name: file.uri.pathSegments.last,
        size: size,
      ).encode(),
    );
    final stream = file.openRead();
    await for(final chunk in stream){
      _hostService?.send(chunk);
    }
    // -- send EOF signal ---
    send(FileEnd().encode());
  }
}