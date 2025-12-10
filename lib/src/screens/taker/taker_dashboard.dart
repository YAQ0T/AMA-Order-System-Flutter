import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/order_item.dart';
import '../../state/order_notifier.dart';
import '../../widgets/order_filters.dart';
import '../../widgets/order_table.dart';

class TakerDashboard extends StatefulWidget {
  const TakerDashboard({super.key});

  @override
  State<TakerDashboard> createState() => _TakerDashboardState();
}

class _TakerDashboardState extends State<TakerDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderNotifier>().loadOrders(status: 'active');
    });
  }

  Future<void> _editItem(OrderModel order, OrderItemModel item) async {
    final nameCtrl = TextEditingController(text: item.name);
    final qtyCtrl = TextEditingController(text: '${item.quantity}');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit item', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      final newName = nameCtrl.text.trim();
                      final newQty = int.tryParse(qtyCtrl.text.trim());
                      if (newName.isEmpty || newQty == null || newQty <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Enter a name and a positive quantity')));
                        return;
                      }

                      final notifier = this.context.read<OrderNotifier>();
                      await notifier.updateOrderDetails(
                        order.id,
                        {
                          'items': order.items
                              .map((i) => {
                                    'name': i.id == item.id ? newName : i.name,
                                    'quantity': i.id == item.id ? newQty : i.quantity,
                                    'price': i.price,
                                    'status': i.status
                                  })
                              .toList()
                        },
                        notifyMaker: false,
                        notifyAccounter: false,
                        skipEmail: true,
                      );

                      if (!mounted) return;
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                    child: const Text('Save'),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
    nameCtrl.dispose();
    qtyCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderNotifier>();

    return RefreshIndicator(
      onRefresh: () => orders.loadOrders(status: orders.statusFilter),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          OrderFilters(
            status: orders.statusFilter,
            allowedStatuses: const ['active', 'pending', 'in-progress'],
            onStatusChanged: (s) => orders.loadOrders(status: s),
            onSearchChanged: (s) => orders.loadOrders(search: s),
          ),
          const SizedBox(height: 12),
          OrderTable(
            orders: orders.orders,
            onUpdateStatus: (id, status) => _updateStatus(orders, id, status),
            onItemStatus: (order, itemId, status) =>
                orders.updateItemStatus(order, itemId, status,
                    notifyMaker: false, notifyAccounter: false, skipEmail: true),
            onItemEdit: _editItem,
            statusGuard: _takerStatusGuard,
            inlineStatusButton: true,
            showPrices: false,
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

  Future<String?> _takerStatusGuard(OrderModel order, String next) async {
    // Taker can only move along pending -> in-progress -> completed
    const allowed = ['pending', 'in-progress', 'completed'];
    final currentIndex = allowed.indexOf(order.status);
    final nextIndex = allowed.indexOf(next);
    if (currentIndex == -1 || nextIndex == -1 || nextIndex - currentIndex != 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can only advance to the next step')));
      return null;
    }

    if (next == 'completed') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Complete order?'),
          content: const Text('Once completed, this order will leave your panel. Continue?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Complete')),
          ],
        ),
      );
      if (confirmed != true) return null;
    }
    return next;
  }

  Future<void> _updateStatus(OrderNotifier orders, int id, String status) async {
    final isCompleted = status == 'completed';
    await orders.updateStatus(
      id,
      status,
      notifyMaker: isCompleted,
      notifyAccounter: isCompleted,
      skipEmail: !isCompleted,
    );
    if (status == 'completed') {
      // Completed orders should disappear from taker view
      await orders.loadOrders(status: orders.statusFilter);
    }
  }
}
