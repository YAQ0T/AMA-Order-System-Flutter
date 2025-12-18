import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../models/user.dart';
import '../state/auth_notifier.dart';
import '../state/order_notifier.dart';

class OrderForm extends StatefulWidget {
  const OrderForm({super.key});

  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GlobalKey<_ItemsEditorState> _itemsEditorKey = GlobalKey<_ItemsEditorState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController(text: 'نابلس');
  final _titleFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _cityFocus = FocusNode();
  String _city = 'نابلس';
  List<OrderItemInput> _items = [OrderItemInput()];
  final Set<int> _selectedTakers = {};
  int? _accounterId;
  bool _archive = false;

  late Future<List<AppUser>> _takersFuture;
  late Future<List<AppUser>> _accountersFuture;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthNotifier>();
    _takersFuture = auth.fetchAssignableTakers();
    _accountersFuture = auth.fetchAccounters();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _cityFocus.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items = [..._items, OrderItemInput()];
    });
    final newIndex = _items.length - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _itemsEditorKey.currentState?.queueFocusOnName(newIndex);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items = List.from(_items)..removeAt(index);
    });
  }

  void _resetForm() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _formKey = GlobalKey<FormState>();
        _itemsEditorKey = GlobalKey<_ItemsEditorState>();
        _titleController.clear();
        _descriptionController.clear();
        _cityController.text = 'نابلس';
        _city = 'نابلس';
        _items = [OrderItemInput()];
        _selectedTakers.clear();
        _accounterId = null;
        _archive = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((__) {
        _itemsEditorKey.currentState?.focusFirstName();
      });
    });
  }

  Future<void> _submit(OrderNotifier orders) async {
    if (!_formKey.currentState!.validate()) return;

    final draft = OrderDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      city: _city,
      items: _items,
      assignedTakerIds: _selectedTakers.toList(),
      accounterId: _accounterId,
      status: _archive ? 'archived' : null,
    );
    try {
      await orders.createOrder(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order created')),
      );
      _resetForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderNotifier>();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(12),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.f3):
              () => setState(() => _archive = !_archive),
          const SingleActivator(LogicalKeyboardKey.enter, control: true):
              () => _formKey.currentState?.validate() == true
                  ? _submit(context.read<OrderNotifier>())
                  : null,
        },
        child: Focus(
          autofocus: true,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Order', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    focusNode: _titleFocus,
                    decoration: const InputDecoration(labelText: 'Title'),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_descriptionFocus),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    focusNode: _descriptionFocus,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _cityFocus.requestFocus(),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Archive immediately'),
                    subtitle: const Text('Create as archived to send later'),
                    value: _archive,
                    onChanged: (v) => setState(() => _archive = v),
                  ),
                  const SizedBox(height: 8),
                  _CityField(
                    focusNode: _cityFocus,
                    controller: _cityController,
                    initialValue: _city,
                    onSelected: (value) {
                      setState(() => _city = value);
                      _itemsEditorKey.currentState?.focusFirstName();
                    },
                    onSubmitted: (value) {
                      setState(() => _city = value);
                      _itemsEditorKey.currentState?.focusFirstName();
                    },
                  ),
                  const SizedBox(height: 12),
                  _ItemsEditor(
                    key: _itemsEditorKey,
                    items: _items,
                    onChanged: (items) => setState(() => _items = items),
                    onRemove: _removeItem,
                    onAdd: _addItem,
                  ),
                  const Divider(height: 28),
                  FutureBuilder<List<AppUser>>(
                    future: _takersFuture,
                    builder: (context, snapshot) {
                      final data = snapshot.data ?? [];
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LinearProgressIndicator();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Assign Takers'),
                          Wrap(
                            spacing: 8,
                            children: data
                                .map(
                                  (u) => FilterChip(
                                    label: Text(u.username),
                                    selected: _selectedTakers.contains(u.id),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedTakers.add(u.id);
                                        } else {
                                          _selectedTakers.remove(u.id);
                                        }
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
                      final data = snapshot.data ?? [];
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LinearProgressIndicator();
                      }
                      return DropdownButtonFormField<int?>(
                        decoration: const InputDecoration(labelText: 'Accounter (optional)'),
                        initialValue: _accounterId,
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('None')),
                          ...data.map(
                            (u) => DropdownMenuItem<int?>(
                              value: u.id,
                              child: Text(u.username),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() => _accounterId = value),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: orders.loading ? null : () => _submit(orders),
                      child: orders.loading
                          ? const SizedBox(
                              height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Create order'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemsEditor extends StatefulWidget {
  const _ItemsEditor({
    super.key,
    required this.items,
    required this.onChanged,
    required this.onRemove,
    required this.onAdd,
  });

  final List<OrderItemInput> items;
  final ValueChanged<List<OrderItemInput>> onChanged;
  final void Function(int) onRemove;
  final VoidCallback onAdd;

  @override
  State<_ItemsEditor> createState() => _ItemsEditorState();
}

class _CityField extends StatelessWidget {
  const _CityField({
    required this.focusNode,
    required this.controller,
    required this.initialValue,
    required this.onSelected,
    required this.onSubmitted,
  });

  final FocusNode focusNode;
  final TextEditingController controller;
  final String initialValue;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onSubmitted;

  static const _cities = [
    'نابلس',
    'الخليل',
    'جنين',
    'طولكرم',
    'بديا',
    'قلقيليا',
    'رامالله',
    'بيت لحم',
    'الداخل',
  ];

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        final input = textEditingValue.text.trim();
        if (input.isEmpty) {
          return _cities;
        }
        return _cities.where(
          (c) => c.toLowerCase().startsWith(input.toLowerCase()),
        );
      },
      onSelected: (value) {
        controller.text = value;
        onSelected(value);
      },
      fieldViewBuilder: (context, textEditingController, fieldFocus, onFieldSubmitted) {
        if (textEditingController.text != controller.text) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (textEditingController.text == controller.text) return;
            textEditingController.value = controller.value;
          });
        }
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: const InputDecoration(labelText: 'City'),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (value) {
            controller.text = value;
            onSubmitted(value.trim().isEmpty ? initialValue : value.trim());
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options.elementAt(index);
                return ListTile(
                  title: Text(option),
                  onTap: () => onSelected(option),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ItemFocusBundle {
  _ItemFocusBundle()
      : name = FocusNode(),
        nameController = TextEditingController(),
        qty = FocusNode(),
        price = FocusNode();

  final FocusNode name;
  final TextEditingController nameController;
  final FocusNode qty;
  final FocusNode price;

  void dispose() {
    name.dispose();
    nameController.dispose();
    qty.dispose();
    price.dispose();
  }
}

class _ItemsEditorState extends State<_ItemsEditor> {
  final List<_ItemFocusBundle> _focuses = [];
  int _previousLength = 0;
  int? _pendingFocusIndex;
  final Map<int, List<String>> _suggestions = {};
  final Map<int, bool> _loading = {};
  final Map<int, String> _lastQueried = {};
  final Map<int, int?> _selectedSuggestion = {};

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
  void initState() {
    super.initState();
    _syncFocuses();
    _previousLength = widget.items.length;
  }

  @override
  void didUpdateWidget(covariant _ItemsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFocuses();
    final grew = widget.items.length > _previousLength;
    _previousLength = widget.items.length;
    if (grew && _focuses.isNotEmpty) {
      queueFocusOnName(widget.items.length - 1);
    }
  }

  @override
  void dispose() {
    for (final f in _focuses) {
      f.dispose();
    }
    super.dispose();
  }

  void _syncFocuses() {
    while (_focuses.length < widget.items.length) {
      _focuses.add(_ItemFocusBundle());
    }
    while (_focuses.length > widget.items.length) {
      _focuses.removeLast().dispose();
    }
    _suggestions.removeWhere((key, _) => key >= widget.items.length);
    _loading.removeWhere((key, _) => key >= widget.items.length);
    _lastQueried.removeWhere((key, _) => key >= widget.items.length);
    _selectedSuggestion.removeWhere((key, _) => key >= widget.items.length);

    // Keep controllers in sync with current item names without resetting selection unexpectedly.
    for (var i = 0; i < widget.items.length; i++) {
      final controller = _focuses[i].nameController;
      final text = widget.items[i].name;
      if (controller.text != text) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (controller.text == text) return;
          controller.text = text;
          controller.selection = TextSelection.collapsed(offset: text.length);
        });
      }
    }
  }

  void focusFirstName() {
    if (_focuses.isNotEmpty) {
      _focuses.first.name.requestFocus();
    }
  }

  void focusLastName() {
    if (_focuses.isNotEmpty) {
      FocusScope.of(context).requestFocus(_focuses.last.name);
    }
  }

  void queueFocusOnName(int index) {
    _pendingFocusIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _pendingFocusIndex;
      if (target != null && target < _focuses.length) {
        FocusScope.of(context).requestFocus(_focuses[target].name);
      }
      _pendingFocusIndex = null;
    });
  }

  Future<void> _fetchSuggestions(int index, String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      _suggestions[index] = [];
      _loading[index] = false;
      _selectedSuggestion[index] = null;
      setState(() {});
      return;
    }
    if (_lastQueried[index] == trimmed && (_suggestions[index] ?? []).isNotEmpty) return;
    _lastQueried[index] = trimmed;
    _loading[index] = true;
    _selectedSuggestion[index] = null;
    setState(() {});
    final results = await context.read<OrderNotifier>().suggestProducts(trimmed);
    if (!mounted) return;
    _suggestions[index] = results;
    _loading[index] = false;
    setState(() {});
  }

  void _clearSuggestions(int index) {
    if ((_suggestions[index] ?? []).isEmpty && (_selectedSuggestion[index] == null)) return;
    setState(() {
      _suggestions[index] = [];
      _selectedSuggestion[index] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Items'),
            const Spacer(),
            TextButton.icon(onPressed: widget.onAdd, icon: const Icon(Icons.add), label: const Text('Add')),
          ],
        ),
        ...widget.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final focus = _focuses[index];
          final nameController = focus.nameController;
          focus.name.onKeyEvent = (node, event) {
            final list = _suggestions[index] ?? const [];
            if (list.isEmpty) return KeyEventResult.ignored;
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            final current = _selectedSuggestion[index] ?? -1;
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              final next = (current + 1) % list.length;
              setState(() => _selectedSuggestion[index] = next);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              final next = current <= 0 ? list.length - 1 : current - 1;
              setState(() => _selectedSuggestion[index] = next);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.enter && current >= 0 && current < list.length) {
              final selected = list[current];
              item.name = selected;
              widget.onChanged(List.from(widget.items));
              setState(() {
                _suggestions[index] = [];
                _selectedSuggestion[index] = null;
              });
              focus.qty.requestFocus();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          };
          final scheme = Theme.of(context).colorScheme;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.f7): () {
                  if (widget.items.length > 1) {
                    widget.onRemove(index);
                  }
                },
              },
              child: Focus(
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: nameController,
                            focusNode: focus.name,
                            decoration: InputDecoration(labelText: 'Name #${index + 1}'),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) {
                              _clearSuggestions(index);
                              focus.qty.requestFocus();
                            },
                            onTapOutside: (_) => _clearSuggestions(index),
                            onChanged: (value) {
                              item.name = value;
                              widget.onChanged(List.from(widget.items));
                              _selectedSuggestion[index] = null;
                              _fetchSuggestions(index, value);
                            },
                            validator: (value) =>
                                value == null || value.trim().isEmpty ? 'Name is required' : null,
                          ),
                          if ((_loading[index] ?? false))
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                          if ((_suggestions[index] ?? []).isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: scheme.surface,
                                border: Border.all(color: scheme.outlineVariant),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: (_suggestions[index] ?? []).take(6).toList().asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final s = entry.value;
                                  final selected = _selectedSuggestion[index] == i;
                                  return InkWell(
                                    onTap: () {
                                      item.name = s;
                                      widget.onChanged(List.from(widget.items));
                                      focus.qty.requestFocus();
                                      setState(() {
                                        _suggestions[index] = [];
                                        _selectedSuggestion[index] = null;
                                      });
                                    },
                                    child: Container(
                                      color: selected ? scheme.primaryContainer.withValues(alpha: 0.5) : Colors.transparent,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      alignment: Alignment.centerLeft,
                                      child: Text(s),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('qty-$index-${item.hashCode}'),
                        initialValue: _formatQuantity(item.quantity),
                        focusNode: focus.qty,
                        decoration: const InputDecoration(labelText: 'Qty'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => focus.price.requestFocus(),
                        onChanged: (value) {
                          final normalized = _normalizeDigits(value);
                          final parsed = double.tryParse(normalized);
                          item.quantity = parsed ?? 0;
                          widget.onChanged(List.from(widget.items));
                        },
                        validator: (value) =>
                            (double.tryParse(_normalizeDigits(value ?? '')) ?? 0) <= 0 ? 'Invalid' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('price-$index-${item.hashCode}'),
                        initialValue: item.price?.toString() ?? '',
                        focusNode: focus.price,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          widget.onAdd();
                          queueFocusOnName(widget.items.length);
                        },
                        onChanged: (value) {
                          final normalized = _normalizeDigits(value);
                          item.price = normalized.isEmpty ? null : double.tryParse(normalized);
                          widget.onChanged(List.from(widget.items));
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: widget.items.length == 1 ? null : () => widget.onRemove(index),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
