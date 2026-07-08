import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_update_info.dart';
import '../providers/anniversary_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/coupon_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/todo_provider.dart';
import '../services/app_update_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final coupleProvider = context.watch<CoupleProvider>();
    final couple = coupleProvider.current;
    final user = auth.user;
    final profile = auth.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _EditableAvatar(
                avatarPath: profile?.avatarUrl,
                nickname: profile?.nickname,
                isLoading: auth.isLoading,
                onTap: auth.isLoading ? null : () => _pickAvatar(context),
              ),
              title: Text(profile?.nickname ?? 'User'),
              subtitle: Text(user?.email ?? ''),
            ),
            if (auth.isLoading) const LinearProgressIndicator(),
            if (auth.error != null) ...[
              const SizedBox(height: 8),
              Text(
                _friendlyMessage(auth.error!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.favorite_border),
                    title: const Text('我们俩'),
                    subtitle: Text(
                        couple == null ? '未配对' : '已配对，关系 ID: ${couple.id}'),
                  ),
                  if (couple != null)
                    ListTile(
                      leading: const Icon(Icons.vpn_key_outlined),
                      title: const Text('邀请码'),
                      subtitle: Text(couple.inviteCode),
                    ),
                  if (couple != null)
                    ListTile(
                      leading: Icon(
                        Icons.link_off,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: const Text('解除配对'),
                      subtitle: const Text('解除后可以重新生成或输入邀请码'),
                      enabled: !coupleProvider.isLoading,
                      onTap: coupleProvider.isLoading
                          ? null
                          : () => _confirmLeaveCouple(context),
                    ),
                  if (coupleProvider.isLoading) const LinearProgressIndicator(),
                ],
              ),
            ),
            if (coupleProvider.error != null) ...[
              const SizedBox(height: 8),
              Text(
                coupleProvider.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            const _UpdateTile(),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout),
              label: const Text('退出登录'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final todos = context.read<TodoProvider>();
    final coupons = context.read<CouponProvider>();
    final journals = context.read<JournalProvider>();
    final anniversaries = context.read<AnniversaryProvider>();
    final meals = context.read<MealProvider>();
    final couple = context.read<CoupleProvider>();
    final auth = context.read<AuthProvider>();

    await todos.stopWatching();
    await coupons.stopWatching();
    await journals.stopWatching();
    await anniversaries.stopWatching();
    await meals.stopWatching();

    todos.clear();
    coupons.clear();
    journals.clear();
    anniversaries.clear();
    meals.clear();
    couple.clear();
    await auth.signOut();
  }

  Future<void> _confirmLeaveCouple(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('解除当前配对？'),
          content: const Text('解除后双方会回到配对页面，历史数据不会删除，但需要重新配对才能继续共享内容。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('解除配对'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await context.read<CoupleProvider>().leaveCurrentCouple();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已解除配对，可以重新开始。')),
      );
    } catch (_) {
      // The provider exposes the message for the UI.
    }
  }

  Future<void> _pickAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null || !context.mounted) {
      return;
    }

    final extension =
        picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
    final bytes = await picked.readAsBytes();
    if (!context.mounted) {
      return;
    }

    try {
      await context.read<AuthProvider>().updateAvatar(
            imageBytes: bytes,
            fileExtension: extension,
          );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('头像已更新。')),
      );
    } catch (_) {
      // AuthProvider exposes the message for the UI.
    }
  }

  String _friendlyMessage(String message) {
    const exceptionPrefix = 'Exception: ';
    if (message.startsWith(exceptionPrefix)) {
      return message.substring(exceptionPrefix.length);
    }
    return message;
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.avatarPath,
    required this.nickname,
    required this.isLoading,
    required this.onTap,
  });

  final String? avatarPath;
  final String? nickname;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final initial = _initial(nickname);

    return Tooltip(
      message: '修改头像',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _AvatarImage(
              avatarPath: avatarPath,
              initial: initial,
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isLoading ? Icons.hourglass_top : Icons.photo_camera,
                    size: 14,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initial(String? nickname) {
    final value = nickname?.trim();
    if (value == null || value.isEmpty) {
      return 'U';
    }

    return value.substring(0, 1).toUpperCase();
  }
}

class _AvatarImage extends StatefulWidget {
  const _AvatarImage({
    required this.avatarPath,
    required this.initial,
  });

  final String? avatarPath;
  final String initial;

  @override
  State<_AvatarImage> createState() => _AvatarImageState();
}

class _AvatarImageState extends State<_AvatarImage> {
  Future<String>? _signedUrlFuture;

  @override
  void initState() {
    super.initState();
    _loadSignedUrl();
  }

  @override
  void didUpdateWidget(covariant _AvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarPath != widget.avatarPath) {
      _loadSignedUrl();
    }
  }

  @override
  Widget build(BuildContext context) {
    final future = _signedUrlFuture;
    if (future == null) {
      return _InitialAvatar(initial: widget.initial);
    }

    return FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _InitialAvatar(initial: widget.initial);
        }

        return ClipOval(
          child: Image.network(
            snapshot.data!,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return _InitialAvatar(initial: widget.initial);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return _InitialAvatar(initial: widget.initial);
            },
          ),
        );
      },
    );
  }

  void _loadSignedUrl() {
    final avatarPath = widget.avatarPath;
    if (avatarPath == null || avatarPath.trim().isEmpty) {
      _signedUrlFuture = null;
      return;
    }

    _signedUrlFuture =
        context.read<AuthProvider>().signedAvatarUrl(avatarPath.trim());
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 28,
      child: Text(initial),
    );
  }
}

class _UpdateTile extends StatefulWidget {
  const _UpdateTile();

  @override
  State<_UpdateTile> createState() => _UpdateTileState();
}

class _UpdateTileState extends State<_UpdateTile> {
  final AppUpdateService _service = const AppUpdateService();
  late final Future<String> _versionFuture;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _versionFuture = _service.currentVersionLabel();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: FutureBuilder<String>(
        future: _versionFuture,
        builder: (context, snapshot) {
          final version = snapshot.data;
          return ListTile(
            leading: const Icon(Icons.system_update_alt),
            title: const Text('安卓版更新'),
            subtitle: Text(
              version == null ? '点击检查新版 APK' : '当前版本 $version',
            ),
            trailing: _isChecking
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _isChecking ? null : _checkForUpdate,
          );
        },
      ),
    );
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final status = await _service.checkForUpdate();
      if (!mounted) {
        return;
      }
      await _showUpdateResult(status);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('检查更新失败：$error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _showUpdateResult(AppUpdateStatus status) {
    final notes = status.info.releaseNotes;
    final downloadUrl = status.info.downloadUrl;
    final downloadPageUrl = status.info.downloadPageUrl;

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(status.hasUpdate ? '发现新版本' : '已是最新版本'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('当前版本：${status.currentLabel}'),
              Text('最新版本：${status.latestLabel}'),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '更新内容',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                ...notes.map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $note'),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(status.hasUpdate ? '稍后' : '知道了'),
            ),
            if (status.hasUpdate && downloadPageUrl != null)
              TextButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _openDownload(downloadPageUrl);
                },
                icon: const Icon(Icons.apps),
                label: const Text('更多版本'),
              ),
            if (status.hasUpdate)
              FilledButton.icon(
                onPressed: downloadUrl == null
                    ? null
                    : () async {
                        Navigator.of(context).pop();
                        await _openDownload(downloadUrl);
                      },
                icon: const Icon(Icons.download),
                label: const Text('下载推荐版'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openDownload(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('下载地址不正确。')),
      );
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开下载地址。')),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('打开下载地址失败：$error')),
      );
    }
  }
}
