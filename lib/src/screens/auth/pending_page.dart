import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_notifier.dart';

class PendingApprovalPage extends StatelessWidget {
  const PendingApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthNotifier>();
    return Scaffold(
      appBar: AppBar(title: const Text('Pending approval')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account awaiting approval',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Your account has been created and is pending admin approval. '
              'You will be able to access the system once approved.',
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => auth.logout(),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
