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
    this.categoryFilter,
    this.categoryFilterColor,
    this.onClearCategory,
  });

  final String query;
  final ValueChanged<String> onQueryChanged;
  final int filteredCount;
  final Color surfaceColor;
  final ExpenseSurfaceInteraction surfaceStyle;
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
    final hasMerchant = widget.merchantFilter != null;
    final hasCategory = widget.categoryFilter != null;
    final hasFilters = hasMerchant || hasCategory;
    final capsules = <Widget>[
      if (hasMerchant)
        _FilterCapsule(
          capsuleKey: const ValueKey('search-pill-capsule-merchant'),
          value: widget.merchantFilter!,
          color: AppColors.primary,
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

    final content = Row(
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
          child: Container(
            key: const ValueKey('search-pill-text-wrapper'),
            decoration: BoxDecoration(color: widget.surfaceColor),
            child: DebugTextField(
              debugLabel: 'SearchPill.query',
              focusNode: _focusNode,
              controller: _controller,
              onChanged: widget.onQueryChanged,
              onTapOutside: (_) => _focusNode.unfocus(),
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
        ),
      ],
    );

    return TextFieldTapRegion(
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _requestFocus,
          child: ValueListenableBuilder<bool>(
            valueListenable: _focused,
            child: content,
            builder: (context, focused, child) {
              return ExpensePressable(
                enabled: widget.surfaceStyle.hasPressEffect,
                forcePressed:
                    focused && widget.surfaceStyle.hasPressEffect,
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
                      color: focused ? AppColors.primary : AppColors.gray200,
                      width: focused ? 1.5 : 1,
                    ),
                    neutralShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        offset: const Offset(0, 2),
                        blurRadius: 3,
                      ),
                    ],
                    child: child ?? const SizedBox.shrink(),
                  );
                },
              );
            },
          ),
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
