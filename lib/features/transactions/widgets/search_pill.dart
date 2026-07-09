import 'package:flutter/material.dart';

import '../../../core/debug/debug_console.dart';
import '../../../core/debug/debug_text_input.dart';
import '../../../core/theme/app_colors.dart';
import '../../settings/models/app_theme_settings.dart';

class SearchPill extends StatefulWidget {
  const SearchPill({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.filteredCount,
    this.surfaceColor = AppColors.white,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.merchantFilter,
    this.merchantFilterColor,
    this.onClearMerchant,
    this.merchantFilters = const <SearchPillFilter>[],
    this.categoryFilter,
    this.categoryFilterColor,
    this.onClearCategory,
    this.categoryFilters = const <SearchPillFilter>[],
    this.onVendorListPressed,
    this.accentColor = AppColors.primary,
    this.shadowEnabled = true,
  });

  final String query;
  final ValueChanged<String> onQueryChanged;
  final int filteredCount;
  final Color surfaceColor;
  final ExpenseSurfaceInteraction surfaceStyle;
  final String? merchantFilter;
  final Color? merchantFilterColor;
  final VoidCallback? onClearMerchant;
  final List<SearchPillFilter> merchantFilters;
  final String? categoryFilter;
  final Color? categoryFilterColor;
  final VoidCallback? onClearCategory;
  final List<SearchPillFilter> categoryFilters;
  final VoidCallback? onVendorListPressed;
  final Color accentColor;
  final bool shadowEnabled;

  @override
  State<SearchPill> createState() => _SearchPillState();
}

class SearchPillFilter {
  const SearchPillFilter({
    required this.id,
    required this.label,
    required this.color,
    required this.onClear,
  });

  final String id;
  final String label;
  final Color color;
  final VoidCallback onClear;
}

class _SearchPillState extends State<SearchPill> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final ValueNotifier<bool> _focused;
  DateTime? _focusStartedAt;
  var _focusRequestLoggedForCycle = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
    _focused = ValueNotifier(false);
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
    _focused.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    final hasFocus = _focusNode.hasFocus;
    if (hasFocus) {
      if (!_focusRequestLoggedForCycle) {
        _logFocusRequest();
      }
      _focusStartedAt = DateTime.now();
      DebugConsole.log(
        '[Perf] SearchPill focus active=true keyboard=${_keyboardInsetText()}',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_focusNode.hasFocus) return;
        DebugConsole.log(
          '[Perf] SearchPill focus frame elapsed=${_elapsedMs(_focusStartedAt)}ms '
          'keyboard=${_keyboardInsetText()}',
        );
      });
    } else {
      DebugConsole.log(
        '[Perf] SearchPill focus active=false elapsed=${_elapsedMs(_focusStartedAt)}ms '
        'keyboard=${_keyboardInsetText()}',
      );
      _focusStartedAt = null;
      _focusRequestLoggedForCycle = false;
    }
    if (_focused.value != hasFocus) {
      _focused.value = hasFocus;
    }
  }

  void _requestFocus() {
    if (_focusNode.hasFocus) return;
    _logFocusRequest();
    _focusNode.requestFocus();
  }

  void _logFocusRequest() {
    DebugConsole.log(
      '[Perf] SearchPill focus request active=${_focusNode.hasFocus} '
      'keyboard=${_keyboardInsetText()}',
    );
    _focusRequestLoggedForCycle = true;
  }

  String _keyboardInsetText() {
    return (MediaQuery.maybeOf(context)?.viewInsets.bottom ?? 0)
        .toStringAsFixed(1);
  }

  int _elapsedMs(DateTime? startedAt) {
    if (startedAt == null) return 0;
    return DateTime.now().difference(startedAt).inMilliseconds;
  }

  @override
  Widget build(BuildContext context) {
    final merchantFilters = widget.merchantFilters.isNotEmpty
        ? widget.merchantFilters
        : _legacyMerchantFilters();
    final categoryFilters = widget.categoryFilters.isNotEmpty
        ? widget.categoryFilters
        : _legacyCategoryFilters();
    final hasMerchant = merchantFilters.isNotEmpty;
    final hasCategory = categoryFilters.isNotEmpty;
    final hasFilters = hasMerchant || hasCategory;
    final transparentInnerField = widget.surfaceStyle.hasPressEffect;
    final innerFillColor = transparentInnerField
        ? Colors.transparent
        : widget.surfaceColor;
    final capsules = <Widget>[
      for (final filter in merchantFilters)
        _FilterCapsule(
          capsuleKey: ValueKey('search-pill-capsule-merchant-${filter.id}'),
          value: filter.label,
          color: filter.color,
          surfaceStyle: widget.surfaceStyle,
          onClear: filter.onClear,
        ),
      for (final filter in categoryFilters)
        _FilterCapsule(
          capsuleKey: ValueKey('search-pill-capsule-category-${filter.id}'),
          value: filter.label,
          color: filter.color,
          surfaceStyle: widget.surfaceStyle,
          onClear: filter.onClear,
        ),
    ];

    final content = Row(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            key: const ValueKey('search-pill-vendor-button'),
            padding: EdgeInsets.zero,
            iconSize: 18,
            color: AppColors.gray400,
            icon: const Icon(Icons.search),
            tooltip: 'Vendor lista',
            onPressed: widget.onVendorListPressed ?? _requestFocus,
          ),
        ),
        if (capsules.isNotEmpty) ...[
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('search-pill-capsule-scroll'),
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
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 132),
            child: Text(
              '${widget.filteredCount} tranzakció',
              key: const ValueKey('search-pill-filtered-count'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray500,
                height: 1.1,
              ),
            ),
          ),
        ],
        if (!hasFilters) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              key: const ValueKey('search-pill-text-wrapper'),
              decoration: BoxDecoration(color: innerFillColor),
              child: DebugTextField(
                debugLabel: 'SearchPill.query',
                focusNode: _focusNode,
                controller: _controller,
                onChanged: widget.onQueryChanged,
                onTap: _requestFocus,
                onTapOutside: (_) => _focusNode.unfocus(),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: true,
                  fillColor: innerFillColor,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Keresés tranzakciók között...',
                  isDense: true,
                ),
              ),
            ),
          ),
        ],
      ],
    );

    return TextFieldTapRegion(
      child: Material(
        color: Colors.transparent,
        child: ValueListenableBuilder<bool>(
          valueListenable: _focused,
          child: content,
          builder: (context, focused, child) {
            return ExpensePressable(
              enabled: widget.surfaceStyle.hasPressEffect,
              forcePressed: focused && widget.surfaceStyle.hasPressEffect,
              builder: (context, pressed) {
                return ExpenseSurfaceContainer(
                  surfaceKey: const ValueKey('search-pill-container'),
                  style: widget.surfaceStyle,
                  color: widget.surfaceColor,
                  borderRadius: BorderRadius.circular(25),
                  pressed: pressed,
                  margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  constraints: const BoxConstraints(minHeight: 46),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  neutralBorder: Border.all(
                    color: focused ? widget.accentColor : AppColors.gray200,
                    width: focused ? 1.5 : 1,
                  ),
                  neutralShadow: widget.shadowEnabled
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            offset: const Offset(0, 2),
                            blurRadius: 3,
                          ),
                        ]
                      : null,
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<SearchPillFilter> _legacyMerchantFilters() {
    final label = widget.merchantFilter;
    final onClear = widget.onClearMerchant;
    if (label == null || onClear == null) return const <SearchPillFilter>[];
    return <SearchPillFilter>[
      SearchPillFilter(
        id: label,
        label: label,
        color: widget.accentColor,
        onClear: onClear,
      ),
    ];
  }

  List<SearchPillFilter> _legacyCategoryFilters() {
    final label = widget.categoryFilter;
    final onClear = widget.onClearCategory;
    if (label == null || onClear == null) return const <SearchPillFilter>[];
    return <SearchPillFilter>[
      SearchPillFilter(
        id: label,
        label: label,
        color: widget.categoryFilterColor ?? widget.accentColor,
        onClear: onClear,
      ),
    ];
  }
}

class _FilterCapsule extends StatelessWidget {
  const _FilterCapsule({
    required this.capsuleKey,
    required this.value,
    required this.color,
    required this.surfaceStyle,
    required this.onClear,
  });

  final Key capsuleKey;
  final String value;
  final Color color;
  final ExpenseSurfaceInteraction surfaceStyle;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(15);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 126),
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
    );
    if (!surfaceStyle.hasPressEffect) {
      return Container(
        key: capsuleKey,
        height: 30,
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(color: color, borderRadius: radius),
        child: content,
      );
    }
    final rawKey = capsuleKey;
    return ExpenseSurfaceContainer(
      surfaceKey: rawKey is ValueKey
          ? ValueKey('${rawKey.value}-surface')
          : null,
      style: surfaceStyle,
      color: color,
      primary: true,
      primaryColor: color,
      borderRadius: radius,
      height: 30,
      padding: const EdgeInsets.only(left: 12),
      child: content,
    );
  }
}
