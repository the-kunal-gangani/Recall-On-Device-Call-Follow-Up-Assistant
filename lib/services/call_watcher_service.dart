import 'dart:io';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

const String callWatchTaskName = 'com.recall.callWatchTask';
const String _lastScanKey = 'last_call_scan_timestamp';

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

Future<List<File>> _findNewRecordings(int sinceMillis) async {
  final dirPath = await _resolveCallRecordingsPath();
  if (dirPath == null) return [];

  final dir = Directory(dirPath);
  final files = await dir
      .list()
      .where((entity) => entity is File && entity.path.endsWith('.m4a'))
      .cast<File>()
      .toList();

  final newFiles = <File>[];
  for (final file in files) {
    final stat = await file.stat();
    if (stat.modified.millisecondsSinceEpoch > sinceMillis) {
      newFiles.add(file);
    }
  }
  return newFiles;
}

void callWatchCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != callWatchTaskName) return Future.value(true);

    final prefs = await SharedPreferences.getInstance();
    final lastScan = prefs.getInt(_lastScanKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    final newRecordings = await _findNewRecordings(lastScan);

    for (final recording in newRecordings) {
      await _enqueueForProcessing(recording);
    }

    await prefs.setInt(_lastScanKey, now);
    return Future.value(true);
  });
}

Future<void> _enqueueForProcessing(File recording) async {
  final appDir = await getApplicationDocumentsDirectory();
  final queueFile = File('${appDir.path}/pending_queue.txt');
  await queueFile.writeAsString('${recording.path}\n', mode: FileMode.append);
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
