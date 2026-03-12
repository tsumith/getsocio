import 'dart:async';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart';

class StreamingBufferSource extends StreamAudioSource {
  final List<int> _buffer = []; // -- buffer for prefetching --
  final int totalSize;
  bool _isFinished = false; //- end file stream --
  final String contentType;
  final StreamController<List<int>> _eventController =
      StreamController<List<int>>.broadcast();
  StreamingBufferSource({
    required this.totalSize,
    required this.contentType,
    dynamic tag,
  }) : super(tag: tag);

  void feed(List<int> chunk) {
    if (_isFinished) return;
    _buffer.addAll(chunk);
    _eventController.add(chunk); // Notify listeners that data grew
  }

  void finish() {
    _isFinished = true;
    if (!_eventController.isClosed) {
      _eventController.add([]);
    }
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= totalSize;

    print(
      "📡 Stream request: $start → $end (buffer: ${_buffer.length}, finished: $_isFinished)",
    );

    return StreamAudioResponse(
      sourceLength: totalSize,
      contentLength: end - start,
      offset: start,
      contentType: contentType,
      stream: _createByteStream(start, end),
    );
  }

  Stream<List<int>> _createByteStream(int start, int end) async* {
    int currentPos = start;
    // yield data in already buffer
    if (currentPos < _buffer.length) {
      final intialEnd = (end < _buffer.length) ? end : _buffer.length;
      yield _buffer.sublist(currentPos, intialEnd);
      currentPos = intialEnd;
    }
    // listen to the controller for new chunks
    if (currentPos < end && !_isFinished) {
      await for (final chunk in _eventController.stream) {
        if (currentPos >= end) break;

        // ensure we dont yield more than requested 'end'
        if (currentPos + chunk.length > end) {
          final remaining = end - currentPos;
          yield chunk.sublist(0, remaining);
          currentPos += end;
          break;
        } else {
          yield chunk;
          currentPos += chunk.length;
        }
        if (_isFinished && currentPos >= _buffer.length) break;
      }
    }
  }
}
