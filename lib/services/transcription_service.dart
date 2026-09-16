import 'dart:io';
import 'package:whisper_ggml/whisper_ggml.dart';
import 'package:path_provider/path_provider.dart';
import '../core/model/model_exceptions.dart';

class TranscriptionService {
  static WhisperController? _controller;
  static const _modelName = 'ggml-base.bin';
  // Base model is roughly 140MB — anything much smaller means a partial download.
  static const int _minExpectedBytes = 100 * 1024 * 1024;

  static Future<void> initialize() async {
    _controller ??= WhisperController();
    await _ensureModelHealthy();
  }

  static Future<void> _ensureModelHealthy() async {
    final appDir = await getApplicationSupportDirectory();
    final modelFile = File('${appDir.path}/models/$_modelName');

    if (!await modelFile.exists()) {
      throw ModelMissingException(
        'whisper',
        'Whisper model not found. Run first-time setup to download it.',
      );
    }

    final size = await modelFile.length();
    if (size < _minExpectedBytes) {
      try {
        await modelFile.delete();
      } catch (_) {}
      throw ModelCorruptedException(
        'whisper',
        'Whisper model file appears corrupted or incomplete. Setup needs to run again.',
      );
    }
  }

  static Future<String> transcribe(String audioFilePath) async {
    if (_controller == null) {
      throw StateError('TranscriptionService not initialized');
    }

    final result = await _controller!.transcribe(
      model: WhisperModel.base,
      audioPath: audioFilePath,
      lang: 'auto',
    );

    return result?.transcription.text.trim() ?? '';
  }
}
