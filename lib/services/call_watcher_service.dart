import 'dart:io';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/security/encrypted_queue.dart';

const String callWatchTaskName = 'com.recall.callWatchTask';
const String _lastScanKey = 'last_call_scan_timestamp';
const Duration _stabilityCheckDelay = Duration(seconds: 3);
const int _minFileAgeSeconds = 10;

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
      final prefs = await SharedPreferences.getInstance();
      final lastScan = prefs.getInt(_lastScanKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      final newRecordings = await _findNewRecordings(lastScan);

      for (final recording in newRecordings) {
        await EncryptedQueue.addPath(recording.path);
      }

      await prefs.setInt(_lastScanKey, now);
    } catch (_) {
      // Whole-task failure (permission revoked, storage unavailable) —
      // WorkManager will retry on the next scheduled 15-minute cycle
      // rather than crashing the background isolate.
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
