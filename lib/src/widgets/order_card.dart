import 'package:flutter/material.dart';

import '../models/order.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.onStatusChange,
    this.availableStatuses = const [],
    this.onDelete,
    this.onTap,
  });

  final OrderModel order;
  final ValueChanged<String>? onStatusChange;
  final List<String> availableStatuses;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onTap,
                    child: Text(
                      order.titleOrFallback,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                Chip(
                  label: Text(order.status),
                  backgroundColor: _statusColor(context, order.status),
                  labelStyle: TextStyle(color: scheme.onSurface),
                ),
                if (availableStatuses.isNotEmpty && onStatusChange != null)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: onStatusChange,
                    itemBuilder: (_) => availableStatuses
                        .map((s) => PopupMenuItem<String>(
                              value: s,
                              child: Text(_labelForStatus(s)),
                            ))
                        .toList(),
                  ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (order.description != null && order.description!.isNotEmpty)
              Text(order.description!, style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (order.city != null) _tag(context, Icons.location_on, order.city!),
                _tag(context, Icons.schedule, 'Sent: ${_formatDate(order.createdAt)}'),
                if (order.maker != null) _tag(context, Icons.person, 'Maker: ${order.maker!.username}'),
                if (order.assignedTakers.isNotEmpty)
                  _tag(context, Icons.group, 'Takers: ${order.assignedTakers.map((e) => e.username).join(', ')}'),
                if (order.accounter != null)
                  _tag(context, Icons.account_balance_wallet, 'Accounter: ${order.accounter!.username}'),
              ],
            ),
            if (order.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: order.items
                    .map((item) => Chip(
                      label: Text('${item.name} x${item.quantity}'
                          '${item.price != null ? ' - ${item.price}' : ''}'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: _itemColor(scheme, item.status),
                      avatar: item.status == 'collected'
                          ? Icon(Icons.check, size: 16, color: scheme.primary)
                          : item.status == 'unavailable'
                              ? Icon(Icons.close, size: 16, color: scheme.error)
                              : null,
                    ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _labelForStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in-progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'archived':
        return 'Archived';
      case 'entered_erp':
        return 'Entered to ERP';
      default:
        return status;
    }
  }

  Color _statusColor(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
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

  Widget _tag(BuildContext context, IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16, color: scheme.primary),
      backgroundColor: scheme.surfaceContainerHighest,
      label: Text(text, style: TextStyle(color: scheme.onSurface)),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final date = '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  Color? _itemColor(ColorScheme scheme, String? status) {
    switch (status) {
      case 'collected':
        return scheme.primaryContainer.withValues(alpha: 0.6);
      case 'unavailable':
        return scheme.errorContainer;
      default:
        return scheme.surfaceContainerHighest;
    }
  }
}
