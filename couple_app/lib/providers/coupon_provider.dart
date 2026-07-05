import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/coupon.dart';
import '../models/coupon_request.dart';
import '../services/coupon_service.dart';
import '../services/supabase_service.dart';

class CouponProvider extends ChangeNotifier {
  final CouponService _service = CouponService();

  List<Coupon> _items = [];
  List<CouponRequest> _requests = [];
  RealtimeChannel? _channel;
  RealtimeChannel? _requestChannel;
  String? _watchedCoupleId;
  bool _isLoading = false;
  String? _error;

  List<Coupon> get items => _items;
  List<CouponRequest> get requests => _requests;
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
    _requestChannel = _service.subscribeRequests(
      coupleId,
      () => loadCouponRequests(coupleId),
    );
  }

  Future<void> stopWatching() async {
    final channel = _channel;
    final requestChannel = _requestChannel;
    _channel = null;
    _requestChannel = null;
    _watchedCoupleId = null;

    if (channel != null) {
      await SupabaseService.client.removeChannel(channel);
    }
    if (requestChannel != null) {
      await SupabaseService.client.removeChannel(requestChannel);
    }
  }

  Future<void> loadCoupons(String coupleId) async {
    await _run(() async {
      _items = await _service.loadCoupons(coupleId);
      _requests = await _service.loadCouponRequests(coupleId);
    });
  }

  Future<void> loadCouponRequests(String coupleId) async {
    await _run(() async {
      _requests = await _service.loadCouponRequests(coupleId);
    });
  }

  Future<void> issueCoupon({
    required String coupleId,
    required String receiverId,
    required String title,
    String? description,
    DateTime? expiresAt,
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
        description:
            trimmedDescription?.isEmpty == true ? null : trimmedDescription,
        expiresAt: expiresAt,
      );
      _items = await _service.loadCoupons(coupleId);
    });
  }

  Future<void> requestCoupon({
    required String coupleId,
    required String approverId,
    required String title,
    String? description,
    DateTime? expiresAt,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedDescription = description?.trim();
    if (trimmedTitle.isEmpty) {
      return;
    }

    await _run(() async {
      await _service.requestCoupon(
        coupleId: coupleId,
        approverId: approverId,
        title: trimmedTitle,
        description:
            trimmedDescription?.isEmpty == true ? null : trimmedDescription,
        expiresAt: expiresAt,
      );
      _requests = await _service.loadCouponRequests(coupleId);
    });
  }

  Future<void> respondToRequest(
    CouponRequest request, {
    required bool approve,
    String? responseNote,
  }) async {
    final trimmedNote = responseNote?.trim();
    await _run(() async {
      await _service.respondToRequest(
        requestId: request.id,
        approve: approve,
        responseNote: trimmedNote?.isEmpty == true ? null : trimmedNote,
      );
      final coupleId = _watchedCoupleId ?? request.coupleId;
      _items = await _service.loadCoupons(coupleId);
      _requests = await _service.loadCouponRequests(coupleId);
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
    _requests = [];
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
    final requestChannel = _requestChannel;
    if (channel != null) {
      SupabaseService.client.removeChannel(channel);
    }
    if (requestChannel != null) {
      SupabaseService.client.removeChannel(requestChannel);
    }
    super.dispose();
  }
}
