import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import '../../core/security/key_manager.dart';

class TaskStore {
  static Database? _db;

  static Future<Database> _database() async {
    if (_db != null) return _db!;

    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDir.path, 'recall_tasks.db');
    final dbKey = await KeyManager.getOrCreateDbKey();

    final db = sqlite3.open(dbPath);
    db.execute("PRAGMA key = '$dbKey';");

    db.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        deadline_mentioned TEXT,
        person TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at INTEGER NOT NULL
      );
    ''');

    _db = db;
    return db;
  }

  static Future<void> updateStatus(int id, String status) async {
    final db = await _database();
    db.execute('UPDATE tasks SET status = ? WHERE id = ?', [status, id]);
  }

  static Future<Map<String, Object?>?> getById(int id) async {
    final db = await _database();
    final result = db.select('SELECT * FROM tasks WHERE id = ?', [id]);
    if (result.isEmpty) return null;
    return Map<String, Object?>.from(result.first);
  }

  static Future<List<Map<String, Object?>>> getByStatus(String status) async {
    final db = await _database();
    final result = db.select(
      'SELECT * FROM tasks WHERE status = ? ORDER BY created_at DESC',
      [status],
    );
    return result.map((row) => Map<String, Object?>.from(row)).toList();
  }

  static Future<List<Map<String, Object?>>> getAll() async {
    final db = await _database();
    final result = db.select('SELECT * FROM tasks ORDER BY created_at DESC');
    return result.map((row) => Map<String, Object?>.from(row)).toList();
  }

  static Future<void> delete(int id) async {
    final db = await _database();
    db.execute('DELETE FROM tasks WHERE id = ?', [id]);
  }

  static Future<int> saveAll({
    required String description,
    String? deadlineMentioned,
    String? person,
  }) async {
    final db = await _database();
    db.execute(
      'INSERT INTO tasks (description, deadline_mentioned, person, status, created_at) VALUES (?, ?, ?, ?, ?)',
      [
        description,
        deadlineMentioned,
        person,
        'pending',
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
    return db.lastInsertRowId;
  }
}
