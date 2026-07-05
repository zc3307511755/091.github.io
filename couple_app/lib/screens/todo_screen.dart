import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo_item.dart';
import '../providers/couple_provider.dart';
import '../providers/todo_provider.dart';

class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final couple = context.watch<CoupleProvider>().current;
    final todos = context.watch<TodoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('共享待办'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: couple == null || todos.isLoading
                ? null
                : () => todos.loadTodos(couple.id),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '新增待办',
        onPressed: couple == null ? null : () => _showAddTodoSheet(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (todos.isLoading) const LinearProgressIndicator(),
            if (todos.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  todos.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: todos.items.isEmpty
                  ? const _TodoEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: todos.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _TodoTile(item: todos.items[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTodoSheet(BuildContext context) {
    final couple = context.read<CoupleProvider>().current;
    if (couple == null) {
      return;
    }

    final controller = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
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
                '新增待办',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '要一起完成什么？',
                  prefixIcon: Icon(Icons.edit_note),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _addTodo(sheetContext, couple.id, controller),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _addTodo(sheetContext, couple.id, controller),
                icon: const Icon(Icons.add_task),
                label: const Text('添加'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addTodo(
    BuildContext context,
    String coupleId,
    TextEditingController controller,
  ) async {
    final title = controller.text.trim();
    if (title.isEmpty) {
      return;
    }

    await context.read<TodoProvider>().addTodo(coupleId, title);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({required this.item});

  final TodoItem item;

  @override
  Widget build(BuildContext context) {
    final todos = context.read<TodoProvider>();

    return Card(
      child: ListTile(
        leading: Checkbox(
          value: item.isDone,
          onChanged: (value) {
            todos.setDone(item, value ?? false);
          },
        ),
        title: Text(
          item.title,
          style: TextStyle(
            decoration: item.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: IconButton(
          tooltip: '删除',
          onPressed: () => todos.deleteTodo(item),
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}

class _TodoEmptyState extends StatelessWidget {
  const _TodoEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              '还没有共享待办',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text('点右下角添加你们要一起完成的小事。'),
          ],
        ),
      ),
    );
  }
}
