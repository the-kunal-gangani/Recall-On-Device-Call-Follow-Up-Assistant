import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class ModelDownloadProgress {
  final String modelName;
  final int received;
  final int total;

  ModelDownloadProgress({
    required this.modelName,
    required this.received,
    required this.total,
  });

  double get fraction => total > 0 ? received / total : 0;
}

class ModelDownloader {
  static const _whisperUrl =
      'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin';
  static const _gemmaUrl =
      'https://huggingface.co/litert-community/Gemma2-2B-IT/resolve/main/gemma-2b-it.task';

  static Future<void> downloadAll({
    required void Function(ModelDownloadProgress) onProgress,
  }) async {
    final appDir = await getApplicationSupportDirectory();
    final modelsDir = Directory('${appDir.path}/models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    await _downloadOne(
      url: _whisperUrl,
      destPath: '${modelsDir.path}/ggml-base.bin',
      modelName: 'whisper',
      onProgress: onProgress,
    );

    await _downloadOne(
      url: _gemmaUrl,
      destPath: '${modelsDir.path}/gemma-2b-it.task',
      modelName: 'gemma',
      onProgress: onProgress,
    );
  }

  static Future<void> _downloadOne({
    required String url,
    required String destPath,
    required String modelName,
    required void Function(ModelDownloadProgress) onProgress,
  }) async {
    final dio = Dio();
    final tempPath = '$destPath.part';

    await dio.download(
      url,
      tempPath,
      onReceiveProgress: (received, total) {
        onProgress(
          ModelDownloadProgress(
            modelName: modelName,
            received: received,
            total: total,
          ),
        );
      },
    );

    final tempFile = File(tempPath);
    await tempFile.rename(destPath);
  }
}
