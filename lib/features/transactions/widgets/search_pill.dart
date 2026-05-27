import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SearchPill extends StatelessWidget {
  const SearchPill({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.filteredCount,
    this.merchantFilter,
    this.onClearMerchant,
  });

  final String query;
  final ValueChanged<String> onQueryChanged;
  final int filteredCount;
  final String? merchantFilter;
  final VoidCallback? onClearMerchant;

  @override
  Widget build(BuildContext context) {
    final hasMerchant = merchantFilter != null;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: AppColors.gray400),
          const SizedBox(width: 8),
          Expanded(
            child: hasMerchant
                ? Text(
                    '$filteredCount tranzakció találva',
                    style: const TextStyle(color: AppColors.gray400),
                  )
                : TextField(
                    onChanged: onQueryChanged,
                    controller: TextEditingController(text: query)
                      ..selection = TextSelection.collapsed(
                        offset: query.length,
                      ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Keresés tranzakciók között...',
                      isDense: true,
                    ),
                  ),
          ),
          if (hasMerchant)
            _MerchantCapsule(value: merchantFilter!, onClear: onClearMerchant),
        ],
      ),
    );
  }
}

class _MerchantCapsule extends StatelessWidget {
  const _MerchantCapsule({required this.value, required this.onClear});

  final String value;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close, size: 14, color: AppColors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          ),
        ],
      ),
    );
  }
}
