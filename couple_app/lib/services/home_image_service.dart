import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

enum HomeImageSlot {
  hero,
  memoryLeft,
  memoryRight;

  String get metadataKey => switch (this) {
        HomeImageSlot.hero => 'home_hero_path',
        HomeImageSlot.memoryLeft => 'home_memory_left_path',
        HomeImageSlot.memoryRight => 'home_memory_right_path',
      };

  String get filePrefix => switch (this) {
        HomeImageSlot.hero => 'hero',
        HomeImageSlot.memoryLeft => 'memory-left',
        HomeImageSlot.memoryRight => 'memory-right',
      };
}

class HomeImageService {
  Future<User> updateImage({
    required User user,
    required HomeImageSlot slot,
    required Uint8List imageBytes,
    required String fileExtension,
  }) async {
    final extension = _safeImageExtension(fileExtension);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${user.id}/home/${slot.filePrefix}-$timestamp.$extension';
    final oldPath = imagePath(user, slot);

    await SupabaseService.client.storage.from('avatars').uploadBinary(
          path,
          imageBytes,
          fileOptions: FileOptions(
            contentType: _contentTypeForExtension(extension),
            upsert: true,
          ),
        );

    try {
      final response = await SupabaseService.client.auth.updateUser(
        UserAttributes(data: {slot.metadataKey: path}),
      );
      final updatedUser = response.user;
      if (updatedUser == null) {
        throw Exception('图片已上传，但用户资料更新失败。');
      }

      if (oldPath != null &&
          oldPath != path &&
          _isOwnedHomePath(user, oldPath)) {
        try {
          await SupabaseService.client.storage
              .from('avatars')
              .remove([oldPath]);
        } catch (_) {
          // A stale image is harmless; keep the new metadata if cleanup fails.
        }
      }

      return updatedUser;
    } catch (_) {
      await SupabaseService.client.storage.from('avatars').remove([path]);
      rethrow;
    }
  }

  String? imagePath(User user, HomeImageSlot slot) {
    final value = user.userMetadata?[slot.metadataKey];
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  Future<String> signedUrl(String imagePath) {
    return SupabaseService.client.storage
        .from('avatars')
        .createSignedUrl(imagePath, 60 * 30);
  }

  bool _isOwnedHomePath(User user, String path) {
    return path.startsWith('${user.id}/home/');
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
