import 'dart:io';
import 'package:recall/data/db/transcript_store.dart';

import '../core/security/encrypted_queue.dart';
import 'transcription_service.dart';

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

  static Future<void> _purgeRecording(File file) async {
    final length = await file.length();
    final zeros = List<int>.filled(length, 0);
    await file.writeAsBytes(zeros, flush: true);
    await file.delete();
  }
}
