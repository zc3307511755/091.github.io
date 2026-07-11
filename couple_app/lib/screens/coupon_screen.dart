import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/coupon.dart';
import '../models/coupon_request.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/coupon_provider.dart';
import '../widgets/stitch_ui.dart';

class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CouponProvider>();
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final couple = context.watch<CoupleProvider>().current;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StitchPageFrame(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const StitchTopBar(
                    avatarAsset: 'assets/stitch/coupon_avatar.jpg',
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: StitchSegmentedControl(
                      labels: const ['我的券', '请求列表'],
                      selectedIndex: _selectedIndex,
                      onSelected: (index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                    ),
                  ),
                  if (provider.isLoading)
                    const LinearProgressIndicator(minHeight: 2),
                  if (provider.error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        provider.error!,
                        style: const TextStyle(color: StitchColors.red),
                      ),
                    ),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: [
                        _CouponList(
                          coupons: provider.items,
                          currentUserId: currentUserId,
                          onRefresh: couple == null
                              ? null
                              : () => provider.loadCoupons(couple.id),
                        ),
                        _CouponRequestsList(
                          requests: provider.requests,
                          currentUserId: currentUserId,
                          onRefresh: couple == null
                              ? null
                              : () => provider.loadCouponRequests(couple.id),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 16,
                bottom: 94,
                child: FloatingActionButton(
                  tooltip: '创建情侣券',
                  onPressed: couple == null || currentUserId == null
                      ? null
                      : () => _openComposer(context, currentUserId),
                  backgroundColor: StitchColors.primary,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add_rounded, size: 32),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openComposer(
    BuildContext context,
    String currentUserId,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: StitchColors.page,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.90,
        child: _CouponComposerSheet(currentUserId: currentUserId),
      ),
    );
  }
}

class _CouponList extends StatelessWidget {
  const _CouponList({
    required this.coupons,
    required this.currentUserId,
    required this.onRefresh,
  });

  final List<Coupon> coupons;
  final String? currentUserId;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    if (coupons.isEmpty) {
      return const StitchEmptyState(
        icon: Icons.local_activity_outlined,
        title: '还没有情侣券',
        message: '点击右下角加号，送出一张券或向 TA 请求。',
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 172),
        itemCount: coupons.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _TicketCard(
            coupon: coupons[index],
            currentUserId: currentUserId,
          );
        },
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.coupon,
    required this.currentUserId,
  });

  final Coupon coupon;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final isReceived = coupon.receiverId == currentUserId;
    final canUse = isReceived && coupon.canUse;
    final disabled = coupon.isUsed || coupon.isExpired;
    final foreground =
        disabled ? const Color(0xFF9B8D91) : StitchColors.primary;
    final background =
        disabled ? StitchColors.surfaceLow : const Color(0xFFFFEDF1);

    return Semantics(
      button: canUse,
      label: canUse ? '使用${coupon.title}' : coupon.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canUse ? () => _confirmUse(context) : null,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 132,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ColoredBox(
                    color: background,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 86,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _iconForCoupon(coupon.title),
                                color: foreground,
                                size: 34,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _statusLabel(coupon),
                                style: TextStyle(
                                  color: foreground,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 1,
                          height: 106,
                          child: CustomPaint(
                            painter: _DashedLinePainter(
                              color: disabled
                                  ? const Color(0xFFD5CFD2)
                                  : const Color(0xFFE6CBD2),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        coupon.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: disabled
                                              ? const Color(0xFF8D8085)
                                              : const Color(0xFF4A0011),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _expiryLabel(coupon),
                                      style: TextStyle(
                                        color: foreground.withValues(
                                          alpha: disabled ? 0.8 : 0.72,
                                        ),
                                        fontSize: 12,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 9),
                                Text(
                                  coupon.description?.trim().isNotEmpty == true
                                      ? coupon.description!.trim()
                                      : isReceived
                                          ? '这是一份只属于你的偏爱。'
                                          : '已送给 TA，等待幸福兑现。',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: disabled
                                        ? const Color(0xFFA4959A)
                                        : StitchColors.primary,
                                    fontSize: 14,
                                    height: 1.4,
                                    letterSpacing: 0,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  canUse
                                      ? '轻触使用'
                                      : isReceived
                                          ? '我收到的'
                                          : '我发出的',
                                  style: TextStyle(
                                    color: foreground,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ..._notches(background: StitchColors.page),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _notches({required Color background}) {
    const size = 18.0;
    return [
      Positioned(left: 77, top: -size / 2, child: _Notch(size, background)),
      Positioned(left: 77, bottom: -size / 2, child: _Notch(size, background)),
      Positioned(left: -size / 2, top: 57, child: _Notch(size, background)),
      Positioned(right: -size / 2, top: 57, child: _Notch(size, background)),
    ];
  }

  IconData _iconForCoupon(String title) {
    if (title.contains('按摩') || title.contains('抱抱')) {
      return Icons.spa_outlined;
    }
    if (title.contains('碗') || title.contains('饭') || title.contains('餐')) {
      return Icons.restaurant_rounded;
    }
    if (title.contains('电影')) {
      return Icons.movie_outlined;
    }
    return Icons.card_giftcard_rounded;
  }

  String _statusLabel(Coupon coupon) {
    if (coupon.isExpired) {
      return '已过期';
    }
    if (coupon.isUsed) {
      return '已使用';
    }
    return '未使用';
  }

  String _expiryLabel(Coupon coupon) {
    if (coupon.isExpired) {
      return '已过期';
    }
    final expiresAt = coupon.expiresAt;
    if (expiresAt == null) {
      return '永久有效';
    }
    return '至 ${DateFormat('MM.dd').format(expiresAt)}';
  }

  Future<void> _confirmUse(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('使用这张券？'),
          content: Text('确认使用「${coupon.title}」后，对方会看到它已被使用。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.favorite),
              label: const Text('确认使用'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await context.read<CouponProvider>().useCoupon(coupon);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已使用「${coupon.title}」')),
        );
      }
    }
  }
}

class _Notch extends StatelessWidget {
  const _Notch(this.size, this.color);

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    const dash = 5.0;
    const gap = 5.0;
    var y = 0.0;
    while (y < size.height) {
      final endY = (y + dash).clamp(0.0, size.height).toDouble();
      canvas.drawLine(Offset(0, y), Offset(0, endY), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _CouponRequestsList extends StatelessWidget {
  const _CouponRequestsList({
    required this.requests,
    required this.currentUserId,
    required this.onRefresh,
  });

  final List<CouponRequest> requests;
  final String? currentUserId;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const StitchEmptyState(
        icon: Icons.mark_email_unread_outlined,
        title: '还没有请求',
        message: '对方发来的请求和你的请求记录会显示在这里。',
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 172),
        itemCount: requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _RequestCard(
            request: requests[index],
            currentUserId: currentUserId,
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.currentUserId,
  });

  final CouponRequest request;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final isApprover = request.approverId == currentUserId;
    final canRespond = isApprover && request.isPending;
    final accent = request.isExpired
        ? const Color(0xFF8D8085)
        : request.isApproved
            ? StitchColors.green
            : request.isRejected
                ? StitchColors.red
                : StitchColors.primary;

    return StitchGroupCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.volunteer_activism_outlined, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StitchColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      request.requesterId == currentUserId
                          ? '我发起的请求'
                          : 'TA 向我请求',
                      style: const TextStyle(
                        color: StitchColors.muted,
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _statusLabel(),
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          if (request.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(request.description!.trim()),
          ],
          const SizedBox(height: 10),
          Text(
            _expiryLabel(),
            style: const TextStyle(
              color: StitchColors.muted,
              fontSize: 12,
              letterSpacing: 0,
            ),
          ),
          if (canRespond) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _respond(context, approve: false),
                  child: const Text('拒绝'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: request.isExpired
                      ? null
                      : () => _respond(context, approve: true),
                  child: const Text('同意'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel() {
    if (request.isExpired) {
      return '已过期';
    }
    if (request.isApproved) {
      return '已同意';
    }
    if (request.isRejected) {
      return '已拒绝';
    }
    return '等待中';
  }

  String _expiryLabel() {
    final expiresAt = request.expiresAt;
    if (request.isExpired) {
      return '期望有效期已过';
    }
    if (expiresAt == null) {
      return '期望有效期：永久有效';
    }
    return '期望有效期至 ${DateFormat('yyyy-MM-dd').format(expiresAt)}';
  }

  Future<void> _respond(BuildContext context, {required bool approve}) async {
    await context.read<CouponProvider>().respondToRequest(
          request,
          approve: approve,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? '已同意请求并生成券' : '已拒绝请求')),
      );
    }
  }
}

class _CouponComposerSheet extends StatefulWidget {
  const _CouponComposerSheet({required this.currentUserId});

  final String currentUserId;

  @override
  State<_CouponComposerSheet> createState() => _CouponComposerSheetState();
}

class _CouponComposerSheetState extends State<_CouponComposerSheet> {
  static const _presets = ['抱抱券', '按摩券', '免洗碗券', '电影选择权', '陪伴券', '约会券'];

  final TextEditingController _titleController =
      TextEditingController(text: _presets.first);
  final TextEditingController _descriptionController = TextEditingController();
  int _modeIndex = 0;
  DateTime? _expiresAt;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CouponProvider>();

    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 38,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFFD1CDD2),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '创建情侣券',
                  style: TextStyle(
                    color: StitchColors.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 24,
            ),
            children: [
              StitchSegmentedControl(
                labels: const ['送给 TA', '向 TA 请求'],
                selectedIndex: _modeIndex,
                onSelected: (index) {
                  setState(() {
                    _modeIndex = index;
                  });
                },
              ),
              const SizedBox(height: 22),
              const Text(
                '选择一种心意',
                style: TextStyle(
                  color: StitchColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets.map((preset) {
                  return ChoiceChip(
                    label: Text(preset),
                    selected: _titleController.text == preset,
                    onSelected: (_) {
                      setState(() {
                        _titleController.text = preset;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _titleController,
                maxLength: 30,
                decoration: const InputDecoration(
                  labelText: '券名称',
                  prefixIcon: Icon(Icons.local_activity_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: '使用说明',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              _ExpirySelector(
                expiresAt: _expiresAt,
                onChanged: (value) {
                  setState(() {
                    _expiresAt = value;
                  });
                },
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: provider.isLoading ? null : _submit,
                icon: Icon(
                  _modeIndex == 0
                      ? Icons.card_giftcard_rounded
                      : Icons.send_rounded,
                ),
                label: Text(_modeIndex == 0 ? '生成并发送' : '发送请求'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final couple = context.read<CoupleProvider>().current;
    final title = _titleController.text.trim();
    if (couple == null || title.isEmpty) {
      return;
    }

    final partnerId = couple.partnerId(widget.currentUserId);
    final provider = context.read<CouponProvider>();
    if (_modeIndex == 0) {
      await provider.issueCoupon(
        coupleId: couple.id,
        receiverId: partnerId,
        title: title,
        description: _descriptionController.text,
        expiresAt: _expiresAt,
      );
    } else {
      await provider.requestCoupon(
        coupleId: couple.id,
        approverId: partnerId,
        title: title,
        description: _descriptionController.text,
        expiresAt: _expiresAt,
      );
    }

    if (!mounted || provider.error != null) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_modeIndex == 0 ? '情侣券已生成' : '请求已发送')),
    );
  }
}

class _ExpirySelector extends StatelessWidget {
  const _ExpirySelector({
    required this.expiresAt,
    required this.onChanged,
  });

  final DateTime? expiresAt;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '有效期',
          style: TextStyle(
            color: StitchColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('永久有效'),
              selected: expiresAt == null,
              onSelected: (_) => onChanged(null),
            ),
            ChoiceChip(
              label: const Text('7 天'),
              selected: _isSameDay(
                expiresAt,
                DateTime.now().add(const Duration(days: 7)),
              ),
              onSelected: (_) {
                onChanged(DateTime.now().add(const Duration(days: 7)));
              },
            ),
            ChoiceChip(
              label: const Text('30 天'),
              selected: _isSameDay(
                expiresAt,
                DateTime.now().add(const Duration(days: 30)),
              ),
              onSelected: (_) {
                onChanged(DateTime.now().add(const Duration(days: 30)));
              },
            ),
            OutlinedButton.icon(
              onPressed: () => _pickDate(context),
              icon: const Icon(Icons.edit_calendar_outlined),
              label: Text(
                expiresAt == null
                    ? '自定义'
                    : DateFormat('yyyy-MM-dd').format(expiresAt!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: expiresAt ?? now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5, now.month, now.day),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    return a != null &&
        a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }
}
