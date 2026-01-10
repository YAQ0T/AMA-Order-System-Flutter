import 'package:flutter/material.dart';

import '../models/order.dart';

class CitySelector extends StatelessWidget {
  const CitySelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText = 'City',
    this.errorText,
    this.cities,
    this.allowAll = false,
    this.allLabel = 'All cities',
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String labelText;
  final String? errorText;
  final List<String>? cities;
  final bool allowAll;
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final availableCities = cities ?? kOrderCities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: textTheme.bodyMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (allowAll)
              ChoiceChip(
                label: Text(allLabel),
                selected: value == null,
                onSelected: (_) => onChanged(null),
              ),
            ...availableCities.map((city) {
              final selected = value == city;
              return ChoiceChip(
                label: Text(city),
                selected: selected,
                onSelected: (_) => onChanged(city),
              );
            }),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              errorText!,
              style: textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
      ],
    );
  }
}
