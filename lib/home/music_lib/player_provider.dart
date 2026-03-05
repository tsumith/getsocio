import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../models/local_song.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  List<LocalSong> _queue = [];
  int _currentIndex = -1;


  LocalSong? get currentSong => _currentIndex != -1 ? _queue[_currentIndex] : null;
  AudioPlayer get player => _player;
  List<LocalSong> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _player.playing;


  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  PlayerProvider() {
    // Listen to player state changes to update UI (play/pause icons)
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        playAt((_currentIndex + 1) % _queue.length);
      }
    });
    _player.playerStateStream.listen((state) => notifyListeners());
  }

  // --- 1. LOCAL PLAYBACK ---

  Future<void> playLoadSong(LocalSong song, List<LocalSong> currentQueue, {bool autoPlay = true}) async {
    _queue = currentQueue;
    _currentIndex = _queue.indexOf(song);

    await _loadCurrentTrack(autoPlay: autoPlay);
  }

  Future<void> playAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    if (index == _currentIndex) return;

    _currentIndex = index;
    await _loadCurrentTrack();
  }


  Future<void>  _loadCurrentTrack({bool autoPlay = true}) async {
    if (currentSong==null) return;
    final song=currentSong!;

    try {
      final source = AudioSource.uri(
        Uri.parse(song.path),
        tag: MediaItem(
          id: song.path,
          title: song.title,
          artist: song.artist,
          artUri: song.coverPath != null ? Uri.file(song.coverPath!) : null,
        ),
      );

      await _player.setAudioSource(source);
      if (autoPlay) {
        await _player.play();
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Playback Error: $e");
    }
  }


  // --- 2. CONTROLS ---


  void togglePlay() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void next(){
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      _loadCurrentTrack();
    } else {
      _currentIndex = 0;
      _loadCurrentTrack();
    }
  }
  void previous() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _loadCurrentTrack();
    }
  }
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }



  void stopAndClear() {
    _player.stop();
    _currentIndex = -1;
    _queue = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
 

}