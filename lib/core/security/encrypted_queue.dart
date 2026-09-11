import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';
import 'key_manager.dart';

class EncryptedQueue {
  static const _fileName = 'pending_queue.enc';
  static final _algorithm = AesGcm.with256bits();

  static Future<File> _queueFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/$_fileName');
  }

  static Future<SecretKey> _secretKey() async {
    final keyString = await KeyManager.getOrCreateQueueKey();
    final keyBytes = base64Url.decode(keyString);
    return SecretKey(keyBytes);
  }

  static Future<void> removeAll(List<String> pathsToRemove) async {
    final existing = await readAll();
    existing.removeWhere((path) => pathsToRemove.contains(path));
    await _writeAll(existing);
  }

  static Future<void> addPath(String filePath) async {
    final existing = await readAll();
    existing.add(filePath);
    await _writeAll(existing);
  }

  static Future<List<String>> readAll() async {
    final file = await _queueFile();
    if (!await file.exists()) return [];

    final raw = await file.readAsBytes();
    if (raw.isEmpty) return [];

    final nonce = raw.sublist(0, 12);
    final cipherText = raw.sublist(12);

    final secretKey = await _secretKey();
    final secretBox = SecretBox.fromConcatenation(
      cipherText,
      nonceLength: 0,
      macLength: 16,
    );

    try {
      final decrypted = await _algorithm.decrypt(
        SecretBox(secretBox.cipherText, nonce: nonce, mac: secretBox.mac),
        secretKey: secretKey,
      );
      final jsonStr = utf8.decode(decrypted);
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _writeAll(List<String> paths) async {
    final secretKey = await _secretKey();
    final jsonStr = jsonEncode(paths);
    final plainBytes = utf8.encode(jsonStr);

    final nonce = _algorithm.newNonce();
    final secretBox = await _algorithm.encrypt(
      plainBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    final file = await _queueFile();
    final output = BytesBuilder()
      ..add(nonce)
      ..add(secretBox.cipherText)
      ..add(secretBox.mac.bytes);

    await file.writeAsBytes(output.toBytes());
  }

  static Future<void> clear() async {
    await _writeAll([]);
  }
}
