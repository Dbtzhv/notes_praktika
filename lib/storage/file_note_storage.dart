import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/note.dart';
import 'note_storage.dart';

/// Каждая заметка — отдельный JSON-файл в подкаталоге приложения.
class FileNoteStorage implements NoteStorage {
  Directory? _dir;

  @override
  Future<void> init() async {
    if (_dir != null) return;
    final docs = await getApplicationDocumentsDirectory();
    _dir = Directory(p.join(docs.path, 'notes_org_files'));
    await _directory.create(recursive: true);
  }

  Directory get _directory {
    final d = _dir;
    if (d == null) {
      throw StateError('FileNoteStorage.init() must be called first');
    }
    return d;
  }

  Future<File> _fileFor(String id) async {
    return File(p.join(_directory.path, '$id.json'));
  }

  @override
  Future<List<Note>> getAll() async {
    final entities = _directory.listSync(followLinks: false);
    final notes = <Note>[];
    for (final entity in entities) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final text = await entity.readAsString();
        notes.add(Note.fromJsonString(text));
      } on Object {
        continue;
      }
    }
    notes.sort((a, b) {
      final c = b.eventAt.compareTo(a.eventAt);
      return c != 0 ? c : b.updatedAt.compareTo(a.updatedAt);
    });
    return notes;
  }

  @override
  Future<void> upsert(Note note) async {
    final f = await _fileFor(note.id);
    await f.writeAsString(note.toJsonString(), flush: true);
  }

  @override
  Future<void> deleteById(String id) async {
    final f = await _fileFor(id);
    if (await f.exists()) {
      await f.delete();
    }
  }
}
