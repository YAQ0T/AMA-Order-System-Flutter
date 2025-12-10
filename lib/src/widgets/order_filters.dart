import 'dart:async';

import 'package:flutter/material.dart';

class OrderFilters extends StatefulWidget {
  const OrderFilters({
    super.key,
    required this.status,
    required this.onStatusChanged,
    required this.onSearchChanged,
    this.statusEnabled = true,
    this.allowedStatuses = const [
      'active',
      'pending',
      'in-progress',
      'completed',
      'archived',
      'entered_erp',
      'all'
    ],
  });

  final String status;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onSearchChanged;
  final bool statusEnabled;
  final List<String> allowedStatuses;

  @override
  State<OrderFilters> createState() => _OrderFiltersState();
}

class _OrderFiltersState extends State<OrderFilters> {
  late String _status;
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _status = widget.allowedStatuses.contains(widget.status)
        ? widget.status
        : (widget.allowedStatuses.isNotEmpty ? widget.allowedStatuses.first : widget.status);
  }

  @override
  void didUpdateWidget(covariant OrderFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status || oldWidget.allowedStatuses != widget.allowedStatuses) {
      _status = widget.allowedStatuses.contains(widget.status)
          ? widget.status
          : (widget.allowedStatuses.isNotEmpty ? widget.allowedStatuses.first : widget.status);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearchChanged(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DropdownButton<String>(
          value: _status,
          items: widget.allowedStatuses
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(_labelForStatus(s)),
                ),
              )
              .toList(),
          onChanged: widget.statusEnabled
              ? (value) {
                  if (value == null) return;
                  setState(() => _status = value);
                  widget.onStatusChanged(value);
                }
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search orders',
            ),
            onChanged: _handleSearch,
          ),
        ),
      ],
    );
  }
}

String _labelForStatus(String status) {
  switch (status) {
    case 'active':
      return 'Active';
    case 'pending':
      return 'Pending';
    case 'in-progress':
      return 'In Progress';
    case 'completed':
      return 'Completed';
    case 'archived':
      return 'Archived';
    case 'entered_erp':
      return 'Entered ERP';
    case 'all':
      return 'All';
    default:
      return status;
  }
}
