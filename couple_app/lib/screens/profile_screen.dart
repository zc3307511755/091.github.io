import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/anniversary_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/coupon_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/todo_provider.dart';

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
                    title: const Text('情侣空间'),
                    subtitle: Text(couple == null
                        ? '未配对'
                        : '已配对，关系 ID: ${couple.id}'),
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
