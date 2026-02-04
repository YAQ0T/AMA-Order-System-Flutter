import '../models/order.dart';

class OrderReport {
  const OrderReport({
    required this.from,
    required this.to,
    required this.orders,
    required this.orderCount,
    required this.totalSoldQuantity,
    required this.productsSold,
    required this.unavailableProducts,
    required this.takerAssignments,
    required this.customerOrders,
  });

  final DateTime from;
  final DateTime to;
  final List<OrderModel> orders;
  final int orderCount;
  final double totalSoldQuantity;
  final Map<String, double> productsSold;
  final Map<String, double> unavailableProducts;
  final Map<String, int> takerAssignments;
  final Map<String, int> customerOrders;
}

class OrderReportBuilder {
  static OrderReport build({
    required List<OrderModel> orders,
    required DateTime from,
    required DateTime to,
  }) {
    final start = _startOfDay(from);
    final end = _endOfDay(to);
    final filtered = orders
        .where((order) {
          final local = order.createdAt.toLocal();
          return !local.isBefore(start) && !local.isAfter(end);
        })
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final soldProducts = <String, double>{};
    final unavailable = <String, double>{};
    final takers = <String, int>{};
    final customers = <String, int>{};
    double totalSoldQuantity = 0;

    for (final order in filtered) {
      final customerName = order.titleOrFallback.trim();
      if (customerName.isNotEmpty) {
        customers[customerName] = (customers[customerName] ?? 0) + 1;
      }

      final takerNames = order.assignedTakers
          .map((t) => t.username.trim())
          .where((name) => name.isNotEmpty)
          .toSet();
      for (final name in takerNames) {
        takers[name] = (takers[name] ?? 0) + 1;
      }

      for (final item in order.items) {
        final name = item.name.trim();
        if (name.isEmpty) continue;
        final qty = item.quantity;
        final status = item.status?.toLowerCase().trim();
        final isUnavailable = status == 'unavailable' || status == 'x' || status == 'red';
        if (isUnavailable) {
          unavailable[name] = (unavailable[name] ?? 0) + qty;
        } else {
          totalSoldQuantity += qty;
          soldProducts[name] = (soldProducts[name] ?? 0) + qty;
        }
      }
    }

    return OrderReport(
      from: start,
      to: end,
      orders: filtered,
      orderCount: filtered.length,
      totalSoldQuantity: totalSoldQuantity,
      productsSold: soldProducts,
      unavailableProducts: unavailable,
      takerAssignments: takers,
      customerOrders: customers,
    );
  }

  static DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  static DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
}
