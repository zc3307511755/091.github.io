import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/meal_entry.dart';
import '../models/meal_comment.dart';
import '../models/meal_plan.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/meal_provider.dart';

class MealScreen extends StatelessWidget {
  const MealScreen({super.key});

  static const mealTypes = [
    ('breakfast', '早餐', Icons.free_breakfast),
    ('lunch', '午餐', Icons.rice_bowl_outlined),
    ('dinner', '晚餐', Icons.dinner_dining),
    ('snack', '加餐', Icons.icecream_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final meal = context.watch<MealProvider>();
    final couple = context.watch<CoupleProvider>().current;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('今天吃啥'),
          actions: [
            IconButton(
              tooltip: '选择日期',
              onPressed: couple == null ? null : () => _pickDate(context),
              icon: const Icon(Icons.calendar_today),
            ),
            IconButton(
              tooltip: '刷新',
              onPressed: couple == null || meal.isLoading
                  ? null
                  : () => meal.loadForDate(couple.id, meal.selectedDate),
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.photo_library_outlined), text: '餐食照片'),
              Tab(icon: Icon(Icons.restaurant_menu), text: '饮食计划'),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _DateHeader(date: meal.selectedDate),
              if (meal.isLoading) const LinearProgressIndicator(),
              if (meal.error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    meal.error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const Expanded(
                child: TabBarView(
                  children: [
                    _MealPhotosTab(mealTypes: MealScreen.mealTypes),
                    _MealPlansTab(mealTypes: MealScreen.mealTypes),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final couple = context.read<CoupleProvider>().current;
    final meal = context.read<MealProvider>();
    if (couple == null) {
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: meal.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && context.mounted) {
      await meal.changeDate(couple.id, picked);
    }
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Icon(
            Icons.event,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('yyyy-MM-dd').format(date),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _MealPhotosTab extends StatelessWidget {
  const _MealPhotosTab({required this.mealTypes});

  final List<(String, String, IconData)> mealTypes;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: mealTypes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final (type, label, icon) = mealTypes[index];
        final entries = context.watch<MealProvider>().entriesForType(type);

        return _MealSection(
          title: label,
          icon: icon,
          actionIcon: Icons.add_a_photo_outlined,
          onAction: () => _showAddPhotoSheet(context, type),
          child: entries.isEmpty
              ? const _SectionEmptyText(text: '还没有照片')
              : Column(
                  children: entries.map((entry) {
                    return _MealPhotoCard(entry: entry);
                  }).toList(),
                ),
        );
      },
    );
  }

  void _showAddPhotoSheet(BuildContext context, String mealType) {
    final noteController = TextEditingController();
    XFile? pickedFile;

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
                    '添加餐食照片',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final file = await ImagePicker().pickImage(
                              source: ImageSource.camera,
                              imageQuality: 82,
                              maxWidth: 1600,
                            );
                            if (file != null) {
                              setState(() {
                                pickedFile = file;
                              });
                            }
                          },
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('拍照'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final file = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 82,
                              maxWidth: 1600,
                            );
                            if (file != null) {
                              setState(() {
                                pickedFile = file;
                              });
                            }
                          },
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('相册'),
                        ),
                      ),
                    ],
                  ),
                  if (pickedFile != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      pickedFile!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: '备注',
                      prefixIcon: Icon(Icons.notes),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: pickedFile == null
                        ? null
                        : () => _uploadPhoto(
                              context,
                              pickedFile!,
                              mealType,
                              noteController.text,
                            ),
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('上传'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _uploadPhoto(
    BuildContext context,
    XFile file,
    String mealType,
    String note,
  ) async {
    final couple = context.read<CoupleProvider>().current;
    final user = context.read<AuthProvider>().user;
    if (couple == null || user == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    final extension =
        file.name.contains('.') ? file.name.split('.').last : 'jpg';

    if (context.mounted) {
      await context.read<MealProvider>().addEntry(
            coupleId: couple.id,
            userId: user.id,
            mealType: mealType,
            imageBytes: bytes,
            fileExtension: extension,
            note: note,
          );
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

class _MealPlansTab extends StatelessWidget {
  const _MealPlansTab({required this.mealTypes});

  final List<(String, String, IconData)> mealTypes;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: mealTypes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final (type, label, icon) = mealTypes[index];
        final plans = context.watch<MealProvider>().plansForType(type);

        return _MealSection(
          title: label,
          icon: icon,
          actionIcon: Icons.add,
          onAction: () => _showAddPlanSheet(context, type),
          child: plans.isEmpty
              ? const _SectionEmptyText(text: '还没有计划')
              : Column(
                  children: plans.map((plan) {
                    return _MealPlanTile(plan: plan);
                  }).toList(),
                ),
        );
      },
    );
  }

  void _showAddPlanSheet(BuildContext context, String mealType) {
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
                '添加饮食计划',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '计划吃什么？',
                  prefixIcon: Icon(Icons.restaurant_menu),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) =>
                    _addPlan(sheetContext, mealType, controller.text),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    _addPlan(sheetContext, mealType, controller.text),
                icon: const Icon(Icons.add_task),
                label: const Text('添加'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addPlan(
    BuildContext context,
    String mealType,
    String content,
  ) async {
    final couple = context.read<CoupleProvider>().current;
    if (couple == null) {
      return;
    }

    await context.read<MealProvider>().addPlan(
          coupleId: couple.id,
          mealType: mealType,
          content: content,
        );
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.title,
    required this.icon,
    required this.actionIcon,
    required this.onAction,
    required this.child,
  });

  final String title;
  final IconData icon;
  final IconData actionIcon;
  final VoidCallback onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: '添加',
                  onPressed: onAction,
                  icon: Icon(actionIcon),
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

class _MealPhotoCard extends StatelessWidget {
  const _MealPhotoCard({required this.entry});

  final MealEntry entry;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MealProvider>();
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final isMine = entry.authorId == currentUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FutureBuilder<String>(
              future: provider.signedPhotoUrl(entry.photoPath),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return Image.network(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  height: 210,
                );
              },
            ),
          ),
          if (entry.note?.isNotEmpty == true || isMine)
            Row(
              children: [
                if (entry.note?.isNotEmpty == true)
                  Expanded(child: Text(entry.note!))
                else
                  const Spacer(),
                if (isMine)
                  IconButton(
                    tooltip: '删除照片',
                    onPressed: () => provider.deleteEntry(entry),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
          _MealComments(entry: entry),
        ],
      ),
    );
  }
}

class _MealComments extends StatefulWidget {
  const _MealComments({required this.entry});

  final MealEntry entry;

  @override
  State<_MealComments> createState() => _MealCommentsState();
}

class _MealCommentsState extends State<_MealComments> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showAll = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MealProvider>();
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final comments = provider.commentsForEntry(widget.entry.id);
    final visibleComments = !_showAll && comments.length > 3
        ? comments.sublist(comments.length - 3)
        : comments;
    final isSending = provider.isSendingComment(widget.entry.id);

    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 17,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                comments.isEmpty ? '评论' : '评论 ${comments.length}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const Spacer(),
              if (comments.length > 3)
                TextButton(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  child: Text(_showAll ? '收起' : '查看全部'),
                ),
            ],
          ),
          if (comments.isEmpty && provider.commentError == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '还没有评论，说点什么吧',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            ...visibleComments.map(
              (comment) => _MealCommentRow(
                comment: comment,
                isMine: comment.authorId == currentUserId,
                onDelete: () => provider.deleteComment(comment),
              ),
            ),
          if (provider.commentError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      provider.commentError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: '重试加载评论',
                    onPressed: provider.refreshComments,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.refresh, size: 18),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: !isSending,
                  maxLength: 300,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    hintText: '写下评论...',
                    counterText: '',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submitComment(),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                tooltip: '发送评论',
                onPressed: isSending ? null : _submitComment,
                icon: isSending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 19),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitComment() async {
    final userId = context.read<AuthProvider>().user?.id;
    final content = _controller.text.trim();
    if (userId == null || content.isEmpty) {
      return;
    }

    final provider = context.read<MealProvider>();
    final sent = await provider.addComment(
      entry: widget.entry,
      userId: userId,
      content: content,
    );
    if (!mounted) {
      return;
    }

    if (sent) {
      _controller.clear();
      _focusNode.unfocus();
      setState(() => _showAll = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.commentError ?? '评论发送失败')),
      );
    }
  }
}

class _MealCommentRow extends StatelessWidget {
  const _MealCommentRow({
    required this.comment,
    required this.isMine,
    required this.onDelete,
  });

  final MealComment comment;
  final bool isMine;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final nickname = isMine
        ? '我'
        : comment.authorNickname?.trim().isNotEmpty == true
            ? comment.authorNickname!.trim()
            : '对方';
    final avatarText = String.fromCharCode(nickname.runes.first);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              avatarText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      nickname,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('HH:mm').format(comment.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.content),
              ],
            ),
          ),
          if (isMine)
            IconButton(
              tooltip: '删除评论',
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline, size: 18),
            ),
        ],
      ),
    );
  }
}

class _MealPlanTile extends StatelessWidget {
  const _MealPlanTile({required this.plan});

  final MealPlan plan;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MealProvider>();

    return CheckboxListTile(
      value: plan.isDone,
      onChanged: (value) => provider.setPlanDone(plan, value ?? false),
      title: Text(
        plan.content,
        style: TextStyle(
          decoration: plan.isDone ? TextDecoration.lineThrough : null,
        ),
      ),
      secondary: IconButton(
        tooltip: '删除计划',
        onPressed: () => provider.deletePlan(plan),
        icon: const Icon(Icons.delete_outline),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _SectionEmptyText extends StatelessWidget {
  const _SectionEmptyText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
