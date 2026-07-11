import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
import '../services/home_image_service.dart';
import '../widgets/stitch_ui.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.onOpenTab,
    required this.onOpenMeals,
    required this.onOpenAnniversaries,
    super.key,
  });

  final ValueChanged<int> onOpenTab;
  final VoidCallback onOpenMeals;
  final VoidCallback onOpenAnniversaries;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final couple = context.watch<CoupleProvider>().current;
    final todos = context.watch<TodoProvider>();
    final coupons = context.watch<CouponProvider>();
    final journals = context.watch<JournalProvider>();
    final anniversaries = context.watch<AnniversaryProvider>();

    final openTodos = todos.items.where((item) => !item.isDone).toList();
    final unusedCoupons = coupons.items.where((coupon) => coupon.canUse).length;
    final nextAnniversary = _nextAnniversary(anniversaries.items);
    final latestJournal = journals.items.isEmpty ? null : journals.items.first;
    final relationshipAnniversary = _firstAnniversaryOfType(
      anniversaries.items,
      'together',
    );
    final relationshipStart =
        relationshipAnniversary?.eventDate ?? couple?.pairedAt;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StitchPageFrame(
        backgroundColor: StitchColors.grouped,
        child: RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              _HomeHero(
                avatarPath: auth.profile?.avatarUrl,
                heroImagePath: auth.homeImagePath(HomeImageSlot.hero),
                isUpdatingImage: auth.isUpdatingHomeImage,
                startDate: relationshipStart,
                onEditCover: () => _pickHomeImage(
                  context,
                  HomeImageSlot.hero,
                ),
                onEditStartDate: () => _editRelationshipStartDate(
                  context,
                  existing: relationshipAnniversary,
                ),
                onOpenProfile: () => onOpenTab(4),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Column(
                  children: [
                    _QuickActions(
                      onOpenMeals: onOpenMeals,
                      onOpenAnniversaries: onOpenAnniversaries,
                      onOpenTodos: () => onOpenTab(1),
                      onOpenCoupons: () => onOpenTab(2),
                    ),
                    const SizedBox(height: 18),
                    _MetricsRow(
                      openTodoCount: openTodos.length,
                      totalTodoCount: todos.items.length,
                      unusedCouponCount: unusedCoupons,
                    ),
                    const SizedBox(height: 16),
                    _AnniversaryBanner(
                      item: nextAnniversary,
                      onTap: onOpenAnniversaries,
                    ),
                    const SizedBox(height: 16),
                    _TodoPreview(
                      items: openTodos.take(3).toList(),
                      isLoading: todos.isLoading,
                      onOpenTodos: () => onOpenTab(1),
                    ),
                    const SizedBox(height: 16),
                    _MemoryPreview(
                      journal: latestJournal,
                      leftImagePath: auth.homeImagePath(
                        HomeImageSlot.memoryLeft,
                      ),
                      rightImagePath: auth.homeImagePath(
                        HomeImageSlot.memoryRight,
                      ),
                      isUpdatingImage: auth.isUpdatingHomeImage,
                      onEditLeftImage: () => _pickHomeImage(
                        context,
                        HomeImageSlot.memoryLeft,
                      ),
                      onEditRightImage: () => _pickHomeImage(
                        context,
                        HomeImageSlot.memoryRight,
                      ),
                      onOpenJournals: () => onOpenTab(3),
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

  Anniversary? _nextAnniversary(List<Anniversary> items) {
    if (items.isEmpty) {
      return null;
    }
    final sorted = [...items]..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    return sorted.first;
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

  Future<void> _pickHomeImage(
    BuildContext context,
    HomeImageSlot slot,
  ) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 86,
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
      await context.read<AuthProvider>().updateHomeImage(
            slot: slot,
            imageBytes: bytes,
            fileExtension: extension,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_imageLabel(slot)}已更新')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_imageLabel(slot)}更新失败：$error')),
        );
      }
    }
  }

  String _imageLabel(HomeImageSlot slot) {
    return switch (slot) {
      HomeImageSlot.hero => '首页封面',
      HomeImageSlot.memoryLeft => '左侧回忆图片',
      HomeImageSlot.memoryRight => '右侧回忆图片',
    };
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

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.avatarPath,
    required this.heroImagePath,
    required this.isUpdatingImage,
    required this.startDate,
    required this.onEditCover,
    required this.onEditStartDate,
    required this.onOpenProfile,
  });

  final String? avatarPath;
  final String? heroImagePath;
  final bool isUpdatingImage;
  final DateTime? startDate;
  final VoidCallback onEditCover;
  final VoidCallback onEditStartDate;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final days = _daysTogether(startDate);
    final topPadding = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: 292 + topPadding,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _PrivateImage(
            imagePath: heroImagePath,
            fallbackAsset: 'assets/stitch/home_hero.jpg',
            fit: BoxFit.cover,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x22000000),
                  Color(0x08000000),
                  Color(0xA8000000)
                ],
                stops: [0, 0.42, 1],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: topPadding + 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Material(
                  color: Colors.white.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    onTap: onOpenProfile,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.fromLTRB(5, 4, 14, 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.36),
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipOval(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: _PrivateImage(
                                imagePath: avatarPath,
                                fallbackAsset: 'assets/stitch/home_avatar.jpg',
                                fit: BoxFit.cover,
                                isProfileAvatar: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '我们俩',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: '修改首页封面',
                        onPressed: isUpdatingImage ? null : onEditCover,
                        color: Colors.white,
                        icon: isUpdatingImage
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.photo_camera_outlined),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Material(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: const CircleBorder(),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.favorite_border_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 20,
            bottom: 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '在一起的第',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                days?.toString() ?? '--',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 50,
                                  height: 0.95,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 8, bottom: 3),
                            child: Text(
                              '天',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: onEditStartDate,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(88, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    backgroundColor: const Color(0x995A514B),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(startDate == null ? '设置' : '修改'),
                ),
              ],
            ),
          ),
        ],
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
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onOpenMeals,
    required this.onOpenAnniversaries,
    required this.onOpenTodos,
    required this.onOpenCoupons,
  });

  final VoidCallback onOpenMeals;
  final VoidCallback onOpenAnniversaries;
  final VoidCallback onOpenTodos;
  final VoidCallback onOpenCoupons;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ActionData(
        Icons.restaurant_rounded,
        '吃什么',
        const Color(0xFFF8DFE7),
        StitchColors.primary,
        onOpenMeals,
      ),
      _ActionData(
        Icons.event_outlined,
        '纪念日',
        const Color(0xFFE1ECFA),
        StitchColors.blue,
        onOpenAnniversaries,
      ),
      _ActionData(
        Icons.playlist_add_check_circle_outlined,
        '记待办',
        const Color(0xFFDCEDE8),
        StitchColors.green,
        onOpenTodos,
      ),
      _ActionData(
        Icons.local_activity_outlined,
        '发礼券',
        const Color(0xFFF7E2E9),
        StitchColors.primary,
        onOpenCoupons,
      ),
    ];

    return Row(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == items.length - 1 ? 0 : 8),
            child: Material(
              color: StitchColors.surface,
              borderRadius: BorderRadius.circular(12),
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 92,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: item.background,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, color: item.color, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: StitchColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ActionData {
  const _ActionData(
    this.icon,
    this.label,
    this.background,
    this.color,
    this.onTap,
  );

  final IconData icon;
  final String label;
  final Color background;
  final Color color;
  final VoidCallback onTap;
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.openTodoCount,
    required this.totalTodoCount,
    required this.unusedCouponCount,
  });

  final int openTodoCount;
  final int totalTodoCount;
  final int unusedCouponCount;

  @override
  Widget build(BuildContext context) {
    final completed = totalTodoCount - openTodoCount;
    final progress = totalTodoCount == 0 ? 0.0 : completed / totalTodoCount;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MetricCard(
              icon: Icons.fact_check_outlined,
              iconColor: StitchColors.green,
              label: '本月待办',
              value: '$openTodoCount',
              suffix: '/$totalTodoCount',
              footer: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  color: StitchColors.green,
                  backgroundColor: StitchColors.surfaceHigh,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MetricCard(
              icon: Icons.wallet_outlined,
              iconColor: StitchColors.primary,
              label: '可用礼券',
              value: '$unusedCouponCount',
              suffix: '张',
              footer: const Text(
                '把偏爱及时兑现',
                style: TextStyle(
                  color: StitchColors.muted,
                  fontSize: 12,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.suffix,
    required this.footer,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String suffix;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return StitchGroupCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: StitchColors.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: StitchColors.ink,
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  suffix,
                  style: const TextStyle(
                    color: StitchColors.muted,
                    fontSize: 15,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          footer,
        ],
      ),
    );
  }
}

class _AnniversaryBanner extends StatelessWidget {
  const _AnniversaryBanner({required this.item, required this.onTap});

  final Anniversary? item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final anniversary = item;
    return Material(
      color: const Color(0xFFF4DCE5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 18, 15),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.favorite_border_rounded,
                          color: StitchColors.primary,
                          size: 18,
                        ),
                        SizedBox(width: 7),
                        Text(
                          '即将到来',
                          style: TextStyle(
                            color: StitchColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      anniversary?.title ?? '添加一个纪念日',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StitchColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              if (anniversary != null)
                Column(
                  children: [
                    const Text(
                      '还剩',
                      style: TextStyle(
                        color: StitchColors.muted,
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${anniversary.daysLeft}',
                          style: const TextStyle(
                            color: StitchColors.primary,
                            fontSize: 32,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 3, bottom: 2),
                          child: Text('天'),
                        ),
                      ],
                    ),
                  ],
                )
              else
                const Icon(Icons.chevron_right, color: StitchColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodoPreview extends StatelessWidget {
  const _TodoPreview({
    required this.items,
    required this.isLoading,
    required this.onOpenTodos,
  });

  final List<TodoItem> items;
  final bool isLoading;
  final VoidCallback onOpenTodos;

  @override
  Widget build(BuildContext context) {
    return StitchGroupCard(
      child: Column(
        children: [
          _SectionHeader(
            title: '待办事项',
            action: '查看全部',
            onTap: onOpenTodos,
          ),
          const Divider(),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(18),
              child: LinearProgressIndicator(),
            )
          else if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text('今天没有待办，享受属于你们的时间。'),
            )
          else
            ...List.generate(items.length, (index) {
              final item = items[index];
              return Column(
                children: [
                  ListTile(
                    minLeadingWidth: 24,
                    leading: const Icon(
                      Icons.radio_button_unchecked,
                      color: StitchColors.roseLine,
                    ),
                    title: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (index != items.length - 1) const Divider(indent: 52),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _MemoryPreview extends StatelessWidget {
  const _MemoryPreview({
    required this.journal,
    required this.leftImagePath,
    required this.rightImagePath,
    required this.isUpdatingImage,
    required this.onEditLeftImage,
    required this.onEditRightImage,
    required this.onOpenJournals,
  });

  final Journal? journal;
  final String? leftImagePath;
  final String? rightImagePath;
  final bool isUpdatingImage;
  final VoidCallback onEditLeftImage;
  final VoidCallback onEditRightImage;
  final VoidCallback onOpenJournals;

  @override
  Widget build(BuildContext context) {
    final item = journal;
    return StitchGroupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: '最新回忆',
            action: '写日记',
            onTap: onOpenJournals,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item == null
                      ? '还没有日记，写下今天发生的小事吧。'
                      : DateFormat('MM月dd日  HH:mm').format(item.createdAt),
                  style: const TextStyle(
                    color: StitchColors.muted,
                    fontSize: 13,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item?.content ?? '每一段平常的日子，都值得被好好收藏。',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StitchColors.ink,
                    fontSize: 16,
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MemoryImage(
                        asset: 'assets/stitch/memory_tiramisu.jpg',
                        imagePath: leftImagePath,
                        isUpdating: isUpdatingImage,
                        onEdit: onEditLeftImage,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MemoryImage(
                        asset: 'assets/stitch/memory_bund.jpg',
                        imagePath: rightImagePath,
                        isUpdating: isUpdatingImage,
                        onEdit: onEditRightImage,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryImage extends StatelessWidget {
  const _MemoryImage({
    required this.asset,
    required this.imagePath,
    required this.isUpdating,
    required this.onEdit,
  });

  final String asset;
  final String? imagePath;
  final bool isUpdating;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUpdating ? null : onEdit,
        borderRadius: BorderRadius.circular(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 1.55,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _PrivateImage(
                  imagePath: imagePath,
                  fallbackAsset: asset,
                  fit: BoxFit.cover,
                ),
                const Positioned(
                  right: 6,
                  bottom: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xA6000000),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: Icon(
                        Icons.photo_camera_outlined,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivateImage extends StatefulWidget {
  const _PrivateImage({
    required this.imagePath,
    required this.fallbackAsset,
    required this.fit,
    this.isProfileAvatar = false,
  });

  final String? imagePath;
  final String fallbackAsset;
  final BoxFit fit;
  final bool isProfileAvatar;

  @override
  State<_PrivateImage> createState() => _PrivateImageState();
}

class _PrivateImageState extends State<_PrivateImage> {
  Future<String>? _signedUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _PrivateImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath ||
        oldWidget.isProfileAvatar != widget.isProfileAvatar) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final future = _signedUrl;
    if (future == null) {
      return Image.asset(widget.fallbackAsset, fit: widget.fit);
    }

    return FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null) {
          return Image.asset(widget.fallbackAsset, fit: widget.fit);
        }
        return Image.network(
          url,
          fit: widget.fit,
          errorBuilder: (_, __, ___) {
            return Image.asset(widget.fallbackAsset, fit: widget.fit);
          },
        );
      },
    );
  }

  void _load() {
    final path = widget.imagePath?.trim();
    if (path == null || path.isEmpty) {
      _signedUrl = null;
      return;
    }
    final auth = context.read<AuthProvider>();
    _signedUrl = widget.isProfileAvatar
        ? auth.signedAvatarUrl(path)
        : auth.signedHomeImageUrl(path);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: StitchColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          TextButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    );
  }
}
