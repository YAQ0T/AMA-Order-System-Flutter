import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../models/user.dart';
import '../state/auth_notifier.dart';
import 'city_selector.dart';

/// Bottom sheet that lets makers edit their own orders.
class OrderEditSheet extends StatefulWidget {
  const OrderEditSheet({super.key, required this.order, required this.onSubmit});

  final OrderModel order;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  @override
  State<OrderEditSheet> createState() => _OrderEditSheetState();
}

class _OrderEditSheetState extends State<OrderEditSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  String? _selectedCity;
  late String _status;
  late List<OrderItemInput> _items;
  late Future<List<AppUser>> _takersFuture;
  late Future<List<AppUser>> _accountersFuture;
  late final Set<int> _selectedTakers;
  int? _accounterId;
  bool _saving = false;

  static const _allowedStatuses = [
    'pending',
    'in-progress',
    'completed',
    'archived',
    'entered_erp'
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.order.title ?? '');
    _descCtrl = TextEditingController(text: widget.order.description ?? '');
    _selectedCity = widget.order.city ?? '';
    _status = widget.order.status;
    _items = widget.order.items
        .map((i) => OrderItemInput(name: i.name, quantity: i.quantity, price: i.price))
        .toList();
    _selectedTakers = widget.order.assignedTakers.map((t) => t.id).toSet();
    _accounterId = widget.order.accounter?.id;
    final auth = context.read<AuthNotifier>();
    _takersFuture = auth.fetchAssignableTakers();
    _accountersFuture = auth.fetchAccounters();
    if (_items.isEmpty) {
      _items = [OrderItemInput()];
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    // Basic validation so the server doesn't reject obvious mistakes.
    if (_items.any((i) => i.name.trim().isEmpty || i.quantity <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item with a name and quantity')),
      );
      return;
    }
    final selectedCity = (_selectedCity ?? '').trim();
    if (selectedCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a city')),
      );
      return;
    }
    final isUnarchiving = widget.order.status == 'archived' && _status != 'archived';
    if (isUnarchiving && _selectedTakers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one taker before activating')),
      );
      return;
    }
    if (isUnarchiving && _accounterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an accounter before activating')),
      );
      return;
    }

    setState(() => _saving = true);
    final isArchiving = _status == 'archived';
    final payload = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'city': selectedCity,
      'status': _status,
      'items': _items.map((e) => e.toJson()).toList(),
      'assignedTakerIds': isArchiving ? const <int>[] : _selectedTakers.toList(),
      'accounterId': isArchiving ? null : _accounterId,
    };

    try {
      await widget.onSubmit(payload);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _normalizeDigits(String input) {
    const map = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
      '۰': '0',
      '۱': '1',
      '۲': '2',
      '۳': '3',
      '۴': '4',
      '۵': '5',
      '۶': '6',
      '۷': '7',
      '۸': '8',
      '۹': '9',
    };
    final buffer = StringBuffer();
    for (final ch in input.split('')) {
      buffer.write(map[ch] ?? ch);
    }
    final normalized = buffer.toString();
    return normalized
        .replaceAll(',', '.')
        .replaceAll('٫', '.')
        .replaceAll('٬', '.')
        .replaceAll('،', '.');
  }

  String _formatQuantity(num value) => value % 1 == 0 ? value.toInt().toString() : value.toString();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit order #${widget.order.id}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Customer name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              CitySelector(
                value: _selectedCity,
                onChanged: (value) => setState(() => _selectedCity = value),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _allowedStatuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _status = value;
                    if (value == 'archived') {
                      _selectedTakers.clear();
                      _accounterId = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<AppUser>>(
                future: _takersFuture,
                builder: (context, snapshot) {
                  final takers = snapshot.data ?? [];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assign takers', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: takers
                            .map(
                              (t) => FilterChip(
                                label: Text(t.username),
                                selected: _selectedTakers.contains(t.id),
                                onSelected: (selected) {
                                  setState(() {
                                    selected ? _selectedTakers.add(t.id) : _selectedTakers.remove(t.id);
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<AppUser>>(
                future: _accountersFuture,
                builder: (context, snapshot) {
                  final accs = snapshot.data ?? [];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    );
                  }
                  return DropdownButtonFormField<int?>(
                    value: _accounterId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Accounter'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('None')),
                      ...accs.map((a) => DropdownMenuItem<int?>(value: a.id, child: Text(a.username))),
                    ],
                    onChanged: (v) => setState(() => _accounterId = v),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._items.asMap().entries.map((entry) => _itemRow(entry.key, entry.value)),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _items.add(OrderItemInput())),
                  icon: const Icon(Icons.add),
                  label: const Text('Add item'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save changes'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemRow(int index, OrderItemInput item) {
    return Card(
      key: ValueKey(item),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                initialValue: item.name,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (v) => item.name = v,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextFormField(
                initialValue: _formatQuantity(item.quantity),
                decoration: const InputDecoration(labelText: 'Qty'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^(\d+\.?\d*|\.\d+)?$')),
                ],
                onChanged: (v) {
                  final normalized = _normalizeDigits(v);
                  final parsed = double.tryParse(normalized);
                  item.quantity = parsed ?? item.quantity;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: item.price != null ? '${item.price}' : '',
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^(\d+\.?\d*|\.\d+)?$')),
                ],
                onChanged: (v) => item.price = double.tryParse(_normalizeDigits(v)),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove item',
              onPressed: _items.length == 1
                  ? null
                  : () => setState(() {
                        _items.removeAt(index);
                      }),
            )
          ],
        ),
      ),
    );
  }
}
