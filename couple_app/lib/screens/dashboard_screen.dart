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
    final unusedCoupons = coupons.items.where((coupon) => coupon.canUse).length;
    final nextAnniversary =
        anniversaries.items.isEmpty ? null : anniversaries.items.first;
    final latestJournal = journals.items.isEmpty ? null : journals.items.first;
    final todayPlanCount = meals.plans.where((plan) => !plan.isDone).length;
    final todayPhotoCount = meals.entries.length;
    final relationshipAnniversary = _firstAnniversaryOfType(
      anniversaries.items,
      'together',
    );
    final relationshipStart =
        relationshipAnniversary?.eventDate ?? couple?.pairedAt;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 64,
        title: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFE1EA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.favorite_rounded, color: Color(0xFFE94B78)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('我们俩', style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '今天也在一起',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF8A7B86),
                      ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filledTonal(
              tooltip: '我的',
              onPressed: () => onOpenTab(6),
              icon: const Icon(Icons.person_outline),
            ),
          ),
        ],
      ),
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
          child: RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
              children: [
                _HeroSummary(
                  nickname: auth.profile?.nickname,
                  startDate: relationshipStart,
                  onEditStartDate: () => _editRelationshipStartDate(
                    context,
                    existing: relationshipAnniversary,
                  ),
                ),
                const SizedBox(height: 20),
                _QuickActions(onOpenTab: onOpenTab),
                const SizedBox(height: 20),
                _MetricsGrid(
                  openTodoCount: openTodos.length,
                  unusedCouponCount: unusedCoupons,
                  todayPlanCount: todayPlanCount,
                  todayPhotoCount: todayPhotoCount,
                ),
                const SizedBox(height: 20),
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
      ),
    );
  }

  Anniversary? _firstAnniversaryOfType(
    List<Anniversary> items,
    String type,
  ) {
    for (final item in items) {
      if (item.type == type) {
        return item;
      }
    }
    return null;
  }

  Future<void> _editRelationshipStartDate(
    BuildContext context, {
    Anniversary? existing,
  }) async {
    final couple = context.read<CoupleProvider>().current;
    if (couple == null) {
      return;
    }

    final now = DateTime.now();
    final initialDate = existing?.eventDate ?? couple.pairedAt ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(
        initialDate.year,
        initialDate.month,
        initialDate.day,
      ),
      firstDate: DateTime(1970),
      lastDate: DateTime(now.year, now.month, now.day),
    );

    if (picked == null || !context.mounted) {
      return;
    }

    final provider = context.read<AnniversaryProvider>();
    if (existing == null) {
      await provider.addAnniversary(
        coupleId: couple.id,
        title: '我们在一起',
        eventDate: picked,
        type: 'together',
        repeatYearly: true,
      );
    } else {
      await provider.updateAnniversary(
        anniversary: existing,
        title: existing.title.trim().isEmpty ? '我们在一起' : existing.title,
        eventDate: picked,
        type: 'together',
        repeatYearly: true,
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('在一起日期已更新')),
      );
    }
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
    required this.startDate,
    required this.onEditStartDate,
  });

  final String? nickname;
  final DateTime? startDate;
  final VoidCallback onEditStartDate;

  @override
  Widget build(BuildContext context) {
    final days = _daysTogether(startDate);
    final greeting = _greeting();
    final name = nickname?.trim().isNotEmpty == true ? nickname!.trim() : '今天';

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD93E6B), Color(0xFFE95B7B), Color(0xFFF09461)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3DDB5C7E),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting，$name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                days?.toString() ?? 'NOW',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 54,
                                  height: 0.94,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(
                              days == null ? '开始记录' : '天的陪伴',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: startDate == null ? '设置开始日期' : '修改开始日期',
                  onPressed: onEditStartDate,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0x33FFFFFF),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.edit_calendar_outlined),
                ),
              ],
            ),
            const SizedBox(height: 18),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x29FFFFFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x52FFFFFF)),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        startDate == null
                            ? '设置第一天，让故事从这里开始'
                            : '从 ${DateFormat('yyyy.MM.dd').format(startDate!)} 开始',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _todayLabel(),
                      style: const TextStyle(
                          color: Color(0xE6FFFFFF), fontSize: 12),
                    ),
                  ],
                ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final childAspectRatio = constraints.maxWidth >= 720
            ? 2.15
            : constraints.maxWidth >= 520
                ? 1.45
                : 0.86;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '此刻想做什么',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: childAspectRatio,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _ActionTile(
                  icon: Icons.add_task,
                  label: '待办',
                  accent: const Color(0xFFE94B78),
                  onTap: () => onOpenTab(1),
                ),
                _ActionTile(
                  icon: Icons.card_giftcard,
                  label: '发券',
                  accent: const Color(0xFFF19A48),
                  onTap: () => onOpenTab(2),
                ),
                _ActionTile(
                  icon: Icons.restaurant_menu,
                  label: '吃啥',
                  accent: const Color(0xFF249C98),
                  onTap: () => onOpenTab(3),
                ),
                _ActionTile(
                  icon: Icons.edit_note,
                  label: '日志',
                  accent: const Color(0xFF527FBD),
                  onTap: () => onOpenTab(4),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF1DDE4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F5B3342),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(icon, color: accent, size: 21),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
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
              accent: const Color(0xFFE94B78),
            ),
            _MetricTile(
              width: width,
              label: '可用券',
              value: unusedCouponCount.toString(),
              icon: Icons.local_activity_outlined,
              accent: const Color(0xFFF19A48),
            ),
            _MetricTile(
              width: width,
              label: '今日计划',
              value: todayPlanCount.toString(),
              icon: Icons.restaurant_outlined,
              accent: const Color(0xFF249C98),
            ),
            _MetricTile(
              width: width,
              label: '今日照片',
              value: todayPhotoCount.toString(),
              icon: Icons.photo_library_outlined,
              accent: const Color(0xFF527FBD),
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
    required this.accent,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF1DDE4)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D5B3342),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: Icon(icon, color: accent, size: 20),
                ),
              ),
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
      icon: Icons.favorite_border,
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
      icon: Icons.checklist,
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
      icon: Icons.auto_stories_outlined,
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
    required this.icon,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  final String title;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child:
                        Icon(icon, size: 19, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 10),
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
