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
    final data = await _ignoreMissingSchema(
      () => SupabaseService.client
          .from('coupon_requests')
          .select()
          .eq('couple_id', coupleId)
          .order('created_at', ascending: false),
      fallback: const [],
    );

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
    final payload = <String, dynamic>{
      'couple_id': coupleId,
      'receiver_id': receiverId,
      'title': title,
      'description': description,
    };
    if (expiresAt != null) {
      payload['expires_at'] = _dateOnly(expiresAt);
    }

    try {
      await SupabaseService.client.from('coupons').insert(payload);
    } on PostgrestException catch (error) {
      if (expiresAt != null && _isMissingSchema(error)) {
        throw const CouponFeatureUnavailable(
          '当前数据库还没有情侣券有效期字段。请先在 Supabase 运行新版 supabase_schema.sql。',
        );
      }
      rethrow;
    }
  }

  Future<void> requestCoupon({
    required String coupleId,
    required String approverId,
    required String title,
    String? description,
    DateTime? expiresAt,
  }) async {
    try {
      await SupabaseService.client.from('coupon_requests').insert({
        'couple_id': coupleId,
        'approver_id': approverId,
        'title': title,
        'description': description,
        'expires_at': expiresAt == null ? null : _dateOnly(expiresAt),
      });
    } on PostgrestException catch (error) {
      if (_isMissingSchema(error)) {
        throw const CouponFeatureUnavailable(
          '当前数据库还没有请求券功能。请先在 Supabase 运行新版 supabase_schema.sql。',
        );
      }
      rethrow;
    }
  }

  Future<void> respondToRequest({
    required String requestId,
    required bool approve,
    String? responseNote,
  }) async {
    try {
      await SupabaseService.client.rpc(
        'respond_coupon_request',
        params: {
          'request_id_input': requestId,
          'approve_input': approve,
          'response_note_input': responseNote,
        },
      );
    } on PostgrestException catch (error) {
      if (_isMissingSchema(error)) {
        throw const CouponFeatureUnavailable(
          '当前数据库还没有请求券处理功能。请先在 Supabase 运行新版 supabase_schema.sql。',
        );
      }
      rethrow;
    }
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

  Future<T> _ignoreMissingSchema<T>(
    Future<T> Function() action, {
    required T fallback,
  }) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      if (_isMissingSchema(error)) {
        return fallback;
      }
      rethrow;
    }
  }

  bool _isMissingSchema(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == 'PGRST202' ||
        error.code == 'PGRST204' ||
        error.code == 'PGRST205' ||
        message.contains('coupon_requests') ||
        message.contains('expires_at') ||
        message.contains('source_request_id') ||
        message.contains('schema cache');
  }
}

class CouponFeatureUnavailable implements Exception {
  const CouponFeatureUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}
