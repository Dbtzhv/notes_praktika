import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/note.dart';
import '../storage/note_storage.dart';

class NoteEditScreen extends StatefulWidget {
  const NoteEditScreen({
    super.key,
    required this.storage,
    this.existing,
  });

  final NoteStorage storage;
  final Note? existing;

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  late DateTime _eventDate;
  late TimeOfDay _eventTime;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final n = widget.existing;
    if (n != null) {
      _titleCtrl.text = n.title;
      _contentCtrl.text = n.content;
      _eventDate = DateTime(n.eventAt.year, n.eventAt.month, n.eventAt.day);
      _eventTime = TimeOfDay.fromDateTime(n.eventAt);
    } else {
      final now = DateTime.now();
      _eventDate = DateTime(now.year, now.month, now.day);
      _eventTime = TimeOfDay.fromDateTime(now);
    }
  }

  DateTime get _combinedEventAt {
    return DateTime(
      _eventDate.year,
      _eventDate.month,
      _eventDate.day,
      _eventTime.hour,
      _eventTime.minute,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Дата мероприятия',
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _eventTime,
      helpText: 'Время',
    );
    if (picked != null) {
      setState(() => _eventTime = picked);
    }
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final id = widget.existing?.id ?? const Uuid().v4();
    final note = Note(
      id: id,
      title: _titleCtrl.text.trim(),
      eventAt: _combinedEventAt,
      content: _contentCtrl.text,
      updatedAt: now,
    );
    await widget.storage.upsert(note);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final dateLabel = loc.formatFullDate(_eventDate);
    final timeLabel = _eventTime.format(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Новая заметка' : 'Редактирование'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Сохранить'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Заголовок',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(dateLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule),
                  label: Text(timeLabel),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentCtrl,
            decoration: const InputDecoration(
              labelText: 'Содержание',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            minLines: 8,
            maxLines: 24,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }
}
