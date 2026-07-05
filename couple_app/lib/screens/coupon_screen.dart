import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/coupon.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/coupon_provider.dart';

class CouponScreen extends StatelessWidget {
  const CouponScreen({super.key});

  static const _presets = ['和好券', '抱抱券', '免做家务券', '请客券', '陪看剧券'];

  @override
  Widget build(BuildContext context) {
    final coupons = context.watch<CouponProvider>();
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final couple = context.watch<CoupleProvider>().current;

    return Scaffold(
      appBar: AppBar(
        title: const Text('情侣券'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: couple == null || coupons.isLoading
                ? null
                : () => coupons.loadCoupons(couple.id),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '发券',
        onPressed: couple == null || currentUserId == null
            ? null
            : () => _showIssueSheet(context),
        child: const Icon(Icons.card_giftcard),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (coupons.isLoading) const LinearProgressIndicator(),
            if (coupons.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  coupons.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: coupons.items.isEmpty
                  ? const _CouponEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: coupons.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _CouponCard(
                          coupon: coupons.items[index],
                          currentUserId: currentUserId,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIssueSheet(BuildContext context) {
    final couple = context.read<CoupleProvider>().current;
    final currentUserId = context.read<AuthProvider>().user?.id;
    if (couple == null || currentUserId == null) {
      return;
    }

    final receiverId = couple.partnerId(currentUserId);
    final titleController = TextEditingController(text: _presets.first);
    final descriptionController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '发一张券',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presets.map((preset) {
                      return ChoiceChip(
                        label: Text(preset),
                        selected: titleController.text == preset,
                        onSelected: (_) {
                          setState(() {
                            titleController.text = preset;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: '券名称',
                      prefixIcon: Icon(Icons.local_activity_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: '备注',
                      prefixIcon: Icon(Icons.notes),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      await context.read<CouponProvider>().issueCoupon(
                            coupleId: couple.id,
                            receiverId: receiverId,
                            title: titleController.text,
                            description: descriptionController.text,
                          );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('发送'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({
    required this.coupon,
    required this.currentUserId,
  });

  final Coupon coupon;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final isReceived = coupon.receiverId == currentUserId;
    final canUse = isReceived && coupon.isUnused;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  coupon.isUnused ? Icons.local_activity : Icons.done_all,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    coupon.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Chip(
                  label: Text(coupon.isUnused ? '未使用' : '已使用'),
                ),
              ],
            ),
            if (coupon.description?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(coupon.description!),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(isReceived ? '我收到的' : '我发出的'),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: canUse
                      ? () => context.read<CouponProvider>().useCoupon(coupon)
                      : null,
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
}

class _CouponEmptyState extends StatelessWidget {
  const _CouponEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('还没有情侣券，点右下角发一张。'),
      ),
    );
  }
}
