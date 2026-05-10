import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/note.dart';
import 'note_storage.dart';

class SqliteNoteStorage implements NoteStorage {
  Database? _db;

  @override
  Future<void> init() async {
    if (_db != null) return;
    final docs = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docs.path, 'notes_org.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE notes (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  event_at INTEGER NOT NULL,
  content TEXT NOT NULL,
  updated_at INTEGER NOT NULL
)
''');
      },
    );
  }

  Database get _database {
    final d = _db;
    if (d == null) {
      throw StateError('SqliteNoteStorage.init() must be called first');
    }
    return d;
  }

  @override
  Future<List<Note>> getAll() async {
    final rows = await _database.query(
      'notes',
      orderBy: 'event_at DESC, updated_at DESC',
    );
    return rows.map((r) => Note.fromMap(_rowToMap(r))).toList();
  }

  Map<String, Object?> _rowToMap(Map<String, Object?> r) => {
        'id': r['id'],
        'title': r['title'],
        'event_at': r['event_at'],
        'content': r['content'],
        'updated_at': r['updated_at'],
      };

  @override
  Future<void> upsert(Note note) async {
    await _database.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteById(String id) async {
    await _database.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
