import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/coupon.dart';
import '../models/coupon_request.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/coupon_provider.dart';

class CouponScreen extends StatelessWidget {
  const CouponScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CouponProvider>();
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final couple = context.watch<CoupleProvider>().current;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('情侣券'),
          actions: [
            IconButton(
              tooltip: '刷新',
              onPressed: couple == null || provider.isLoading
                  ? null
                  : () => provider.loadCoupons(couple.id),
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.local_activity_outlined), text: '我的券'),
              Tab(icon: Icon(Icons.mark_email_unread_outlined), text: '请求'),
              Tab(icon: Icon(Icons.card_giftcard), text: '生成'),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (provider.isLoading) const LinearProgressIndicator(),
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    provider.error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              Expanded(
                child: TabBarView(
                  children: [
                    _CouponListTab(
                      coupons: provider.items,
                      currentUserId: currentUserId,
                    ),
                    _CouponRequestsTab(
                      requests: provider.requests,
                      currentUserId: currentUserId,
                    ),
                    _CouponCreateTab(currentUserId: currentUserId),
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

class _CouponListTab extends StatelessWidget {
  const _CouponListTab({
    required this.coupons,
    required this.currentUserId,
  });

  final List<Coupon> coupons;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    if (coupons.isEmpty) {
      return const _EmptyState(
        icon: Icons.local_activity_outlined,
        title: '还没有情侣券',
        message: '去生成一张，或者向对方请求一张。',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: coupons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: _CouponCard(
            key: ValueKey(coupons[index].id),
            coupon: coupons[index],
            currentUserId: currentUserId,
          ),
        );
      },
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({
    super.key,
    required this.coupon,
    required this.currentUserId,
  });

  final Coupon coupon;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReceived = coupon.receiverId == currentUserId;
    final canUse = isReceived && coupon.canUse;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: coupon.isExpired
              ? const [Color(0xFFEDE7EA), Color(0xFFF7F4F5)]
              : const [Color(0xFFFFD6E4), Color(0xFFE4F5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1AF17A9C),
            blurRadius: 14,
            offset: Offset(0, 8),
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
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.favorite, color: Color(0xFFF17A9C)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF4B3440),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        isReceived ? '我收到的' : '我发出的',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF6F5965),
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(coupon: coupon),
              ],
            ),
            if (coupon.description?.isNotEmpty == true) ...[
              const SizedBox(height: 14),
              Text(coupon.description!),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  size: 18,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(_expiryText(coupon))),
                FilledButton.tonalIcon(
                  onPressed: canUse ? () => _confirmUse(context) : null,
                  icon: const Icon(Icons.redeem),
                  label: const Text('使用'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _expiryText(Coupon coupon) {
    final expiresAt = coupon.expiresAt;
    if (coupon.isExpired) {
      return '已过期';
    }
    if (expiresAt == null) {
      return '长期有效';
    }
    return '有效期至 ${DateFormat('yyyy-MM-dd').format(expiresAt)}';
  }

  Future<void> _confirmUse(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('使用这张券？'),
          content: Text('确认使用「${coupon.title}」后，对方会看到它已被使用。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.coupon});

  final Coupon coupon;

  @override
  Widget build(BuildContext context) {
    final label = coupon.isExpired
        ? '已过期'
        : coupon.isUsed
            ? '已使用'
            : '未使用';
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: Colors.white.withValues(alpha: 0.74),
    );
  }
}

class _CouponRequestsTab extends StatelessWidget {
  const _CouponRequestsTab({
    required this.requests,
    required this.currentUserId,
  });

  final List<CouponRequest> requests;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const _EmptyState(
        icon: Icons.mark_email_unread_outlined,
        title: '还没有请求',
        message: '你可以向对方请求一张券，也可以在这里处理对方的请求。',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _RequestCard(
          request: requests[index],
          currentUserId: currentUserId,
        );
      },
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
    final theme = Theme.of(context);
    final isApprover = request.approverId == currentUserId;
    final isMine = request.requesterId == currentUserId;
    final canRespond = isApprover && request.isPending;
    final canApprove = canRespond && !request.isExpired;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  request.isExpired
                      ? Icons.timer_off_outlined
                      : request.isPending
                          ? Icons.hourglass_top
                          : request.isApproved
                              ? Icons.verified_outlined
                              : Icons.block,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    request.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Chip(label: Text(_statusText(request))),
              ],
            ),
            const SizedBox(height: 8),
            Text(isMine ? '我发起的请求' : '对方向我请求'),
            if (request.description?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(request.description!),
            ],
            const SizedBox(height: 8),
            Text(_expiryText(request)),
            if (canRespond) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _respond(context, approve: false),
                    icon: const Icon(Icons.close),
                    label: const Text('拒绝'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: canApprove
                        ? () => _respond(context, approve: true)
                        : null,
                    icon: const Icon(Icons.check),
                    label: const Text('同意'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusText(CouponRequest request) {
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

  String _expiryText(CouponRequest request) {
    final expiresAt = request.expiresAt;
    if (request.isExpired) {
      return '期望有效期已过';
    }
    if (expiresAt == null) {
      return '期望有效期：长期有效';
    }
    return '期望有效期至 ${DateFormat('yyyy-MM-dd').format(expiresAt)}';
  }

  Future<void> _respond(
    BuildContext context, {
    required bool approve,
  }) async {
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

class _CouponCreateTab extends StatefulWidget {
  const _CouponCreateTab({required this.currentUserId});

  final String? currentUserId;

  @override
  State<_CouponCreateTab> createState() => _CouponCreateTabState();
}

class _CouponCreateTabState extends State<_CouponCreateTab> {
  static const _presets = ['抱抱券', '亲亲券', '陪伴券', '和好券', '免家务券', '约会券'];

  final TextEditingController _titleController =
      TextEditingController(text: _presets.first);
  final TextEditingController _descriptionController = TextEditingController();
  String _mode = 'issue';
  DateTime? _expiresAt;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'issue',
              label: Text('送给 TA'),
              icon: Icon(Icons.send_outlined),
            ),
            ButtonSegment(
              value: 'request',
              label: Text('向 TA 请求'),
              icon: Icon(Icons.volunteer_activism_outlined),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (values) {
            setState(() {
              _mode = values.first;
            });
          },
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: '券名称',
            prefixIcon: Icon(Icons.local_activity_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: '备注',
            prefixIcon: Icon(Icons.notes),
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
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
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _submit,
          icon: Icon(_mode == 'issue' ? Icons.card_giftcard : Icons.send),
          label: Text(_mode == 'issue' ? '生成并发送' : '发送请求'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final couple = context.read<CoupleProvider>().current;
    final currentUserId = widget.currentUserId;
    if (couple == null || currentUserId == null) {
      return;
    }

    final partnerId = couple.partnerId(currentUserId);
    final provider = context.read<CouponProvider>();
    if (_mode == 'issue') {
      await provider.issueCoupon(
        coupleId: couple.id,
        receiverId: partnerId,
        title: _titleController.text,
        description: _descriptionController.text,
        expiresAt: _expiresAt,
      );
    } else {
      await provider.requestCoupon(
        coupleId: couple.id,
        approverId: partnerId,
        title: _titleController.text,
        description: _descriptionController.text,
        expiresAt: _expiresAt,
      );
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_mode == 'issue' ? '情侣券已生成' : '请求已发送')),
    );
    _descriptionController.clear();
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('长期有效'),
          selected: expiresAt == null,
          onSelected: (_) => onChanged(null),
        ),
        ChoiceChip(
          label: const Text('7天'),
          selected: _isSameDay(
              expiresAt, DateTime.now().add(const Duration(days: 7))),
          onSelected: (_) =>
              onChanged(DateTime.now().add(const Duration(days: 7))),
        ),
        ChoiceChip(
          label: const Text('30天'),
          selected: _isSameDay(
              expiresAt, DateTime.now().add(const Duration(days: 30))),
          onSelected: (_) =>
              onChanged(DateTime.now().add(const Duration(days: 30))),
        ),
        OutlinedButton.icon(
          onPressed: () => _pickDate(context),
          icon: const Icon(Icons.edit_calendar_outlined),
          label: Text(
            expiresAt == null
                ? '自定义日期'
                : DateFormat('yyyy-MM-dd').format(expiresAt!),
          ),
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
    if (a == null) {
      return false;
    }
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
