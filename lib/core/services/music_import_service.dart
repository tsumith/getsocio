import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../models/local_song.dart';
import 'db_writer_isolate.dart';

/// ─────────────────────────────────────────────
/// Import Events
/// ─────────────────────────────────────────────

sealed class ImportEvent {}

class ImportStarted extends ImportEvent {
  final int total;
  ImportStarted(this.total);
}

class ImportSong extends ImportEvent {
  final int index;
  final int total;
  final LocalSong song;

  ImportSong({
    required this.index,
    required this.total,
    required this.song,
  });
}

class ImportCompleted extends ImportEvent {}

class ImportError extends ImportEvent {
  final Object error;
  ImportError(this.error);
}

/// ─────────────────────────────────────────────
/// Music Import Service (indexing)
/// ─────────────────────────────────────────────

class MusicImportService {
  Stream<ImportEvent> importFiles(List<PlatformFile> files)  {
    if (files.isEmpty) {
      return const Stream.empty();
    }

    final metadataReceivePort = ReceivePort();
    final controller = StreamController<ImportEvent>();



    () async{
      try {
        final dbHandshakePort = ReceivePort();

        RootIsolateToken? token = RootIsolateToken.instance;

        if (token == null) {
          throw ImportError("Failed to get Isolate Token");
        }

        await Isolate.spawn(dbWriterIsolate, {
          'port':dbHandshakePort.sendPort,
          'token': token,
        });
        final SendPort dbSendPort = await dbHandshakePort.first;


        final appDir = await getApplicationDocumentsDirectory();

        final rawFiles = files
            .where((f) => f.path != null)
            .map((f) => {
          'path': f.path!,
          'name': f.name,
        })
            .toList();

        controller.add(ImportStarted(rawFiles.length));

        await Isolate.spawn(
          _metadataIsolate,
          {
            'sendPort': metadataReceivePort.sendPort,
            'files': rawFiles,
            'coversDir': '${appDir.path}/covers',
          },
        );

        await for (final msg in metadataReceivePort) {
          if (msg == null) break;
          if (msg is! Map) continue;

          switch (msg['type']) {
            case 'song':
              final song = LocalSong(
                path: msg['path'],
                title: msg['title'],
                artist: msg['artist'],
                coverPath: msg['coverPath'],
              );
              dbSendPort.send(DbWriteMessage.song(song));
              controller.add(
                ImportSong(
                  index: msg['index'],
                  total: rawFiles.length,
                  song: song
                ),
              );
              break;

            case 'done':
              dbSendPort.send(DbWriteMessage.done());
              controller.add(ImportCompleted());
              metadataReceivePort.close();
              dbHandshakePort.close();
              break;
          }
        }
      } catch (e) {
        debugPrint("Import Service Error: $e");
        controller.add(ImportError(e));
      } finally {
        if (!controller.isClosed) {
          await controller.close();
        }
      }
    } ();


    return controller.stream;
  }
}

/// ─────────────────────────────────────────────
/// Isolate: metadata + cover extraction only
/// ─────────────────────────────────────────────

Future<void> _metadataIsolate(Map<String, dynamic> params) async {
  final SendPort sendPort = params['sendPort'];
  final List files = params['files'];
  final String coversDirPath = params['coversDir'];

  await Directory(coversDirPath).create(recursive: true);

  for (int i = 0; i < files.length; i++) {
    try {
      final path = files[i]['path'];
      final name = files[i]['name'];

      final file = File(path);
      final metadata = readMetadata(file, getImage: true);

      String? coverPath;

      if (metadata.pictures.isNotEmpty) {
        final decoded = img.decodeImage(metadata.pictures.first.bytes);
        if (decoded != null) {
          final thumb = img.copyResize(decoded, width: 300);
          coverPath =
          '$coversDirPath/${path.hashCode}.jpg';
          await File(coverPath)
              .writeAsBytes(img.encodeJpg(thumb, quality: 85));
        }
      }

      sendPort.send({
        'type': 'song',
        'index': i,
        'path': path,
        'title':  (metadata.title?.trim().isNotEmpty ?? false)
            ? metadata.title
            : name,
        'artist': (metadata.artist?.trim().isNotEmpty ?? false)
            ? metadata.artist
            : 'Unknown Artist',
        'coverPath': coverPath,
      });
    } catch (_) {
      // Skip unreadable/broken files
    }
  }

  sendPort.send({'type': 'done'});
}
