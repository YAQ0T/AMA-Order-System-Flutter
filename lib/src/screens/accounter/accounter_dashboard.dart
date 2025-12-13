import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../state/order_notifier.dart';
import '../../widgets/order_filters.dart';
import '../../widgets/order_table.dart';
import '../../utils/order_printer.dart';

class AccounterDashboard extends StatefulWidget {
  const AccounterDashboard({super.key});

  @override
  State<AccounterDashboard> createState() => _AccounterDashboardState();
}

class _AccounterDashboardState extends State<AccounterDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderNotifier>().loadOrders(status: 'completed');
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderNotifier>();

    return RefreshIndicator(
      onRefresh: () => orders.loadOrders(status: 'completed'),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          OrderFilters(
            status: orders.statusFilter,
            onStatusChanged: (s) => orders.loadOrders(status: 'completed', search: orders.searchTerm),
            onSearchChanged: (s) => orders.loadOrders(status: 'completed', search: s),
            statusEnabled: false,
            allowedStatuses: const ['completed'],
          ),
          const SizedBox(height: 12),
          OrderTable(
            orders: orders.orders,
            onSendToErp: _sendToErp,
            onPrint: (order) => OrderPrinter.printOrder(order),
            showLogs: true,
          ),
          if (orders.orders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No orders ready for ERP')),
            ),
          if (orders.loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Future<void> _sendToErp(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send to ERP'),
        content: Text('Send order #${order.id} to ERP? This will mark it as entered.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send')),
        ],
      ),
    );
    if (confirm != true) return;

    final notifier = context.read<OrderNotifier>();
    try {
      await notifier.updateStatus(order.id, 'entered_erp');
      await notifier.loadOrders(status: 'completed');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Order #${order.id} sent to ERP')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send order: $e')));
      }
    }
  }
}
