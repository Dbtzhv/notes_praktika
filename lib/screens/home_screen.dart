import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_storage_kind.dart';
import '../models/note.dart';
import '../search/note_search.dart';
import '../storage/file_note_storage.dart';
import '../storage/note_storage.dart';
import '../storage/sqlite_note_storage.dart';
import 'note_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  NoteStorage? _storage;
  AppStorageKind _kind = AppStorageKind.sqlite;
  List<Note> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(AppStorageKind.prefKey);
      _kind = AppStorageKind.fromName(name);
      await _applyStorage(prefs, _kind, persist: false);
    } on Object catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _applyStorage(
    SharedPreferences prefs,
    AppStorageKind kind, {
    required bool persist,
  }) async {
    final storage = kind == AppStorageKind.sqlite
        ? SqliteNoteStorage()
        : FileNoteStorage();
    await storage.init();
    final list = await storage.getAll();
    if (persist) {
      await prefs.setString(AppStorageKind.prefKey, kind.name);
    }
    if (!mounted) return;
    setState(() {
      _storage = storage;
      _kind = kind;
      _all = list;
      _loading = false;
      _error = null;
    });
  }

  Future<void> _reloadList() async {
    final s = _storage;
    if (s == null) return;
    final list = await s.getAll();
    if (!mounted) return;
    setState(() => _all = list);
  }

  Future<void> _onStorageChanged(AppStorageKind kind) async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    await _applyStorage(prefs, kind, persist: true);
  }

  Future<void> _confirmDelete(Note note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить заметку?'),
        content: Text('«${note.title}» будет удалена без возможности восстановления из приложения.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _storage?.deleteById(note.id);
    await _reloadList();
  }

  Future<void> _openEditor([Note? note]) async {
    final s = _storage;
    if (s == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NoteEditScreen(storage: s, existing: note),
      ),
    );
    if (changed == true && mounted) {
      await _reloadList();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filterNotesByQuery(_all, _searchController.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заметки мероприятий'),
        actions: [
          IconButton(
            tooltip: 'Обновить список',
            onPressed: _loading ? null : _reloadList,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DrawerHeader(
                child: Text(
                  'Хранилище данных',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Два независимых варианта: база SQLite и файлы JSON в каталоге приложения. При переключении отображаются только заметки выбранного хранилища.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              ...AppStorageKind.values.map(
                (k) => ListTile(
                  leading: Icon(
                    _kind == k ? Icons.radio_button_checked : Icons.radio_button_off,
                  ),
                  title: Text(k.title),
                  enabled: !_loading,
                  onTap:
                      _loading || _kind == k ? null : () => _onStorageChanged(k),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Ошибка: $_error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: SearchBar(
                        controller: _searchController,
                        hintText: 'Поиск по тексту, дате (дд.мм.гггг) или времени',
                        leading: const Icon(Icons.search),
                        trailing: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            ),
                        ],
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                _all.isEmpty
                                    ? 'Нет заметок. Нажмите «+», чтобы добавить первую.'
                                    : 'Ничего не найдено. Измените запрос.',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 88),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final n = filtered[i];
                                final date = MaterialLocalizations.of(context)
                                    .formatFullDate(n.eventAt);
                                final time = TimeOfDay.fromDateTime(n.eventAt)
                                    .format(context);
                                return ListTile(
                                  title: Text(
                                    n.title.isEmpty ? '(без заголовка)' : n.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text('$date · $time'),
                                  isThreeLine: false,
                                  onTap: () => _openEditor(n),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _confirmDelete(n),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading || _storage == null ? null : () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Новая заметка'),
      ),
    );
  }
}
