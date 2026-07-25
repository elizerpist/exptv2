import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../models/transaction_category.dart';
import 'spendee_balance_ticking_carousel.dart';
import 'spendee_balance_visual_spec.dart';

const _previousPeriodSemanticsAction = CustomSemanticsAction(
  label: 'Előző időszak',
);
const _nextPeriodSemanticsAction = CustomSemanticsAction(
  label: 'Következő időszak',
);
const _cycleViewSemanticsAction = CustomSemanticsAction(label: 'Nézet váltása');
const _resetCurrentMonthSemanticsAction = CustomSemanticsAction(
  label: 'Aktuális hónap visszaállítása',
);
const _incomeActionRaster = AssetImage(
  'assets/b3ma3/final_income_glass_wallet_plus_3d_inkscape2_mapped.png',
);
const _expenseActionRaster = AssetImage(
  'assets/b3ma3/expense_glass_shopping_bag_3d_perspective_fixed_final1_mapped.png',
);
const _filterGlyphRaster = AssetImage('assets/b3ma3/filter_glyph.png');
const _traditionalFocusOutlineColor = Color(0x6B7D8798);

class SpendeeBalanceActionToggle extends StatefulWidget {
  const SpendeeBalanceActionToggle({
    super.key,
    required this.activeType,
    required this.onChanged,
  });

  final TransactionType activeType;
  final ValueChanged<TransactionType> onChanged;

  static Future<void> precacheAssets(BuildContext context) {
    return Future.wait([
      precacheImage(_incomeActionRaster, context, size: const Size(50, 50)),
      precacheImage(_expenseActionRaster, context, size: const Size(48, 48)),
      precacheImage(_filterGlyphRaster, context, size: const Size(18, 18)),
    ]);
  }

  @override
  State<SpendeeBalanceActionToggle> createState() =>
      _SpendeeBalanceActionToggleState();
}

class _SpendeeBalanceActionToggleState extends State<SpendeeBalanceActionToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  TransactionType? _pulsingType;
  double? _preloadedDevicePixelRatio;
  var _preloadGeneration = 0;
  var _assetsReady = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: SpendeeBalanceVisualSpec.actionPulseDuration,
    )..addListener(_handlePulseTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    if (_preloadedDevicePixelRatio == devicePixelRatio) return;
    _preloadedDevicePixelRatio = devicePixelRatio;
    _assetsReady = false;
    final generation = ++_preloadGeneration;
    unawaited(_preloadActionAssets(generation));
  }

  Future<void> _preloadActionAssets(int generation) async {
    await SpendeeBalanceActionToggle.precacheAssets(context);
    if (!mounted || generation != _preloadGeneration) return;
    setState(() => _assetsReady = true);
  }

  @override
  void dispose() {
    _preloadGeneration += 1;
    _pulseController
      ..removeListener(_handlePulseTick)
      ..dispose();
    super.dispose();
  }

  void _handlePulseTick() {
    if (mounted) setState(() {});
  }

  void _activate(TransactionType type) {
    HapticFeedback.selectionClick();
    widget.onChanged(type);
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reducedMotion) {
      _pulseController.stop();
      setState(() => _pulsingType = null);
      return;
    }
    setState(() => _pulsingType = type);
    unawaited(
      _pulseController.forward(from: 0).whenComplete(() {
        if (!mounted || _pulsingType != type) return;
        setState(() => _pulsingType = null);
      }),
    );
  }

  double _scaleFor(TransactionType type) {
    if (_pulsingType == type) return _pulseScale(_pulseController.value);
    return widget.activeType == type ? 1 : .9;
  }

  @override
  Widget build(BuildContext context) {
    if (!_assetsReady) {
      return const SizedBox(
        key: ValueKey('spendee-balance-actions'),
        width: SpendeeBalanceVisualSpec.contentWidth,
        height: SpendeeBalanceVisualSpec.actionHeight,
        child: SizedBox(key: ValueKey('spendee-balance-action-assets-loading')),
      );
    }
    return Semantics(
      key: const ValueKey('spendee-balance-actions-semantics'),
      container: true,
      explicitChildNodes: true,
      label: 'Tranzakció típusa',
      child: SizedBox(
        key: const ValueKey('spendee-balance-actions'),
        width: SpendeeBalanceVisualSpec.contentWidth,
        height: SpendeeBalanceVisualSpec.actionHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpendeeBalanceVisualSpec.actionSideInset,
          ),
          child: Row(
            children: [
              Expanded(
                child: _ActionButton(
                  type: TransactionType.income,
                  active: widget.activeType == TransactionType.income,
                  iconScale: _scaleFor(TransactionType.income),
                  onPressed: () => _activate(TransactionType.income),
                ),
              ),
              const SizedBox(width: SpendeeBalanceVisualSpec.actionGap),
              Expanded(
                child: _ActionButton(
                  type: TransactionType.expense,
                  active: widget.activeType == TransactionType.expense,
                  iconScale: _scaleFor(TransactionType.expense),
                  onPressed: () => _activate(TransactionType.expense),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.type,
    required this.active,
    required this.iconScale,
    required this.onPressed,
  });

  final TransactionType type;
  final bool active;
  final double iconScale;
  final VoidCallback onPressed;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  var _showFocusOutline = false;

  bool get _income => widget.type == TransactionType.income;

  void _handleFocusChange(bool focused) {
    final show =
        focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (_showFocusOutline == show) return;
    setState(() => _showFocusOutline = show);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(SpendeeBalanceVisualSpec.actionRadius);
    return Semantics(
      button: true,
      toggled: widget.active,
      excludeSemantics: true,
      label: _income ? 'Bevétel hozzáadása' : 'Kiadás hozzáadása',
      onTap: widget.onPressed,
      child: Material(
        key: ValueKey('spendee-balance-${widget.type.name}-action'),
        color: Colors.transparent,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: _gradient,
            boxShadow: [
              BoxShadow(
                color: widget.active
                    ? (_income
                          ? const Color(0x4D7054ED)
                          : const Color(0x4DF5368D))
                    : const Color(0x14707070),
                offset: const Offset(0, 11),
                blurRadius: 20,
              ),
            ],
          ),
          child: InkWell(
            borderRadius: radius,
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            onFocusChange: _handleFocusChange,
            onTap: widget.onPressed,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Center(
                  child: Text(
                    widget.type.label,
                    style: TextStyle(
                      color: widget.active
                          ? Colors.white
                          : const Color(0xFF4F4F4F),
                      fontSize: 15,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Positioned(
                  top: _income ? -4 : -3,
                  left: _income ? 4 : null,
                  right: _income ? null : 4,
                  width: _income ? 50 : 48,
                  height: _income ? 50 : 48,
                  child: Transform.scale(
                    key: ValueKey(
                      'spendee-balance-${widget.type.name}-icon-transform',
                    ),
                    scale: widget.iconScale,
                    child: Image(
                      image: _income
                          ? _incomeActionRaster
                          : _expenseActionRaster,
                      key: ValueKey(
                        _income
                            ? 'spendee-balance-income-wallet-raster'
                            : 'spendee-balance-expense-bag-raster',
                      ),
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                if (_showFocusOutline)
                  Positioned.fill(
                    child: Padding(
                      // CSS `outline: 2px` with `outline-offset: -3px`
                      // occupies the 1…3px inset inside the authored edge.
                      padding: const EdgeInsets.all(1),
                      child: IgnorePointer(
                        child: DecoratedBox(
                          key: ValueKey(
                            'spendee-balance-${widget.type.name}-action-focus-outline',
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xF0FFFFFF),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(
                              SpendeeBalanceVisualSpec.actionRadius - 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Gradient get _gradient {
    if (_income && widget.active) {
      return const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF7054ED),
          Color(0xFF7054ED),
          Color(0xFFB54EDE),
          Color(0xFFF5368D),
        ],
        stops: [0, 46 / 180, .64, 1],
      );
    }
    if (!_income && widget.active) {
      return const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFFFFB15C),
          Color(0xFFFF6B6B),
          Color(0xFFF5368D),
          Color(0xFFF5368D),
        ],
        stops: [0, .36, 136 / 180, 1],
      );
    }
    return CssLinearGradient(
      cssDegrees: 126,
      colors: _income
          ? const [Color(0xFFF7F7F7), Color(0xFFD4D4D4), Color(0xFFE4E4E4)]
          : const [Color(0xFFE4E4E4), Color(0xFFEDEDED), Color(0xFFF7F7F7)],
      stops: const [0, .45, 1],
    );
  }
}

/// Frozen CSS-material palette used to pre-render the authored SVG layer graph.
///
/// Flutter's SVG backend drops the source filter nodes. Production therefore
/// displays browser-rasterized PNGs while retaining the approved SVG sources
/// and this exact palette as the reproducible visual contract.
abstract final class B3ma3ActionRasterPalette {
  static const income = <int, Color>{
    0xFF5B3DF4: Color(0xFF483698),
    0xFF7A63FF: Color(0xFF7054ED),
    0xFFD05CFF: Color(0xFF8A73F0),
    0xFFB9B2FF: Color(0xFFD7CFFA),
    0xFF5F48FF: Color(0xFF7054ED),
    0xFFC9C3FF: Color(0xFFB5A6F6),
    0xFF5B35FF: Color(0xFF483698),
    0xFFD8D3FF: Color(0xFFD7CFFA),
    0xFF9987FF: Color(0xFFB5A6F6),
    0xFF6548EA: Color(0xFF7054ED),
    0xFF3F25BE: Color(0xFF483698),
    0xFFF5F3FF: Color(0xFFF4F1FE),
    0xFFBAAAFF: Color(0xFFD7CFFA),
    0xFF6B51ED: Color(0xFF7054ED),
    0xFF4226B9: Color(0xFF483698),
    0xFFE7E2FF: Color(0xFFF4F1FE),
    0xFFB7A9FF: Color(0xFFD7CFFA),
    0xFF7860E8: Color(0xFF8A73F0),
    0xFF6D4EF6: Color(0xFF7054ED),
    0xFF3420A2: Color(0xFF2F2364),
    0xFF251178: Color(0xFF1D163E),
    0xFF24106D: Color(0xFF201845),
    0xFF2E1688: Color(0xFF2B205A),
    0xFF4727CC: Color(0xFF483698),
    0xFF4A24C9: Color(0xFF483698),
    0xFFF2EFFF: Color(0xFFF4F1FE),
    0xFF4F2BCC: Color(0xFF483698),
    0xFFE7E1FF: Color(0xFFF4F1FE),
    0xFF2D168F: Color(0xFF2F2364),
    0xFFE8E3FF: Color(0xFFF4F1FE),
    0xFF321693: Color(0xFF2F2364),
    0xFFF5F2FF: Color(0xFFF4F1FE),
  };

  static const expense = <int, Color>{
    0xFFFFF8FF: Color(0xFFFFFFFF),
    0xFFFFC9E9: Color(0xFFFCC7DF),
    0xFFFF4CA6: Color(0xFFF5368D),
    0xFFFFB8DF: Color(0xFFFCC7DF),
    0xFFD91B73: Color(0xFFC92C74),
    0xFFFFF3FB: Color(0xFFFEEFF6),
    0xFFFFC9E8: Color(0xFFFCC7DF),
    0xFFFF82BE: Color(0xFFFA96C4),
    0xFFD52C7B: Color(0xFFC92C74),
    0xFFFFB4D9: Color(0xFFFCC7DF),
    0xFFED5AA0: Color(0xFFF75AA2),
    0xFF9F1457: Color(0xFF9D235A),
    0xFFF777B4: Color(0xFFF5368D),
    0xFF981050: Color(0xFF67173B),
    0xFFFFFAFF: Color(0xFFFEEFF6),
    0xFFFFC9E7: Color(0xFFFCC7DF),
    0xFFDC3D88: Color(0xFFC92C74),
    0xFF8E1457: Color(0xFF7B1B47),
    0xFF8F1458: Color(0xFF841D4C),
    0xFF97155C: Color(0xFF8E1F52),
    0xFFC51D70: Color(0xFFC92C74),
    0xFFD1267E: Color(0xFFC92C74),
    0xFFFFCAE6: Color(0xFFFCC7DF),
    0xFFFFF0FA: Color(0xFFFEEFF6),
    0xFFA9175D: Color(0xFF67173B),
    0xFFFFF4FB: Color(0xFFFEEFF6),
    0xFFFFF2FA: Color(0xFFFEEFF6),
  };
}

double _pulseScale(double value) {
  const easing = Cubic(.2, .8, .2, 1);
  if (value <= .45) {
    return 0.9 + (1.12 - .9) * easing.transform(value / .45);
  }
  if (value <= .72) {
    return 1.12 + (.98 - 1.12) * easing.transform((value - .45) / .27);
  }
  return .98 + (1 - .98) * easing.transform((value - .72) / .28);
}

class SpendeeBalanceSummary extends StatelessWidget {
  const SpendeeBalanceSummary({
    super.key,
    required this.label,
    required this.amount,
    required this.onOpenScopePicker,
    required this.onResetCurrentMonth,
    required this.onShiftPeriod,
    required this.onCycleScope,
  });

  final String label;
  final String amount;
  final VoidCallback onOpenScopePicker;
  final VoidCallback onResetCurrentMonth;
  final ValueChanged<int> onShiftPeriod;
  final VoidCallback onCycleScope;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            onShiftPeriod(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            onShiftPeriod(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): onCycleScope,
        const SingleActivator(LogicalKeyboardKey.home): onResetCurrentMonth,
        const SingleActivator(LogicalKeyboardKey.enter): onOpenScopePicker,
        const SingleActivator(LogicalKeyboardKey.space): onOpenScopePicker,
      },
      child: Focus(
        child: Semantics(
          key: const ValueKey('spendee-balance-summary-semantics'),
          container: true,
          button: true,
          excludeSemantics: true,
          label: '$label, $amount',
          onTap: onOpenScopePicker,
          customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
            _previousPeriodSemanticsAction: () => onShiftPeriod(-1),
            _nextPeriodSemanticsAction: () => onShiftPeriod(1),
            _cycleViewSemanticsAction: onCycleScope,
            _resetCurrentMonthSemanticsAction: onResetCurrentMonth,
          },
          child: _SpendeeBalanceSlideGesture(
            transformKey: const ValueKey('spendee-balance-summary-transform'),
            onTap: onOpenScopePicker,
            onDoubleTap: onResetCurrentMonth,
            onHorizontalAction: onShiftPeriod,
            onVerticalAction: onCycleScope,
            child: Container(
              key: const ValueKey('spendee-balance-summary'),
              width: SpendeeBalanceVisualSpec.contentWidth,
              height: SpendeeBalanceVisualSpec.summaryHeight,
              padding: const EdgeInsets.symmetric(
                horizontal: SpendeeBalanceVisualSpec.summaryHorizontalPadding,
              ),
              decoration: BoxDecoration(
                color: const Color(0xF0FFFFFF),
                border: Border.all(color: const Color(0x1A666FAB)),
                borderRadius: BorderRadius.circular(
                  SpendeeBalanceVisualSpec.summaryRadius,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14524B93),
                    offset: Offset(0, 8),
                    blurRadius: 17,
                  ),
                  BoxShadow(
                    color: Color(0xF0FFFFFF),
                    offset: Offset(0, 1),
                    blurRadius: 0,
                    blurStyle: BlurStyle.inner,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 25,
                    height: 25,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EFFF),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/lucide/house.svg',
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF7564F5),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF677392),
                        fontSize: 10,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    amount,
                    style: const TextStyle(
                      color: Color(0xFF1D2B50),
                      fontSize: 13,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      fontVariations: SpendeeBalanceVisualSpec.weight950,
                    ),
                  ),
                  const SizedBox(width: 9),
                  const SizedBox(
                    width: 16,
                    child: Text(
                      '⌄',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF7D88A4),
                        fontSize: 21,
                        height: 1,
                      ),
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

@immutable
class SpendeeBalanceSearchChip {
  const SpendeeBalanceSearchChip({
    required this.keyValue,
    required this.label,
    required this.color,
  });

  final String keyValue;
  final String label;
  final Color color;
}

class SpendeeBalanceSearchFilter extends StatefulWidget {
  const SpendeeBalanceSearchFilter({
    super.key,
    required this.query,
    required this.filters,
    required this.onQueryChanged,
    required this.onRemoveFilter,
    required this.onFilterPressed,
    required this.onCycleScope,
  });

  final String query;
  final List<SpendeeBalanceSearchChip> filters;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<SpendeeBalanceSearchChip> onRemoveFilter;
  final VoidCallback onFilterPressed;
  final VoidCallback onCycleScope;

  @override
  State<SpendeeBalanceSearchFilter> createState() =>
      _SpendeeBalanceSearchFilterState();
}

class _SpendeeBalanceSearchFilterState
    extends State<SpendeeBalanceSearchFilter> {
  late final TextEditingController _controller;
  var _filterShowsFocusOutline = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant SpendeeBalanceSearchFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleFilterFocusChange(bool focused) {
    final show =
        focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (_filterShowsFocusOutline == show) return;
    setState(() => _filterShowsFocusOutline = show);
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.pageUp): widget.onCycleScope,
        const SingleActivator(LogicalKeyboardKey.pageDown): widget.onCycleScope,
      },
      child: Semantics(
        key: const ValueKey('spendee-balance-search-semantics'),
        container: true,
        explicitChildNodes: true,
        label: 'Keresési időszak',
        customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
          _cycleViewSemanticsAction: widget.onCycleScope,
        },
        child: _SpendeeBalanceSlideGesture(
          transformKey: const ValueKey('spendee-balance-search-transform'),
          onVerticalAction: widget.onCycleScope,
          child: SizedBox(
            key: const ValueKey('spendee-balance-search-row'),
            width: SpendeeBalanceVisualSpec.contentWidth,
            height: SpendeeBalanceVisualSpec.searchHeight,
            child: Row(
              children: [
                Expanded(child: _buildField()),
                const SizedBox(width: SpendeeBalanceVisualSpec.searchGap),
                Tooltip(
                  message: 'Szűrés',
                  child: Semantics(
                    button: true,
                    label: 'Szűrés',
                    child: Container(
                      key: const ValueKey('spendee-balance-filter-button'),
                      width: SpendeeBalanceVisualSpec.filterWidth,
                      height: SpendeeBalanceVisualSpec.searchHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xF0FFFFFF),
                        border: Border.all(color: const Color(0x17666FAB)),
                        borderRadius: BorderRadius.circular(
                          SpendeeBalanceVisualSpec.filterRadius,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12524B93),
                            offset: Offset(0, 7),
                            blurRadius: 15,
                          ),
                          BoxShadow(
                            color: Color(0xF0FFFFFF),
                            offset: Offset(0, 1),
                            blurRadius: 0,
                            blurStyle: BlurStyle.inner,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          SpendeeBalanceVisualSpec.filterRadius,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            SpendeeBalanceVisualSpec.filterRadius,
                          ),
                          splashFactory: NoSplash.splashFactory,
                          overlayColor: const WidgetStatePropertyAll<Color>(
                            Colors.transparent,
                          ),
                          onFocusChange: _handleFilterFocusChange,
                          onTap: widget.onFilterPressed,
                          child: Stack(
                            children: [
                              const Center(
                                child: Image(
                                  key: ValueKey('spendee-balance-filter-glyph'),
                                  image: _filterGlyphRaster,
                                  width: 18,
                                  height: 18,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  excludeFromSemantics: true,
                                ),
                              ),
                              if (_filterShowsFocusOutline)
                                Positioned.fill(
                                  child: _TraditionalFocusOutline(
                                    outlineKey: const ValueKey(
                                      'spendee-balance-filter-button-focus-outline',
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    inset: 0,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField() {
    return Container(
      key: const ValueKey('spendee-balance-search-field'),
      height: SpendeeBalanceVisualSpec.searchHeight,
      padding: const EdgeInsets.symmetric(horizontal: 17),
      decoration: BoxDecoration(
        color: const Color(0xF0FFFFFF),
        border: Border.all(color: const Color(0x17666FAB)),
        borderRadius: BorderRadius.circular(
          SpendeeBalanceVisualSpec.searchFieldRadius,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12524B93),
            offset: Offset(0, 7),
            blurRadius: 15,
          ),
          BoxShadow(
            color: Color(0xF0FFFFFF),
            offset: Offset(0, 1),
            blurRadius: 0,
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(
            key: ValueKey('spendee-balance-search-glyph'),
            width: 14,
            height: 14,
            child: CustomPaint(painter: _SearchGlyphPainter()),
          ),
          const SizedBox(width: 11),
          if (widget.filters.isNotEmpty)
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in widget.filters)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Semantics(
                          button: true,
                          label: '${filter.label} szűrő törlése',
                          child: InkWell(
                            splashFactory: NoSplash.splashFactory,
                            overlayColor: const WidgetStatePropertyAll<Color>(
                              Colors.transparent,
                            ),
                            onTap: () => widget.onRemoveFilter(filter),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 20,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                color: filter.color.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${filter.label} ×',
                                style: TextStyle(
                                  color: filter.color,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onQueryChanged,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFF1D2B50),
                fontSize: 9,
                height: 1,
                fontWeight: FontWeight.w700,
                fontVariations: SpendeeBalanceVisualSpec.weight750,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.filters.isEmpty
                    ? 'Keresés tranzakciók között...'
                    : null,
                hintStyle: const TextStyle(
                  color: Color(0xFF7E89A4),
                  fontSize: 9,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  fontVariations: SpendeeBalanceVisualSpec.weight750,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
class SpendeeBalanceTimeScopeItem {
  const SpendeeBalanceTimeScopeItem({required this.key, required this.label});

  final String key;
  final String label;
}

class SpendeeBalanceTimeScopeRail extends StatefulWidget {
  const SpendeeBalanceTimeScopeRail({
    super.key,
    required this.label,
    required this.currentLabel,
    required this.selectedKey,
    required this.options,
    required this.collapseProgress,
    this.dragging = false,
    required this.onSelected,
    required this.onCollapseDragStart,
    required this.onCollapseDragUpdate,
    required this.onCollapseDragEnd,
    required this.onCollapseToggle,
  });

  final String label;
  final String currentLabel;
  final String selectedKey;
  final List<SpendeeBalanceTimeScopeItem> options;
  final double collapseProgress;
  final bool dragging;
  final ValueChanged<SpendeeBalanceTimeScopeItem> onSelected;
  final VoidCallback onCollapseDragStart;
  final ValueChanged<double> onCollapseDragUpdate;
  final VoidCallback onCollapseDragEnd;
  final VoidCallback onCollapseToggle;

  @override
  State<SpendeeBalanceTimeScopeRail> createState() =>
      _SpendeeBalanceTimeScopeRailState();
}

class _SpendeeBalanceTimeScopeRailState
    extends State<SpendeeBalanceTimeScopeRail> {
  late String _activeKey;
  var _collapseHandleShowsFocusOutline = false;

  @override
  void initState() {
    super.initState();
    _activeKey = widget.selectedKey;
  }

  @override
  void didUpdateWidget(covariant SpendeeBalanceTimeScopeRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedKey != widget.selectedKey) {
      _activeKey = widget.selectedKey;
    }
    if (widget.options.isNotEmpty &&
        !widget.options.any((option) => option.key == _activeKey)) {
      _activeKey = widget.options.first.key;
    }
  }

  int get _activeIndex {
    final index = widget.options.indexWhere(
      (option) => option.key == _activeKey,
    );
    return index < 0 ? 0 : index;
  }

  void _selectIndex(int index) {
    if (index < 0 || index >= widget.options.length) return;
    final option = widget.options[index];
    if (_activeKey != option.key) {
      setState(() => _activeKey = option.key);
    }
    widget.onSelected(option);
  }

  void _handleCollapseFocusChange(bool focused) {
    final show =
        focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (_collapseHandleShowsFocusOutline == show) return;
    setState(() => _collapseHandleShowsFocusOutline = show);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('spendee-balance-time-rail'),
      width: SpendeeBalanceVisualSpec.contentWidth,
      height: SpendeeBalanceVisualSpec.timeRailHeight,
      child: Column(
        children: [
          SizedBox(
            height: SpendeeBalanceVisualSpec.timeRailControlHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Color(0xFF51647A),
                          fontSize: 6.5,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          fontVariations: SpendeeBalanceVisualSpec.weight950,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        widget.currentLabel,
                        style: const TextStyle(
                          color: Color(0xFF1D2B50),
                          fontSize: 8,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          fontVariations: SpendeeBalanceVisualSpec.weight950,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 178,
                  child: CallbackShortcuts(
                    bindings: <ShortcutActivator, VoidCallback>{
                      const SingleActivator(LogicalKeyboardKey.enter):
                          widget.onCollapseToggle,
                      const SingleActivator(LogicalKeyboardKey.space):
                          widget.onCollapseToggle,
                    },
                    child: Focus(
                      onFocusChange: _handleCollapseFocusChange,
                      child: Semantics(
                        key: const ValueKey(
                          'spendee-balance-collapse-handle-semantics',
                        ),
                        button: true,
                        expanded: widget.collapseProgress <= .98,
                        label: widget.collapseProgress > .5
                            ? 'Nézet kibontása'
                            : 'Nézet összecsukása',
                        onTap: widget.onCollapseToggle,
                        child: RawGestureDetector(
                          key: const ValueKey(
                            'spendee-balance-collapse-handle',
                          ),
                          behavior: HitTestBehavior.opaque,
                          gestures: {
                            VerticalDragGestureRecognizer:
                                GestureRecognizerFactoryWithHandlers<
                                  VerticalDragGestureRecognizer
                                >(VerticalDragGestureRecognizer.new, (
                                  recognizer,
                                ) {
                                  recognizer.gestureSettings =
                                      const DeviceGestureSettings(touchSlop: 3);
                                  recognizer.onStart = (_) {
                                    widget.onCollapseDragStart();
                                  };
                                  recognizer.onUpdate = (details) {
                                    widget.onCollapseDragUpdate(
                                      details.delta.dy,
                                    );
                                  };
                                  recognizer.onEnd = (_) {
                                    widget.onCollapseDragEnd();
                                  };
                                  recognizer.onCancel =
                                      widget.onCollapseDragEnd;
                                }),
                          },
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            excludeFromSemantics: true,
                            onTap: widget.onCollapseToggle,
                            child: SizedBox(
                              width: 92,
                              height: 21,
                              child: Stack(
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 22,
                                        height: 3,
                                        child: DecoratedBox(
                                          key: const ValueKey(
                                            'spendee-balance-collapse-handle-bar',
                                          ),
                                          decoration: BoxDecoration(
                                            color: widget.dragging
                                                ? const Color(0xFF6E5CF1)
                                                : const Color(0xFFAEB7C8),
                                            borderRadius:
                                                const BorderRadius.all(
                                                  Radius.circular(99),
                                                ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x94FFFFFF),
                                                offset: Offset(0, 1),
                                                blurRadius: 0,
                                                blurStyle: BlurStyle.inner,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Húzd a nézetet',
                                            key: const ValueKey(
                                              'spendee-balance-collapse-handle-label',
                                            ),
                                            maxLines: 1,
                                            style: TextStyle(
                                              color: widget.dragging
                                                  ? const Color(0xFF4C3ED3)
                                                  : const Color(0xFF65748B),
                                              fontSize: 6.5,
                                              height: 1,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_collapseHandleShowsFocusOutline)
                                    Positioned.fill(
                                      child: _TraditionalFocusOutline(
                                        outlineKey: const ValueKey(
                                          'spendee-balance-collapse-handle-focus-outline',
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          9.5,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 37,
            child: widget.options.isEmpty
                ? const SizedBox(
                    key: ValueKey('spendee-balance-rail-ticking-viewport'),
                  )
                : SpendeeBalanceTickingViewport(
                    key: const ValueKey(
                      'spendee-balance-rail-ticking-viewport',
                    ),
                    width: SpendeeBalanceVisualSpec.contentWidth,
                    height: 37,
                    itemCount: widget.options.length,
                    slotDistance: 68.5,
                    centerAnchor: SpendeeBalanceVisualSpec.contentWidth / 2,
                    selectedIndex: _activeIndex,
                    centerOffsetBuilder: _railCenterOffset,
                    onIndexChanged: _selectIndex,
                    semanticLabel: 'Választható időszakok',
                    itemSizeBuilder: (_, selected) => selected
                        ? SpendeeBalanceVisualSpec.activeYearPillSize
                        : SpendeeBalanceVisualSpec.yearPillSize,
                    itemBuilder: (context, index, selected, select) {
                      return _YearPill(
                        item: widget.options[index],
                        selected: selected,
                        onPressed: select,
                      );
                    },
                    decorativeItemBuilder: (context, index, selected, select) {
                      return _YearPill(
                        item: widget.options[index],
                        selected: selected,
                        onPressed: select,
                        decorative: true,
                      );
                    },
                  ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            height: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < widget.options.length; index++) ...[
                  _RailDot(
                    item: widget.options[index],
                    active: widget.options[index].key == _activeKey,
                  ),
                  if (index != widget.options.length - 1)
                    const SizedBox(width: 9),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _railCenterOffset(int logicalOffset) {
    if (logicalOffset == 0) return 0;
    final direction = logicalOffset.isNegative ? -1.0 : 1.0;
    return direction * (68.5 + (logicalOffset.abs() - 1) * 59);
  }
}

class _YearPill extends StatefulWidget {
  const _YearPill({
    required this.item,
    required this.selected,
    required this.onPressed,
    this.decorative = false,
  });

  final SpendeeBalanceTimeScopeItem item;
  final bool selected;
  final VoidCallback onPressed;
  final bool decorative;

  @override
  State<_YearPill> createState() => _YearPillState();
}

class _YearPillState extends State<_YearPill> {
  var _showFocusOutline = false;

  void _handleFocusChange(bool focused) {
    final show =
        focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (_showFocusOutline == show) return;
    setState(() => _showFocusOutline = show);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.selected
        ? SpendeeBalanceVisualSpec.activeYearPillSize
        : SpendeeBalanceVisualSpec.yearPillSize;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: '${widget.item.label} kiválasztása',
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          excludeFromSemantics: true,
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          onFocusChange: _handleFocusChange,
          onTap: widget.onPressed,
          child: Transform.translate(
            key: widget.decorative
                ? null
                : ValueKey(
                    'spendee-balance-year-pill-transform-${widget.item.key}',
                  ),
            offset: widget.selected ? const Offset(0, -1) : Offset.zero,
            child: Container(
              key: widget.decorative
                  ? null
                  : ValueKey('spendee-balance-year-pill-${widget.item.key}'),
              width: size.width,
              height: size.height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.selected ? null : Colors.white,
                gradient: widget.selected
                    ? const CssLinearGradient(
                        cssDegrees: 126,
                        colors: [
                          Color(0xFF715EFB),
                          Color(0xFFB484F3),
                          Color(0xFFE478C3),
                        ],
                        stops: [0, .5, 1],
                      )
                    : null,
                border: widget.selected
                    ? null
                    : Border.all(color: const Color(0x0A666FAB)),
                borderRadius: BorderRadius.circular(widget.selected ? 16 : 14),
                boxShadow: [
                  BoxShadow(
                    color: widget.selected
                        ? const Color(0x407D5BE6)
                        : const Color(0x14524B93),
                    offset: Offset(0, widget.selected ? 8 : 6),
                    blurRadius: widget.selected ? 17 : 13,
                  ),
                  BoxShadow(
                    color: widget.selected
                        ? const Color(0x61FFFFFF)
                        : const Color(0xFAFFFFFF),
                    offset: const Offset(0, 1),
                    blurRadius: 0,
                    blurStyle: BlurStyle.inner,
                  ),
                ],
              ),
              child: SizedBox.expand(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _TimeScopePillLabel(
                      item: widget.item,
                      selected: widget.selected,
                      size: size,
                      decorative: widget.decorative,
                    ),
                    if (widget.selected)
                      const Positioned(
                        bottom: 4,
                        child: SizedBox(
                          width: 5,
                          height: 5,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x334D35B3),
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_showFocusOutline && !widget.decorative)
                      Positioned.fill(
                        child: _TraditionalFocusOutline(
                          outlineKey: ValueKey(
                            'spendee-balance-year-pill-${widget.item.key}-focus-outline',
                          ),
                          borderRadius: BorderRadius.circular(
                            widget.selected ? 15 : 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeScopePillLabel extends StatelessWidget {
  const _TimeScopePillLabel({
    required this.item,
    required this.selected,
    required this.size,
    required this.decorative,
  });

  final SpendeeBalanceTimeScopeItem item;
  final bool selected;
  final Size size;
  final bool decorative;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : const Color(0xFF1D2B50);
    final style = TextStyle(
      color: color,
      fontSize: selected ? 15 : 11,
      height: 1,
      fontWeight: FontWeight.w900,
      fontVariations: SpendeeBalanceVisualSpec.weight950,
    );
    if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(item.key)) {
      return Text(item.label, maxLines: 1, style: style);
    }
    final separator = item.label.lastIndexOf(' ');
    if (separator <= 0 || separator == item.label.length - 1) {
      return Text(item.label, maxLines: 1, style: style);
    }
    final month = item.label.substring(0, separator);
    final year = item.label.substring(separator + 1);
    return Padding(
      padding: EdgeInsets.only(bottom: selected ? 5 : 0),
      child: SizedBox(
        key: decorative
            ? null
            : ValueKey('spendee-balance-time-pill-label-${item.key}'),
        width: size.width - 8,
        height: selected ? 25 : 22,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: selected ? 13 : 10,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  month,
                  key: decorative
                      ? null
                      : ValueKey('spendee-balance-time-pill-month-${item.key}'),
                  maxLines: 1,
                  style: style.copyWith(fontSize: selected ? 13 : 10),
                ),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              year,
              key: decorative
                  ? null
                  : ValueKey('spendee-balance-time-pill-year-${item.key}'),
              maxLines: 1,
              style: style.copyWith(fontSize: selected ? 11 : 9),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailDot extends StatelessWidget {
  const _RailDot({required this.item, required this.active});

  final SpendeeBalanceTimeScopeItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('spendee-balance-year-dot-${item.key}'),
      width: SpendeeBalanceVisualSpec.railDotSize,
      height: SpendeeBalanceVisualSpec.railDotSize,
      child: DecoratedBox(
        key: ValueKey('spendee-balance-year-dot-decoration-${item.key}'),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF24CAE) : const Color(0xFFE1E4EC),
          shape: BoxShape.circle,
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x47F24CAE),
                    offset: Offset(0, 2),
                    blurRadius: 5,
                  ),
                  BoxShadow(
                    color: Color(0x85FFFFFF),
                    offset: Offset(0, 1),
                    blurRadius: 0,
                    blurStyle: BlurStyle.inner,
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0xD1FFFFFF),
                    offset: Offset(0, 1),
                    blurRadius: 0,
                    blurStyle: BlurStyle.inner,
                  ),
                ],
        ),
      ),
    );
  }
}

class _TraditionalFocusOutline extends StatelessWidget {
  const _TraditionalFocusOutline({
    required this.outlineKey,
    required this.borderRadius,
    this.inset = 1,
  });

  final Key outlineKey;
  final BorderRadius borderRadius;
  final double inset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(inset),
      child: IgnorePointer(
        child: DecoratedBox(
          key: outlineKey,
          decoration: BoxDecoration(
            border: Border.all(color: _traditionalFocusOutlineColor, width: 2),
            borderRadius: borderRadius,
          ),
        ),
      ),
    );
  }
}

class _SpendeeBalanceSlideGesture extends StatefulWidget {
  const _SpendeeBalanceSlideGesture({
    required this.transformKey,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onHorizontalAction,
    this.onVerticalAction,
  });

  final Key transformKey;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final ValueChanged<int>? onHorizontalAction;
  final VoidCallback? onVerticalAction;

  @override
  State<_SpendeeBalanceSlideGesture> createState() =>
      _SpendeeBalanceSlideGestureState();
}

class _SpendeeBalanceSlideGestureState
    extends State<_SpendeeBalanceSlideGesture>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<Offset>? _animation;
  Offset _offset = Offset.zero;
  double _dx = 0;
  double _dy = 0;
  bool _triggered = false;
  int? _pendingHorizontal;
  var _pendingVertical = false;

  bool get _reducedMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SpendeeBalanceVisualSpec.summarySettleDuration,
    )..addListener(_tick);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  void _tick() {
    final animation = _animation;
    if (animation == null) return;
    setState(() => _offset = animation.value);
  }

  void _start() {
    _controller.stop();
    _animation = null;
    _dx = 0;
    _dy = 0;
    _triggered = false;
    _pendingHorizontal = null;
    _pendingVertical = false;
    setState(() => _offset = Offset.zero);
  }

  void _horizontal(DragUpdateDetails details) {
    if (_triggered) return;
    _dx += details.delta.dx;
    setState(() {
      _offset = Offset((_dx * .1).clamp(-18.0, 18.0), _offset.dy);
    });
    if (_dx.abs() < 60) return;
    _triggered = true;
    _pendingHorizontal = _dx < 0 ? 1 : -1;
  }

  void _vertical(DragUpdateDetails details) {
    if (_triggered) return;
    _dy += details.delta.dy;
    setState(() {
      _offset = Offset(_offset.dx, (_dy * .1).clamp(-18.0, 18.0));
    });
    if (_dy.abs() < 60) return;
    _triggered = true;
    _pendingVertical = true;
  }

  void _end() {
    final horizontal = _pendingHorizontal;
    final vertical = _pendingVertical;
    _dx = 0;
    _dy = 0;
    _triggered = false;
    if (_reducedMotion) {
      _controller.stop();
      _animation = null;
      _pendingHorizontal = null;
      _pendingVertical = false;
      setState(() => _offset = Offset.zero);
      _dispatch(horizontal: horizontal, vertical: vertical);
      return;
    }
    _animation = Tween<Offset>(
      begin: _offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    unawaited(
      _controller.forward(from: 0).whenComplete(() {
        if (!mounted) return;
        _animation = null;
        _pendingHorizontal = null;
        _pendingVertical = false;
        _dispatch(horizontal: horizontal, vertical: vertical);
      }),
    );
  }

  void _dispatch({required int? horizontal, required bool vertical}) {
    if (vertical) {
      widget.onVerticalAction?.call();
    } else if (horizontal != null) {
      widget.onHorizontalAction?.call(horizontal);
    }
  }

  void _cancel() {
    _pendingHorizontal = null;
    _pendingVertical = false;
    _end();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      onHorizontalDragStart: widget.onHorizontalAction == null
          ? null
          : (_) => _start(),
      onHorizontalDragUpdate: widget.onHorizontalAction == null
          ? null
          : _horizontal,
      onHorizontalDragEnd: widget.onHorizontalAction == null
          ? null
          : (_) => _end(),
      onHorizontalDragCancel: widget.onHorizontalAction == null
          ? null
          : _cancel,
      onVerticalDragStart: widget.onVerticalAction == null
          ? null
          : (_) => _start(),
      onVerticalDragUpdate: widget.onVerticalAction == null ? null : _vertical,
      onVerticalDragEnd: widget.onVerticalAction == null ? null : (_) => _end(),
      onVerticalDragCancel: widget.onVerticalAction == null ? null : _cancel,
      child: Transform.translate(
        key: widget.transformKey,
        offset: _offset,
        child: RepaintBoundary(child: widget.child),
      ),
    );
  }
}

class _SearchGlyphPainter extends CustomPainter {
  const _SearchGlyphPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9AA5BE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..isAntiAlias = true;
    canvas.drawCircle(const Offset(7, 7), 6.15, paint);
    paint.style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(12, 16.15);
    canvas.rotate(.8377580409572781);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, -.85, 7, 1.7),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SearchGlyphPainter oldDelegate) => false;
}
