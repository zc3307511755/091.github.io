import 'package:couple_app/models/meal_comment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MealComment parses its record and attaches author profile data', () {
    final comment = MealComment.fromMap({
      'id': 'comment-1',
      'meal_entry_id': 'meal-1',
      'couple_id': 'couple-1',
      'author_id': 'user-1',
      'content': '看起来很好吃',
      'created_at': '2026-07-11T12:30:00Z',
    }).withAuthorProfile({
      'nickname': '小超',
      'avatar_url': 'user-1/avatar.jpg',
    });

    expect(comment.mealEntryId, 'meal-1');
    expect(comment.content, '看起来很好吃');
    expect(comment.createdAt.toUtc(), DateTime.utc(2026, 7, 11, 12, 30));
    expect(comment.authorNickname, '小超');
    expect(comment.authorAvatarPath, 'user-1/avatar.jpg');
  });
}
