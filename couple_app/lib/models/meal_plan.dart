class MealPlan {
  const MealPlan({
    required this.id,
    required this.coupleId,
    required this.mealDate,
    required this.mealType,
    required this.content,
    required this.isDone,
    required this.createdBy,
  });

  final String id;
  final String coupleId;
  final DateTime mealDate;
  final String mealType;
  final String content;
  final bool isDone;
  final String createdBy;

  factory MealPlan.fromMap(Map<String, dynamic> map) {
    return MealPlan(
      id: map['id'] as String,
      coupleId: map['couple_id'] as String,
      mealDate: DateTime.parse(map['meal_date'] as String),
      mealType: map['meal_type'] as String,
      content: map['content'] as String,
      isDone: map['is_done'] as bool? ?? false,
      createdBy: map['created_by'] as String,
    );
  }
}
