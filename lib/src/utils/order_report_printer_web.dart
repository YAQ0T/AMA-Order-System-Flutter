// Web fallback: generate the PDF and open it in a new tab for download/print.
import 'dart:js_interop';
import 'package:web/web.dart' as web;

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'order_report.dart';
import 'order_report_printer_shared.dart';

Future<void> exportReport(OrderReport report) async {
  await initializeDateFormatting('en', null);
  final fonts = await _loadFonts();
  final doc =
      buildOrderReportDocument(report, fonts.base, fonts.arabicFallback, fonts.latinFallback);
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

Future<pw.Font?> _tryLoadFont(String assetPath) async {
  try {
    final byteData = await rootBundle.load(assetPath);
    return pw.Font.ttf(byteData);
  } catch (_) {
    return null;
  }
}

Future<_PdfFonts> _loadFonts() async {
  if (_cachedFonts != null) return _cachedFonts!;
  final base = await _tryLoadFont('assets/fonts/NotoSansArabic-Regular.ttf') ??
      await PdfGoogleFonts.notoSansArabicRegular();
  final arabic = await _tryLoadFont('assets/fonts/NotoNaskhArabic-Regular.ttf') ??
      await PdfGoogleFonts.notoNaskhArabicRegular();
  final latin = pw.Font.helvetica();
  _cachedFonts = _PdfFonts(base, arabic, latin);
  return _cachedFonts!;
}
