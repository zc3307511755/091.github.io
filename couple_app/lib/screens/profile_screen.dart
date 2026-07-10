import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_update_info.dart';
import '../models/user_presence.dart';
import '../providers/anniversary_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/coupon_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/presence_provider.dart';
import '../providers/todo_provider.dart';
import '../services/app_update_service.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final coupleProvider = context.watch<CoupleProvider>();
    final couple = coupleProvider.current;
    final presence = context.watch<PresenceProvider>();
    final user = auth.user;
    final profile = auth.profile;
    final partnerId = user != null && couple?.isActive == true
        ? couple!.partnerId(user.id)
        : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('我的')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBFC), Color(0xFFFFF5F8), Color(0xFFF5FBFA)],
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
            children: [
              _ProfileHero(
                avatar: _EditableAvatar(
                  avatarPath: profile?.avatarUrl,
                  nickname: profile?.nickname,
                  isLoading: auth.isLoading,
                  onTap: auth.isLoading ? null : () => _pickAvatar(context),
                ),
                nickname: profile?.nickname ?? 'User',
                email: user?.email ?? '',
                isLoading: auth.isLoading,
                onEditNickname: () => _editNickname(context),
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
              Text('我们的连接', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFF1DDE4)),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F5B3342),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE1EA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(
                            Icons.favorite_rounded,
                            color: Color(0xFFE94B78),
                          ),
                        ),
                      ),
                      title: const Text('我们俩'),
                      subtitle: Text(
                        couple == null ? '还没有连接另一半' : '已经和 TA 连接在一起',
                      ),
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
                    if (coupleProvider.isLoading)
                      const LinearProgressIndicator(),
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
              if (user != null && partnerId != null) ...[
                const SizedBox(height: 20),
                _PartnerProfileName(
                  partnerId: partnerId,
                  builder: (context, partnerName) {
                    return _OnlineStatusCard(
                      selfName: profile?.nickname ?? '我',
                      partnerName: partnerName ?? '另一半',
                      selfPresence: presence.presenceFor(user.id),
                      partnerPresence: presence.presenceFor(partnerId),
                      isLoading: presence.isLoading,
                      error: presence.error,
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),
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
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final todos = context.read<TodoProvider>();
    final coupons = context.read<CouponProvider>();
    final journals = context.read<JournalProvider>();
    final anniversaries = context.read<AnniversaryProvider>();
    final meals = context.read<MealProvider>();
    final presence = context.read<PresenceProvider>();
    final couple = context.read<CoupleProvider>();
    final auth = context.read<AuthProvider>();

    await todos.stopWatching();
    await coupons.stopWatching();
    await journals.stopWatching();
    await anniversaries.stopWatching();
    await meals.stopWatching();
    await presence.stopWatching();

    todos.clear();
    coupons.clear();
    journals.clear();
    anniversaries.clear();
    meals.clear();
    presence.clear();
    couple.clear();
    await auth.signOut();
  }

  Future<void> _editNickname(BuildContext context) async {
    final current = context.read<AuthProvider>().profile?.nickname ?? '';
    final controller = TextEditingController(text: current);

    final nickname = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('修改名字'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 20,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: '你的名字',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            onSubmitted: (_) {
              Navigator.of(context).pop(controller.text.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (nickname == null || !context.mounted) {
      return;
    }
    if (nickname.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('名字不能为空。')),
      );
      return;
    }

    try {
      await context.read<AuthProvider>().updateNickname(nickname);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('名字已更新。')),
      );
    } catch (_) {
      // AuthProvider exposes the message for the UI.
    }
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

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.avatar,
    required this.nickname,
    required this.email,
    required this.isLoading,
    required this.onEditNickname,
  });

  final Widget avatar;
  final String nickname;
  final String email;
  final bool isLoading;
  final VoidCallback onEditNickname;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE5ED), Color(0xFFE2F5F1)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x99FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F5B3342),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nickname, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 3),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '在我们俩的小世界里',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF80606D),
                        ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: '修改名字',
              onPressed: isLoading ? null : onEditNickname,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerProfileName extends StatefulWidget {
  const _PartnerProfileName({
    required this.partnerId,
    required this.builder,
  });

  final String partnerId;
  final Widget Function(BuildContext context, String? partnerName) builder;

  @override
  State<_PartnerProfileName> createState() => _PartnerProfileNameState();
}

class _PartnerProfileNameState extends State<_PartnerProfileName> {
  final ProfileService _service = ProfileService();
  Future<String?>? _nameFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _PartnerProfileName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.partnerId != widget.partnerId) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _nameFuture,
      builder: (context, snapshot) {
        return widget.builder(context, snapshot.data);
      },
    );
  }

  void _load() {
    _nameFuture = _service.loadVisibleProfile(widget.partnerId).then((profile) {
      final nickname = profile?.nickname.trim();
      return nickname == null || nickname.isEmpty ? null : nickname;
    }).catchError((_) => null);
  }
}

class _OnlineStatusCard extends StatelessWidget {
  const _OnlineStatusCard({
    required this.selfName,
    required this.partnerName,
    required this.selfPresence,
    required this.partnerPresence,
    required this.isLoading,
    required this.error,
  });

  final String selfName;
  final String partnerName;
  final UserPresence? selfPresence;
  final UserPresence? partnerPresence;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD5EEE9)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ListTile(
            leading: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFD7F3EF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.sensors, color: Color(0xFF249C98)),
              ),
            ),
            title: const Text('在线状态'),
            subtitle: const Text('根据最近活跃时间自动更新'),
            trailing: isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          const Divider(height: 1),
          _PresenceRow(
            label: selfName.trim().isEmpty ? '我' : selfName.trim(),
            presence: selfPresence,
          ),
          _PresenceRow(
            label: partnerName.trim().isEmpty ? '另一半' : partnerName.trim(),
            presence: partnerPresence,
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

class _PresenceRow extends StatelessWidget {
  const _PresenceRow({
    required this.label,
    required this.presence,
  });

  final String label;
  final UserPresence? presence;

  @override
  Widget build(BuildContext context) {
    final isOnline = presence?.isOnline == true;
    final lastSeenAt = presence?.lastSeenAt;
    final color = isOnline
        ? const Color(0xFF2E7D32)
        : Theme.of(context).colorScheme.outline;

    return ListTile(
      leading: Icon(
        Icons.circle,
        size: 12,
        color: color,
      ),
      title: Text(label),
      subtitle: Text(_statusText(isOnline, lastSeenAt)),
    );
  }

  String _statusText(bool isOnline, DateTime? lastSeenAt) {
    if (isOnline) {
      return '在线';
    }
    if (lastSeenAt == null) {
      return '暂无在线记录';
    }

    final diff = DateTime.now().difference(lastSeenAt);
    if (diff.inMinutes < 1) {
      return '刚刚离线';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes} 分钟前在线';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours} 小时前在线';
    }
    return '${diff.inDays} 天前在线';
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
