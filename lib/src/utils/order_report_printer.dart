import 'order_report.dart';
import 'order_report_printer_io.dart' if (dart.library.html) 'order_report_printer_web.dart' as impl;

class OrderReportPrinter {
  static Future<void> exportReport(OrderReport report) => impl.exportReport(report);
}
