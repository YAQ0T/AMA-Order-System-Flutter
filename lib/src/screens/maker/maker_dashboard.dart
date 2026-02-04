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
import '../../widgets/order_report_view.dart';
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
    _tab = TabController(length: 3, vsync: this);
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

  String get _tabStatus {
    if (_tab.index == 0) return 'active';
    if (_tab.index == 1) return 'archived';
    return 'active';
  }

  Future<void> _loadForTab() {
    if (_tab.index == 2) return Future.value();
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
            Tab(text: 'Reports'),
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
                const OrderReportView(title: 'My orders report'),
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

  Future<void> _updateStatus(OrderNotifier orders, int id, String status) async {
    if (status == 'archived') {
      await orders.updateOrderDetails(id, {
        'status': 'archived',
        'assignedTakerIds': const <int>[],
        'accounterId': null,
      });
      await orders.loadOrders(status: orders.statusFilter, search: orders.searchTerm);
      return;
    }
    await orders.updateStatus(id, status);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const OrderForm(),
        const SizedBox(height: 12),
        OrderFilters(
          status: orders.statusFilter,
          allowedStatuses: const ['active', 'pending', 'in-progress', 'completed', 'entered_erp'],
          onStatusChanged: onStatusChanged,
          onSearchChanged: onSearchChanged,
        ),
        const SizedBox(height: 12),
        OrderTable(
          orders: orders.orders,
          onUpdateStatus: (id, status) => _updateStatus(orders, id, status),
          onDelete: (id) async {
            final order = orders.orders.firstWhere(
              (o) => o.id == id,
              orElse: () => OrderModel(id: id, status: 'pending', createdAt: DateTime.now()),
            );
            final confirmed = await _confirmDeleteOrder(context, order);
            if (confirmed) {
              await orders.deleteOrder(id);
            }
          },
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

class _ArchivedTab extends StatefulWidget {
  const _ArchivedTab({
    required this.orders,
    required this.onEdit,
    required this.onSearchChanged,
  });

  final OrderNotifier orders;
  final Future<void> Function(OrderModel) onEdit;
  final ValueChanged<String> onSearchChanged;

  @override
  State<_ArchivedTab> createState() => _ArchivedTabState();
}

class _ArchivedTabState extends State<_ArchivedTab> {
  final Set<int> _selectedOrderIds = {};
  bool _sending = false;

  String _cityLabel(OrderModel order) {
    final city = order.city?.trim() ?? '';
    return city.isEmpty ? 'Unspecified' : city;
  }

  List<MapEntry<String, List<OrderModel>>> _groupByCity(List<OrderModel> orders) {
    final grouped = <String, List<OrderModel>>{};
    for (final order in orders) {
      final city = _cityLabel(order);
      grouped.putIfAbsent(city, () => []).add(order);
    }

    final orderedKeys = <String>[];
    for (final city in kOrderCities) {
      if (grouped.containsKey(city)) {
        orderedKeys.add(city);
      }
    }
    final extraKeys = grouped.keys
        .where((city) => !kOrderCities.contains(city) && city != 'Unspecified')
        .toList()
      ..sort();
    orderedKeys.addAll(extraKeys);
    if (grouped.containsKey('Unspecified')) {
      orderedKeys.add('Unspecified');
    }

    return orderedKeys.map((city) => MapEntry(city, grouped[city]!)).toList();
  }

  String _itemCountLabel(int count) => count == 1 ? '1 item' : '$count items';

  String _formatShortDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.month}/${local.day}/${local.year}';
  }

  void _toggleOrderSelection(OrderModel order, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedOrderIds.add(order.id);
      } else {
        _selectedOrderIds.remove(order.id);
      }
    });
  }

  void _toggleSelectAll(List<OrderModel> orders) {
    final allSelected = orders.every((order) => _selectedOrderIds.contains(order.id));
    setState(() {
      if (allSelected) {
        for (final order in orders) {
          _selectedOrderIds.remove(order.id);
        }
      } else {
        for (final order in orders) {
          _selectedOrderIds.add(order.id);
        }
      }
    });
  }

  Future<void> _handleDelete(OrderModel order) async {
    final confirmed = await _confirmDeleteOrder(context, order);
    if (confirmed) {
      await widget.orders.deleteOrder(order.id);
    }
  }

  Future<void> _printSelected(List<OrderModel> selected) async {
    for (final order in selected) {
      await OrderPrinter.printOrder(order);
    }
  }

  Future<void> _sendSelected(List<OrderModel> selected) async {
    if (selected.isEmpty || _sending) return;
    final payload = await _openSendSheet();
    if (payload == null) return;

    setState(() => _sending = true);
    final notifier = widget.orders;
    try {
      for (final order in selected) {
        await notifier.updateOrderDetails(order.id, {
          'status': 'pending',
          'assignedTakerIds': payload.takerIds,
          'accounterId': payload.accounterId,
        });
      }
      if (!mounted) return;
      setState(() {
        for (final order in selected) {
          _selectedOrderIds.remove(order.id);
        }
      });
      await notifier.loadOrders(status: 'archived', search: notifier.searchTerm);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Orders sent')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send orders: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<_ArchivedSendPayload?> _openSendSheet() {
    return showModalBottomSheet<_ArchivedSendPayload>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ArchivedSendSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final archivedOrders = widget.orders.orders.where((o) => o.status == 'archived').toList();
    _selectedOrderIds.removeWhere((id) => archivedOrders.every((order) => order.id != id));
    final grouped = _groupByCity(archivedOrders);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        OrderFilters(
          status: 'archived',
          allowedStatuses: const ['archived'],
          statusEnabled: false,
          onStatusChanged: (_) {},
          onSearchChanged: widget.onSearchChanged,
        ),
        const SizedBox(height: 12),
        if (archivedOrders.isEmpty && widget.orders.loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (archivedOrders.isEmpty && !widget.orders.loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('No archived orders yet')),
          ),
        ...grouped.map((entry) => _buildCityGroup(context, entry)),
        if (widget.orders.loading && archivedOrders.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
  Widget _buildCityGroup(BuildContext context, MapEntry<String, List<OrderModel>> entry) {
    final orders = entry.value;
    final selectedOrders = orders.where((order) => _selectedOrderIds.contains(order.id)).toList();
    final selectedCount = selectedOrders.length;
    final allSelected = orders.isNotEmpty && selectedCount == orders.length;
    final scheme = Theme.of(context).colorScheme;

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _sending ? null : () => _toggleSelectAll(orders),
          child: Text(allSelected ? 'Clear' : 'Select All'),
        ),
        FilledButton.tonal(
          onPressed: selectedCount == 0 ? null : () => _printSelected(selectedOrders),
          child: Text('Print Selected ($selectedCount)'),
        ),
        FilledButton(
          onPressed: selectedCount == 0 || _sending ? null : () => _sendSelected(selectedOrders),
          child: Text('Send Selected ($selectedCount)'),
        ),
      ],
    );

    final rows = <Widget>[];
    for (var i = 0; i < orders.length; i++) {
      if (i > 0) {
        rows.add(const Divider(height: 16));
      }
      rows.add(_buildArchivedRow(context, orders[i]));
    }

    final header = LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final title = Row(
          children: [
            const Icon(Icons.folder_open, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${entry.key} (${orders.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: title),
            actions,
          ],
        );
      },
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 8),
            if (orders.isEmpty)
              Text('No archived orders for ${entry.key}.', style: TextStyle(color: scheme.onSurfaceVariant))
            else
              ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedRow(BuildContext context, OrderModel order) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = _selectedOrderIds.contains(order.id);
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.titleOrFallback,
          style: Theme.of(context).textTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '${_itemCountLabel(order.items.length)} - Created ${_formatShortDate(order.createdAt)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    final actionStyle = OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 10),
    );
    final deleteStyle = OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      foregroundColor: scheme.error,
      side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
      padding: const EdgeInsets.symmetric(horizontal: 10),
    );
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          style: actionStyle,
          onPressed: () => OrderPrinter.printOrder(order),
          icon: const Icon(Icons.print, size: 18),
          label: const Text('Print'),
        ),
        OutlinedButton.icon(
          style: actionStyle,
          onPressed: () => widget.onEdit(order),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit'),
        ),
        OutlinedButton(
          style: deleteStyle,
          onPressed: () => _handleDelete(order),
          child: const Text('Delete'),
        ),
      ],
    );

    final checkbox = Checkbox(
      value: isSelected,
      visualDensity: VisualDensity.compact,
      onChanged: _sending ? null : (value) => _toggleOrderSelection(order, value),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  checkbox,
                  Expanded(child: details),
                ],
              ),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            checkbox,
            Expanded(child: details),
            actions,
          ],
        );
      },
    );
  }
}

class _ArchivedSendPayload {
  const _ArchivedSendPayload({required this.takerIds, required this.accounterId});

  final List<int> takerIds;
  final int accounterId;
}

class _ArchivedSendSheet extends StatefulWidget {
  const _ArchivedSendSheet();

  @override
  State<_ArchivedSendSheet> createState() => _ArchivedSendSheetState();
}

class _ArchivedSendSheetState extends State<_ArchivedSendSheet> {
  late final Future<List<AppUser>> _takersFuture;
  late final Future<List<AppUser>> _accountersFuture;
  final Set<int> _takerIds = {};
  int? _accounterId;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthNotifier>();
    _takersFuture = auth.fetchAssignableTakers();
    _accountersFuture = auth.fetchAccounters();
  }

  bool get _canSend => _takerIds.isNotEmpty && _accounterId != null;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + inset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send selected orders', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            FutureBuilder<List<AppUser>>(
              future: _takersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final takers = snapshot.data ?? [];
                if (takers.isEmpty) {
                  return const Text('No takers available.');
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: takers
                      .map(
                        (t) => FilterChip(
                          label: Text(t.username),
                          selected: _takerIds.contains(t.id),
                          onSelected: (selected) {
                            setState(() {
                              selected ? _takerIds.add(t.id) : _takerIds.remove(t.id);
                            });
                          },
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<AppUser>>(
              future: _accountersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final accounters = snapshot.data ?? [];
                if (accounters.isEmpty) {
                  return const Text('No accounters available.');
                }
                return DropdownButton<int>(
                  isExpanded: true,
                  value: _accounterId,
                  hint: const Text('Select accounter'),
                  items: accounters
                      .map((a) => DropdownMenuItem<int>(value: a.id, child: Text(a.username)))
                      .toList(),
                  onChanged: (value) => setState(() => _accounterId = value),
                );
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _canSend
                    ? () => Navigator.of(context).pop(
                          _ArchivedSendPayload(
                            takerIds: _takerIds.toList(),
                            accounterId: _accounterId!,
                          ),
                        )
                    : null,
                child: const Text('Send'),
              ),
            ),
          ],
        ),
      ),
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
