import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/journal.dart';
import 'supabase_service.dart';

class JournalService {
  Future<List<Journal>> loadJournals(String coupleId) async {
    final data = await SupabaseService.client
        .from('journals')
        .select()
        .eq('couple_id', coupleId)
        .order('entry_date', ascending: false)
        .order('created_at', ascending: false);

    return data.map((item) => Journal.fromMap(item)).toList();
  }

  RealtimeChannel subscribe(String coupleId, void Function() onChange) {
    return SupabaseService.client
        .channel('journals:$coupleId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'journals',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_id',
            value: coupleId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  Future<void> addJournal({
    required String coupleId,
    required DateTime entryDate,
    required String content,
    String? mood,
  }) async {
    await SupabaseService.client.from('journals').insert({
      'couple_id': coupleId,
      'entry_date': _dateOnly(entryDate),
      'mood': mood,
      'content': content,
    });
  }

  Future<void> updateJournal({
    required String id,
    required DateTime entryDate,
    required String content,
    String? mood,
  }) async {
    await SupabaseService.client.from('journals').update({
      'entry_date': _dateOnly(entryDate),
      'mood': mood,
      'content': content,
    }).eq('id', id);
  }

  Future<void> deleteJournal(String id) async {
    await SupabaseService.client.from('journals').delete().eq('id', id);
  }

  String _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .substring(0, 10);
  }
}
