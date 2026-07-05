import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/coupon.dart';
import '../services/coupon_service.dart';
import '../services/supabase_service.dart';

class CouponProvider extends ChangeNotifier {
  final CouponService _service = CouponService();

  List<Coupon> _items = [];
  RealtimeChannel? _channel;
  String? _watchedCoupleId;
  bool _isLoading = false;
  String? _error;

  List<Coupon> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> watchCoupons(String coupleId) async {
    if (_watchedCoupleId == coupleId) {
      return;
    }

    await stopWatching();
    _watchedCoupleId = coupleId;
    await loadCoupons(coupleId);
    _channel = _service.subscribe(coupleId, () => loadCoupons(coupleId));
  }

  Future<void> stopWatching() async {
    final channel = _channel;
    _channel = null;
    _watchedCoupleId = null;

    if (channel != null) {
      await SupabaseService.client.removeChannel(channel);
    }
  }

  Future<void> loadCoupons(String coupleId) async {
    await _run(() async {
      _items = await _service.loadCoupons(coupleId);
    });
  }

  Future<void> issueCoupon({
    required String coupleId,
    required String receiverId,
    required String title,
    String? description,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedDescription = description?.trim();
    if (trimmedTitle.isEmpty) {
      return;
    }

    await _run(() async {
      await _service.issueCoupon(
        coupleId: coupleId,
        receiverId: receiverId,
        title: trimmedTitle,
        description: trimmedDescription?.isEmpty == true
            ? null
            : trimmedDescription,
      );
      _items = await _service.loadCoupons(coupleId);
    });
  }

  Future<void> useCoupon(Coupon coupon) async {
    await _run(() async {
      await _service.useCoupon(coupon.id);
      final coupleId = _watchedCoupleId ?? coupon.coupleId;
      _items = await _service.loadCoupons(coupleId);
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
