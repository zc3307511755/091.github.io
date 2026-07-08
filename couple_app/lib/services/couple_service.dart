import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/couple.dart';
import 'supabase_service.dart';

class CoupleInviteResult {
  const CoupleInviteResult({
    required this.id,
    required this.inviteCode,
  });

  final String id;
  final String inviteCode;

  factory CoupleInviteResult.fromMap(Map<String, dynamic> map) {
    return CoupleInviteResult(
      id: map['id'] as String,
      inviteCode: map['invite_code'] as String,
    );
  }
}

class CoupleService {
  Future<Couple?> loadCurrentCouple() async {
    try {
      final data = await SupabaseService.client
          .from('couples')
          .select()
          .inFilter('status', ['pending', 'active']).maybeSingle();

      return data == null ? null : Couple.fromMap(data);
    } on PostgrestException catch (error) {
      throw CoupleServiceException(_friendlyPostgrestMessage(error));
    }
  }

  Future<CoupleInviteResult> createInvite() async {
    try {
      final data = await SupabaseService.client
          .rpc('create_couple_invite')
          .select()
          .single();

      return CoupleInviteResult.fromMap(data);
    } on PostgrestException catch (error) {
      throw CoupleServiceException(_friendlyPostgrestMessage(error));
    }
  }

  Future<Couple> bindByInviteCode(String inviteCode) async {
    try {
      final data = await SupabaseService.client
          .rpc(
            'bind_couple',
            params: {'invite_code_input': inviteCode},
          )
          .select()
          .single();

      return Couple.fromMap(data);
    } on PostgrestException catch (error) {
      throw CoupleServiceException(_friendlyPostgrestMessage(error));
    }
  }

  Future<void> leaveCurrentCouple() async {
    try {
      await SupabaseService.client.rpc('leave_current_couple');
    } on PostgrestException catch (error) {
      throw CoupleServiceException(_friendlyPostgrestMessage(error));
    }
  }

  String _friendlyPostgrestMessage(PostgrestException error) {
    final message = [
      error.message,
      if (error.details != null) error.details!,
      if (error.hint != null) error.hint!,
      if (error.code != null) error.code!,
    ].join(' ').toLowerCase();

    if (message.contains('user already has an active or pending couple')) {
      return '当前账号已经有配对或待确认的邀请码，请先取消当前邀请码或解除配对后再重新开始。';
    }
    if (message.contains('invalid or used invite code')) {
      return '邀请码无效或已被使用，请确认对方发的是最新邀请码。';
    }
    if (message.contains('cannot bind with your own invite code')) {
      return '不能使用自己生成的邀请码，请让另一方登录后输入。';
    }
    if (message.contains('invite code is required')) {
      return '请输入邀请码。';
    }
    if (message.contains('not authenticated')) {
      return '登录状态已失效，请重新登录后再试。';
    }
    if ((message.contains('multiple') && message.contains('row')) ||
        message.contains('json object requested')) {
      return '当前账号存在多条待处理配对记录，请重置配对状态后重新开始。';
    }
    if (message.contains('leave_current_couple') ||
        message.contains('schema cache') ||
        message.contains('pgrst202')) {
      return '数据库配对功能尚未升级，请先在 Supabase SQL Editor 重新运行 supabase_schema.sql。';
    }

    return error.message;
  }
}

class CoupleServiceException implements Exception {
  const CoupleServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
