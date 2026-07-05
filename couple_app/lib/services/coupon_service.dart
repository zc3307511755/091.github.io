import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/coupon.dart';
import '../models/coupon_request.dart';
import 'supabase_service.dart';

class CouponService {
  Future<List<Coupon>> loadCoupons(String coupleId) async {
    final data = await SupabaseService.client
        .from('coupons')
        .select()
        .eq('couple_id', coupleId)
        .order('created_at', ascending: false);

    return data.map((item) => Coupon.fromMap(item)).toList();
  }

  Future<List<CouponRequest>> loadCouponRequests(String coupleId) async {
    final data = await SupabaseService.client
        .from('coupon_requests')
        .select()
        .eq('couple_id', coupleId)
        .order('created_at', ascending: false);

    return data.map((item) => CouponRequest.fromMap(item)).toList();
  }

  RealtimeChannel subscribe(String coupleId, void Function() onChange) {
    return SupabaseService.client
        .channel('coupons:$coupleId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'coupons',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_id',
            value: coupleId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  RealtimeChannel subscribeRequests(String coupleId, void Function() onChange) {
    return SupabaseService.client
        .channel('coupon_requests:$coupleId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'coupon_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_id',
            value: coupleId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  Future<void> issueCoupon({
    required String coupleId,
    required String receiverId,
    required String title,
    String? description,
    DateTime? expiresAt,
  }) async {
    await SupabaseService.client.from('coupons').insert({
      'couple_id': coupleId,
      'receiver_id': receiverId,
      'title': title,
      'description': description,
      'expires_at': expiresAt == null ? null : _dateOnly(expiresAt),
    });
  }

  Future<void> requestCoupon({
    required String coupleId,
    required String approverId,
    required String title,
    String? description,
    DateTime? expiresAt,
  }) async {
    await SupabaseService.client.from('coupon_requests').insert({
      'couple_id': coupleId,
      'approver_id': approverId,
      'title': title,
      'description': description,
      'expires_at': expiresAt == null ? null : _dateOnly(expiresAt),
    });
  }

  Future<void> respondToRequest({
    required String requestId,
    required bool approve,
    String? responseNote,
  }) async {
    await SupabaseService.client.rpc(
      'respond_coupon_request',
      params: {
        'request_id_input': requestId,
        'approve_input': approve,
        'response_note_input': responseNote,
      },
    );
  }

  Future<void> useCoupon(String couponId) async {
    await SupabaseService.client.rpc(
      'use_coupon',
      params: {'coupon_id_input': couponId},
    );
  }

  String _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .substring(0, 10);
  }
}
