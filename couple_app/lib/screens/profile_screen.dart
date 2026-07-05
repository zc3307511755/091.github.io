import 'package:flutter/material.dart';
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
    final couple = context.watch<CoupleProvider>().current;
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
              leading: CircleAvatar(
                child: Text(
                  _initial(profile?.nickname),
                ),
              ),
              title: Text(profile?.nickname ?? 'User'),
              subtitle: Text(user?.email ?? ''),
            ),
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
                ],
              ),
            ),
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

  String _initial(String? nickname) {
    final value = nickname?.trim();
    if (value == null || value.isEmpty) {
      return 'U';
    }

    return value.substring(0, 1).toUpperCase();
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
            if (status.hasUpdate)
              FilledButton.icon(
                onPressed: downloadUrl == null
                    ? null
                    : () async {
                        Navigator.of(context).pop();
                        await _openDownload(downloadUrl);
                      },
                icon: const Icon(Icons.download),
                label: const Text('下载新版'),
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
