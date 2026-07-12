class MealComment {
  const MealComment({
    required this.id,
    required this.mealEntryId,
    required this.coupleId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.authorNickname,
    this.authorAvatarPath,
  });

  final String id;
  final String mealEntryId;
  final String coupleId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final String? authorNickname;
  final String? authorAvatarPath;

  factory MealComment.fromMap(Map<String, dynamic> map) {
    return MealComment(
      id: map['id'] as String,
      mealEntryId: map['meal_entry_id'] as String,
      coupleId: map['couple_id'] as String,
      authorId: map['author_id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  MealComment withAuthorProfile(Map<String, dynamic>? profile) {
    return MealComment(
      id: id,
      mealEntryId: mealEntryId,
      coupleId: coupleId,
      authorId: authorId,
      content: content,
      createdAt: createdAt,
      authorNickname: profile?['nickname'] as String?,
      authorAvatarPath: profile?['avatar_url'] as String?,
    );
  }
}
