import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/order.dart';
import 'order_printer_shared.dart';

Future<void> printOrder(OrderModel order) async {
  final fonts = await _loadFonts();
  final doc = buildOrderDocument(order, fonts.base, fonts.arabicFallback, fonts.latinFallback);
  await Printing.layoutPdf(onLayout: (format) async => doc.save());
}

class _PdfFonts {
  _PdfFonts(this.base, this.arabicFallback, this.latinFallback);
  final pw.Font base;
  final pw.Font arabicFallback;
  final pw.Font latinFallback;
}

_PdfFonts? _cachedFonts;

Future<_PdfFonts> _loadFonts() async {
  if (_cachedFonts != null) return _cachedFonts!;
  final base = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));
  final arabic = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf'));
  final latin = pw.Font.helvetica();
  _cachedFonts = _PdfFonts(base, arabic, latin);
  return _cachedFonts!;
}
