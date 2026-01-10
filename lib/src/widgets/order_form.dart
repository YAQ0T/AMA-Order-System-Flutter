import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../models/user.dart';
import '../state/auth_notifier.dart';
import '../state/order_notifier.dart';
import 'city_selector.dart';

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
  final _titleFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  String? _city;
  List<OrderItemInput> _items = [OrderItemInput()];
  final Set<int> _selectedTakers = {};
  int? _accounterId;

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
    _titleFocus.dispose();
    _descriptionFocus.dispose();
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
        _city = null;
        _items = [OrderItemInput()];
        _selectedTakers.clear();
        _accounterId = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((__) {
        _itemsEditorKey.currentState?.focusFirstName();
      });
    });
  }

  Future<void> _submit(OrderNotifier orders, {required bool archive}) async {
    if (!_formKey.currentState!.validate()) return;

    if (!archive) {
      if (_selectedTakers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least one taker for active orders')),
        );
        return;
      }
      if (_accounterId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select an accounter for active orders')),
        );
        return;
      }
    }

    final selectedCity = _city?.trim() ?? '';
    if (selectedCity.isEmpty) return;
    final draft = OrderDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      city: selectedCity,
      items: _items,
      assignedTakerIds: archive ? const [] : _selectedTakers.toList(),
      accounterId: archive ? null : _accounterId,
      status: archive ? 'archived' : null,
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
              () => _submit(context.read<OrderNotifier>(), archive: true),
          const SingleActivator(LogicalKeyboardKey.enter, control: true):
              () => _submit(context.read<OrderNotifier>(), archive: false),
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
                    decoration: const InputDecoration(labelText: 'Customer name'),
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
                    onFieldSubmitted: (_) => _itemsEditorKey.currentState?.focusFirstName(),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  FormField<String>(
                    initialValue: _city,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Select a city';
                      }
                      return null;
                    },
                    builder: (field) {
                      return CitySelector(
                        value: field.value,
                        errorText: field.errorText,
                        onChanged: (value) {
                          field.didChange(value);
                          field.validate();
                          setState(() => _city = value);
                          _itemsEditorKey.currentState?.focusFirstName();
                        },
                      );
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
                        decoration: const InputDecoration(labelText: 'Accounter'),
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final buttonWidth = constraints.maxWidth * 0.4;
                      final gapWidth = constraints.maxWidth * 0.1;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: buttonWidth,
                            child: OutlinedButton(
                              onPressed: orders.loading ? null : () => _submit(orders, archive: true),
                              child: const Text('Create archived (F3)'),
                            ),
                          ),
                          SizedBox(width: gapWidth),
                          SizedBox(
                            width: buttonWidth,
                            child: FilledButton(
                              onPressed: orders.loading ? null : () => _submit(orders, archive: false),
                              child: orders.loading
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Create order'),
                            ),
                          ),
                        ],
                      );
                    },
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

class _ItemFocusBundle {
  _ItemFocusBundle()
      : name = FocusNode(),
        nameController = TextEditingController(),
        qty = FocusNode(),
        price = FocusNode(),
        nameLink = LayerLink(),
        nameFieldKey = GlobalKey();

  final FocusNode name;
  final TextEditingController nameController;
  final FocusNode qty;
  final FocusNode price;
  final LayerLink nameLink;
  final GlobalKey nameFieldKey;

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
  final Map<int, OverlayEntry> _suggestionOverlays = {};

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
    for (final entry in _suggestionOverlays.values) {
      entry.remove();
    }
    _suggestionOverlays.clear();
    for (final f in _focuses) {
      f.dispose();
    }
    super.dispose();
  }

  void _syncFocuses() {
    while (_focuses.length < widget.items.length) {
      final bundle = _ItemFocusBundle();
      bundle.name.addListener(() => _handleNameFocusChange(bundle.name));
      _focuses.add(bundle);
    }
    while (_focuses.length > widget.items.length) {
      _focuses.removeLast().dispose();
    }
    _suggestions.removeWhere((key, _) => key >= widget.items.length);
    _loading.removeWhere((key, _) => key >= widget.items.length);
    _lastQueried.removeWhere((key, _) => key >= widget.items.length);
    _selectedSuggestion.removeWhere((key, _) => key >= widget.items.length);
    for (final key in _suggestionOverlays.keys.where((key) => key >= widget.items.length).toList()) {
      _removeSuggestionOverlay(key);
    }

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

  void _handleNameFocusChange(FocusNode node) {
    if (node.hasFocus) return;
    final index = _focuses.indexWhere((f) => f.name == node);
    if (index == -1) return;
    _clearSuggestions(index);
  }

  void _removeSuggestionOverlay(int index) {
    final entry = _suggestionOverlays.remove(index);
    entry?.remove();
  }

  void _updateSuggestionOverlay(int index) {
    if (!mounted) return;
    if (index < 0 || index >= _focuses.length) return;
    if (!_focuses[index].name.hasFocus) {
      _removeSuggestionOverlay(index);
      return;
    }
    final hasSuggestions = (_suggestions[index] ?? const []).isNotEmpty;
    final isLoading = _loading[index] ?? false;
    if (!hasSuggestions && !isLoading) {
      _removeSuggestionOverlay(index);
      return;
    }
    final existing = _suggestionOverlays[index];
    if (existing != null) {
      existing.markNeedsBuild();
      return;
    }
    final entry = OverlayEntry(
      builder: (context) {
        if (index >= _focuses.length) return const SizedBox.shrink();
        final suggestions = _suggestions[index] ?? const [];
        final isLoading = _loading[index] ?? false;
        if (suggestions.isEmpty && !isLoading) return const SizedBox.shrink();
        final focus = _focuses[index];
        final fieldContext = focus.nameFieldKey.currentContext;
        final box = fieldContext?.findRenderObject() as RenderBox?;
        final size = box?.size ?? Size.zero;
        if (size == Size.zero) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        return Positioned.fill(
          child: CompositedTransformFollower(
            link: focus.nameLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 4),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(6),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: size.width,
                  maxWidth: size.width,
                  maxHeight: 220,
                ),
                child: isLoading && suggestions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: suggestions.take(6).toList().asMap().entries.map((entry) {
                          final i = entry.key;
                          final s = entry.value;
                          final selected = _selectedSuggestion[index] == i;
                          return InkWell(
                            onTapDown: (_) => focus.name.requestFocus(),
                            onTap: () {
                              widget.items[index].name = s;
                              widget.onChanged(List.from(widget.items));
                              focus.qty.requestFocus();
                              setState(() {
                                _suggestions[index] = [];
                                _selectedSuggestion[index] = null;
                                _loading[index] = false;
                              });
                              _updateSuggestionOverlay(index);
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
            ),
          ),
        );
      },
    );
    _suggestionOverlays[index] = entry;
    final overlay = Overlay.of(context);
    if (overlay == null) {
      _suggestionOverlays.remove(index);
      return;
    }
    overlay.insert(entry);
  }

  Future<void> _fetchSuggestions(int index, String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      _suggestions[index] = [];
      _loading[index] = false;
      _selectedSuggestion[index] = null;
      setState(() {});
      _updateSuggestionOverlay(index);
      return;
    }
    if (_lastQueried[index] == trimmed && (_suggestions[index] ?? []).isNotEmpty) return;
    _lastQueried[index] = trimmed;
    _loading[index] = true;
    _selectedSuggestion[index] = null;
    setState(() {});
    _updateSuggestionOverlay(index);
    final results = await context.read<OrderNotifier>().suggestProducts(trimmed);
    if (!mounted) return;
    _suggestions[index] = results;
    _loading[index] = false;
    setState(() {});
    _updateSuggestionOverlay(index);
  }

  void _clearSuggestions(int index) {
    if ((_suggestions[index] ?? []).isEmpty &&
        (_selectedSuggestion[index] == null) &&
        !(_loading[index] ?? false)) {
      return;
    }
    setState(() {
      _suggestions[index] = [];
      _selectedSuggestion[index] = null;
      _loading[index] = false;
    });
    _updateSuggestionOverlay(index);
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
              _updateSuggestionOverlay(index);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              final next = current <= 0 ? list.length - 1 : current - 1;
              setState(() => _selectedSuggestion[index] = next);
              _updateSuggestionOverlay(index);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.enter && current >= 0 && current < list.length) {
              final selected = list[current];
              item.name = selected;
              widget.onChanged(List.from(widget.items));
              _clearSuggestions(index);
              focus.qty.requestFocus();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          };
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
                          CompositedTransformTarget(
                            link: focus.nameLink,
                            child: TextFormField(
                              key: focus.nameFieldKey,
                              controller: nameController,
                              focusNode: focus.name,
                              decoration: InputDecoration(labelText: 'Name #${index + 1}'),
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) {
                                _clearSuggestions(index);
                                focus.qty.requestFocus();
                              },
                              onChanged: (value) {
                                item.name = value;
                                widget.onChanged(List.from(widget.items));
                                _selectedSuggestion[index] = null;
                                _fetchSuggestions(index, value);
                              },
                              validator: (value) =>
                                  value == null || value.trim().isEmpty ? 'Name is required' : null,
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
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^(\d+\.?\d*|\.\d+)?$')),
                        ],
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
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^(\d+\.?\d*|\.\d+)?$')),
                        ],
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
