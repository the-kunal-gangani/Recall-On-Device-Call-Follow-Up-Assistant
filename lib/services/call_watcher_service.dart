import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:recall/core/permissions/storage_permission_handler.dart';
import 'package:recall/data/db/sqlcipher_init.dart';
import 'package:recall/services/extraction_service.dart';
import 'package:recall/services/queue_processor.dart';
import 'package:recall/services/transcription_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/security/encrypted_queue.dart';

const String callWatchTaskName = 'com.recall.callWatchTask';
const String _lastScanKey = 'last_call_scan_timestamp';
const String _lastPermissionWarningKey = 'last_permission_warning';
const Duration _stabilityCheckDelay = Duration(seconds: 3);
const int _minFileAgeSeconds = 10;
const int _permissionWarningCooldownHours = 24;

Future<void> _warnIfPermissionsMissing(SharedPreferences prefs) async {
  final lastWarning = prefs.getInt(_lastPermissionWarningKey) ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;
  final hoursSinceWarning = (now - lastWarning) / (1000 * 60 * 60);

  if (hoursSinceWarning < _permissionWarningCooldownHours) return;

  final plugin = FlutterLocalNotificationsPlugin();
  const androidDetails = AndroidNotificationDetails(
    'recall_permission_channel',
    'Permission Alerts',
    importance: Importance.high,
    priority: Priority.high,
  );

  await plugin.show(
    id: 999999,
    title: 'Recall needs permissions',
    body:
        'Storage or notification access was turned off — reopen Recall to fix this.',
    notificationDetails: const NotificationDetails(android: androidDetails),
  );

  await prefs.setInt(_lastPermissionWarningKey, now);
}

Future<String?> _resolveCallRecordingsPath() async {
  final candidates = [
    '/storage/emulated/0/Recordings/Call',
    '/storage/emulated/0/Call',
  ];

  for (final path in candidates) {
    if (await Directory(path).exists()) {
      return path;
    }
  }
  return null;
}

Future<bool> _isFileStable(File file) async {
  try {
    final sizeBefore = await file.length();
    await Future.delayed(_stabilityCheckDelay);
    if (!await file.exists()) return false;
    final sizeAfter = await file.length();
    return sizeBefore == sizeAfter && sizeAfter > 0;
  } catch (_) {
    return false;
  }
}

Future<bool> _isOldEnough(File file) async {
  try {
    final stat = await file.stat();
    final ageSeconds = DateTime.now().difference(stat.modified).inSeconds;
    return ageSeconds >= _minFileAgeSeconds;
  } catch (_) {
    return false;
  }
}

Future<List<File>> _findNewRecordings(int sinceMillis) async {
  final dirPath = await _resolveCallRecordingsPath();
  if (dirPath == null) {
    // No recorder folder found — either recorder isn't set up, or this
    // device uses a different path. Not an error state, just nothing to do.
    return [];
  }

  final dir = Directory(dirPath);
  List<FileSystemEntity> entities;
  try {
    entities = await dir.list().toList();
  } catch (_) {
    // Folder briefly inaccessible (permission race, storage remount) —
    // skip this cycle, try again next scan.
    return [];
  }

  final candidateFiles = entities
      .whereType<File>()
      .where((f) => f.path.endsWith('.m4a'))
      .toList();

  final newFiles = <File>[];
  for (final file in candidateFiles) {
    try {
      final stat = await file.stat();
      if (stat.modified.millisecondsSinceEpoch <= sinceMillis) continue;

      // Skip files still being written by the recorder.
      if (!await _isOldEnough(file)) continue;
      if (!await _isFileStable(file)) continue;

      newFiles.add(file);
    } catch (_) {
      // Individual file failed to stat/read — skip it, don't fail the batch.
      continue;
    }
  }
  return newFiles;
}

void callWatchCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != callWatchTaskName) return Future.value(true);

    try {
      SqlCipherInit.ensureInitialized();

      try {
        await TranscriptionService.initialize();
      } catch (_) {
        // Missing/corrupted model handled inside processPending's own
        // try/catch when it actually attempts transcription.
      }

      try {
        await ExtractionService.initialize();
      } catch (_) {
        // Same — surfaced via processPending's model-issue notification.
      }

      final prefs = await SharedPreferences.getInstance();

      final hasPermissions = await StoragePermissionHandler.hasAllPermissions();
      if (!hasPermissions) {
        await _warnIfPermissionsMissing(prefs);
        return Future.value(true);
      }

      final lastScan = prefs.getInt(_lastScanKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      final newRecordings = await _findNewRecordings(lastScan);

      for (final recording in newRecordings) {
        await EncryptedQueue.addPath(recording.path);
      }

      await prefs.setInt(_lastScanKey, now);

      await QueueProcessor.processPending();
    } catch (_) {
      // Whole-task failure — WorkManager retries on the next 15-minute cycle.
    }

    return Future.value(true);
  });
}

class CallWatcherService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callWatchCallbackDispatcher);
  }

  static Future<void> schedulePeriodicScan() async {
    await Workmanager().registerPeriodicTask(
      callWatchTaskName,
      callWatchTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(requiresBatteryNotLow: true),
    );
  }
}
