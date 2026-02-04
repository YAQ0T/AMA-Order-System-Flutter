import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/order.dart';

pw.Document buildOrderDocument(
  OrderModel order,
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
  final dateFmt = DateFormat('yyyy-MM-dd HH:mm', 'en');

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

  pw.Widget labelWithValue(
    String label,
    String value, {
    double fontSize = 11,
    bool boldLabel = false,
    bool boldValue = false,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: boldLabel ? pw.FontWeight.bold : null,
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          value,
          textDirection: pw.TextDirection.ltr,
          style: latinStyle(
            fontSize: fontSize,
            fontWeight: boldValue ? pw.FontWeight.bold : null,
          ),
        ),
      ],
    );
  }

  String statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'completed':
        return 'مكتمل';
      case 'archived':
        return 'مؤرشف';
      case 'entered_erp':
        return 'تم الإدخال في ERP';
      default:
        return status;
    }
  }

  String formatPrice(double? value) =>
      value == null ? '-' : 'ILS ${value.toStringAsFixed(2)}';

  String formatQuantity(num value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toString();

  final itemsWithTotals = [
    for (var i = 0; i < order.items.length; i++)
      (
        index: i + 1,
        item: order.items[i],
        total: (order.items[i].price ?? 0) * order.items[i].quantity,
      )
  ];

  final grandTotal = itemsWithTotals.fold<double>(
    0,
    (sum, row) => sum + row.total,
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      textDirection: pw.TextDirection.rtl,
      build: (_) => [
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'نظام طلبات AMA',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  labelWithValue(
                    'رقم الطلب:',
                    '${order.id}',
                    fontSize: 12,
                    boldLabel: true,
                    boldValue: true,
                  ),
                  labelWithValue(
                    'التاريخ:',
                    dateFmt.format(order.createdAt),
                    fontSize: 11,
                  ),
                  if (order.city != null)
                    pw.Text('المدينة: ${order.city}',
                        textDirection: pw.TextDirection.rtl, style: const pw.TextStyle(fontSize: 11)),
                  pw.Text(
                    'الحالة: ${statusLabel(order.status)}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'العميل: ${order.titleOrFallback}',
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              if (order.description?.isNotEmpty == true)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 6),
                  child: pw.Text('الملاحظات: ${order.description}',
                      textDirection: pw.TextDirection.rtl,
                      style: const pw.TextStyle(fontSize: 11)),
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'المنتجات',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                for (final header in ['#', 'اسم المنتج', 'الكمية', 'السعر', 'الإجمالي'])
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      header,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                    ),
                  ),
              ],
            ),
            for (final row in itemsWithTotals)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      '${row.index}',
                      textDirection: pw.TextDirection.ltr,
                      textAlign: pw.TextAlign.center,
                      style: latinStyle(fontSize: 11),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      row.item.name,
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(fontSize: 11),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      formatQuantity(row.item.quantity),
                      textDirection: pw.TextDirection.ltr,
                      textAlign: pw.TextAlign.center,
                      style: latinStyle(fontSize: 11),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      formatPrice(row.item.price),
                      textDirection: pw.TextDirection.ltr,
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        font: latinFont,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      formatPrice(row.total == 0 ? null : row.total),
                      textDirection: pw.TextDirection.ltr,
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        font: latinFont,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        if (grandTotal > 0) ...[
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6, bottom: 10),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'الإجمالي الكلي:',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Text(
                    formatPrice(grandTotal),
                    textDirection: pw.TextDirection.ltr,
                    style: pw.TextStyle(
                      font: latinFont,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (order.assignedTakers.isNotEmpty)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'المسؤولون المخصصون:',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        order.assignedTakers.map((e) => e.username).join(', '),
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              if (order.accounter != null)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'المحاسب:',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        order.accounter!.username,
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Center(
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                'طُبع في:',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.SizedBox(width: 4),
              pw.Text(
                dateFmt.format(DateTime.now()),
                textDirection: pw.TextDirection.ltr,
                style: latinStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
        )
      ],
    ),
  );

  return doc;
}
