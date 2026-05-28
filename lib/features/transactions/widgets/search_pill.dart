import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SearchPill extends StatefulWidget {
  const SearchPill({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.filteredCount,
    this.merchantFilter,
    this.merchantFilterColor,
    this.onClearMerchant,
    this.categoryFilter,
    this.categoryFilterColor,
    this.onClearCategory,
  });

  final String query;
  final ValueChanged<String> onQueryChanged;
  final int filteredCount;
  final String? merchantFilter;
  final Color? merchantFilterColor;
  final VoidCallback? onClearMerchant;
  final String? categoryFilter;
  final Color? categoryFilterColor;
  final VoidCallback? onClearCategory;

  @override
  State<SearchPill> createState() => _SearchPillState();
}

class _SearchPillState extends State<SearchPill> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(SearchPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query == _controller.text) return;
    _controller.value = TextEditingValue(
      text: widget.query,
      selection: TextSelection.collapsed(offset: widget.query.length),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasMerchant = widget.merchantFilter != null;
    final hasCategory = widget.categoryFilter != null;
    final hasFilters = hasMerchant || hasCategory;
    final capsules = <Widget>[
      if (hasMerchant)
        _FilterCapsule(
          capsuleKey: const ValueKey('search-pill-capsule-merchant'),
          value: widget.merchantFilter!,
          color: widget.merchantFilterColor ?? AppColors.primary,
          onClear: widget.onClearMerchant,
        ),
      if (hasCategory)
        _FilterCapsule(
          capsuleKey: const ValueKey('search-pill-capsule-category'),
          value: widget.categoryFilter!,
          color: widget.categoryFilterColor ?? AppColors.primary,
          onClear: widget.onClearCategory,
        ),
    ];

    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('search-pill-container'),
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        constraints: const BoxConstraints(minHeight: 46),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: _focusNode.hasFocus ? AppColors.primary : AppColors.gray200,
            width: _focusNode.hasFocus ? 1.5 : 1,
          ),
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
            if (capsules.isNotEmpty) ...[
              const SizedBox(width: 8),
              Flexible(
                flex: 3,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var index = 0; index < capsules.length; index++) ...[
                        if (index > 0) const SizedBox(width: 6),
                        capsules[index],
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextField(
                focusNode: _focusNode,
                controller: _controller,
                onChanged: widget.onQueryChanged,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: hasFilters
                      ? '${widget.filteredCount} tranzakció találva'
                      : 'Keresés tranzakciók között...',
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterCapsule extends StatelessWidget {
  const _FilterCapsule({
    required this.capsuleKey,
    required this.value,
    required this.color,
    required this.onClear,
  });

  final Key capsuleKey;
  final String value;
  final Color color;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: capsuleKey,
      height: 30,
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 64),
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
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
