import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class LibProvider extends ChangeNotifier{
  List<String> _audioFiles=[];
  List<String> get audioFiles => _audioFiles;


  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.audio.isGranted) return true;
      final status = await Permission.audio.request();
      return status.isGranted;
    }
    return true;
  }


  Future<String?> pickAudioFiles() async {
    if (!await _requestPermission()) {
      return 'PermissionDenied';
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac','flac'],
      );

      if (result != null && result.files.isNotEmpty) {
        _audioFiles = result.paths.whereType<String>().toList();
        notifyListeners();
      }
    } catch (e) {
      return e.toString();
    }

    return null;
  }


  void clearFiles() {
    _audioFiles = [];
    notifyListeners();
  }
  
}