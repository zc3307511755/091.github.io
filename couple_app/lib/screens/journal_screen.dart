import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/journal.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/journal_provider.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  static const _moods = ['😊', '🥰', '😋', '😴', '😢', '😡', '✨', '🌧'];

  @override
  Widget build(BuildContext context) {
    final journals = context.watch<JournalProvider>();
    final couple = context.watch<CoupleProvider>().current;
    final currentUserId = context.watch<AuthProvider>().user?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('共享日志'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: couple == null || journals.isLoading
                ? null
                : () => journals.loadJournals(couple.id),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '写日志',
        onPressed: couple == null
            ? null
            : () => _showJournalSheet(context, couple.id),
        child: const Icon(Icons.edit),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (journals.isLoading) const LinearProgressIndicator(),
            if (journals.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  journals.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: journals.items.isEmpty
                  ? const _JournalEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: journals.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _JournalCard(
                          journal: journals.items[index],
                          isMine: journals.items[index].authorId ==
                              currentUserId,
                          onEdit: () => _showJournalSheet(
                            context,
                            journals.items[index].coupleId,
                            journal: journals.items[index],
                          ),
                          onDelete: () => _confirmDelete(
                            context,
                            journals.items[index],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJournalSheet(
    BuildContext context,
    String coupleId, {
    Journal? journal,
  }) {
    final contentController = TextEditingController(text: journal?.content);
    var selectedDate = journal?.entryDate ?? DateTime.now();
    var selectedMood = journal?.mood ?? _moods.first;

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
                    journal == null ? '写日志' : '编辑日志',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
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
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _moods.map((mood) {
                      return ChoiceChip(
                        label: Text(mood),
                        selected: selectedMood == mood,
                        onSelected: (_) {
                          setState(() {
                            selectedMood = mood;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: '今天想记录什么？',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      final provider = context.read<JournalProvider>();
                      if (journal == null) {
                        await provider.addJournal(
                          coupleId: coupleId,
                          entryDate: selectedDate,
                          mood: selectedMood,
                          content: contentController.text,
                        );
                      } else {
                        await provider.updateJournal(
                          journal: journal,
                          entryDate: selectedDate,
                          mood: selectedMood,
                          content: contentController.text,
                        );
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: Text(journal == null ? '发布' : '保存'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Journal journal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除日志？'),
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
      await context.read<JournalProvider>().deleteJournal(journal);
    }
  }
}

class _JournalCard extends StatelessWidget {
  const _JournalCard({
    required this.journal,
    required this.isMine,
    required this.onEdit,
    required this.onDelete,
  });

  final Journal journal;
  final bool isMine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  journal.mood ?? '😊',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(journal.entryDate),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Chip(label: Text(isMine ? '我' : 'TA')),
              ],
            ),
            const SizedBox(height: 12),
            Text(journal.content),
            if (isMine) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('编辑'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('删除'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JournalEmptyState extends StatelessWidget {
  const _JournalEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('还没有共享日志，点右下角记录第一条。'),
      ),
    );
  }
}
