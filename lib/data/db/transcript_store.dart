import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import '../../core/security/key_manager.dart';

class TranscriptStore {
  static Database? _db;

  static Future<Database> _database() async {
    if (_db != null) return _db!;

    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDir.path, 'recall_transcripts.db');
    final dbKey = await KeyManager.getOrCreateDbKey();

    final db = sqlite3.open(dbPath);
    db.execute("PRAGMA key = '$dbKey';");

    db.execute('''
      CREATE TABLE IF NOT EXISTS transcripts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recording_path TEXT NOT NULL,
        transcript TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        extracted INTEGER NOT NULL DEFAULT 0
      );
    ''');

    _db = db;
    return db;
  }

  static Future<void> save({
    required String recordingPath,
    required String transcript,
  }) async {
    final db = await _database();
    db.execute(
      'INSERT INTO transcripts (recording_path, transcript, created_at, extracted) VALUES (?, ?, ?, 0)',
      [recordingPath, transcript, DateTime.now().millisecondsSinceEpoch],
    );
  }

  static Future<List<Map<String, Object?>>> getUnextracted() async {
    final db = await _database();
    final result = db.select(
      'SELECT id, recording_path, transcript, created_at FROM transcripts WHERE extracted = 0',
    );
    return result.map((row) => Map<String, Object?>.from(row)).toList();
  }

  static Future<void> markExtracted(int id) async {
    final db = await _database();
    db.execute('UPDATE transcripts SET extracted = 1 WHERE id = ?', [id]);
  }

  static Future<void> close() async {
    _db?.dispose();
    _db = null;
  }
}
