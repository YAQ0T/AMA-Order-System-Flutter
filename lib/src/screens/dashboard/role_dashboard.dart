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
    final auth = context.read<AuthNotifier>();
    final orders = context.read<OrderNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: Text('AMA Order System - ${user.role}'),
        actions: [
          IconButton(
            onPressed: () => orders.loadOrders(),
            icon: const Icon(Icons.refresh),
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
