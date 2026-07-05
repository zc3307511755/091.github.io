import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/anniversary.dart';
import '../services/anniversary_service.dart';
import '../services/supabase_service.dart';

class AnniversaryProvider extends ChangeNotifier {
  final AnniversaryService _service = AnniversaryService();

  List<Anniversary> _items = [];
  RealtimeChannel? _channel;
  String? _watchedCoupleId;
  bool _isLoading = false;
  String? _error;

  List<Anniversary> get items {
    final sorted = [..._items];
    sorted.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    return sorted;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> watchAnniversaries(String coupleId) async {
    if (_watchedCoupleId == coupleId) {
      return;
    }

    await stopWatching();
    _watchedCoupleId = coupleId;
    await loadAnniversaries(coupleId);
    _channel = _service.subscribe(
      coupleId,
      () => loadAnniversaries(coupleId),
    );
  }

  Future<void> stopWatching() async {
    final channel = _channel;
    _channel = null;
    _watchedCoupleId = null;

    if (channel != null) {
      await SupabaseService.client.removeChannel(channel);
    }
  }

  Future<void> loadAnniversaries(String coupleId) async {
    await _run(() async {
      _items = await _service.loadAnniversaries(coupleId);
    });
  }

  Future<void> addAnniversary({
    required String coupleId,
    required String title,
    required DateTime eventDate,
    required String type,
    required bool repeatYearly,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await _run(() async {
      await _service.addAnniversary(
        coupleId: coupleId,
        title: trimmed,
        eventDate: eventDate,
        type: type,
        repeatYearly: repeatYearly,
      );
      _items = await _service.loadAnniversaries(coupleId);
    });
  }

  Future<void> updateAnniversary({
    required Anniversary anniversary,
    required String title,
    required DateTime eventDate,
    required String type,
    required bool repeatYearly,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await _run(() async {
      await _service.updateAnniversary(
        id: anniversary.id,
        title: trimmed,
        eventDate: eventDate,
        type: type,
        repeatYearly: repeatYearly,
      );
      final coupleId = _watchedCoupleId ?? anniversary.coupleId;
      _items = await _service.loadAnniversaries(coupleId);
    });
  }

  Future<void> deleteAnniversary(Anniversary anniversary) async {
    await _run(() async {
      await _service.deleteAnniversary(anniversary.id);
      final coupleId = _watchedCoupleId ?? anniversary.coupleId;
      _items = await _service.loadAnniversaries(coupleId);
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
