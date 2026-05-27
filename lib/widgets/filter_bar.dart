import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.value,
    required this.enabled,
    required this.errorText,
    required this.onTextChanged,
    required this.onEnabledChanged,
  });

  final String value;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<bool> onEnabledChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: value,
                  decoration: InputDecoration(
                    labelText: 'App regex',
                    errorText: errorText,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: onTextChanged,
                ),
              ),
              const SizedBox(width: 8),
              Switch(value: enabled, onChanged: onEnabledChanged),
            ],
          ),
        ),
      ),
    );
  }
}
