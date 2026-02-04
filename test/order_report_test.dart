import 'package:flutter_test/flutter_test.dart';

import 'package:ama_order_system_flutter/src/models/order.dart';
import 'package:ama_order_system_flutter/src/models/order_item.dart';
import 'package:ama_order_system_flutter/src/models/user.dart';
import 'package:ama_order_system_flutter/src/utils/order_report.dart';

void main() {
  test('builds report with sold, unavailable, and taker counts', () {
    final taker1 = AppUser(id: 1, username: 'taker1', role: 'taker', isApproved: true);
    final taker2 = AppUser(id: 2, username: 'taker2', role: 'taker', isApproved: true);

    final orders = [
      OrderModel(
        id: 101,
        status: 'completed',
        createdAt: DateTime(2026, 1, 10, 10, 0),
        assignedTakers: [taker1, taker2],
        items: const [
          OrderItemModel(id: 1, name: 'Apples', quantity: 2),
          OrderItemModel(id: 2, name: 'Bananas', quantity: 1, status: 'unavailable'),
        ],
      ),
      OrderModel(
        id: 102,
        status: 'completed',
        createdAt: DateTime(2026, 1, 12, 9, 30),
        assignedTakers: [taker1],
        items: const [
          OrderItemModel(id: 3, name: 'Apples', quantity: 3, status: 'collected'),
          OrderItemModel(id: 4, name: 'Carrots', quantity: 1, status: 'red'),
          OrderItemModel(id: 5, name: 'Dates', quantity: 2, status: 'x'),
        ],
      ),
      OrderModel(
        id: 103,
        status: 'completed',
        createdAt: DateTime(2026, 1, 20, 12, 0),
        assignedTakers: [taker2],
        items: const [
          OrderItemModel(id: 6, name: 'Eggplant', quantity: 4),
        ],
      ),
    ];

    final report = OrderReportBuilder.build(
      orders: orders,
      from: DateTime(2026, 1, 9),
      to: DateTime(2026, 1, 12),
    );

    expect(report.orderCount, 2);
    expect(report.totalSoldQuantity, 5);
    expect(report.productsSold['Apples'], 5);
    expect(report.productsSold.containsKey('Bananas'), isFalse);
    expect(report.unavailableProducts['Bananas'], 1);
    expect(report.unavailableProducts['Carrots'], 1);
    expect(report.unavailableProducts['Dates'], 2);
    expect(report.takerAssignments['taker1'], 2);
    expect(report.takerAssignments['taker2'], 1);
    expect(report.customerOrders['Order #101'], 1);
    expect(report.customerOrders['Order #102'], 1);
    expect(report.customerOrders.containsKey('Order #103'), isFalse);
  });
}
