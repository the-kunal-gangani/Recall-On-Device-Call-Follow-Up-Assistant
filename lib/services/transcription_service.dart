import 'dart:io';
import 'package:whisper_ggml/whisper_ggml.dart';
import 'package:path_provider/path_provider.dart';

class TranscriptionService {
  static WhisperController? _controller;
  static const _modelName = 'ggml-base.bin';

  static Future<void> initialize() async {
    _controller ??= WhisperController();
    await _ensureModelDownloaded();
  }

  static Future<void> _ensureModelDownloaded() async {
    final appDir = await getApplicationSupportDirectory();
    final modelFile = File('${appDir.path}/models/$_modelName');

    if (!await modelFile.exists()) {
      throw StateError(
        'Whisper model not bundled. Place $_modelName in assets/models/ '
        'and copy it to ${modelFile.path} on first run.',
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
