import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/todo_item.dart';
import 'supabase_service.dart';

class TodoService {
  Future<List<TodoItem>> loadTodos(String coupleId) async {
    final data = await SupabaseService.client
        .from('todos')
        .select()
        .eq('couple_id', coupleId)
        .order('created_at', ascending: false);

    return data.map((item) => TodoItem.fromMap(item)).toList();
  }

  RealtimeChannel subscribe(String coupleId, void Function() onChange) {
    return SupabaseService.client
        .channel('todos:$coupleId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'todos',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_id',
            value: coupleId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  Future<void> addTodo(String coupleId, String title) {
    return SupabaseService.client.from('todos').insert({
      'couple_id': coupleId,
      'title': title,
    });
  }

  Future<void> setDone(String id, bool isDone) {
    return SupabaseService.client
        .from('todos')
        .update({'is_done': isDone}).eq('id', id);
  }

  Future<void> deleteTodo(String id) {
    return SupabaseService.client.from('todos').delete().eq('id', id);
  }
}
