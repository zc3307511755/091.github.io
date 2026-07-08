import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/couple_provider.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _inviteController = TextEditingController();

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final couple = context.watch<CoupleProvider>();
    final inviteCode = couple.inviteCode;
    final canResetPairing = couple.error?.contains('当前账号') == true &&
        (couple.error?.contains('配对') == true ||
            couple.error?.contains('邀请码') == true);

    return Scaffold(
      appBar: AppBar(title: const Text('情侣配对')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '先把你们连接起来',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '一方生成邀请码，另一方输入后即可共享待办、日志和更多内容。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  if (inviteCode == null)
                    FilledButton.icon(
                      onPressed: couple.isLoading ? null : _createInvite,
                      icon: const Icon(Icons.key),
                      label: const Text('生成邀请码'),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text('把这个邀请码发给另一半'),
                            const SizedBox(height: 12),
                            SelectableText(
                              inviteCode,
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: couple.isLoading
                                  ? null
                                  : _confirmCancelInvite,
                              icon: const Icon(Icons.refresh),
                              label: const Text('取消这个邀请码'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '或者',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _inviteController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: '输入对方的邀请码',
                      prefixIcon: Icon(Icons.link),
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: couple.isLoading ? null : _bind,
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('完成配对'),
                  ),
                  if (couple.isLoading) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ],
                  if (couple.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      couple.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    if (canResetPairing) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed:
                            couple.isLoading ? null : _confirmResetPairingState,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('重置配对状态'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createInvite() async {
    try {
      await context.read<CoupleProvider>().createInvite();
    } catch (_) {
      // The provider exposes the message for the UI.
    }
  }

  Future<void> _bind() async {
    final code = _inviteController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入 6 位邀请码')),
      );
      return;
    }

    try {
      await context.read<CoupleProvider>().bindByInviteCode(code);
    } catch (_) {
      // The provider exposes the message for the UI.
    }
  }

  Future<void> _confirmCancelInvite() async {
    await _confirmLeaveCurrentCouple(
      title: '取消当前邀请码？',
      content: '取消后，这个邀请码会失效，你可以重新生成新的邀请码。',
      cancelLabel: '保留',
      confirmLabel: '取消邀请码',
      successMessage: '已取消，可以重新生成邀请码。',
    );
  }

  Future<void> _confirmResetPairingState() async {
    await _confirmLeaveCurrentCouple(
      title: '重置配对状态？',
      content: '这会解除当前账号参与的待确认或已配对关系，然后你可以重新生成或输入邀请码。',
      cancelLabel: '取消',
      confirmLabel: '重置',
      successMessage: '已重置，可以重新开始配对。',
    );
  }

  Future<void> _confirmLeaveCurrentCouple({
    required String title,
    required String content,
    required String cancelLabel,
    required String confirmLabel,
    required String successMessage,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await context.read<CoupleProvider>().leaveCurrentCouple();
      _inviteController.clear();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (_) {
      // The provider exposes the message for the UI.
    }
  }
}
