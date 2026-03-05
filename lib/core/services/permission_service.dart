import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<void> requestAllPermissions() async {
    if (Platform.isAndroid) {
      // 1. Audio Permissions (for LibProvider)
      // 2. Location & Nearby (for SyncProvider/Hotspot)
      Map<Permission, PermissionStatus> statuses = await [
        Permission.audio,
        Permission.location,
        Permission.nearbyWifiDevices,
      ].request();

      // Optional: Check if something was permanently denied
      if (statuses[Permission.location]!.isPermanentlyDenied) {
        openAppSettings();
      }
    }
  }
}