import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_presence.dart';
import 'supabase_service.dart';

class PresenceService {
  Future<UserPresence> touch() async {
    try {
      final data = await SupabaseService.client
          .rpc('touch_user_presence')
          .select()
          .single();

      return UserPresence.fromMap(data);
    } on PostgrestException catch (error) {
      throw PresenceServiceException(_friendlyPostgrestMessage(error));
    }
  }

  Future<List<UserPresence>> loadVisible(List<String> userIds) async {
    if (userIds.isEmpty) {
      return const [];
    }

    try {
      final data = await SupabaseService.client
          .from('user_presence')
          .select()
          .inFilter('user_id', userIds);

      return data.map((item) => UserPresence.fromMap(item)).toList();
    } on PostgrestException catch (error) {
      throw PresenceServiceException(_friendlyPostgrestMessage(error));
    }
  }

  RealtimeChannel subscribeUser(String userId, void Function() onChange) {
    return SupabaseService.client
        .channel('user_presence:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_presence',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  String _friendlyPostgrestMessage(PostgrestException error) {
    final message = [
      error.message,
      if (error.details != null) error.details!,
      if (error.hint != null) error.hint!,
      if (error.code != null) error.code!,
    ].join(' ').toLowerCase();

    if (message.contains('user_presence') ||
        message.contains('touch_user_presence') ||
        message.contains('schema cache') ||
        message.contains('pgrst202') ||
        message.contains('pgrst205')) {
      return '数据库在线状态功能尚未升级，请先在 Supabase SQL Editor 重新运行 supabase_schema.sql。';
    }

    return error.message;
  }
}

class PresenceServiceException implements Exception {
  const PresenceServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
