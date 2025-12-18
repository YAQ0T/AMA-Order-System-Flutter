import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/activity_log.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../state/admin_notifier.dart';
import '../../state/order_notifier.dart';
import '../../widgets/order_card.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminNotifier>().refreshAll();
      context.read<OrderNotifier>().loadOrders();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminNotifier>();

    return Column(
      children: [
        TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Orders'),
            Tab(text: 'Logs'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _OverviewTab(admin: admin),
              _UsersTab(admin: admin),
              _OrdersTab(),
              _LogsTab(admin: admin),
            ],
          ),
        )
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.admin});

  final AdminNotifier admin;

  @override
  Widget build(BuildContext context) {
    if (admin.loading && admin.stats == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final stats = admin.stats;
    if (stats == null) {
      return const Center(child: Text('No stats'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _statCard('Users', stats.totalUsers.toString()),
            _statCard('Pending approvals', stats.pendingApprovals.toString()),
            _statCard('Total orders', stats.totalOrders.toString()),
            _statCard('Active orders', stats.activeOrders.toString()),
          ],
        ),
        const SizedBox(height: 16),
        Text('Recent activity', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...stats.recentActivity.map(_activityTile),
      ],
    );
  }

  Widget _statCard(String title, String value) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityTile(ActivityLog log) {
    return ListTile(
      dense: true,
      title: Text(log.type),
      subtitle: Text('${log.entityType} ${log.entityId ?? ''}'),
      trailing: Text(log.createdAt.toLocal().toString().split('.').first),
    );
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab({required this.admin});

  final AdminNotifier admin;

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _emailController = TextEditingController();
  int? _editingUserId;

  @override
  Widget build(BuildContext context) {
    final admin = widget.admin;

    return RefreshIndicator(
      onRefresh: () => admin.refreshAll(),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('Pending approvals', style: Theme.of(context).textTheme.titleMedium),
          ...admin.pendingUsers.map(
            (u) => ListTile(
              title: Text(u.username),
              subtitle: Text(u.role),
              trailing: TextButton(
                onPressed: () => admin.approveUser(u.id),
                child: const Text('Approve'),
              ),
            ),
          ),
          const Divider(),
          Text('All users', style: Theme.of(context).textTheme.titleMedium),
          ...admin.users.map(_userTile),
        ],
      ),
    );
  }

  Widget _userTile(AppUser user) {
    final admin = widget.admin;
    final isEditing = _editingUserId == user.id;
    if (isEditing) {
      _emailController.text = user.email ?? '';
    }
    return ListTile(
      title: Text('${user.username} (${user.role})'),
      subtitle: isEditing
          ? TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              onSubmitted: (value) async {
                await admin.updateEmail(user.id, value);
                setState(() => _editingUserId = null);
              },
            )
          : Text(user.email ?? 'No email'),
      trailing: Wrap(
        spacing: 8,
        children: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.email_outlined),
            onPressed: () async {
              if (!isEditing) {
                setState(() => _editingUserId = user.id);
              } else {
                await admin.updateEmail(user.id, _emailController.text);
                setState(() => _editingUserId = null);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await admin.deleteUser(user.id);
            },
          ),
        ],
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminNotifier>();
    final orders = context.watch<OrderNotifier>();

    return RefreshIndicator(
      onRefresh: () async {
        await admin.reloadOrders();
        await orders.loadOrders();
      },
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('All orders', style: Theme.of(context).textTheme.titleMedium),
          ...admin.orders.map(
            (order) => OrderCard(
              order: order,
              availableStatuses: const ['pending', 'in-progress', 'completed', 'archived', 'entered_erp'],
              onStatusChange: (status) => orders.updateStatus(order.id, status),
              onDelete: () async {
                final confirmed = await _confirmDeleteOrder(context, order);
                if (confirmed) {
                  await admin.deleteOrder(order.id);
                }
              },
            ),
          ),
          if (admin.orders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No orders')),
            ),
        ],
      ),
    );
  }
}

class _LogsTab extends StatelessWidget {
  const _LogsTab({required this.admin});

  final AdminNotifier admin;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => admin.refreshAll(),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('Recent logs', style: Theme.of(context).textTheme.titleMedium),
          ...admin.logs.map(_tile),
          const Divider(),
          Text('Audit logs', style: Theme.of(context).textTheme.titleMedium),
          ...admin.auditLogs.map(_tile),
        ],
      ),
    );
  }

  Widget _tile(ActivityLog log) {
    return ListTile(
      dense: true,
      title: Text(log.type),
      subtitle: Text('${log.entityType} ${log.entityId ?? ''} by ${log.user?.username ?? ''}'),
      trailing: Text(log.createdAt.toLocal().toString().split('.').first),
    );
  }
}

Future<bool> _confirmDeleteOrder(BuildContext context, OrderModel order) async {
  final title = order.titleOrFallback;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete order?'),
      content: Text('Delete "$title"? This action cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton.tonal(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result == true;
}
