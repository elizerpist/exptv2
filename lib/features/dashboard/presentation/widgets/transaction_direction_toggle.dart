import 'package:flutter/material.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/design/app_control_metrics.dart';
import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_corner_profile.dart';
import '../../../../core/design/dashboard_border_profile.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_global_appearance.dart';
import '../../../../core/design/fluvi_rounded_box.dart';
import '../../application/transaction_direction_controller.dart';
import '../../application/dashboard_performance_counters.dart';
import '../dashboard_corner_roundness.dart';
import '../dashboard_shadow_style.dart';
import '../dashboard_border_style.dart';

/// Input-only renderer for the two transaction directions.
class TransactionDirectionToggle extends StatelessWidget {
  const TransactionDirectionToggle({
    super.key,
    required this.bounds,
    required this.selectedDirection,
    required this.incomeIconScale,
    required this.expenseIconScale,
    required this.onSelected,
    this.directionColorProfile = FluviDirectionColorProfile.original,
    this.showsDirectionArtwork = true,
    this.directionControlStyle = FluviDirectionControlStyle.splitButtons,
    this.activeLabelTone = FluviActiveDirectionLabelTone.softenedWhite,
    this.inactiveLabelTone = FluviInactiveDirectionLabelTone.softenedGray,
    this.selectedIconScaleAnimation,
    this.performanceCounters,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  final DashboardBounds bounds;
  final TransactionDirection selectedDirection;
  final double incomeIconScale;
  final double expenseIconScale;
  final ValueChanged<TransactionDirection> onSelected;
  final FluviDirectionColorProfile directionColorProfile;
  final bool showsDirectionArtwork;
  final FluviDirectionControlStyle directionControlStyle;
  final FluviActiveDirectionLabelTone activeLabelTone;
  final FluviInactiveDirectionLabelTone inactiveLabelTone;
  final Animation<double>? selectedIconScaleAnimation;
  final DashboardPerformanceCounters? performanceCounters;
  final GestureDragStartCallback? onVerticalDragStart;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    if (directionControlStyle == FluviDirectionControlStyle.slidingRail) {
      return _SlidingDirectionRail(
        bounds: bounds,
        selectedDirection: selectedDirection,
        incomeIconScale: incomeIconScale,
        expenseIconScale: expenseIconScale,
        onSelected: onSelected,
        directionColorProfile: directionColorProfile,
        showsDirectionArtwork: showsDirectionArtwork,
        activeLabelTone: activeLabelTone,
        inactiveLabelTone: inactiveLabelTone,
        selectedIconScaleAnimation: selectedIconScaleAnimation,
        performanceCounters: performanceCounters,
        onVerticalDragStart: onVerticalDragStart,
        onVerticalDragUpdate: onVerticalDragUpdate,
        onVerticalDragEnd: onVerticalDragEnd,
      );
    }
    final assetAtlas = PreparedVectorAssetAtlas.instance;
    final controlWidth = (bounds.width - FluviVisualTokens.controlInnerGap) / 2;
    final controlRadius = DashboardCornerRoundnessScope.profileOf(context)
        .borderRadiusFor(
          DashboardCornerSurfaceFamily.directionControl,
          size: Size(controlWidth, AppSelectorMetrics.directionControlHeight),
        );
    return SizedBox(
      width: bounds.width,
      height: bounds.height,
      child: Row(
        children: [
          Expanded(
            child: _DirectionButton(
              direction: TransactionDirection.income,
              label: 'Bevétel',
              picture: assetAtlas.picture(
                PreparedVectorAssetAtlas.incomeWalletHandle,
              ),
              assetKey: const ValueKey('fluvi-income-wallet'),
              activeGradient: FluviDirectionColorPaletteCatalog.income(
                directionColorProfile,
              ),
              selected: selectedDirection == TransactionDirection.income,
              iconScale: incomeIconScale,
              showsArtwork: showsDirectionArtwork,
              iconScaleAnimation:
                  selectedDirection == TransactionDirection.income
                  ? selectedIconScaleAnimation
                  : null,
              onTap: onSelected,
              onVerticalDragStart: onVerticalDragStart,
              onVerticalDragUpdate: onVerticalDragUpdate,
              onVerticalDragEnd: onVerticalDragEnd,
              performanceCounters: performanceCounters,
              borderRadius: controlRadius,
            ),
          ),
          const SizedBox(width: FluviVisualTokens.controlInnerGap),
          Expanded(
            child: _DirectionButton(
              direction: TransactionDirection.expense,
              label: 'Kiadás',
              picture: assetAtlas.picture(
                PreparedVectorAssetAtlas.expenseBagHandle,
              ),
              assetKey: const ValueKey('fluvi-expense-bag'),
              activeGradient: FluviDirectionColorPaletteCatalog.expense(
                directionColorProfile,
              ),
              selected: selectedDirection == TransactionDirection.expense,
              iconScale: expenseIconScale,
              showsArtwork: showsDirectionArtwork,
              iconScaleAnimation:
                  selectedDirection == TransactionDirection.expense
                  ? selectedIconScaleAnimation
                  : null,
              onTap: onSelected,
              onVerticalDragStart: onVerticalDragStart,
              onVerticalDragUpdate: onVerticalDragUpdate,
              onVerticalDragEnd: onVerticalDragEnd,
              performanceCounters: performanceCounters,
              borderRadius: controlRadius,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pure geometry exposes the fixed shader domain separately from the moving
/// mask, making a pill-local travelling gradient regression testable.
@immutable
class DirectionRailGeometry {
  const DirectionRailGeometry({
    required this.fullGradientRect,
    required this.pillRect,
  });

  final Rect fullGradientRect;
  final Rect pillRect;

  factory DirectionRailGeometry.resolve({
    required Size size,
    required double position,
    double inset = 3,
  }) {
    final normalized = position.clamp(0.0, 1.0).toDouble();
    final usableWidth = (size.width - inset * 2).clamp(0.0, double.infinity);
    final pillWidth = usableWidth / 2;
    final travel = usableWidth - pillWidth;
    return DirectionRailGeometry(
      fullGradientRect: Offset.zero & size,
      pillRect: Rect.fromLTWH(
        inset + travel * normalized,
        inset,
        pillWidth,
        (size.height - inset * 2).clamp(0.0, double.infinity),
      ),
    );
  }
}

final class _SlidingDirectionRail extends StatefulWidget {
  const _SlidingDirectionRail({
    required this.bounds,
    required this.selectedDirection,
    required this.incomeIconScale,
    required this.expenseIconScale,
    required this.onSelected,
    required this.directionColorProfile,
    required this.showsDirectionArtwork,
    required this.activeLabelTone,
    required this.inactiveLabelTone,
    required this.selectedIconScaleAnimation,
    required this.performanceCounters,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  final DashboardBounds bounds;
  final TransactionDirection selectedDirection;
  final double incomeIconScale;
  final double expenseIconScale;
  final ValueChanged<TransactionDirection> onSelected;
  final FluviDirectionColorProfile directionColorProfile;
  final bool showsDirectionArtwork;
  final FluviActiveDirectionLabelTone activeLabelTone;
  final FluviInactiveDirectionLabelTone inactiveLabelTone;
  final Animation<double>? selectedIconScaleAnimation;
  final DashboardPerformanceCounters? performanceCounters;
  final GestureDragStartCallback? onVerticalDragStart;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;

  @override
  State<_SlidingDirectionRail> createState() => _SlidingDirectionRailState();
}

final class _SlidingDirectionRailState extends State<_SlidingDirectionRail>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 220);
  late final AnimationController _position;

  double get _target =>
      widget.selectedDirection == TransactionDirection.income ? 0 : 1;

  @override
  void initState() {
    super.initState();
    _position = AnimationController(vsync: this, value: _target);
  }

  @override
  void didUpdateWidget(covariant _SlidingDirectionRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_target == _position.value) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _position.value = _target;
    } else {
      // animateTo retargets the existing visual position without queueing.
      _position.animateTo(
        _target,
        duration: _duration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetAtlas = PreparedVectorAssetAtlas.instance;
    final depth = DashboardShadowStyleScope.profileOf(
      context,
    ).depthFor(DashboardCornerSurfaceFamily.directionControl);
    final radius = DashboardCornerRoundnessScope.profileOf(context)
        .borderRadiusFor(
          DashboardCornerSurfaceFamily.directionControl,
          size: Size(
            widget.bounds.width,
            AppSelectorMetrics.directionControlHeight,
          ),
        );
    return SizedBox(
      width: widget.bounds.width,
      height: widget.bounds.height,
      child: FluviRoundedBox(
        key: const ValueKey<String>('fluvi-direction-sliding-rail'),
        color: Colors.white,
        border: DashboardBorderScope.profileOf(
          context,
        ).borderFor(DashboardBorderSurface.incomeDirection),
        borderRadius: radius,
        boxShadow: depth.shadows,
        child: LayoutBuilder(
          builder: (context, constraints) => AnimatedBuilder(
            animation: _position,
            builder: (context, _) {
              final geometry = DirectionRailGeometry.resolve(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                position: _position.value,
              );
              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  IgnorePointer(
                    child: CustomPaint(
                      key: const ValueKey<String>(
                        'fluvi-direction-sliding-rail-active-pill',
                      ),
                      painter: _DirectionRailActivePillPainter(
                        geometry: geometry,
                        gradient: FluviDirectionColorPaletteCatalog.rail(
                          widget.directionColorProfile,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _DirectionRailHalf(
                          key: const ValueKey<String>(
                            'fluvi-direction-rail-income',
                          ),
                          direction: TransactionDirection.income,
                          label: 'Bevétel',
                          picture: assetAtlas.picture(
                            PreparedVectorAssetAtlas.incomeWalletHandle,
                          ),
                          assetKey: const ValueKey('fluvi-income-wallet'),
                          selected:
                              widget.selectedDirection ==
                              TransactionDirection.income,
                          activeWeight: 1 - _position.value,
                          iconScale: widget.incomeIconScale,
                          showsArtwork: widget.showsDirectionArtwork,
                          iconScaleAnimation:
                              widget.selectedDirection ==
                                  TransactionDirection.income
                              ? widget.selectedIconScaleAnimation
                              : null,
                          activeColor: widget.activeLabelTone.color,
                          inactiveColor: widget.inactiveLabelTone.color,
                          performanceCounters: widget.performanceCounters,
                          onTap: widget.onSelected,
                          onVerticalDragStart: widget.onVerticalDragStart,
                          onVerticalDragUpdate: widget.onVerticalDragUpdate,
                          onVerticalDragEnd: widget.onVerticalDragEnd,
                        ),
                      ),
                      Expanded(
                        child: _DirectionRailHalf(
                          key: const ValueKey<String>(
                            'fluvi-direction-rail-expense',
                          ),
                          direction: TransactionDirection.expense,
                          label: 'Kiadás',
                          picture: assetAtlas.picture(
                            PreparedVectorAssetAtlas.expenseBagHandle,
                          ),
                          assetKey: const ValueKey('fluvi-expense-bag'),
                          selected:
                              widget.selectedDirection ==
                              TransactionDirection.expense,
                          activeWeight: _position.value,
                          iconScale: widget.expenseIconScale,
                          showsArtwork: widget.showsDirectionArtwork,
                          iconScaleAnimation:
                              widget.selectedDirection ==
                                  TransactionDirection.expense
                              ? widget.selectedIconScaleAnimation
                              : null,
                          activeColor: widget.activeLabelTone.color,
                          inactiveColor: widget.inactiveLabelTone.color,
                          performanceCounters: widget.performanceCounters,
                          onTap: widget.onSelected,
                          onVerticalDragStart: widget.onVerticalDragStart,
                          onVerticalDragUpdate: widget.onVerticalDragUpdate,
                          onVerticalDragEnd: widget.onVerticalDragEnd,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

final class _DirectionRailActivePillPainter extends CustomPainter {
  const _DirectionRailActivePillPainter({
    required this.geometry,
    required this.gradient,
  });

  final DirectionRailGeometry geometry;
  final LinearGradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = gradient.createShader(geometry.fullGradientRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(geometry.pillRect, const Radius.circular(16)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DirectionRailActivePillPainter oldDelegate) =>
      oldDelegate.geometry.fullGradientRect != geometry.fullGradientRect ||
      oldDelegate.geometry.pillRect != geometry.pillRect ||
      oldDelegate.gradient != gradient;
}

final class _DirectionRailHalf extends StatelessWidget {
  const _DirectionRailHalf({
    super.key,
    required this.direction,
    required this.label,
    required this.picture,
    required this.assetKey,
    required this.selected,
    required this.activeWeight,
    required this.iconScale,
    required this.showsArtwork,
    required this.iconScaleAnimation,
    required this.activeColor,
    required this.inactiveColor,
    required this.performanceCounters,
    required this.onTap,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  final TransactionDirection direction;
  final String label;
  final PreparedVectorPicture picture;
  final Key assetKey;
  final bool selected;
  final double activeWeight;
  final double iconScale;
  final bool showsArtwork;
  final Animation<double>? iconScaleAnimation;
  final Color activeColor;
  final Color inactiveColor;
  final DashboardPerformanceCounters? performanceCounters;
  final ValueChanged<TransactionDirection> onTap;
  final GestureDragStartCallback? onVerticalDragStart;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    final labelColor = Color.lerp(
      inactiveColor,
      activeColor,
      activeWeight.clamp(0.0, 1.0),
    )!;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(direction),
        onVerticalDragStart: onVerticalDragStart,
        onVerticalDragUpdate: onVerticalDragUpdate,
        onVerticalDragEnd: onVerticalDragEnd,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (showsArtwork) ...<Widget>[
                _DirectionIcon(
                  picture: picture,
                  assetKey: assetKey,
                  iconScale: iconScale,
                  iconScaleAnimation: iconScaleAnimation,
                  performanceCounters: performanceCounters,
                ),
                const SizedBox(width: FluviVisualTokens.controlInnerGap),
              ],
              Text(
                label,
                style: FluviVisualTokens.actionLabelTextStyle.copyWith(
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectionButton extends StatelessWidget {
  const _DirectionButton({
    required this.direction,
    required this.label,
    required this.picture,
    required this.assetKey,
    required this.activeGradient,
    required this.selected,
    required this.iconScale,
    required this.showsArtwork,
    required this.iconScaleAnimation,
    required this.onTap,
    required this.performanceCounters,
    required this.borderRadius,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  final TransactionDirection direction;
  final String label;
  final PreparedVectorPicture picture;
  final Key assetKey;
  final LinearGradient activeGradient;
  final bool selected;
  final double iconScale;
  final bool showsArtwork;
  final Animation<double>? iconScaleAnimation;
  final ValueChanged<TransactionDirection> onTap;
  final DashboardPerformanceCounters? performanceCounters;
  final BorderRadius borderRadius;
  final GestureDragStartCallback? onVerticalDragStart;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    final depth = DashboardShadowStyleScope.profileOf(
      context,
    ).depthFor(DashboardCornerSurfaceFamily.directionControl);
    return GestureDetector(
      onTap: () => onTap(direction),
      onVerticalDragStart: onVerticalDragStart,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      child: SizedBox(
        height: AppSelectorMetrics.directionControlHeight,
        child: FluviRoundedBox(
          key: assetKey == const ValueKey('fluvi-income-wallet')
              ? const ValueKey('fluvi-income-button')
              : const ValueKey('fluvi-expense-button'),
          color: selected
              ? null
              : (depth.surfaceColor ?? FluviVisualTokens.surface),
          gradient: selected ? activeGradient : null,
          border: DashboardBorderScope.profileOf(context).borderFor(
            direction == TransactionDirection.income
                ? DashboardBorderSurface.incomeDirection
                : DashboardBorderSurface.expenseDirection,
          ),
          borderRadius: borderRadius,
          boxShadow: depth.shadows,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showsArtwork) ...<Widget>[
                  _DirectionIcon(
                    picture: picture,
                    assetKey: assetKey,
                    iconScale: iconScale,
                    iconScaleAnimation: iconScaleAnimation,
                    performanceCounters: performanceCounters,
                  ),
                  const SizedBox(width: FluviVisualTokens.controlInnerGap),
                ],
                Text(
                  label,
                  style: selected
                      ? FluviVisualTokens.actionLabelOnActiveTextStyle
                      : FluviVisualTokens.actionLabelTextStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectionIcon extends StatelessWidget {
  const _DirectionIcon({
    required this.picture,
    required this.assetKey,
    required this.iconScale,
    required this.iconScaleAnimation,
    required this.performanceCounters,
  });

  final PreparedVectorPicture picture;
  final Key assetKey;
  final double iconScale;
  final Animation<double>? iconScaleAnimation;
  final DashboardPerformanceCounters? performanceCounters;

  @override
  Widget build(BuildContext context) {
    performanceCounters?.increment(
      DashboardPerformanceMetric.svgPulseSubtreeBuild,
    );
    final icon = PreparedVectorPictureView(
      picture: picture,
      key: assetKey,
      width: FluviVisualTokens.actionIconSize,
      height: FluviVisualTokens.actionIconSize,
    );
    final animation = iconScaleAnimation;
    if (animation == null) return _scaledIcon(iconScale, icon);
    return AnimatedBuilder(
      animation: animation,
      child: icon,
      builder: (context, child) => _scaledIcon(animation.value, child!),
    );
  }

  Widget _scaledIcon(double scale, Widget child) => Transform.scale(
    scale: scale * FluviVisualTokens.directionIconScaleMultiplier,
    child: child,
  );
}
