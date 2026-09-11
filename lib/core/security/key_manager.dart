import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';

class KeyManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _queueKeyAlias = 'recall_queue_encryption_key';

  static const _dbKeyAlias = 'recall_db_encryption_key';

  static Future<String> getOrCreateDbKey() async {
    final existing = await _storage.read(key: _dbKeyAlias);
    if (existing != null) return existing;

    final newKey = _generateKey();
    await _storage.write(key: _dbKeyAlias, value: newKey);
    return newKey;
  }

  static Future<String> getOrCreateQueueKey() async {
    final existing = await _storage.read(key: _queueKeyAlias);
    if (existing != null) return existing;

    final newKey = _generateKey();
    await _storage.write(key: _queueKeyAlias, value: newKey);
    return newKey;
  }

  static String _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
