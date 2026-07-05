class Journal {
  const Journal({
    required this.id,
    required this.coupleId,
    required this.authorId,
    required this.entryDate,
    this.mood,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String coupleId;
  final String authorId;
  final DateTime entryDate;
  final String? mood;
  final String content;
  final DateTime createdAt;

  factory Journal.fromMap(Map<String, dynamic> map) {
    return Journal(
      id: map['id'] as String,
      coupleId: map['couple_id'] as String,
      authorId: map['author_id'] as String,
      entryDate: DateTime.parse(map['entry_date'] as String),
      mood: map['mood'] as String?,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}
