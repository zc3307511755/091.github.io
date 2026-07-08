import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

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
        .update({'nickname': nickname}).eq('id', userId);
  }

  Future<Profile?> updateAvatar({
    required String userId,
    required Uint8List imageBytes,
    required String fileExtension,
    String? oldAvatarPath,
  }) async {
    final safeExtension = _safeImageExtension(fileExtension);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/avatar-$timestamp.$safeExtension';

    await SupabaseService.client.storage.from('avatars').uploadBinary(
          path,
          imageBytes,
          fileOptions: FileOptions(
            contentType: _contentTypeForExtension(safeExtension),
            upsert: true,
          ),
        );

    try {
      final data = await SupabaseService.client
          .from('profiles')
          .update({'avatar_url': path})
          .eq('id', userId)
          .select()
          .maybeSingle();

      if (oldAvatarPath != null &&
          oldAvatarPath.isNotEmpty &&
          oldAvatarPath != path) {
        await SupabaseService.client.storage
            .from('avatars')
            .remove([oldAvatarPath]);
      }

      return data == null ? null : Profile.fromMap(data);
    } catch (_) {
      await SupabaseService.client.storage.from('avatars').remove([path]);
      rethrow;
    }
  }

  Future<String> signedAvatarUrl(String avatarPath) {
    return SupabaseService.client.storage
        .from('avatars')
        .createSignedUrl(avatarPath, 60 * 30);
  }

  String _safeImageExtension(String extension) {
    final normalized = extension.replaceAll('.', '').toLowerCase();
    return switch (normalized) {
      'png' => 'png',
      'webp' => 'webp',
      'heic' => 'heic',
      _ => 'jpg',
    };
  }

  String _contentTypeForExtension(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
  }
}
