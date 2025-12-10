import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/user.dart';
import '../../state/auth_notifier.dart';
import '../../state/order_notifier.dart';
import '../../utils/order_printer.dart';
import '../../widgets/order_filters.dart';
import '../../widgets/order_form.dart';
import '../../widgets/order_edit_sheet.dart';
import '../../widgets/order_table.dart';

class MakerDashboard extends StatefulWidget {
  const MakerDashboard({super.key});

  @override
  State<MakerDashboard> createState() => _MakerDashboardState();
}

class _MakerDashboardState extends State<MakerDashboard> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) {
        _loadForTab();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadForTab());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String get _tabStatus => _tab.index == 0 ? 'active' : 'archived';

  Future<void> _loadForTab() {
    return context.read<OrderNotifier>().loadOrders(status: _tabStatus);
  }

  Future<void> _openEdit(OrderModel order) async {
    final notifier = context.read<OrderNotifier>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => OrderEditSheet(
        order: order,
        onSubmit: (payload) => notifier.updateOrderDetails(order.id, payload),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderNotifier>();

    return Column(
      children: [
        TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Archived'),
          ],
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadForTab,
            child: TabBarView(
              controller: _tab,
              children: [
                _OrdersTab(
                  orders: orders,
                  onEdit: _openEdit,
                  onStatusChanged: (s) => orders.loadOrders(status: s),
                  onSearchChanged: (s) => orders.loadOrders(search: s),
                ),
                _ArchivedTab(
                  orders: orders,
                  onEdit: _openEdit,
                  onSearchChanged: (s) => orders.loadOrders(search: s, status: 'archived'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab({
    required this.orders,
    required this.onEdit,
    required this.onStatusChanged,
    required this.onSearchChanged,
  });

  final OrderNotifier orders;
  final Future<void> Function(OrderModel) onEdit;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        OrderFilters(
          status: orders.statusFilter,
          allowedStatuses: const ['active', 'pending', 'in-progress', 'completed', 'entered_erp'],
          onStatusChanged: onStatusChanged,
          onSearchChanged: onSearchChanged,
        ),
        const SizedBox(height: 12),
        const OrderForm(),
        const SizedBox(height: 12),
        OrderTable(
          orders: orders.orders,
          onUpdateStatus: (id, status) => orders.updateStatus(id, status),
          onDelete: (id) => orders.deleteOrder(id),
          onEdit: onEdit,
          onPrint: (order) => OrderPrinter.printOrder(order),
          showLogs: true,
        ),
        if (orders.loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _ArchivedTab extends StatelessWidget {
  const _ArchivedTab({
    required this.orders,
    required this.onEdit,
    required this.onSearchChanged,
  });

  final OrderNotifier orders;
  final Future<void> Function(OrderModel) onEdit;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        OrderFilters(
          status: 'archived',
          allowedStatuses: const ['archived'],
          statusEnabled: false,
          onStatusChanged: (_) {},
          onSearchChanged: onSearchChanged,
        ),
        const SizedBox(height: 12),
        _ArchivedBulkSend(orders: orders),
        const SizedBox(height: 12),
        OrderTable(
          orders: orders.orders,
          onUpdateStatus: (id, status) => orders.updateStatus(id, status),
          onDelete: (id) => orders.deleteOrder(id),
          onEdit: onEdit,
          onPrint: (order) => OrderPrinter.printOrder(order),
          showLogs: true,
        ),
        if (orders.loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _ArchivedBulkSend extends StatefulWidget {
  const _ArchivedBulkSend({required this.orders});
  final OrderNotifier orders;

  @override
  State<_ArchivedBulkSend> createState() => _ArchivedBulkSendState();
}

class _ArchivedBulkSendState extends State<_ArchivedBulkSend> {
  String? _city;
  final Set<int> _selectedOrderIds = {};
  final Set<int> _takerIds = {};
  int? _accounterId;

  @override
  Widget build(BuildContext context) {
    final allOrders = widget.orders.orders.where((o) => o.status == 'archived').toList();
    final cities = allOrders.map((o) => o.city ?? 'Unspecified').toSet().toList()..sort();
    final filtered = _city == null ? allOrders : allOrders.where((o) => (o.city ?? 'Unspecified') == _city).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Archived orders', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButton<String>(
              isExpanded: true,
              value: _city,
              hint: const Text('Select city'),
              items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _city = v),
            ),
            const SizedBox(height: 8),
            if (filtered.isEmpty)
              const Text('No archived orders for this city.')
            else
              Column(
                children: filtered
                    .map(
                      (o) => CheckboxListTile(
                        value: _selectedOrderIds.contains(o.id),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedOrderIds.add(o.id);
                            } else {
                              _selectedOrderIds.remove(o.id);
                            }
                          });
                        },
                        title: Text(o.titleOrFallback),
                        subtitle: Text('City: ${o.city ?? 'Unspecified'}'),
                      ),
                    )
                    .toList(),
              ),
            const Divider(),
            FutureBuilder<List<AppUser>>(
              future: context.read<AuthNotifier>().fetchAssignableTakers(),
              builder: (context, snapshot) {
                final takers = snapshot.data ?? [];
                return Wrap(
                  spacing: 8,
                  children: takers
                      .map(
                        (t) => FilterChip(
                          label: Text(t.username),
                          selected: _takerIds.contains(t.id),
                          onSelected: (v) {
                            setState(() {
                              v ? _takerIds.add(t.id) : _takerIds.remove(t.id);
                            });
                          },
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<AppUser>>(
              future: context.read<AuthNotifier>().fetchAccounters(),
              builder: (context, snapshot) {
                final accs = snapshot.data ?? [];
                return DropdownButton<int?>(
                  isExpanded: true,
                  value: _accounterId,
                  hint: const Text('Select accounter (optional)'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('None')),
                    ...accs.map((a) => DropdownMenuItem<int?>(value: a.id, child: Text(a.username)))
                  ],
                  onChanged: (v) => setState(() => _accounterId = v),
                );
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _sendSelected,
                child: const Text('Send selected'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _sendSelected() async {
    if (_selectedOrderIds.isEmpty) return;
    if (_takerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one taker')));
      return;
    }
    final notifier = widget.orders;
    for (final id in _selectedOrderIds) {
      await notifier.updateOrderDetails(id, {
        'status': 'pending',
        'assignedTakerIds': _takerIds.toList(),
        'accounterId': _accounterId
      });
    }
    setState(() {
      _selectedOrderIds.clear();
      _takerIds.clear();
      _accounterId = null;
    });
    await notifier.loadOrders(status: notifier.statusFilter);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Orders sent')));
    }
  }
}
