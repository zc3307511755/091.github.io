import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/anniversary.dart';
import '../providers/anniversary_provider.dart';
import '../providers/couple_provider.dart';

class AnniversaryScreen extends StatelessWidget {
  const AnniversaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnniversaryProvider>();
    final couple = context.watch<CoupleProvider>().current;
    final items = provider.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('纪念日'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: couple == null || provider.isLoading
                ? null
                : () => provider.loadAnniversaries(couple.id),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '添加纪念日',
        onPressed: couple == null
            ? null
            : () => _showAnniversarySheet(context, couple.id),
        child: const Icon(Icons.add),
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
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: items.isEmpty
                  ? const _AnniversaryEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: items.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _NextAnniversaryCard(item: items.first);
                        }

                        final item = items[index - 1];
                        return _AnniversaryTile(
                          item: item,
                          onEdit: () => _showAnniversarySheet(
                            context,
                            item.coupleId,
                            anniversary: item,
                          ),
                          onDelete: () => _confirmDelete(context, item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnniversarySheet(
    BuildContext context,
    String coupleId, {
    Anniversary? anniversary,
  }) {
    final titleController = TextEditingController(text: anniversary?.title);
    var selectedDate = anniversary?.eventDate ?? DateTime.now();
    var selectedType = anniversary?.type ?? 'custom';
    var repeatYearly = anniversary?.repeatYearly ?? false;

    if (anniversary == null && selectedType != 'custom') {
      repeatYearly = true;
    }

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
                    anniversary == null ? '添加纪念日' : '编辑纪念日',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'together',
                        label: Text('在一起'),
                        icon: Icon(Icons.favorite),
                      ),
                      ButtonSegment(
                        value: 'birthday',
                        label: Text('生日'),
                        icon: Icon(Icons.cake_outlined),
                      ),
                      ButtonSegment(
                        value: 'custom',
                        label: Text('自定义'),
                        icon: Icon(Icons.star_outline),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (values) {
                      setState(() {
                        selectedType = values.first;
                        if (selectedType != 'custom') {
                          repeatYearly = true;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: '标题',
                      prefixIcon: Icon(Icons.title),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(1970),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: repeatYearly,
                    onChanged: (value) {
                      setState(() {
                        repeatYearly = value;
                      });
                    },
                    title: const Text('每年提醒'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      final provider = context.read<AnniversaryProvider>();
                      if (anniversary == null) {
                        await provider.addAnniversary(
                          coupleId: coupleId,
                          title: titleController.text,
                          eventDate: selectedDate,
                          type: selectedType,
                          repeatYearly: repeatYearly,
                        );
                      } else {
                        await provider.updateAnniversary(
                          anniversary: anniversary,
                          title: titleController.text,
                          eventDate: selectedDate,
                          type: selectedType,
                          repeatYearly: repeatYearly,
                        );
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: Text(anniversary == null ? '添加' : '保存'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Anniversary anniversary,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除纪念日？'),
          content: const Text('删除后无法在 App 内恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await context
          .read<AnniversaryProvider>()
          .deleteAnniversary(anniversary);
    }
  }
}

class _NextAnniversaryCard extends StatelessWidget {
  const _NextAnniversaryCard({required this.item});

  final Anniversary item;

  @override
  Widget build(BuildContext context) {
    final days = item.daysLeft;
    final description = days == 0 ? '就是今天！' : '还有 $days 天';

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最近的纪念日',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnniversaryTile extends StatelessWidget {
  const _AnniversaryTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final Anniversary item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(_iconForType(item.type))),
        title: Text(item.title),
        subtitle: Text(
          '${DateFormat('yyyy-MM-dd').format(item.eventDate)}'
          '${item.repeatYearly ? ' · 每年' : ''}',
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: '编辑',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: '删除',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
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

class _AnniversaryEmptyState extends StatelessWidget {
  const _AnniversaryEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('还没有纪念日，点右下角添加一个。'),
      ),
    );
  }
}
