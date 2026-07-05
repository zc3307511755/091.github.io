class MealEntry {
  const MealEntry({
    required this.id,
    required this.coupleId,
    required this.authorId,
    required this.mealDate,
    required this.mealType,
    required this.photoPath,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String coupleId;
  final String authorId;
  final DateTime mealDate;
  final String mealType;
  final String photoPath;
  final String? note;
  final DateTime createdAt;

  factory MealEntry.fromMap(Map<String, dynamic> map) {
    return MealEntry(
      id: map['id'] as String,
      coupleId: map['couple_id'] as String,
      authorId: map['author_id'] as String,
      mealDate: DateTime.parse(map['meal_date'] as String),
      mealType: map['meal_type'] as String,
      photoPath: map['photo_path'] as String,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}
