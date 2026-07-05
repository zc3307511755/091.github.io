import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/coupon.dart';
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

  Future<void> issueCoupon({
    required String coupleId,
    required String receiverId,
    required String title,
    String? description,
  }) async {
    await SupabaseService.client.from('coupons').insert({
      'couple_id': coupleId,
      'receiver_id': receiverId,
      'title': title,
      'description': description,
    });
  }

  Future<void> useCoupon(String couponId) async {
    await SupabaseService.client.rpc(
      'use_coupon',
      params: {'coupon_id_input': couponId},
    );
  }
}
