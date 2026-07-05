import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/anniversary.dart';
import '../models/journal.dart';
import '../models/todo_item.dart';
import '../providers/anniversary_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/coupon_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/todo_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.onOpenTab,
    super.key,
  });

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final couple = context.watch<CoupleProvider>().current;
    final todos = context.watch<TodoProvider>();
    final coupons = context.watch<CouponProvider>();
    final journals = context.watch<JournalProvider>();
    final anniversaries = context.watch<AnniversaryProvider>();
    final meals = context.watch<MealProvider>();

    final openTodos = todos.items.where((item) => !item.isDone).toList();
    final unusedCoupons =
        coupons.items.where((coupon) => coupon.isUnused).length;
    final nextAnniversary =
        anniversaries.items.isEmpty ? null : anniversaries.items.first;
    final latestJournal = journals.items.isEmpty ? null : journals.items.first;
    final todayPlanCount = meals.plans.where((plan) => !plan.isDone).length;
    final todayPhotoCount = meals.entries.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        actions: [
          IconButton(
            tooltip: '我的',
            onPressed: () => onOpenTab(6),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _HeroSummary(
                nickname: auth.profile?.nickname,
                pairedAt: couple?.pairedAt,
              ),
              const SizedBox(height: 16),
              _QuickActions(onOpenTab: onOpenTab),
              const SizedBox(height: 16),
              _MetricsGrid(
                openTodoCount: openTodos.length,
                unusedCouponCount: unusedCoupons,
                todayPlanCount: todayPlanCount,
                todayPhotoCount: todayPhotoCount,
              ),
              const SizedBox(height: 16),
              _NextAnniversarySection(
                item: nextAnniversary,
                onOpenAnniversaries: () => onOpenTab(5),
              ),
              const SizedBox(height: 16),
              _TodoPreviewSection(
                items: openTodos.take(3).toList(),
                isLoading: todos.isLoading,
                onOpenTodos: () => onOpenTab(1),
              ),
              const SizedBox(height: 16),
              _JournalPreviewSection(
                item: latestJournal,
                onOpenJournals: () => onOpenTab(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    final couple = context.read<CoupleProvider>().current;
    if (couple == null) {
      return;
    }

    await Future.wait([
      context.read<TodoProvider>().loadTodos(couple.id),
      context.read<CouponProvider>().loadCoupons(couple.id),
      context.read<JournalProvider>().loadJournals(couple.id),
      context.read<AnniversaryProvider>().loadAnniversaries(couple.id),
      context.read<MealProvider>().loadForDate(couple.id, DateTime.now()),
    ]);
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({
    required this.nickname,
    required this.pairedAt,
  });

  final String? nickname;
  final DateTime? pairedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = _daysTogether(pairedAt);
    final greeting = _greeting();
    final name = nickname?.trim().isNotEmpty == true ? nickname!.trim() : '今天';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting，$name',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              days == null ? '情侣空间已经准备好了' : '这是你们在一起的第 $days 天',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _todayLabel(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int? _daysTogether(DateTime? date) {
    if (date == null) {
      return null;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(date.year, date.month, date.day);
    return today.difference(start).inDays + 1;
  }

  String _todayLabel() {
    final now = DateTime.now();
    const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return '${DateFormat('yyyy年MM月dd日').format(now)} ${weekdays[now.weekday - 1]}';
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) {
      return '夜深啦';
    }
    if (hour < 12) {
      return '早上好';
    }
    if (hour < 18) {
      return '下午好';
    }
    return '晚上好';
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.92,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _ActionTile(
          icon: Icons.add_task,
          label: '待办',
          onTap: () => onOpenTab(1),
        ),
        _ActionTile(
          icon: Icons.card_giftcard,
          label: '发券',
          onTap: () => onOpenTab(2),
        ),
        _ActionTile(
          icon: Icons.restaurant_menu,
          label: '吃啥',
          onTap: () => onOpenTab(3),
        ),
        _ActionTile(
          icon: Icons.edit_note,
          label: '日志',
          onTap: () => onOpenTab(4),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.openTodoCount,
    required this.unusedCouponCount,
    required this.todayPlanCount,
    required this.todayPhotoCount,
  });

  final int openTodoCount;
  final int unusedCouponCount;
  final int todayPlanCount;
  final int todayPhotoCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = constraints.maxWidth >= 520 ? 12.0 : 8.0;
        final columns = constraints.maxWidth >= 520 ? 4 : 2;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _MetricTile(
              width: width,
              label: '未完成',
              value: openTodoCount.toString(),
              icon: Icons.checklist,
            ),
            _MetricTile(
              width: width,
              label: '可用券',
              value: unusedCouponCount.toString(),
              icon: Icons.local_activity_outlined,
            ),
            _MetricTile(
              width: width,
              label: '今日计划',
              value: todayPlanCount.toString(),
              icon: Icons.restaurant_outlined,
            ),
            _MetricTile(
              width: width,
              label: '今日照片',
              value: todayPhotoCount.toString(),
              icon: Icons.photo_library_outlined,
            ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.secondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextAnniversarySection extends StatelessWidget {
  const _NextAnniversarySection({
    required this.item,
    required this.onOpenAnniversaries,
  });

  final Anniversary? item;
  final VoidCallback onOpenAnniversaries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final anniversary = item;

    return _SectionShell(
      title: '最近纪念日',
      actionLabel: '查看',
      onAction: onOpenAnniversaries,
      child: anniversary == null
          ? const Text('还没有纪念日，去添加一个值得记住的日子。')
          : Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  child: Text(_iconForType(anniversary.type)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anniversary.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        anniversary.daysLeft == 0
                            ? '就是今天'
                            : '还有 ${anniversary.daysLeft} 天',
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _iconForType(String type) {
    return switch (type) {
      'together' => '💕',
      'birthday' => '🎂',
      _ => '🎉',
    };
  }
}

class _TodoPreviewSection extends StatelessWidget {
  const _TodoPreviewSection({
    required this.items,
    required this.isLoading,
    required this.onOpenTodos,
  });

  final List<TodoItem> items;
  final bool isLoading;
  final VoidCallback onOpenTodos;

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      title: '待完成小事',
      actionLabel: '打开',
      onAction: onOpenTodos,
      child: isLoading
          ? const LinearProgressIndicator()
          : items.isEmpty
              ? const Text('今天没有待办，状态很好。')
              : Column(
                  children: items.map((item) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.radio_button_unchecked),
                      title: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}

class _JournalPreviewSection extends StatelessWidget {
  const _JournalPreviewSection({
    required this.item,
    required this.onOpenJournals,
  });

  final Journal? item;
  final VoidCallback onOpenJournals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final journal = item;

    return _SectionShell(
      title: '最近日志',
      actionLabel: '记录',
      onAction: onOpenJournals,
      child: journal == null
          ? const Text('还没有日志，今天可以写下第一条。')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      journal.mood ?? '😊',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(width: 8),
                    Text(DateFormat('yyyy-MM-dd').format(journal.entryDate)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  journal.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
