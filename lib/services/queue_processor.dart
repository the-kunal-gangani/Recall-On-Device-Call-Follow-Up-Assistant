import 'dart:io';
import '../core/security/encrypted_queue.dart';
import 'transcription_service.dart';
import '../data/db/transcript_store.dart';
import '../data/db/task_store.dart';
import 'extraction_service.dart';
import 'reminder_service.dart';

class QueueProcessor {
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
