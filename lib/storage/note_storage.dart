import '../models/note.dart';

abstract class NoteStorage {
  Future<void> init();

  Future<List<Note>> getAll();

  Future<void> upsert(Note note);

  Future<void> deleteById(String id);
}
