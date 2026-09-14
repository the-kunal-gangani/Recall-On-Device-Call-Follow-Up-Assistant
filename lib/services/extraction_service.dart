import 'dart:convert';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import '../core/model/model_health.dart';
import '../core/model/model_exceptions.dart';

class ExtractedTask {
  final String description;
  final String? deadlineMentioned;
  final String? person;

  ExtractedTask({
    required this.description,
    this.deadlineMentioned,
    this.person,
  });

  factory ExtractedTask.fromJson(Map<String, dynamic> json) {
    return ExtractedTask(
      description: json['task'] as String,
      deadlineMentioned: json['deadline'] as String?,
      person: json['person'] as String?,
    );
  }
}

class ExtractionService {
  static InferenceModel? _model;
  static const _modelFileName = 'gemma-2b-it.task';

  static Future<void> initialize() async {
    if (_model != null) return;

    final appDir = await getApplicationSupportDirectory();
    final modelPath = '${appDir.path}/models/$_modelFileName';

    try {
      await ModelHealth.checkGemmaModel(modelPath);
    } catch (e) {
      final message = e.toString();
      if (message.contains('missing:')) {
        throw ModelMissingException(
          'gemma',
          'Gemma model not found. Run first-time setup to download it.',
        );
      } else {
        throw ModelCorruptedException(
          'gemma',
          'Gemma model file appears corrupted or incomplete. Setup needs to run again.',
        );
      }
    }

    _model = await FlutterGemmaPlugin.instance.createModel(
      modelType: ModelType.gemmaIt,
      maxTokens: 1024,
    );
  }

  static Future<List<ExtractedTask>> extract(String transcript) async {
    if (_model == null) {
      throw StateError('ExtractionService not initialized');
    }

    final prompt = _buildPrompt(transcript);
    final session = await _model!.createSession();
    await session.addQueryChunk(Message.text(text: prompt, isUser: true));
    final response = await session.getResponse();
    await session.close();

    return _parseResponse(response);
  }

  static String _buildPrompt(String transcript) {
    return '''
Extract any commitments or promises the user made during this call transcript.
Respond ONLY with a JSON array, no other text. Each item must have "task",
"deadline" (or null if not mentioned), and "person" (or null if not clear).
If no commitments were made, respond with [].

Transcript:
$transcript
''';
  }

  static List<ExtractedTask> _parseResponse(String raw) {
    try {
      final cleaned = raw
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final List<dynamic> parsed = jsonDecode(cleaned);
      return parsed
          .map((item) => ExtractedTask.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
