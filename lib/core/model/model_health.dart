import 'dart:io';

class ModelHealth {
  // Gemma 2B quantized .task file is expected in this rough size range.
  // Anything wildly smaller almost certainly means a partial/failed download.
  static const int _minExpectedGemmaBytes = 1200 * 1024 * 1024; // ~1.2GB floor

  static Future<void> checkGemmaModel(String modelPath) async {
    final file = File(modelPath);

    if (!await file.exists()) {
      throw Exception('missing:$modelPath');
    }

    final size = await file.length();
    if (size < _minExpectedGemmaBytes) {
      // Partial download or truncated file — remove it so the next
      // setup attempt starts clean instead of resuming a broken file.
      try {
        await file.delete();
      } catch (_) {}
      throw Exception('corrupted:$modelPath');
    }
  }
}
