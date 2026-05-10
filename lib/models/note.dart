import 'dart:convert';

class Note {
  Note({
    required this.id,
    required this.title,
    required this.eventAt,
    required this.content,
    required this.updatedAt,
  });

  final String id;
  final String title;

  /// Дата и время мероприятия / записи события (совещание, конференция и т.п.).
  final DateTime eventAt;
  final String content;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'event_at': eventAt.millisecondsSinceEpoch,
        'content': content,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Note.fromMap(Map<String, Object?> map) {
    return Note(
      id: map['id']! as String,
      title: map['title']! as String,
      eventAt:
          DateTime.fromMillisecondsSinceEpoch(map['event_at']! as int),
      content: map['content']! as String,
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
    );
  }

  String toJsonString() =>
      const JsonEncoder.withIndent('  ').convert(toMap());

  factory Note.fromJsonString(String source) =>
      Note.fromMap(jsonDecode(source) as Map<String, dynamic>);

  Note copyWith({
    String? id,
    String? title,
    DateTime? eventAt,
    String? content,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      eventAt: eventAt ?? this.eventAt,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
