import 'package:permission_handler/permission_handler.dart';

class StoragePermissionHandler {
  static Future<bool> requestAll() async {
    final storageStatus = await Permission.manageExternalStorage.request();
    final notificationStatus = await Permission.notification.request();

    return storageStatus.isGranted && notificationStatus.isGranted;
  }

  static Future<bool> hasAllPermissions() async {
    final storageGranted = await Permission.manageExternalStorage.isGranted;
    final notificationGranted = await Permission.notification.isGranted;

    return storageGranted && notificationGranted;
  }
}
