import 'package:intl/intl.dart';

import '../models/note.dart';

/// Поиск по ключевым словам и по текстовым представлениям даты и времени.
List<Note> filterNotesByQuery(List<Note> notes, String query) {
  final t = query.trim().toLowerCase();
  if (t.isEmpty) return List<Note>.from(notes);

  final dateFmt = DateFormat('dd.MM.yyyy');
  final timeFmt = DateFormat('HH:mm');

  return notes.where((n) {
    final dateStr = dateFmt.format(n.eventAt).toLowerCase();
    final timeStr = timeFmt.format(n.eventAt).toLowerCase();
    final parts = [
      n.title,
      n.content,
      dateStr,
      timeStr,
    ].map((s) => s.toLowerCase());
    final haystack = parts.join(' ');
    return haystack.contains(t);
  }).toList();
}
