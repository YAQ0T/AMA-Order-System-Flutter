import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      onRefresh: () => orders.loadOrders(),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          OrderFilters(
            status: orders.statusFilter,
            onStatusChanged: (s) => orders.loadOrders(status: s),
            onSearchChanged: (s) => orders.loadOrders(search: s),
          ),
          const SizedBox(height: 12),
          OrderTable(
            orders: orders.orders,
            onUpdateStatus: (id, status) => orders.updateStatus(id, status),
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
}
