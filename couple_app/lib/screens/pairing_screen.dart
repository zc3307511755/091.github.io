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
                      onPressed:
                          couple.isLoading ? null : () => couple.createInvite(),
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
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
}
