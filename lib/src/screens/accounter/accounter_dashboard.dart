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

class _AccounterDashboardState extends State<AccounterDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<_AccounterTab> _tabs = const [
    _AccounterTab(status: 'completed', label: 'Completed'),
    _AccounterTab(status: 'entered_erp', label: 'Entered to ERP'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadForTab();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderNotifier>();
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Material(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            elevation: 1,
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: scheme.onPrimaryContainer,
              unselectedLabelColor: scheme.onSurface,
              tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadForTab,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                OrderFilters(
                  status: _activeStatus,
                  onStatusChanged: (_) => _loadForTab(),
                  onSearchChanged: (s) => orders.loadOrders(status: _activeStatus, search: s),
                  statusEnabled: false,
                  allowedStatuses: [_activeStatus],
                ),
                const SizedBox(height: 12),
                OrderTable(
                  orders: orders.orders,
                  onSendToErp: _sendToErp,
                  onPrint: (order) => OrderPrinter.printOrder(order),
                  showLogs: true,
                ),
                if (orders.orders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        _activeStatus == 'entered_erp'
                            ? 'No orders entered into ERP yet'
                            : 'No orders ready for ERP',
                      ),
                    ),
                  ),
                if (orders.loading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String get _activeStatus => _tabs[_tabController.index].status;

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    _loadForTab();
  }

  Future<void> _loadForTab() {
    final notifier = context.read<OrderNotifier>();
    return notifier.loadOrders(status: _activeStatus, search: notifier.searchTerm);
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
      await notifier.loadOrders(status: _activeStatus);
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

class _AccounterTab {
  const _AccounterTab({required this.status, required this.label});

  final String status;
  final String label;
}
