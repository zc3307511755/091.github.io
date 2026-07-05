import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/todo_item.dart';
import '../services/supabase_service.dart';
import '../services/todo_service.dart';

class TodoProvider extends ChangeNotifier {
  final TodoService _service = TodoService();

  List<TodoItem> _items = [];
  RealtimeChannel? _channel;
  String? _watchedCoupleId;
  bool _isLoading = false;
  String? _error;

  List<TodoItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> watchTodos(String coupleId) async {
    if (_watchedCoupleId == coupleId) {
      return;
    }

    await stopWatching();
    _watchedCoupleId = coupleId;
    await loadTodos(coupleId);
    _channel = _service.subscribe(coupleId, () => loadTodos(coupleId));
  }

  Future<void> stopWatching() async {
    final channel = _channel;
    _channel = null;
    _watchedCoupleId = null;

    if (channel != null) {
      await SupabaseService.client.removeChannel(channel);
    }
  }

  Future<void> loadTodos(String coupleId) async {
    await _run(() async {
      _items = await _service.loadTodos(coupleId);
    });
  }

  Future<void> addTodo(String coupleId, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await _run(() async {
      await _service.addTodo(coupleId, trimmed);
      _items = await _service.loadTodos(coupleId);
    });
  }

  Future<void> setDone(TodoItem item, bool isDone) async {
    await _run(() async {
      await _service.setDone(item.id, isDone);
      final coupleId = _watchedCoupleId ?? item.coupleId;
      _items = await _service.loadTodos(coupleId);
    });
  }

  Future<void> deleteTodo(TodoItem item) async {
    await _run(() async {
      await _service.deleteTodo(item.id);
      final coupleId = _watchedCoupleId ?? item.coupleId;
      _items = await _service.loadTodos(coupleId);
    });
  }

  void clear() {
    _items = [];
    _error = null;
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await action();
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) {
      SupabaseService.client.removeChannel(channel);
    }
    super.dispose();
  }
}
