import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/header_cascade_motion.dart';
import 'dashboard_upper_avatar_cascade_motion.dart';

/// One master frame supplies the accepted lower transform and upper cascade.
/// No layout measurements, controllers or independently eased tracks are used.
class BalanceFocusedCascadeScope extends InheritedWidget {
  const BalanceFocusedCascadeScope({
    super.key,
    required this.frame,
    required this.lowerTransform,
    required this.lowerOpacity,
    required super.child,
  });
  final DashboardLayoutFrame frame;
  final Matrix4 lowerTransform;
  final double lowerOpacity;
  static BalanceFocusedCascadeScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BalanceFocusedCascadeScope>();

  CascadedCardMotion get upperMotion =>
      DashboardUpperAvatarCascadeMotion.resolve(frame);

  Matrix4 get upperTransform {
    if (frame.headerExpansionProgress == 1) return Matrix4.identity();
    final motion = upperMotion;
    final header = frame.headerBounds;
    final canvasWidth = header.width + 2 * header.left;
    final layoutWidth = canvasWidth - motion.left - motion.right;
    final scale = layoutWidth * motion.scale / header.width;
    final left = motion.left + layoutWidth * (1 - motion.scale) / 2;
    // The lower analytical subtree keeps [lowerTransform] exactly as authored.
    // The selector samples its complete lower-cascade origin at the retimed
    // separation, including the lower lane's own shift. That prevents the
    // inherited lower transform from pulling the avatar row under the Header
    // before the content/selector crossing is visible.
    final visualSeparation =
        DashboardUpperAvatarCascadeMotion.retimedSeparation(
          1 - frame.headerExpansionProgress,
        );
    final visualLower = HeaderCascadeMotion.calculate(
      masterProgress: 1 - visualSeparation,
      geometry: frame.motherCardCascadeGeometry,
    ).lower;
    final visualTargetTop =
        visualLower.top + frame.modeContentBounds.top - frame.zone2Bounds.top;
    final visualZone2Shift = visualLower.top - frame.zone2Bounds.top;
    final visualLowerContentOrigin =
        header.bottom +
        (visualTargetTop - header.bottom) * visualSeparation +
        visualZone2Shift;
    final upperContentOrigin =
        visualLowerContentOrigin +
        motion.top -
        frame.motherCardCascadeGeometry.upperExpandedTop;
    return Matrix4.identity()
      ..translateByDouble(
        left - header.left * scale,
        upperContentOrigin - header.bottom * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  /// The selector already inherits lower and compact-canvas transforms. Undo
  /// them in their proper coordinate system before applying the upper track.
  Matrix4 selectorCompensation(Matrix4 authoredToViewport) {
    // Preserve endpoint raster parity; inverse(A) * A can otherwise retain a
    // fractional rounding residue despite its mathematically exact identity.
    if (frame.headerExpansionProgress == 1) return Matrix4.identity();
    return Matrix4.inverted(authoredToViewport)
      ..multiply(Matrix4.inverted(lowerTransform))
      ..multiply(upperTransform)
      ..multiply(authoredToViewport);
  }

  @override
  bool updateShouldNotify(BalanceFocusedCascadeScope oldWidget) =>
      oldWidget.frame != frame ||
      oldWidget.lowerTransform != lowerTransform ||
      oldWidget.lowerOpacity != lowerOpacity;
}

/// Deterministic layout mapping, including the compact FittedBox allocation.
class BalanceFocusedCanvasScope extends InheritedWidget {
  const BalanceFocusedCanvasScope({
    super.key,
    required this.localToViewport,
    required super.child,
  });
  final Matrix4 localToViewport;
  static BalanceFocusedCanvasScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BalanceFocusedCanvasScope>();
  @override
  bool updateShouldNotify(BalanceFocusedCanvasScope oldWidget) =>
      oldWidget.localToViewport != localToViewport;
}

/// Keeps the authored flex allocations and persistent children while painting
/// the selector and analytical children with distinct cascade opacity tracks.
class BalanceFocusedCascadeColumn extends StatelessWidget {
  const BalanceFocusedCascadeColumn({
    super.key,
    required this.children,
    required this.horizontalPadding,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });
  final List<Widget> children;
  final double horizontalPadding;
  final CrossAxisAlignment crossAxisAlignment;
  @override
  Widget build(BuildContext context) {
    final scope = BalanceFocusedCascadeScope.maybeOf(context);
    final canvas = BalanceFocusedCanvasScope.maybeOf(context);
    final mapping = Matrix4.copy(canvas?.localToViewport ?? Matrix4.identity())
      ..translateByDouble(horizontalPadding, 0, 0, 1);
    Widget lower(Widget child) =>
        BalanceCascadeOpacity(opacity: scope?.lowerOpacity ?? 1, child: child);
    Widget preserveFlex(Widget child) {
      if (child is Expanded) {
        return Expanded(
          key: child.key,
          flex: child.flex,
          child: lower(child.child),
        );
      }
      if (child is Flexible) {
        return Flexible(
          key: child.key,
          flex: child.flex,
          fit: child.fit,
          child: lower(child.child),
        );
      }
      return lower(child);
    }

    return _BalanceFocusedCascadePaintColumn(
      key: const ValueKey('balance-focused-cascade-paint-order'),
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++)
          if (i == 0)
            BalanceCascadeOpacity(
              key: const ValueKey('balance-upper-cascade-opacity'),
              opacity: scope?.upperMotion.opacity ?? 1,
              child: Transform(
                key: const ValueKey('balance-upper-cascade-transform'),
                alignment: Alignment.topLeft,
                transform:
                    scope?.selectorCompensation(mapping) ?? Matrix4.identity(),
                child: children[i],
              ),
            )
          else
            preserveFlex(children[i]),
      ],
    );
  }
}

/// Retains the authored Flex layout and child identity while painting the first
/// selector child after the lower analytical children. The visual order is
/// therefore Mother Card → lower content → selector; the Header remains a
/// later sibling of the entire Balance content layer.
final class _BalanceFocusedCascadePaintColumn extends Column {
  const _BalanceFocusedCascadePaintColumn({
    super.key,
    required super.children,
    required super.crossAxisAlignment,
  });

  @override
  RenderFlex createRenderObject(BuildContext context) =>
      _RenderBalanceFocusedCascadePaintColumn(
        direction: direction,
        mainAxisAlignment: mainAxisAlignment,
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: crossAxisAlignment,
        textDirection: getEffectiveTextDirection(context),
        verticalDirection: verticalDirection,
        textBaseline: textBaseline,
        clipBehavior: clipBehavior,
        spacing: spacing,
      );
}

final class _RenderBalanceFocusedCascadePaintColumn extends RenderFlex {
  _RenderBalanceFocusedCascadePaintColumn({
    required super.direction,
    required super.mainAxisAlignment,
    required super.mainAxisSize,
    required super.crossAxisAlignment,
    required super.textDirection,
    required super.verticalDirection,
    required super.textBaseline,
    required super.clipBehavior,
    required super.spacing,
  });

  void _paintChild(PaintingContext context, Offset offset, RenderBox child) {
    final parentData = child.parentData! as FlexParentData;
    context.paintChild(child, parentData.offset + offset);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final upper = firstChild;
    for (
      RenderBox? child = upper == null ? null : childAfter(upper);
      child != null;
      child = childAfter(child)
    ) {
      _paintChild(context, offset, child);
    }
    if (upper != null) _paintChild(context, offset, upper);
  }

  bool _hitTestChild(
    BoxHitTestResult result,
    Offset position,
    RenderBox child,
  ) {
    final parentData = child.parentData! as FlexParentData;
    return result.addWithPaintOffset(
      offset: parentData.offset,
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final upper = firstChild;
    if (upper != null && _hitTestChild(result, position, upper)) return true;
    for (
      RenderBox? child = lastChild;
      child != null && child != upper;
      child = childBefore(child)
    ) {
      if (_hitTestChild(result, position, child)) return true;
    }
    return false;
  }
}

/// Opacity with an exact opaque paint path. Unlike RenderOpacity's permanent
/// repaint boundary at alpha=255, this preserves the original expanded shader
/// raster coordinates. The same render object stays mounted at every phase.
class BalanceCascadeOpacity extends SingleChildRenderObjectWidget {
  const BalanceCascadeOpacity({
    super.key,
    required this.opacity,
    required super.child,
  });
  final double opacity;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderBalanceCascadeOpacity(opacity);
  @override
  void updateRenderObject(
    BuildContext context,
    RenderBalanceCascadeOpacity renderObject,
  ) {
    renderObject.opacity = opacity;
  }
}

class RenderBalanceCascadeOpacity extends RenderProxyBox {
  RenderBalanceCascadeOpacity(this._opacity);
  double _opacity;
  final _opacityLayer = LayerHandle<OpacityLayer>();
  int get _alpha => Color.getAlphaFromOpacity(_opacity);
  set opacity(double value) {
    if (_opacity == value) return;
    final composited = alwaysNeedsCompositing;
    final wasVisible = _alpha > 0;
    _opacity = value;
    if (composited != alwaysNeedsCompositing) markNeedsCompositingBitsUpdate();
    if (wasVisible != (_alpha > 0)) markNeedsSemanticsUpdate();
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing =>
      child != null && _alpha > 0 && _alpha < 255;
  @override
  bool paintsChild(RenderBox child) => _alpha > 0;
  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || _alpha == 0) {
      _opacityLayer.layer = null;
      return;
    }
    if (_alpha == 255) {
      _opacityLayer.layer = null;
      super.paint(context, offset);
      return;
    }
    _opacityLayer.layer = context.pushOpacity(
      offset,
      _alpha,
      super.paint,
      oldLayer: _opacityLayer.layer,
    );
  }

  @override
  void dispose() {
    _opacityLayer.layer = null;
    super.dispose();
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (_alpha > 0) super.visitChildrenForSemantics(visitor);
  }
}
