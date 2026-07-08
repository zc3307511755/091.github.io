import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  StreamSubscription<AuthState>? _subscription;
  User? _user;
  Profile? _profile;
  bool _isLoading = true;
  String? _error;

  User? get user => _user;
  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void bootstrap() {
    _user = _authService.currentUser;
    _loadProfile();
    _subscription ??= _authService.authStateChanges.listen((state) {
      _user = state.session?.user;
      _loadProfile();
    });
  }

  Future<void> signIn(String email, String password) async {
    await _run(() async {
      final response = await _authService.signIn(
        email: email,
        password: password,
      );
      _user = response.user;
      await _loadProfile();
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    await _run(() async {
      final response = await _authService.signUp(
        email: email,
        password: password,
        nickname: nickname,
      );
      final signedInUser = response.session?.user ?? _authService.currentUser;
      if (signedInUser == null) {
        throw Exception('注册成功，请先完成邮箱验证后再登录。');
      }

      _user = signedInUser;
      await _loadProfile();
    });
  }

  Future<void> signOut() async {
    await _run(() async {
      await _authService.signOut();
      _user = null;
      _profile = null;
    });
  }

  Future<void> updateNickname(String nickname) async {
    final currentUser = _user;
    final trimmed = nickname.trim();
    if (currentUser == null) {
      throw Exception('请先登录后再修改名字。');
    }
    if (trimmed.isEmpty) {
      throw Exception('名字不能为空。');
    }
    if (trimmed.length > 20) {
      throw Exception('名字最多 20 个字。');
    }

    await _run(() async {
      _profile =
          await _profileService.updateNickname(currentUser.id, trimmed) ??
              _profile;
    });
  }

  Future<void> updateAvatar({
    required Uint8List imageBytes,
    required String fileExtension,
  }) async {
    final currentUser = _user;
    if (currentUser == null) {
      throw Exception('请先登录后再修改头像。');
    }

    await _run(() async {
      _profile = await _profileService.updateAvatar(
            userId: currentUser.id,
            imageBytes: imageBytes,
            fileExtension: fileExtension,
            oldAvatarPath: _profile?.avatarUrl,
          ) ??
          _profile;
    });
  }

  Future<String> signedAvatarUrl(String avatarPath) {
    return _profileService.signedAvatarUrl(avatarPath);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    final currentUser = _user;
    if (currentUser == null) {
      _profile = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _profile = await _profileService.loadProfile(currentUser.id);
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await action();
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
