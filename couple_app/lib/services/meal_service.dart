import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/meal_entry.dart';
import '../models/meal_comment.dart';
import '../models/meal_plan.dart';
import 'supabase_service.dart';

class MealService {
  Future<List<MealEntry>> loadEntries({
    required String coupleId,
    required DateTime date,
  }) async {
    final data = await SupabaseService.client
        .from('meal_entries')
        .select()
        .eq('couple_id', coupleId)
        .eq('meal_date', _dateOnly(date))
        .order('created_at', ascending: false);

    return data.map((item) => MealEntry.fromMap(item)).toList();
  }

  Future<List<MealPlan>> loadPlans({
    required String coupleId,
    required DateTime date,
  }) async {
    final data = await SupabaseService.client
        .from('meal_plans')
        .select()
        .eq('couple_id', coupleId)
        .eq('meal_date', _dateOnly(date))
        .order('meal_type');

    return data.map((item) => MealPlan.fromMap(item)).toList();
  }

  Future<List<MealComment>> loadComments(List<String> mealEntryIds) async {
    if (mealEntryIds.isEmpty) {
      return const [];
    }

    final data = await SupabaseService.client
        .from('meal_comments')
        .select()
        .inFilter('meal_entry_id', mealEntryIds)
        .order('created_at');
    final comments = data.map((item) => MealComment.fromMap(item)).toList();
    final authorIds =
        comments.map((comment) => comment.authorId).toSet().toList();

    if (authorIds.isEmpty) {
      return comments;
    }

    final profileRows = await SupabaseService.client
        .from('profiles')
        .select('id, nickname, avatar_url')
        .inFilter('id', authorIds);
    final profiles = {
      for (final row in profileRows) row['id'] as String: row,
    };

    return comments
        .map((comment) => comment.withAuthorProfile(profiles[comment.authorId]))
        .toList();
  }

  RealtimeChannel subscribeEntries(String coupleId, void Function() onChange) {
    return SupabaseService.client
        .channel('meal_entries:$coupleId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'meal_entries',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_id',
            value: coupleId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  RealtimeChannel subscribePlans(String coupleId, void Function() onChange) {
    return SupabaseService.client
        .channel('meal_plans:$coupleId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'meal_plans',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_id',
            value: coupleId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  RealtimeChannel subscribeComments(
    String coupleId,
    void Function() onChange,
  ) {
    return SupabaseService.client
        .channel('meal_comments:$coupleId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'meal_comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_id',
            value: coupleId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  Future<void> addEntry({
    required String coupleId,
    required String userId,
    required DateTime mealDate,
    required String mealType,
    required Uint8List imageBytes,
    required String fileExtension,
    String? note,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeExtension = fileExtension.replaceAll('.', '').toLowerCase();
    final path = '$coupleId/$userId/$timestamp-$mealType.$safeExtension';
    final contentType = _contentTypeForExtension(safeExtension);

    await SupabaseService.client.storage.from('meals').uploadBinary(
          path,
          imageBytes,
          fileOptions: FileOptions(contentType: contentType),
        );

    try {
      await SupabaseService.client.from('meal_entries').insert({
        'couple_id': coupleId,
        'meal_date': _dateOnly(mealDate),
        'meal_type': mealType,
        'photo_path': path,
        'note': note,
      });
    } catch (_) {
      await SupabaseService.client.storage.from('meals').remove([path]);
      rethrow;
    }
  }

  Future<String> signedPhotoUrl(String photoPath) {
    return SupabaseService.client.storage
        .from('meals')
        .createSignedUrl(photoPath, 60 * 10);
  }

  Future<void> deleteEntry(MealEntry entry) async {
    await SupabaseService.client
        .from('meal_entries')
        .delete()
        .eq('id', entry.id);
    await SupabaseService.client.storage
        .from('meals')
        .remove([entry.photoPath]);
  }

  Future<void> addComment({
    required String mealEntryId,
    required String coupleId,
    required String authorId,
    required String content,
  }) async {
    await SupabaseService.client.from('meal_comments').insert({
      'meal_entry_id': mealEntryId,
      'couple_id': coupleId,
      'author_id': authorId,
      'content': content,
    });
  }

  Future<void> deleteComment(String commentId) async {
    await SupabaseService.client
        .from('meal_comments')
        .delete()
        .eq('id', commentId);
  }

  Future<void> addPlan({
    required String coupleId,
    required DateTime mealDate,
    required String mealType,
    required String content,
  }) async {
    await SupabaseService.client.from('meal_plans').insert({
      'couple_id': coupleId,
      'meal_date': _dateOnly(mealDate),
      'meal_type': mealType,
      'content': content,
    });
  }

  Future<void> setPlanDone(String id, bool isDone) async {
    await SupabaseService.client
        .from('meal_plans')
        .update({'is_done': isDone}).eq('id', id);
  }

  Future<void> deletePlan(String id) async {
    await SupabaseService.client.from('meal_plans').delete().eq('id', id);
  }

  String _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .substring(0, 10);
  }

  String _contentTypeForExtension(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
  }
}
