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
    final data = await SupabaseService.client
        .from('couples')
        .select()
        .inFilter('status', ['pending', 'active'])
        .maybeSingle();

    return data == null ? null : Couple.fromMap(data);
  }

  Future<CoupleInviteResult> createInvite() async {
    final data = await SupabaseService.client
        .rpc('create_couple_invite')
        .select()
        .single();

    return CoupleInviteResult.fromMap(data);
  }

  Future<Couple> bindByInviteCode(String inviteCode) async {
    final data = await SupabaseService.client
        .rpc(
          'bind_couple',
          params: {'invite_code_input': inviteCode},
        )
        .select()
        .single();

    return Couple.fromMap(data);
  }
}
