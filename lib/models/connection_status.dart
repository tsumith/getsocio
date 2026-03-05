import '../core/app_mode.dart';

enum SyncStatus {
  standby,
  scanning,
  active,
}

class ConnectionState {
  final AppMode mode;
  final SyncStatus status;
  final int clientCount;

  const ConnectionState({
    required this.mode,
    required this.status,
    required this.clientCount,
  });
}