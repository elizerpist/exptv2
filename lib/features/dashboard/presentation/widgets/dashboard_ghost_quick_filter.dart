import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/categories/catalog/category_icon_catalog.dart';
import '../../../../core/categories/presentation/category_icon_view.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../../application/dashboard_presentation_preferences.dart';
import '../../query/domain/ghost_filter_mode.dart';

/// A compact cycle control for the dashboard-wide ghost query dimension.
///
/// It intentionally owns no filter state. Its parent atomically publishes a
/// prepared ghost-membership projection, so this control can react on the
/// next frame without creating a widget-local filtering implementation.
final class DashboardGhostQuickFilter extends StatelessWidget {
  const DashboardGhostQuickFilter({
    super.key,
    required this.mode,
    required this.onTap,
    this.iconPack = DashboardGhostQuickFilterIconPack.current,
    this.presentation = DashboardGhostQuickFilterPresentation.current,
    this.onModeSelected,
  });

  final GhostFilterMode mode;
  final VoidCallback onTap;
  final DashboardGhostQuickFilterIconPack iconPack;
  final DashboardGhostQuickFilterPresentation presentation;

  /// Direct selection is used only by Dropdown and Rail. The Core remains the
  /// one owner of [mode]; this callback never optimistically changes a local
  /// filter value.
  final Future<bool> Function(GhostFilterMode mode)? onModeSelected;

  @override
  Widget build(BuildContext context) {
    if (presentation == DashboardGhostQuickFilterPresentation.dropdown) {
      return _DashboardGhostQuickFilterDropdown(
        mode: mode,
        onModeSelected: onModeSelected ?? (_) async => false,
      );
    }
    if (presentation == DashboardGhostQuickFilterPresentation.rail) {
      return _DashboardGhostQuickFilterRail(
        mode: mode,
        onModeSelected: onModeSelected ?? (_) async => false,
      );
    }
    if (presentation == DashboardGhostQuickFilterPresentation.searchPillFling) {
      // This presentation is installed by DashboardLogBoxHeader as a trailing
      // SearchPill control, never in the resolved quick-filter lane.
      return const SizedBox.shrink();
    }
    final dotCount = GhostFilterMode.values.length;
    final selectedIndex = GhostFilterMode.values.indexOf(mode);
    return Semantics(
      button: true,
      label: 'Ghost gyorsszűrő: ${mode.semanticLabel}',
      hint: 'Következő állapot',
      child: Tooltip(
        message: mode.semanticLabel,
        child: SizedBox(
          key: const ValueKey('dashboard-ghost-quick-filter'),
          width: 48,
          height: 48,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DashboardGhostQuickFilterIcon(
                      mode: mode,
                      iconPack: iconPack,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List<Widget>.generate(dotCount, (index) {
                        final active = index == selectedIndex;
                        return Container(
                          width: active ? 5 : 3,
                          height: active ? 5 : 3,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: FluviVisualTokens.textSecondary.withValues(
                              alpha: active ? .85 : .28,
                            ),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
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

/// The SearchPill-local presentation adapter for the shared vertical carousel.
///
/// It owns only the physical belt and the last user intent. [mode] remains
/// Core-owned, so failed or superseded requests can never leave a local ghost
/// filter state different from the prepared dashboard projection.
final class DashboardGhostSearchPillFling extends StatefulWidget {
  const DashboardGhostSearchPillFling({
    super.key,
    required this.mode,
    required this.onModeSelected,
  });

  final GhostFilterMode mode;
  final Future<bool> Function(GhostFilterMode mode) onModeSelected;

  @override
  State<DashboardGhostSearchPillFling> createState() =>
      _DashboardGhostSearchPillFlingState();
}

final class _DashboardGhostSearchPillFlingState
    extends State<DashboardGhostSearchPillFling> {
  static const _modes = <GhostFilterMode>[
    GhostFilterMode.both,
    GhostFilterMode.nonGhost,
    GhostFilterMode.onlyGhost,
  ];

  late final CenteredCarouselController _carouselController =
      CenteredCarouselController(initialIndex: _indexOf(widget.mode));
  late int _lastLogicalIndex = _indexOf(widget.mode);
  GhostFilterMode? _lastRequestedTarget;
  var _requestEpoch = 0;
  var _motionActive = false;

  bool get _showsCanonicalRestingIcon =>
      !_motionActive && _lastRequestedTarget == null;

  @override
  void didUpdateWidget(covariant DashboardGhostSearchPillFling oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode == widget.mode) return;

    // A completion is accepted only when the canonical query has caught up.
    // Do not interrupt an in-flight physical fling merely because a prior
    // semantic request has published in the meantime.
    if (_lastRequestedTarget == widget.mode) {
      _lastRequestedTarget = null;
    }
    _reconcileCanonicalModeIfIdle();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey<String>('dashboard-ghost-searchpill-fling-semantics'),
    label: 'Ghost gyorsszűrő: ${widget.mode.semanticLabel}',
    hint: 'Függőlegesen húzva válthat.',
    onIncrease: () => _moveBy(1),
    onDecrease: () => _moveBy(-1),
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemExtent = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 40.0;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Opacity(
                    opacity: _showsCanonicalRestingIcon ? 0 : 1,
                    child: CenteredCarousel<GhostFilterMode>(
                      dataSource:
                          const CyclicCarouselDataSource<GhostFilterMode>(
                            _modes,
                          ),
                      controller: _carouselController,
                      spec: CenteredCarouselSpec(
                        itemExtent: itemExtent,
                        scrollDirection: Axis.vertical,
                        visibleItemCount: 1,
                        minScale: 1,
                        neighborScale: 1,
                        outerScale: 1,
                        minOpacity: 1,
                        neighborOpacity: 1,
                        outerOpacity: 1,
                        motionProfile:
                            CenteredCarouselMotionProfiles.timeRefinementRail,
                        enableHaptics: true,
                        enableTapToCenter: false,
                        clipBehavior: Clip.hardEdge,
                      ),
                      height: itemExtent,
                      viewportKey: const ValueKey<String>(
                        'dashboard-ghost-searchpill-fling-viewport',
                      ),
                      onSelectedChanged: _onSelectedChanged,
                      onMotionStarted: (_) => _setMotionActive(true),
                      onMotionIdle: (_) {
                        _setMotionActive(false);
                        _reconcileCanonicalModeIfIdle();
                      },
                      itemBuilder: (context, candidate, metrics) => Center(
                        key: !_showsCanonicalRestingIcon && metrics.isSelected
                            ? ValueKey<String>(
                                'dashboard-ghost-searchpill-fling-icon-${candidate.name}',
                              )
                            : null,
                        child: DashboardGhostFilterReferenceIcon(
                          mode: candidate,
                          color: const Color(0xFF6D28D9),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  if (_showsCanonicalRestingIcon)
                    IgnorePointer(
                      child: Center(
                        key: ValueKey<String>(
                          'dashboard-ghost-searchpill-fling-icon-${widget.mode.name}',
                        ),
                        child: DashboardGhostFilterReferenceIcon(
                          mode: widget.mode,
                          color: const Color(0xFF6D28D9),
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );

  void _onSelectedChanged(int logicalIndex) {
    if (logicalIndex == _lastLogicalIndex) return;
    _lastLogicalIndex = logicalIndex;
    _requestMode(_modeAt(logicalIndex));
  }

  void _moveBy(int delta) {
    unawaited(_carouselController.animateToIndex(_lastLogicalIndex + delta));
  }

  void _requestMode(GhostFilterMode target) {
    // The last physical target, rather than only the still-published query,
    // is the dedupe boundary. This preserves an A -> B -> A fling while A is
    // still the canonical mode.
    if (target == _lastRequestedTarget) return;
    if (_lastRequestedTarget == null && target == widget.mode) return;
    _lastRequestedTarget = target;
    final requestEpoch = ++_requestEpoch;
    unawaited(_applyRequestedMode(target, requestEpoch));
  }

  Future<void> _applyRequestedMode(
    GhostFilterMode target,
    int requestEpoch,
  ) async {
    var accepted = false;
    try {
      accepted = await widget.onModeSelected(target);
    } catch (_) {
      accepted = false;
    }
    if (!mounted || requestEpoch != _requestEpoch) return;
    if (accepted && widget.mode == target) {
      _lastRequestedTarget = null;
      return;
    }
    if (!accepted) {
      _lastRequestedTarget = null;
      _reconcileCanonicalModeIfIdle();
      if (mounted) setState(() {});
    }
  }

  void _setMotionActive(bool active) {
    if (_motionActive == active || !mounted) return;
    setState(() => _motionActive = active);
  }

  void _reconcileCanonicalModeIfIdle() {
    if (_carouselController.isScrolling || _lastRequestedTarget != null) {
      return;
    }
    final canonicalIndex = _indexOf(widget.mode);
    if (_lastLogicalIndex == canonicalIndex) return;
    _lastLogicalIndex = canonicalIndex;
    _carouselController.interruptAndJumpToIndexSilently(canonicalIndex);
  }

  static GhostFilterMode _modeAt(int logicalIndex) =>
      _modes[_positiveModulo(logicalIndex, _modes.length)];

  static int _indexOf(GhostFilterMode mode) => _modes.indexOf(mode);

  static int _positiveModulo(int value, int divisor) {
    final result = value % divisor;
    return result < 0 ? result + divisor : result;
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }
}

/// Reference icon language for the direct-selection variants. It does not
/// depend on the persisted current-control icon package.
final class DashboardGhostFilterReferenceIcon extends StatelessWidget {
  const DashboardGhostFilterReferenceIcon({
    super.key,
    required this.mode,
    required this.color,
    this.size = 23,
  });

  final GhostFilterMode mode;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final receiptSize = size * .88;
    if (mode == GhostFilterMode.onlyGhost) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: _GhostSilhouette(size: size, color: color),
        ),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: size * .04,
            top: size * .03,
            child: Icon(
              Icons.receipt_long_outlined,
              size: receiptSize,
              color: color,
            ),
          ),
          if (mode == GhostFilterMode.both)
            Positioned(
              right: -1,
              bottom: -1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: .30)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: _GhostSilhouette(size: size * .47, color: color),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class _DashboardGhostQuickFilterDropdown extends StatelessWidget {
  const _DashboardGhostQuickFilterDropdown({
    required this.mode,
    required this.onModeSelected,
  });

  final GhostFilterMode mode;
  final Future<bool> Function(GhostFilterMode mode) onModeSelected;

  @override
  Widget build(BuildContext context) {
    const lavender = Color(0xFFEDE9FE);
    const purple = Color(0xFF6D28D9);
    final label = switch (mode) {
      GhostFilterMode.both => 'Összes',
      GhostFilterMode.nonGhost => 'Normál',
      GhostFilterMode.onlyGhost => 'Ghost',
    };
    return Semantics(
      button: true,
      label: 'Ghost gyorsszűrő: $label',
      child: MenuAnchor(
        alignmentOffset: const Offset(0, 4),
        style: const MenuStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
        ),
        menuChildren: <Widget>[
          for (final candidate in <GhostFilterMode>[
            GhostFilterMode.both,
            GhostFilterMode.nonGhost,
            GhostFilterMode.onlyGhost,
          ])
            MenuItemButton(
              key: ValueKey<String>(
                'dashboard-ghost-dropdown-${candidate.name}',
              ),
              onPressed: () => onModeSelected(candidate),
              leadingIcon: DashboardGhostFilterReferenceIcon(
                mode: candidate,
                color: candidate == mode
                    ? purple
                    : FluviVisualTokens.textSecondary,
                size: 20,
              ),
              trailingIcon: candidate == mode
                  ? const Icon(Icons.check_rounded, color: purple, size: 18)
                  : const SizedBox(width: 18),
              child: Text(switch (candidate) {
                GhostFilterMode.both => 'Összes tranzakció',
                GhostFilterMode.nonGhost => 'Ghost nélkül',
                GhostFilterMode.onlyGhost => 'Csak ghost',
              }),
            ),
        ],
        builder: (context, controller, _) => SizedBox(
          key: const ValueKey('dashboard-ghost-quick-filter-dropdown'),
          width: 144,
          height: 48,
          child: Material(
            color: lavender,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: controller.open,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: <Widget>[
                    DashboardGhostFilterReferenceIcon(
                      mode: mode,
                      color: purple,
                      size: 22,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: purple,
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

final class _DashboardGhostQuickFilterRail extends StatelessWidget {
  const _DashboardGhostQuickFilterRail({
    required this.mode,
    required this.onModeSelected,
  });

  final GhostFilterMode mode;
  final Future<bool> Function(GhostFilterMode mode) onModeSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('dashboard-ghost-quick-filter-rail'),
    width: 144,
    height: 48,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          for (final candidate in <GhostFilterMode>[
            GhostFilterMode.both,
            GhostFilterMode.nonGhost,
            GhostFilterMode.onlyGhost,
          ])
            Expanded(
              child: _GhostRailPill(
                mode: candidate,
                active: candidate == mode,
                onPressed: candidate == mode
                    ? null
                    : () => onModeSelected(candidate),
              ),
            ),
        ],
      ),
    ),
  );
}

final class _GhostRailPill extends StatelessWidget {
  const _GhostRailPill({
    required this.mode,
    required this.active,
    required this.onPressed,
  });

  final GhostFilterMode mode;
  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6D28D9);
    final label = switch (mode) {
      GhostFilterMode.both => 'Összes tranzakció',
      GhostFilterMode.nonGhost => 'Ghost nélkül',
      GhostFilterMode.onlyGhost => 'Csak ghost',
    };
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: active ? const Color(0xFFEDE9FE) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            key: ValueKey<String>('dashboard-ghost-rail-${mode.name}'),
            onTap: onPressed,
            borderRadius: BorderRadius.circular(11),
            child: Center(
              child: DashboardGhostFilterReferenceIcon(
                mode: mode,
                color: active
                    ? purple
                    : FluviVisualTokens.textSecondary.withValues(alpha: .72),
                size: 21,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Public shared preview for the persisted ghost-filter appearance choice.
/// It has no query/state side effects, so it is safe in Settings as well as
/// inside the live quick filter.
final class DashboardGhostQuickFilterIcon extends StatelessWidget {
  const DashboardGhostQuickFilterIcon({
    super.key,
    required this.mode,
    this.iconPack = DashboardGhostQuickFilterIconPack.current,
  });

  final GhostFilterMode mode;
  final DashboardGhostQuickFilterIconPack iconPack;

  @override
  Widget build(BuildContext context) {
    final color = FluviVisualTokens.textSecondary;
    return switch (iconPack) {
      DashboardGhostQuickFilterIconPack.current => _CurrentGhostIcon(
        mode: mode,
        color: color,
      ),
      DashboardGhostQuickFilterIconPack.receiptGhost => _ReceiptGhostIcon(
        mode: mode,
        color: color,
      ),
    };
  }
}

/// The existing ghost-only design. It retains the same 26px field as the
/// alternate package so a preference change never moves the dots or hit area.
final class _CurrentGhostIcon extends StatelessWidget {
  const _CurrentGhostIcon({required this.mode, required this.color});

  final GhostFilterMode mode;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 26,
    height: 26,
    child: Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          left: 1,
          top: 1,
          child: _GhostSilhouette(size: 24, color: color),
        ),
        if (mode == GhostFilterMode.nonGhost)
          Positioned.fill(
            child: CustomPaint(painter: _GhostSlashPainter(color)),
          ),
        if (mode == GhostFilterMode.both)
          Positioned(
            right: -1,
            bottom: -1,
            child: _GhostPlusMark(color: color),
          ),
      ],
    ),
  );
}

/// Alternate package: the ordinary ledger universe is a receipt, while the
/// shared universe adds one recognisable ghost source marker.
final class _ReceiptGhostIcon extends StatelessWidget {
  const _ReceiptGhostIcon({required this.mode, required this.color});

  final GhostFilterMode mode;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (mode == GhostFilterMode.onlyGhost) {
      return SizedBox(
        width: 26,
        height: 26,
        child: Center(child: _GhostSilhouette(size: 24, color: color)),
      );
    }
    return SizedBox(
      width: 26,
      height: 26,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          const Positioned(
            left: 1,
            top: 1,
            child: Icon(
              Icons.receipt_long_outlined,
              size: 22,
              color: FluviVisualTokens.textSecondary,
            ),
          ),
          if (mode == GhostFilterMode.both)
            Positioned(
              right: -1,
              bottom: -1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: .3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: _GhostSilhouette(size: 12, color: color),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class _GhostSilhouette extends StatelessWidget {
  const _GhostSilhouette({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CategoryIconView(
    picture: PreparedVectorAssetAtlas.instance.categoryIcon(
      CategoryIconCatalog.handleOf('icon_28'),
    ),
    size: size,
    color: color,
  );
}

final class _GhostSlashPainter extends CustomPainter {
  const _GhostSlashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .16, size.height * .84),
      Offset(size.width * .84, size.height * .16),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GhostSlashPainter oldDelegate) =>
      oldDelegate.color != color;
}

final class _GhostPlusMark extends StatelessWidget {
  const _GhostPlusMark({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: color.withValues(alpha: .35)),
    ),
    child: Icon(Icons.add_rounded, size: 8, color: color),
  );
}
