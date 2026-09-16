import 'dart:io';
import 'package:recall/core/model/model_exceptions.dart';

import '../core/security/encrypted_queue.dart';
import 'transcription_service.dart';
import '../data/db/transcript_store.dart';
import '../data/db/task_store.dart';
import 'extraction_service.dart';
import 'reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class QueueProcessor {
  static const _lastModelWarningKey = 'last_model_warning';
  static const _modelWarningCooldownHours = 24;

  static Future<void> _warnModelIssue(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final lastWarning = prefs.getInt(_lastModelWarningKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final hoursSince = (now - lastWarning) / (1000 * 60 * 60);

    if (hoursSince < _modelWarningCooldownHours) return;

    final plugin = FlutterLocalNotificationsPlugin();
    const androidDetails = AndroidNotificationDetails(
      'recall_permission_channel',
      'Setup Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    await plugin.show(
      id: 999998,
      title: 'Recall setup needed',
      body: message,
      notificationDetails: const NotificationDetails(android: androidDetails),
    );

    await prefs.setInt(_lastModelWarningKey, now);
  }

  static Future<void> processPending() async {
    final pendingPaths = await EncryptedQueue.readAll();
    if (pendingPaths.isEmpty) return;

    final processed = <String>[];

    for (final path in pendingPaths) {
      final file = File(path);
      if (!await file.exists()) {
        processed.add(path);
        continue;
      }

      try {
        final transcript = await TranscriptionService.transcribe(path);
        if (transcript.isNotEmpty) {
          await TranscriptStore.save(
            recordingPath: path,
            transcript: transcript,
          );
          await _extractAndSave(transcript);
        }
        await _purgeRecording(file);
        processed.add(path);
      } on ModelMissingException catch (e) {
        await _warnModelIssue(e.message);
        // Don't mark as processed — retry once the model exists.
      } on ModelCorruptedException catch (e) {
        await _warnModelIssue(e.message);
      } catch (e) {
        continue;
      }
    }

    if (processed.isNotEmpty) {
      await EncryptedQueue.removeAll(processed);
    }
  }

  static Future<void> _extractAndSave(String transcript) async {
    try {
      final tasks = await ExtractionService.extract(transcript);
      for (final task in tasks) {
        final id = await TaskStore.saveAll(
          description: task.description,
          deadlineMentioned: task.deadlineMentioned,
          person: task.person,
        );
        await ReminderService.showConfirmPrompt(id, task.description);
      }
    } catch (e) {
      // Extraction failure shouldn't block transcript being saved —
      // transcript stays in TranscriptStore for a manual/retry pass later
    }
  }

  static Future<void> _purgeRecording(File file) async {
    final length = await file.length();
    final zeros = List<int>.filled(length, 0);
    await file.writeAsBytes(zeros, flush: true);
    await file.delete();
  }
}
