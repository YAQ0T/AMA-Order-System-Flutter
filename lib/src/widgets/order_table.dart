import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/order_item.dart';

class OrderTable extends StatefulWidget {
  const OrderTable({
    super.key,
    required this.orders,
    this.onUpdateStatus,
    this.onDelete,
    this.onItemStatus,
    this.onEdit,
    this.onItemEdit,
    this.showLogs = false,
    this.statusGuard,
    this.inlineStatusButton = false,
    this.onPrint,
    this.showPrices = true,
    this.onSendToErp,
  });

  final List<OrderModel> orders;
  final Future<void> Function(int, String)? onUpdateStatus;
  final Future<void> Function(int)? onDelete;
  final Future<void> Function(OrderModel, int, String?)? onItemStatus;
  final Future<void> Function(OrderModel)? onEdit;
  final Future<void> Function(OrderModel, OrderItemModel)? onItemEdit;
  final bool showLogs;
  final Future<String?> Function(OrderModel, String)? statusGuard;
  final bool inlineStatusButton;
  final Future<void> Function(OrderModel)? onPrint;
  final bool showPrices;
  final Future<void> Function(OrderModel)? onSendToErp;

  @override
  State<OrderTable> createState() => _OrderTableState();
}

class _OrderTableState extends State<OrderTable> {
  static const _allowedStatuses = [
    'pending',
    'in-progress',
    'completed',
    'archived',
    'entered_erp'
  ];

  final Set<int> _expandedLogs = {};

  @override
  Widget build(BuildContext context) {
    _expandedLogs.removeWhere((id) => widget.orders.every((o) => o.id != id));

    if (widget.orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('No orders yet')),
      );
    }

    return Column(
      children: widget.orders.map((order) => _orderCard(context, order)).toList(),
    );
  }

  Widget _orderCard(BuildContext context, OrderModel order) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sent: ${_formatDate(order.createdAt)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text('#${order.id}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.titleOrFallback, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Chip(
                            label: Text(order.status, style: TextStyle(color: scheme.onSurface)),
                            backgroundColor: _statusColor(scheme, order.status),
                          ),
                          if (order.city != null)
                            Chip(
                              label: Text(order.city!, style: TextStyle(color: scheme.onSurface)),
                              backgroundColor: scheme.surfaceContainerHighest,
                            ),
                          if (order.maker != null)
                            Chip(
                              label: Text('Maker: ${order.maker!.username}',
                                  style: TextStyle(color: scheme.onSurface)),
                              backgroundColor: scheme.surfaceContainerHighest,
                            ),
                          if (order.assignedTakers.isNotEmpty)
                            Chip(
                                label: Text('Takers: ${order.assignedTakers.map((t) => t.username).join(', ')}',
                                    style: TextStyle(color: scheme.onSurface)),
                                backgroundColor: scheme.surfaceContainerHighest),
                          if (order.accounter != null)
                            Chip(
                              label:
                                  Text('Accounter: ${order.accounter!.username}', style: TextStyle(color: scheme.onSurface)),
                              backgroundColor: scheme.surfaceContainerHighest,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onSendToErp != null && order.status == 'completed')
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilledButton.icon(
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: const Text('Send to ERP'),
                          onPressed: () => widget.onSendToErp!(order),
                        ),
                      ),
                    if (widget.onPrint != null)
                      IconButton(
                        icon: const Icon(Icons.print),
                        tooltip: 'Print',
                        onPressed: () => widget.onPrint!(order),
                      ),
                    if (widget.onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit order',
                        onPressed: () => widget.onEdit!(order),
                      ),
                    if (widget.onUpdateStatus != null && widget.inlineStatusButton)
                      _statusStepperButton(context, order)
                    else if (widget.onUpdateStatus != null)
                      PopupMenuButton<String>(
                        onSelected: (s) async {
                          final next = widget.statusGuard != null ? await widget.statusGuard!(order, s) : s;
                          if (next != null) {
                            await widget.onUpdateStatus!(order.id, next);
                          }
                        },
                        itemBuilder: (_) => _allowedStatuses
                            .map((s) => PopupMenuItem<String>(
                                  value: s,
                                  child: Text(s),
                                ))
                            .toList(),
                        child: const Icon(Icons.more_vert),
                      ),
                    if (widget.onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => widget.onDelete!(order.id),
                      ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 8),
            _itemsTable(context, order),
            if (widget.showLogs && order.history.isNotEmpty) ...[
              const SizedBox(height: 12),
              _logsSection(context, order),
            ],
          ],
        ),
      ),
    );
  }

  Widget _itemsTable(BuildContext context, OrderModel order) {
    if (order.items.isEmpty) return const Text('No items');
    final scheme = Theme.of(context).colorScheme;
    final hasItemActions = widget.onItemStatus != null || widget.onItemEdit != null;

    final columnWidths = <int, TableColumnWidth>{
      0: const FixedColumnWidth(30),
      1: hasItemActions ? const FlexColumnWidth(1) : const FlexColumnWidth(2),
      2: FixedColumnWidth(hasItemActions ? 60 : 54),
      if (widget.showPrices) 3: FixedColumnWidth(hasItemActions ? 80 : 68),
      (widget.showPrices ? 4 : 3):
          hasItemActions ? const FixedColumnWidth(140) : const FlexColumnWidth(1.2),
    };

    return Table(
      columnWidths: columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: scheme.outlineVariant))),
          children: [
            Padding(
                padding: const EdgeInsets.all(6),
                child: Text('#', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600))),
            Padding(
                padding: const EdgeInsets.all(6),
                child:
                    Text('Product', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600))),
            Padding(
                padding: const EdgeInsets.all(6),
                child: Text('Qty',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600))),
            if (widget.showPrices)
              Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text('Price',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600))),
            Padding(
                padding: const EdgeInsets.all(6),
                child: Text(hasItemActions ? 'Status / Action' : 'Status',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600))),
          ],
        ),
        ...order.items.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final item = entry.value;
          final bg = _rowColor(scheme, item.status);
          return TableRow(
            decoration: BoxDecoration(color: bg),
            children: [
              Padding(padding: const EdgeInsets.all(6), child: Text('$idx')),
              Padding(
                padding: const EdgeInsets.all(6),
                child: GestureDetector(
                  onLongPress: widget.onItemEdit == null ? null : () => widget.onItemEdit!(order, item),
                  child: Text(
                    item.name,
                    style: TextStyle(
                      decoration: item.status == 'unavailable' ? TextDecoration.lineThrough : TextDecoration.none,
                      color: item.status == 'unavailable'
                          ? scheme.onSurface.withValues(alpha: 0.65)
                          : scheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: GestureDetector(
                  onLongPress: widget.onItemEdit == null ? null : () => widget.onItemEdit!(order, item),
                  child: Text(_formatQuantity(item.quantity), textAlign: TextAlign.right),
                ),
              ),
              if (widget.showPrices)
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(item.price != null ? '${item.price}' : '-', textAlign: TextAlign.right),
                ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: _itemStatusCell(context, order, item),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _itemStatusCell(BuildContext context, OrderModel order, OrderItemModel item) {
    if (widget.onItemStatus == null) {
      final scheme = Theme.of(context).colorScheme;
      final icon = item.status == 'collected'
          ? Icon(Icons.check, color: scheme.primary)
          : item.status == 'unavailable'
              ? Icon(Icons.close, color: scheme.error)
              : const SizedBox.shrink();
      return Center(child: icon);
    }
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.check_circle, color: scheme.primary),
          onPressed: () async {
            await widget.onItemStatus!(order, item.id, 'collected');
            // Immediately rebuild so maker/taker sees the highlight
            (context as Element).markNeedsBuild();
          },
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.cancel, color: scheme.error),
          onPressed: () async {
            await widget.onItemStatus!(order, item.id, 'unavailable');
            (context as Element).markNeedsBuild();
          },
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.radio_button_unchecked, color: scheme.outline),
          onPressed: () async {
            await widget.onItemStatus!(order, item.id, null);
            (context as Element).markNeedsBuild();
          },
        ),
      ],
    );
  }

  String _formatQuantity(num qty) => qty % 1 == 0 ? qty.toInt().toString() : qty.toString();

  Color? _rowColor(ColorScheme scheme, String? status) {
    switch (status) {
      case 'collected':
        return scheme.primaryContainer.withValues(alpha: 0.6);
      case 'unavailable':
        return scheme.errorContainer;
      default:
        return scheme.surfaceContainerHighest.withValues(alpha: 0.4);
    }
  }

  Color _statusColor(ColorScheme scheme, String status) {
    switch (status) {
      case 'completed':
        return scheme.primaryContainer;
      case 'in-progress':
        return scheme.tertiaryContainer;
      case 'archived':
        return scheme.surfaceContainerHighest;
      case 'entered_erp':
        return scheme.secondaryContainer;
      default:
        return scheme.surfaceContainerHighest.withValues(alpha: 0.6);
    }
  }

  Widget _statusStepperButton(BuildContext context, OrderModel order) {
    final label = _nextLabel(order.status);
    if (label == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: FilledButton.tonal(
        onPressed: () async {
          final next = _nextStatus(order.status);
          if (next == null) return;
          final guarded = widget.statusGuard != null ? await widget.statusGuard!(order, next) : next;
          if (guarded != null) {
            await widget.onUpdateStatus!(order.id, guarded);
          }
        },
        child: Text(label),
      ),
    );
  }

  String? _nextLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Mark in progress';
      case 'in-progress':
        return 'Mark completed';
      default:
        return null;
    }
  }

  String? _nextStatus(String status) {
    switch (status) {
      case 'pending':
        return 'in-progress';
      case 'in-progress':
        return 'completed';
      default:
        return null;
    }
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final date =
        '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  bool _isLogExpanded(int orderId) => _expandedLogs.contains(orderId);

  void _toggleLog(int orderId) {
    setState(() {
      if (_expandedLogs.contains(orderId)) {
        _expandedLogs.remove(orderId);
      } else {
        _expandedLogs.add(orderId);
      }
    });
  }

  Widget _logsSection(BuildContext context, OrderModel order) {
    final expanded = _isLogExpanded(order.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Order log', style: Theme.of(context).textTheme.titleSmall),
            TextButton.icon(
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              label: Text(expanded ? 'Hide log' : 'Show log'),
              onPressed: () => _toggleLog(order.id),
            ),
          ],
        ),
        if (expanded) ...[
          const SizedBox(height: 6),
          Column(
            children: order.history
                .map(
                  (log) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history, size: 18),
                    title: Text('${log.editorName ?? 'Unknown'} • ${_formatDate(log.createdAt)}'),
                    subtitle: Text(
                      '${log.previousDescription} → ${log.newDescription}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
          )
        ],
      ],
    );
  }
}
