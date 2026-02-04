import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/order_notifier.dart';
import '../utils/order_report.dart';
import '../utils/order_report_printer.dart';

class OrderReportView extends StatefulWidget {
  const OrderReportView({super.key, required this.title});

  final String title;

  @override
  State<OrderReportView> createState() => _OrderReportViewState();
}

class _OrderReportViewState extends State<OrderReportView> {
  late DateTime _fromDate;
  late DateTime _toDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _toDate = today;
    _fromDate = today.subtract(const Duration(days: 6));
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _fromDate = picked;
      if (_fromDate.isAfter(_toDate)) {
        _toDate = _fromDate;
      }
    });
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _toDate = picked;
      if (_toDate.isBefore(_fromDate)) {
        _fromDate = _toDate;
      }
    });
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  String _formatQty(num qty) {
    return qty % 1 == 0 ? qty.toInt().toString() : qty.toString();
  }

  List<MapEntry<String, double>> _sortedProducts(Map<String, double> source) {
    final list = source.entries.toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  List<MapEntry<String, int>> _sortedTakers(Map<String, int> source) {
    final list = source.entries.toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  List<MapEntry<String, int>> _sortedCustomers(Map<String, int> source) {
    final list = source.entries.toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<OrderNotifier>();
    final report = notifier.report;
    final loading = notifier.reportLoading;
    final error = notifier.reportError;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date range', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: loading ? null : _pickFromDate,
                      icon: const Icon(Icons.date_range),
                      label: Text('From: ${_formatDate(_fromDate)}'),
                    ),
                    OutlinedButton.icon(
                      onPressed: loading ? null : _pickToDate,
                      icon: const Icon(Icons.event),
                      label: Text('To: ${_formatDate(_toDate)}'),
                    ),
                    FilledButton(
                      onPressed: loading
                          ? null
                          : () => notifier.generateReport(from: _fromDate, to: _toDate),
                      child: loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Generate report'),
                    ),
                    OutlinedButton.icon(
                      onPressed: report == null || loading
                          ? null
                          : () => OrderReportPrinter.exportReport(report),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Export PDF'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Failed to generate report: $error',
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ),
          ),
        ],
        if (report == null && !loading && error == null) ...[
          const SizedBox(height: 16),
          const Text('Select a date range and generate a report.'),
        ],
        if (report != null) ...[
          const SizedBox(height: 12),
          _summaryCard(context, report),
          const SizedBox(height: 12),
          _customersSection(context, report),
          const SizedBox(height: 12),
          _productsSection(
            context,
            title: 'Products sold',
            emptyLabel: 'No sold products in this range.',
            entries: _sortedProducts(report.productsSold),
          ),
          const SizedBox(height: 12),
          _productsSection(
            context,
            title: 'Products marked X / red',
            emptyLabel: 'No products marked X / red in this range.',
            entries: _sortedProducts(report.unavailableProducts),
          ),
          const SizedBox(height: 12),
          _takersSection(context, report),
        ],
      ],
    );
  }

  Widget _summaryCard(BuildContext context, OrderReport report) {
    final totalSold = _formatQty(report.totalSoldQuantity);
    final soldKinds = report.productsSold.length;
    final unavailableKinds = report.unavailableProducts.length;
    final takerCount = report.takerAssignments.length;
    final customerCount = report.customerOrders.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary (${_formatDate(report.from)} → ${_formatDate(report.to)})',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _summaryChip(context, 'Orders', report.orderCount.toString()),
                _summaryChip(context, 'Sold qty', totalSold),
                _summaryChip(context, 'Sold products', soldKinds.toString()),
                _summaryChip(context, 'Marked X/red', unavailableKinds.toString()),
                _summaryChip(context, 'Takers', takerCount.toString()),
                _summaryChip(context, 'Customers', customerCount.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: scheme.surfaceContainerHighest,
    );
  }

  Widget _customersSection(BuildContext context, OrderReport report) {
    final entries = _sortedCustomers(report.customerOrders);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customers', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Text('No customers in this range.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
            else
              ...entries.map(
                (entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.key),
                  trailing: Text(entry.value.toString()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _productsSection(
    BuildContext context, {
    required String title,
    required String emptyLabel,
    required List<MapEntry<String, double>> entries,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Text(emptyLabel, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
            else
              ...entries.map(
                (entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.key),
                  trailing: Text(_formatQty(entry.value)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _takersSection(BuildContext context, OrderReport report) {
    final entries = _sortedTakers(report.takerAssignments);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assigned takers', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Text('No takers assigned in this range.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
            else
              ...entries.map(
                (entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.key),
                  trailing: Text(entry.value.toString()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
