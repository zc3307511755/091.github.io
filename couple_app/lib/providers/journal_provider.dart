import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/journal.dart';
import '../services/journal_service.dart';
import '../services/supabase_service.dart';

class JournalProvider extends ChangeNotifier {
  final JournalService _service = JournalService();

  List<Journal> _items = [];
  RealtimeChannel? _channel;
  String? _watchedCoupleId;
  bool _isLoading = false;
  String? _error;

  List<Journal> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> watchJournals(String coupleId) async {
    if (_watchedCoupleId == coupleId) {
      return;
    }

    await stopWatching();
    _watchedCoupleId = coupleId;
    await loadJournals(coupleId);
    _channel = _service.subscribe(coupleId, () => loadJournals(coupleId));
  }

  Future<void> stopWatching() async {
    final channel = _channel;
    _channel = null;
    _watchedCoupleId = null;

    if (channel != null) {
      await SupabaseService.client.removeChannel(channel);
    }
  }

  Future<void> loadJournals(String coupleId) async {
    await _run(() async {
      _items = await _service.loadJournals(coupleId);
    });
  }

  Future<void> addJournal({
    required String coupleId,
    required DateTime entryDate,
    required String content,
    String? mood,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await _run(() async {
      await _service.addJournal(
        coupleId: coupleId,
        entryDate: entryDate,
        content: trimmed,
        mood: mood,
      );
      _items = await _service.loadJournals(coupleId);
    });
  }

  Future<void> updateJournal({
    required Journal journal,
    required DateTime entryDate,
    required String content,
    String? mood,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await _run(() async {
      await _service.updateJournal(
        id: journal.id,
        entryDate: entryDate,
        content: trimmed,
        mood: mood,
      );
      final coupleId = _watchedCoupleId ?? journal.coupleId;
      _items = await _service.loadJournals(coupleId);
    });
  }

  Future<void> deleteJournal(Journal journal) async {
    await _run(() async {
      await _service.deleteJournal(journal.id);
      final coupleId = _watchedCoupleId ?? journal.coupleId;
      _items = await _service.loadJournals(coupleId);
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
