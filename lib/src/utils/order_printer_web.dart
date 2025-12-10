// Web fallback: generate the PDF and open it in a new tab for printing.
import 'dart:js_interop';
import 'package:web/web.dart' as web;

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

import '../models/order.dart';
import 'order_printer_shared.dart';

Future<void> printOrder(OrderModel order) async {
  final fonts = await _loadFonts();
  final doc = buildOrderDocument(order, fonts.base, fonts.arabicFallback, fonts.latinFallback);
  final bytes = await doc.save();
  final blob = web.Blob(
    <web.BlobPart>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);
  web.window.open(url, '_blank');
  web.URL.revokeObjectURL(url);
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
