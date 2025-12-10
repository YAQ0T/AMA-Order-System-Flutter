import '../models/order.dart';
import 'order_printer_io.dart' if (dart.library.html) 'order_printer_web.dart' as impl;

class OrderPrinter {
  static Future<void> printOrder(OrderModel order) => impl.printOrder(order);
}
