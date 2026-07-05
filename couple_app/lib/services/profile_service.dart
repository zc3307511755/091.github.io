import '../models/profile.dart';
import 'supabase_service.dart';

class ProfileService {
  Future<Profile?> loadProfile(String userId) async {
    final data = await SupabaseService.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return data == null ? null : Profile.fromMap(data);
  }

  Future<void> updateNickname(String userId, String nickname) {
    return SupabaseService.client
        .from('profiles')
        .update({'nickname': nickname})
        .eq('id', userId);
  }
}
