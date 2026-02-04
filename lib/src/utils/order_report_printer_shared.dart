import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'order_report.dart';

pw.Document buildOrderReportDocument(
  OrderReport report,
  pw.Font baseFont, [
  pw.Font? arabicFallback,
  pw.Font? latinFallback,
]) {
  final latinFont = latinFallback ?? baseFont;
  final theme = pw.ThemeData.withFont(
    base: baseFont,
    bold: baseFont,
    fontFallback: [
      if (arabicFallback != null) arabicFallback,
      if (latinFallback != null) latinFallback,
    ],
  );
  final doc = pw.Document(theme: theme);
  final dateFmt = DateFormat('yyyy-MM-dd', 'en');
  final rtlPattern = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');

  String formatQty(num value) => value % 1 == 0 ? value.toInt().toString() : value.toString();
  bool isRtlText(String text) => rtlPattern.hasMatch(text);

  pw.TextStyle latinStyle({
    double? fontSize,
    pw.FontWeight? fontWeight,
    PdfColor? color,
  }) {
    return pw.TextStyle(
      font: latinFont,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  pw.Widget labelValue(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(label, textDirection: pw.TextDirection.ltr, style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(width: 4),
        pw.Text(
          value,
          textDirection: pw.TextDirection.ltr,
          style: latinStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
      child: pw.Text(
        title,
        textDirection: pw.TextDirection.ltr,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget buildTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            for (final header in headers)
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  header,
                  textDirection: pw.TextDirection.ltr,
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
              ),
          ],
        ),
        for (final row in rows)
          pw.TableRow(
            children: [
              for (final cell in row)
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    cell,
                    textDirection: isRtlText(cell) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                    textAlign: isRtlText(cell) ? pw.TextAlign.right : pw.TextAlign.left,
                    style: isRtlText(cell) ? pw.TextStyle(fontSize: 11) : latinStyle(fontSize: 11),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  final soldProducts = report.productsSold.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final unavailableProducts = report.unavailableProducts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final takers = report.takerAssignments.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final customers = report.customerOrders.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final summaryRows = [
    ['Orders', report.orderCount.toString()],
    ['Sold quantity', formatQty(report.totalSoldQuantity)],
    ['Sold products', report.productsSold.length.toString()],
    ['Marked X / red', report.unavailableProducts.length.toString()],
    ['Assigned takers', report.takerAssignments.length.toString()],
    ['Customers', report.customerOrders.length.toString()],
  ];

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      textDirection: pw.TextDirection.rtl,
      maxPages: 200,
      build: (_) => [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'AMA Order System',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Orders Report',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Wrap(
            spacing: 16,
            runSpacing: 6,
            alignment: pw.WrapAlignment.end,
            children: [
              labelValue('From:', dateFmt.format(report.from)),
              labelValue('To:', dateFmt.format(report.to)),
            ],
          ),
        ),
        sectionTitle('Summary'),
        buildTable(
          headers: const ['Metric', 'Value'],
          rows: summaryRows,
        ),
        sectionTitle('Products sold'),
        if (soldProducts.isEmpty)
          pw.Text('No sold products in this range.', style: const pw.TextStyle(fontSize: 11))
        else
          buildTable(
            headers: const ['Product', 'Quantity'],
            rows: [
              for (final entry in soldProducts) [entry.key, formatQty(entry.value)],
            ],
          ),
        sectionTitle('Products marked X / red'),
        if (unavailableProducts.isEmpty)
          pw.Text('No products marked X / red in this range.', style: const pw.TextStyle(fontSize: 11))
        else
          buildTable(
            headers: const ['Product', 'Quantity'],
            rows: [
              for (final entry in unavailableProducts) [entry.key, formatQty(entry.value)],
            ],
          ),
        sectionTitle('Assigned takers'),
        if (takers.isEmpty)
          pw.Text('No takers assigned in this range.', style: const pw.TextStyle(fontSize: 11))
        else
          buildTable(
            headers: const ['Taker', 'Orders'],
            rows: [
              for (final entry in takers) [entry.key, entry.value.toString()],
            ],
          ),
        sectionTitle('Customers'),
        if (customers.isEmpty)
          pw.Text('No customers in this range.', style: const pw.TextStyle(fontSize: 11))
        else
          buildTable(
            headers: const ['Customer', 'Orders'],
            rows: [
              for (final entry in customers) [entry.key, entry.value.toString()],
            ],
          ),
        pw.SizedBox(height: 16),
        pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            'Generated: ${dateFmt.format(DateTime.now())}',
            style: latinStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
      ],
    ),
  );

  return doc;
}
