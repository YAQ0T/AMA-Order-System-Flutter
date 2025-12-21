import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../state/auth_notifier.dart';
import '../../state/order_notifier.dart';
import '../admin/admin_dashboard.dart';
import '../maker/maker_dashboard.dart';
import '../taker/taker_dashboard.dart';
import '../accounter/accounter_dashboard.dart';

class RoleDashboard extends StatelessWidget {
  const RoleDashboard({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final orders = context.read<OrderNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: Text('AMA Order System - ${user.role}'),
        actions: [
          IconButton(
            onPressed: () => orders.loadOrders(),
            icon: const Icon(Icons.refresh),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Tooltip(
              message: 'Dark mode',
              child: Switch.adaptive(
                value: auth.prefersDark,
                onChanged: (value) => _toggleTheme(context, auth, value),
              ),
            ),
          ),
          IconButton(
            onPressed: () => auth.logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _bodyForRole(user),
    );
  }

  Future<void> _toggleTheme(BuildContext context, AuthNotifier auth, bool prefersDark) async {
    try {
      await auth.setThemePreference(prefersDark);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Widget _bodyForRole(AppUser user) {
    switch (user.role) {
      case 'admin':
        return const AdminDashboard();
      case 'maker':
        return const MakerDashboard();
      case 'taker':
        return const TakerDashboard();
      case 'accounter':
        return const AccounterDashboard();
      default:
        return const Center(child: Text('Unknown role'));
    }
  }
}
