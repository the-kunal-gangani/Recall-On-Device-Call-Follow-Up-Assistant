class ModelMissingException implements Exception {
  final String modelName;
  final String message;

  ModelMissingException(this.modelName, this.message);

  @override
  String toString() => 'ModelMissingException($modelName): $message';
}

class ModelCorruptedException implements Exception {
  final String modelName;
  final String message;

  ModelCorruptedException(this.modelName, this.message);

  @override
  String toString() => 'ModelCorruptedException($modelName): $message';
}
