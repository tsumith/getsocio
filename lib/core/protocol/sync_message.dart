import 'dart:convert';

abstract class SyncMessage {
  String get type;
  Map<String, dynamic> toJson();

  String encode() => jsonEncode(toJson());

  static SyncMessage decode(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final type = map['type'] as String?;
    switch (type) {
      case FileInfo.typeName:
        return FileInfo.fromJson(map);
      case Play.typeName:
        return Play.fromJson(map);
      case Pause.typeName:
        return Pause();
      case Seek.typeName:
        return Seek.fromJson(map);
      case FileEnd.typeName:
        return FileEnd();
      case Ready.typeName:
        return Ready();
      case SyncTime.typeName:
        return SyncTime.fromJson(map);
      default:
        throw UnsupportedError("Unknown message type  $type");
    }
  }
}
// ---------------- MESSAGES ----------------

// --- fileinfo message model ---
class FileInfo extends SyncMessage {
  static const String typeName = 'file_info';

  final String name;
  final int size;
  final String mimeType;

  FileInfo({required this.name, required this.size, required this.mimeType});

  factory FileInfo.fromJson(Map<String, dynamic> json) =>
      FileInfo(name: json['name'], size: json['size'], mimeType: json['mime']);

  @override
  String get type => typeName;

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'name': name,
    'size': size,
    'mime': mimeType,
  };
}

// --- play message model ---
class Play extends SyncMessage {
  static const String typeName = 'play';

  final int positionMs;
  final int? scheduledTime; // -- for traasfer delay integrate

  Play(this.positionMs, {this.scheduledTime});

  factory Play.fromJson(Map<String, dynamic> json) =>
      Play(json['position'] ?? 0, scheduledTime: json['scheduled_time']);

  @override
  String get type => typeName;

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'position': positionMs,
    'scheduled_time': scheduledTime
  };
}

// --- pause message model ---
class Pause extends SyncMessage {
  static const String typeName = 'pause';

  @override
  String get type => typeName;

  @override
  Map<String, dynamic> toJson() => {'type': type};
}

// --- seek message model ---
class Seek extends SyncMessage {
  static const String typeName = 'seek';

  final int positionMs;

  Seek(this.positionMs);

  factory Seek.fromJson(Map<String, dynamic> json) => Seek(json['position']);
  @override
  String get type => typeName;

  @override
  Map<String, dynamic> toJson() => {'type': type, 'position': positionMs};
}

// --- ready message model ---
class Ready extends SyncMessage {
  static const String typeName = 'ready';

  @override
  String get type => typeName;

  @override
  Map<String, dynamic> toJson() => {'type': type};
}

// --- file transfer end model ---
class FileEnd extends SyncMessage {
  static const String typeName = 'file_end';

  @override
  String get type => typeName;

  @override
  Map<String, dynamic> toJson() => {'type': type};
}

// --- time sync message model (send by client) ---
class SyncTime extends SyncMessage {
  static const String typeName = 'sync_time';

  final int clientTransmitTime;
  final int? serverReceiveTime;
  final int? serverTransmitTime;

  SyncTime({
    required this.clientTransmitTime,
    this.serverReceiveTime,
    this.serverTransmitTime,
  });

  factory SyncTime.fromJson(Map<String, dynamic> json) => SyncTime(
        clientTransmitTime: json['ct'],
        serverReceiveTime: json['sr'],
        serverTransmitTime: json['st'],
      );

  @override
  String get type => typeName;

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'ct': clientTransmitTime,
        'sr': serverReceiveTime,
        'st': serverTransmitTime,
      };
}
