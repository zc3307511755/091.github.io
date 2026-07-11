import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_update_info.dart';
import '../models/profile.dart';
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
import '../widgets/stitch_ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final coupleProvider = context.watch<CoupleProvider>();
    final presence = context.watch<PresenceProvider>();
    final user = auth.user;
    final profile = auth.profile;
    final couple = coupleProvider.current;
    final partnerId = user != null && couple?.isActive == true
        ? couple!.partnerId(user.id)
        : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StitchPageFrame(
        backgroundColor: StitchColors.grouped,
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              const StitchTopBar(
                avatarAsset: 'assets/stitch/profile_self.jpg',
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 18, 16, 26),
                child: Text(
                  '我的',
                  style: TextStyle(
                    color: StitchColors.ink,
                    fontSize: 34,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _PartnerProfileBuilder(
                  partnerId: partnerId,
                  builder: (context, partnerProfile) {
                    return _CoupleProfileCard(
                      selfProfile: profile,
                      partnerProfile: partnerProfile,
                      isLoading: auth.isLoading,
                      onEditAvatar: () => _pickAvatar(context),
                    );
                  },
                ),
              ),
              if (auth.isLoading) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(minHeight: 2),
              ],
              if (auth.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    _friendlyMessage(auth.error!),
                    style: const TextStyle(color: StitchColors.red),
                  ),
                ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StitchGroupCard(
                  child: Column(
                    children: [
                      _SettingsRow(
                        icon: Icons.mail_outline_rounded,
                        iconColor: StitchColors.blue,
                        label: '账号邮箱',
                        trailing: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 210),
                          child: Text(
                            user?.email ?? '未登录',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: StitchColors.muted,
                              fontSize: 15,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                      const Divider(indent: 52),
                      _SettingsRow(
                        icon: Icons.manage_accounts_outlined,
                        iconColor: StitchColors.green,
                        label: '编辑个人资料',
                        onTap: auth.isLoading
                            ? null
                            : () => _editNickname(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StitchGroupCard(
                  child: Column(
                    children: [
                      _SettingsRow(
                        icon: Icons.link_rounded,
                        iconColor: StitchColors.primary,
                        label: '配对状态',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8E1E8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            couple?.isActive == true ? '已配对' : '未配对',
                            style: const TextStyle(
                              color: StitchColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                      const Divider(indent: 52),
                      _SettingsRow(
                        icon: Icons.qr_code_2_rounded,
                        iconColor: const Color(0xFF0070EB),
                        label: '邀请码',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              couple?.inviteCode.isNotEmpty == true
                                  ? couple!.inviteCode
                                  : '暂无',
                              style: const TextStyle(
                                color: StitchColors.muted,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.copy_rounded,
                              size: 20,
                              color: StitchColors.roseLine,
                            ),
                          ],
                        ),
                        onTap: couple?.inviteCode.isNotEmpty == true
                            ? () => _copyInviteCode(context, couple!.inviteCode)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StitchGroupCard(
                  child: Column(
                    children: [
                      _SettingsRow(
                        icon: Icons.wifi_rounded,
                        iconColor: StitchColors.green,
                        label: '连接状态',
                        trailing: _PresenceStatus(
                          presence: partnerId == null
                              ? null
                              : presence.presenceFor(partnerId),
                          isLoading: presence.isLoading,
                        ),
                      ),
                      const Divider(indent: 52),
                      const _UpdateRow(),
                    ],
                  ),
                ),
              ),
              if (presence.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    presence.error!,
                    style: const TextStyle(color: StitchColors.red),
                  ),
                ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StitchGroupCard(
                  child: Column(
                    children: [
                      _DangerAction(
                        label: '解除配对',
                        enabled: couple != null && !coupleProvider.isLoading,
                        onTap: () => _confirmLeaveCouple(context),
                      ),
                      const Divider(),
                      _DangerAction(
                        label: '退出登录',
                        enabled: !auth.isLoading,
                        onTap: () => _signOut(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyInviteCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('邀请码已复制')),
      );
    }
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
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('修改名字'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 20,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: '你的名字',
              counterText: '',
            ),
            onSubmitted: (_) {
              Navigator.of(dialogContext).pop(controller.text.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text.trim());
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('名字已更新。')),
        );
      }
    } catch (_) {
      // AuthProvider exposes the message for the UI.
    }
  }

  Future<void> _confirmLeaveCouple(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('解除当前配对？'),
          content: const Text('解除后双方会回到配对页面，历史数据不会删除，但需要重新配对才能继续共享内容。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已解除配对，可以重新开始。')),
        );
      }
    } catch (_) {
      // CoupleProvider exposes the message for the UI.
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('头像已更新。')),
        );
      }
    } catch (_) {
      // AuthProvider exposes the message for the UI.
    }
  }

  String _friendlyMessage(String message) {
    const exceptionPrefix = 'Exception: ';
    return message.startsWith(exceptionPrefix)
        ? message.substring(exceptionPrefix.length)
        : message;
  }
}

class _CoupleProfileCard extends StatelessWidget {
  const _CoupleProfileCard({
    required this.selfProfile,
    required this.partnerProfile,
    required this.isLoading,
    required this.onEditAvatar,
  });

  final Profile? selfProfile;
  final Profile? partnerProfile;
  final bool isLoading;
  final VoidCallback onEditAvatar;

  @override
  Widget build(BuildContext context) {
    return StitchGroupCard(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: _PersonColumn(
              label: '我',
              nickname: selfProfile?.nickname,
              avatar: _EditableProfileAvatar(
                avatarPath: selfProfile?.avatarUrl,
                fallbackAsset: 'assets/stitch/profile_self.jpg',
                isPartner: false,
                isLoading: isLoading,
                onTap: isLoading ? null : onEditAvatar,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Icon(
              Icons.favorite_border_rounded,
              color: StitchColors.primary,
              size: 42,
            ),
          ),
          Expanded(
            child: _PersonColumn(
              label: '你',
              nickname: partnerProfile?.nickname,
              avatar: _EditableProfileAvatar(
                avatarPath: partnerProfile?.avatarUrl,
                fallbackAsset: 'assets/stitch/profile_partner.jpg',
                isPartner: true,
                isLoading: false,
                onTap: null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonColumn extends StatelessWidget {
  const _PersonColumn({
    required this.label,
    required this.nickname,
    required this.avatar,
  });

  final String label;
  final String? nickname;
  final Widget avatar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        avatar,
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: StitchColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          nickname?.trim().isNotEmpty == true ? nickname!.trim() : '未设置名字',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: StitchColors.muted,
            fontSize: 11,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _EditableProfileAvatar extends StatelessWidget {
  const _EditableProfileAvatar({
    required this.avatarPath,
    required this.fallbackAsset,
    required this.isPartner,
    required this.isLoading,
    required this.onTap,
  });

  final String? avatarPath;
  final String fallbackAsset;
  final bool isPartner;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: onTap == null ? '头像' : '修改头像',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 82,
              height: 82,
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: StitchColors.surface,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: StitchColors.roseLine, width: 2),
                ),
              ),
              child: ClipOval(
                child: _SignedAvatarImage(
                  avatarPath: avatarPath,
                  fallbackAsset: fallbackAsset,
                  isPartner: isPartner,
                ),
              ),
            ),
            if (onTap != null)
              Positioned(
                right: -1,
                bottom: 1,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: const BoxDecoration(
                    color: StitchColors.primary,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  child: Icon(
                    isLoading ? Icons.hourglass_top : Icons.photo_camera,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SignedAvatarImage extends StatefulWidget {
  const _SignedAvatarImage({
    required this.avatarPath,
    required this.fallbackAsset,
    required this.isPartner,
  });

  final String? avatarPath;
  final String fallbackAsset;
  final bool isPartner;

  @override
  State<_SignedAvatarImage> createState() => _SignedAvatarImageState();
}

class _SignedAvatarImageState extends State<_SignedAvatarImage> {
  final ProfileService _profileService = ProfileService();
  Future<String>? _signedUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _SignedAvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarPath != widget.avatarPath) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final future = _signedUrl;
    if (future == null) {
      return Image.asset(widget.fallbackAsset, fit: BoxFit.cover);
    }
    return FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null) {
          return Image.asset(widget.fallbackAsset, fit: BoxFit.cover);
        }
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Image.asset(widget.fallbackAsset, fit: BoxFit.cover);
          },
        );
      },
    );
  }

  void _load() {
    final path = widget.avatarPath?.trim();
    if (path == null || path.isEmpty) {
      _signedUrl = null;
      return;
    }
    _signedUrl = widget.isPartner
        ? _profileService.signedAvatarUrl(path)
        : context.read<AuthProvider>().signedAvatarUrl(path);
  }
}

class _PartnerProfileBuilder extends StatefulWidget {
  const _PartnerProfileBuilder({
    required this.partnerId,
    required this.builder,
  });

  final String? partnerId;
  final Widget Function(BuildContext context, Profile? profile) builder;

  @override
  State<_PartnerProfileBuilder> createState() => _PartnerProfileBuilderState();
}

class _PartnerProfileBuilderState extends State<_PartnerProfileBuilder> {
  final ProfileService _service = ProfileService();
  Future<Profile?>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _PartnerProfileBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.partnerId != widget.partnerId) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) {
      return widget.builder(context, null);
    }
    return FutureBuilder<Profile?>(
      future: future,
      builder: (context, snapshot) => widget.builder(context, snapshot.data),
    );
  }

  void _load() {
    final partnerId = widget.partnerId;
    _future = partnerId == null
        ? null
        : _service.loadVisibleProfile(partnerId).catchError((_) => null);
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: StitchColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: StitchColors.roseLine,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PresenceStatus extends StatelessWidget {
  const _PresenceStatus({required this.presence, required this.isLoading});

  final UserPresence? presence;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final online = presence?.isOnline == true;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.circle,
          size: 10,
          color: online ? const Color(0xFF34C759) : const Color(0xFFAEA5A8),
        ),
        const SizedBox(width: 8),
        Text(
          online ? '在线同步中' : _lastSeenText(presence?.lastSeenAt),
          style: const TextStyle(
            color: StitchColors.muted,
            fontSize: 15,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  String _lastSeenText(DateTime? value) {
    if (value == null) {
      return '等待连接';
    }
    final difference = DateTime.now().difference(value);
    if (difference.inMinutes < 1) {
      return '刚刚在线';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} 分钟前';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours} 小时前';
    }
    return '${difference.inDays} 天前';
  }
}

class _DangerAction extends StatelessWidget {
  const _DangerAction({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 60,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? StitchColors.red : const Color(0xFFAEA5A8),
              fontSize: 17,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateRow extends StatefulWidget {
  const _UpdateRow();

  @override
  State<_UpdateRow> createState() => _UpdateRowState();
}

class _UpdateRowState extends State<_UpdateRow> {
  final AppUpdateService _service = const AppUpdateService();
  late final Future<String> _versionFuture;
  AppUpdateStatus? _lastStatus;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _versionFuture = _service.currentVersionLabel();
    _autoCheckForUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _versionFuture,
      builder: (context, snapshot) {
        return _SettingsRow(
          icon: Icons.info_outline_rounded,
          iconColor: StitchColors.muted,
          label: '版本更新',
          trailing: _isChecking
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : _lastStatus?.hasUpdate == true
                  ? Text(
                      '发现 ${_lastStatus!.info.latestVersion}',
                      style: const TextStyle(
                        color: StitchColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    )
                  : Text(
                      snapshot.data ?? '检查更新',
                      style: const TextStyle(
                        color: StitchColors.muted,
                        fontSize: 15,
                        letterSpacing: 0,
                      ),
                    ),
          onTap: _isChecking ? null : _checkForUpdate,
        );
      },
    );
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _isChecking = true;
    });
    try {
      final status = await _service.checkForUpdate();
      if (mounted) {
        setState(() {
          _lastStatus = status;
        });
        await _showUpdateResult(status);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('检查更新失败：$error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _autoCheckForUpdate() async {
    try {
      final status = await _service.checkForUpdate();
      if (mounted) {
        setState(() {
          _lastStatus = status;
        });
      }
    } catch (_) {
      // Keep the row usable; a manual tap reports any network error.
    }
  }

  Future<void> _showUpdateResult(AppUpdateStatus status) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(status.hasUpdate ? '发现新版本' : '已是最新版本'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('当前版本：${status.currentLabel}'),
              Text('最新版本：${status.latestLabel}'),
              if (status.info.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...status.info.releaseNotes.map((note) => Text('• $note')),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(status.hasUpdate ? '稍后' : '知道了'),
            ),
            if (status.hasUpdate && status.info.downloadPageUrl != null)
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await _openDownload(status.info.downloadPageUrl!);
                },
                child: const Text('更多版本'),
              ),
            if (status.hasUpdate)
              FilledButton.icon(
                onPressed: status.info.downloadUrl == null
                    ? null
                    : () async {
                        Navigator.of(dialogContext).pop();
                        await _openDownload(status.info.downloadUrl!);
                      },
                icon: const Icon(Icons.download_rounded),
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
      return;
    }
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开下载地址。')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开下载地址失败：$error')),
        );
      }
    }
  }
}
