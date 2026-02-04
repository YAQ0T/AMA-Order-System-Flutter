import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'order_report.dart';
import 'order_report_printer_shared.dart';

Future<void> exportReport(OrderReport report) async {
  final fonts = await _loadFonts();
  final doc =
      buildOrderReportDocument(report, fonts.base, fonts.arabicFallback, fonts.latinFallback);
  final bytes = await doc.save();
  await Printing.sharePdf(bytes: bytes, filename: _filename(report));
}

String _filename(OrderReport report) {
  final fmt = DateFormat('yyyyMMdd');
  final from = fmt.format(report.from);
  final to = fmt.format(report.to);
  return 'orders_report_${from}_$to.pdf';
}

class _PdfFonts {
  _PdfFonts(this.base, this.arabicFallback, this.latinFallback);
  final pw.Font base;
  final pw.Font arabicFallback;
  final pw.Font latinFallback;
}

_PdfFonts? _cachedFonts;

Future<Set<String>> _loadAssetManifest() async {
  try {
    final manifest = await rootBundle.loadString('AssetManifest.json');
    final decoded = jsonDecode(manifest);
    if (decoded is Map<String, dynamic>) {
      return decoded.keys.toSet();
    }
  } catch (_) {}
  return {};
}

Future<pw.Font?> _tryLoadFont(Set<String> assets, String assetPath) async {
  if (assets.isNotEmpty && !assets.contains(assetPath)) {
    return null;
  }
  try {
    return pw.Font.ttf(await rootBundle.load(assetPath));
  } catch (_) {
    return null;
  }
}

Future<_PdfFonts> _loadFonts() async {
  if (_cachedFonts != null) return _cachedFonts!;
  final assets = await _loadAssetManifest();
  final base = await _tryLoadFont(assets, 'assets/fonts/NotoSansArabic-Regular.ttf') ?? pw.Font.helvetica();
  final arabic = await _tryLoadFont(assets, 'assets/fonts/NotoNaskhArabic-Regular.ttf') ?? base;
  final latin = pw.Font.helvetica();
  _cachedFonts = _PdfFonts(base, arabic, latin);
  return _cachedFonts!;
}
