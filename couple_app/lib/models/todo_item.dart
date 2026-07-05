class TodoItem {
  const TodoItem({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.isDone,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String coupleId;
  final String title;
  final bool isDone;
  final String createdBy;
  final DateTime createdAt;

  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'] as String,
      coupleId: map['couple_id'] as String,
      title: map['title'] as String,
      isDone: map['is_done'] as bool? ?? false,
      createdBy: map['created_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}
