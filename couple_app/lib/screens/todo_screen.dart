import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/todo_item.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/todo_provider.dart';
import '../widgets/stitch_ui.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _controller = TextEditingController();
  int _selectedIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final couple = context.watch<CoupleProvider>().current;
    final provider = context.watch<TodoProvider>();
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final items = provider.items
        .where((item) => _selectedIndex == 0 ? !item.isDone : item.isDone)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StitchPageFrame(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StitchTopBar(
                avatarAsset: 'assets/stitch/todo_couple_avatar.jpg',
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Text(
                  '待办事项',
                  style: TextStyle(
                    color: StitchColors.ink,
                    fontSize: 34,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StitchSegmentedControl(
                  labels: const ['进行中', '已完成'],
                  selectedIndex: _selectedIndex,
                  onSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),
              ),
              if (provider.isLoading) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(minHeight: 2),
              ],
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Text(
                    provider.error!,
                    style: const TextStyle(color: StitchColors.red),
                  ),
                ),
              Expanded(
                child: items.isEmpty
                    ? StitchEmptyState(
                        icon: _selectedIndex == 0
                            ? Icons.check_circle_outline
                            : Icons.history_rounded,
                        title: _selectedIndex == 0 ? '现在没有待办' : '还没有完成记录',
                        message: _selectedIndex == 0
                            ? '添加一件想和 TA 一起完成的小事。'
                            : '完成后的事项会收纳在这里。',
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          if (couple != null) {
                            await provider.loadTodos(couple.id);
                          }
                        },
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
                          children: [
                            StitchGroupCard(
                              child: Column(
                                children: List.generate(items.length, (index) {
                                  return _TodoRow(
                                    item: items[index],
                                    currentUserId: currentUserId,
                                    showDivider: index != items.length - 1,
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                child: _AddTodoComposer(
                  controller: _controller,
                  enabled: couple != null && !provider.isLoading,
                  onSubmit: () => _addTodo(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addTodo(BuildContext context) async {
    final couple = context.read<CoupleProvider>().current;
    final title = _controller.text.trim();
    if (couple == null || title.isEmpty) {
      return;
    }

    await context.read<TodoProvider>().addTodo(couple.id, title);
    if (!mounted) {
      return;
    }
    _controller.clear();
    setState(() {
      _selectedIndex = 0;
    });
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({
    required this.item,
    required this.currentUserId,
    required this.showDivider,
  });

  final TodoItem item;
  final String? currentUserId;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TodoProvider>();
    final isMine = item.createdBy == currentUserId;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await _confirmDelete(context);
        if (confirmed) {
          await provider.deleteTodo(item);
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: StitchColors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Semantics(
                  label: item.isDone ? '标记为未完成' : '标记为已完成',
                  button: true,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => provider.setDone(item, !item.isDone),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        item.isDone
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        size: 26,
                        color: item.isDone
                            ? StitchColors.green
                            : StitchColors.roseLine,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: item.isDone
                              ? StitchColors.muted
                              : StitchColors.ink,
                          fontSize: 17,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                          decoration:
                              item.isDone ? TextDecoration.lineThrough : null,
                          letterSpacing: 0,
                        ),
                      ),
                      if (!item.isDone) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 15,
                              color: StitchColors.primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '创建于 ${DateFormat('MM月dd日').format(item.createdAt)}',
                              style: const TextStyle(
                                color: StitchColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                ClipOval(
                  child: Image.asset(
                    isMine
                        ? 'assets/stitch/todo_assignee_a.jpg'
                        : 'assets/stitch/todo_assignee_b.jpg',
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          if (showDivider) const Divider(indent: 70),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('删除这条待办？'),
              content: Text('「${item.title}」删除后无法恢复。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('删除'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

class _AddTodoComposer extends StatelessWidget {
  const _AddTodoComposer({
    required this.controller,
    required this.enabled,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: StitchColors.page,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: StitchColors.roseLine),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.add_circle_outline, color: StitchColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(
                hintText: '添加新待办…',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          TextButton(
            onPressed: enabled ? onSubmit : null,
            style: TextButton.styleFrom(
              minimumSize: const Size(64, 48),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: const Text('添加'),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
