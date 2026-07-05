import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/anniversary.dart';
import 'supabase_service.dart';

class AnniversaryService {
  Future<List<Anniversary>> loadAnniversaries(String coupleId) async {
    final data = await SupabaseService.client
        .from('anniversaries')
        .select()
        .eq('couple_id', coupleId)
        .order('event_date');

    return data.map((item) => Anniversary.fromMap(item)).toList();
  }

  RealtimeChannel subscribe(String coupleId, void Function() onChange) {
    return SupabaseService.client
        .channel('anniversaries:$coupleId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'anniversaries',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_id',
            value: coupleId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  Future<void> addAnniversary({
    required String coupleId,
    required String title,
    required DateTime eventDate,
    required String type,
    required bool repeatYearly,
  }) async {
    await SupabaseService.client.from('anniversaries').insert({
      'couple_id': coupleId,
      'title': title,
      'event_date': _dateOnly(eventDate),
      'type': type,
      'repeat_yearly': repeatYearly,
    });
  }

  Future<void> updateAnniversary({
    required String id,
    required String title,
    required DateTime eventDate,
    required String type,
    required bool repeatYearly,
  }) async {
    await SupabaseService.client.from('anniversaries').update({
      'title': title,
      'event_date': _dateOnly(eventDate),
      'type': type,
      'repeat_yearly': repeatYearly,
    }).eq('id', id);
  }

  Future<void> deleteAnniversary(String id) async {
    await SupabaseService.client.from('anniversaries').delete().eq('id', id);
  }

  String _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .substring(0, 10);
  }
}
