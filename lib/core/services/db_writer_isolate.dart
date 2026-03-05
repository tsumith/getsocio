import 'dart:isolate';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import '../../models/local_song.dart';
import '../database/music_database.dart';

class DbWriteMessage {
  final LocalSong? song;
  final bool done;

  DbWriteMessage.song(this.song) : done = false;
  DbWriteMessage.done() : song = null, done = true;
}

Future<void> dbWriterIsolate(Map<String, dynamic> initData) async {
  final SendPort sendPort = initData['port'];
  final RootIsolateToken token = initData['token'];

  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  final port = ReceivePort();
  sendPort.send(port.sendPort);

  final db = await MusicDatabase.instance.database;

  const batchSize = 50;
  final buffer = <LocalSong>[];

  Future<void> flush() async {
    if (buffer.isEmpty) return;
    await db.transaction((txn) async {
      for (final song in buffer) {
        await txn.insert(
          'local_songs',
          song.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    buffer.clear();
  }

  await for (final msg in port) {
    if (msg is DbWriteMessage) {
      if (msg.done) {
        await flush();
        break;
      }
      if (msg.song != null) {
        buffer.add(msg.song!);
        if (buffer.length >= batchSize) {
          await flush();
        }
      }
    }
  }

  port.close();
}
