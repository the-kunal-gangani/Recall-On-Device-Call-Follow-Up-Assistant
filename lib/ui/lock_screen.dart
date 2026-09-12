import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/auth/lock_state_provider.dart';

class LockScreen extends ConsumerWidget {
  final Widget child;

  const LockScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(lockProvider);

    if (unlocked) return child;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64),
            const SizedBox(height: 16),
            const Text('Recall is locked'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(lockProvider.notifier).attemptUnlock(),
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}
