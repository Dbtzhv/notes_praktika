enum AppStorageKind {
  sqlite('База SQLite'),
  files('Файлы на устройстве');

  const AppStorageKind(this.title);
  final String title;

  static const prefKey = 'notes_storage_backend';

  static AppStorageKind fromName(String? name) {
    return AppStorageKind.values.firstWhere(
      (v) => v.name == name,
      orElse: () => AppStorageKind.sqlite,
    );
  }
}
