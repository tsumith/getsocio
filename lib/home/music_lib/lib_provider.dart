import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:getsocio/core/database/music_database.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../../core/services/music_import_service.dart';
import '../../models/local_song.dart';
import 'dart:io';

class LibProvider extends ChangeNotifier {
  final MusicImportService _importService = MusicImportService();
  List<LocalSong> _audioFiles = [];
  String _loadingMessage = "";
  double _importProgress = 0.0;
  bool _isDbLoading = false;
  bool _isImporting = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 30;
  int _totalCount = 0;

  List<LocalSong> get audioFiles => _audioFiles;
  String get loadingMessage => _loadingMessage;
  double get importProgress => _importProgress;
  bool get isDbLoading=> _isDbLoading;
  bool get isImporting=> _isImporting;
  bool get hasMore => _hasMore;
  int get totalCount => _totalCount;

  LibProvider() {
    loadSongsfromDb();
    // Industrial housekeeping: Clean orphans on startup
    Future.delayed(const Duration(seconds: 5), () => cleanOrphanedCovers());
  }

  Future<void> loadSongsfromDb({bool refresh = false}) async {
    if (_isImporting) return;
    if (refresh) {
      _currentPage = 0;
      _audioFiles = [];
      _hasMore = true;
    }

    if (!_hasMore) return;

    _isDbLoading = true;
    notifyListeners();

    try {
      _totalCount = await MusicDatabase.instance.getTotalSongCount();
      final List<LocalSong> newSongs = await MusicDatabase.instance.fetchSongs(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (newSongs.length < _pageSize) _hasMore = false;

      _audioFiles.addAll(newSongs);
      _currentPage++;
    } catch (e) {
      debugPrint("Load from DB error: $e");
    } finally {
      _isDbLoading=false;
      notifyListeners();
    }
  }


  void _beginImportUI(int total) {
    _isImporting = true;
    _importProgress = 0.001;
    _loadingMessage = "Preparing to import $total songs...";
    notifyListeners();
  }

  Future<void> pickAudioFiles() async {

    try {
        final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'flac'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      _beginImportUI(result.files.length);

      await Future.delayed(Duration.zero);

      final stream = _importService.importFiles(result.files);

      await for (final event in stream) {
        if (event is ImportStarted) {
          _loadingMessage = "Importing ${event.total} songs...";
          notifyListeners();
        }

        if (event is ImportSong) {
          _importProgress = (event.index + 1) / event.total;
          _loadingMessage = "Importing: ${event.song.title}";
          _audioFiles.add(event.song);
          notifyListeners();

        }

        if (event is ImportCompleted) {
          _isImporting = false;
          _importProgress = 0;
          await loadSongsfromDb(refresh: true);
          notifyListeners();
        }

        if (event is ImportError) {
          _isImporting = false;
          debugPrint("Import failed: ${event.error}");
          notifyListeners();
        }
      }
    }catch(e){
      _isImporting = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cleanOrphanedCovers() async {
    try {
      final allSongs = await MusicDatabase.instance.fetchSongs();
      final activeCovers = allSongs.map((s) => s.coverPath).whereType<String>().toSet();
      final activeTracks = allSongs.map((s) => s.path).toSet();

      final dir = await getApplicationDocumentsDirectory();

      // Clean Covers
      final coversDir = Directory('${dir.path}/covers');
      if (await coversDir.exists()) {
        await for (var file in coversDir.list()) {
          if (file is File && !activeCovers.contains(file.path)) await file.delete();
        }
      }

      // Clean Tracks (if user deleted from DB but file remains)
      final tracksDir = Directory('${dir.path}/tracks');
      if (await tracksDir.exists()) {
        await for (var file in tracksDir.list()) {
          if (file is File && !activeTracks.contains(file.path)) await file.delete();
        }
      }
    } catch (e) {
      debugPrint("Housekeeping failed: $e");
    }
  }

  Future<void> nukeLibrary() async {
    _isDbLoading = true;

    _loadingMessage = "Destroying all local data...";
    notifyListeners();

    try {
      await MusicDatabase.instance.deleteAllSongs();
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = await getTemporaryDirectory();
      final tracksDir = Directory('${dir.path}/tracks');
      final coversDir = Directory('${dir.path}/covers');
      if (await tracksDir.exists()) {
        await tracksDir.delete(recursive: true);
      }
      if (await coversDir.exists()) {
        await coversDir.delete(recursive: true);
      }
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
      _audioFiles.clear();
    } catch (e) {
      debugPrint("Nuke Error: $e");
    } finally {
      _isDbLoading = false;
      notifyListeners();
    }
  }
}

