import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Clips a sliver's full scroll extent to a rounded rectangle.
///
/// Unlike a box [ClipRRect], this keeps a long lazy sliver lazy: the rounded
/// leading/trailing edges stay attached to the complete group while its rows
/// are built only around the viewport.
class SliverClipRRect extends SingleChildRenderObjectWidget {
  const SliverClipRRect({
    required this.borderRadius,
    required Widget sliver,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  }) : super(child: sliver);

  final BorderRadiusGeometry borderRadius;
  final Clip clipBehavior;

  @override
  RenderSliverClipRRect createRenderObject(BuildContext context) {
    return RenderSliverClipRRect(
      borderRadius: borderRadius,
      textDirection: Directionality.maybeOf(context),
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverClipRRect renderObject,
  ) {
    renderObject
      ..borderRadius = borderRadius
      ..textDirection = Directionality.maybeOf(context)
      ..clipBehavior = clipBehavior;
  }
}

class RenderSliverClipRRect extends RenderProxySliver {
  RenderSliverClipRRect({
    required BorderRadiusGeometry borderRadius,
    required TextDirection? textDirection,
    required Clip clipBehavior,
  }) : _borderRadius = borderRadius,
       _textDirection = textDirection,
       _clipBehavior = clipBehavior;

  BorderRadiusGeometry _borderRadius;
  TextDirection? _textDirection;
  Clip _clipBehavior;

  set borderRadius(BorderRadiusGeometry value) {
    if (value == _borderRadius) return;
    _borderRadius = value;
    markNeedsPaint();
  }

  set textDirection(TextDirection? value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsPaint();
  }

  set clipBehavior(Clip value) {
    if (value == _clipBehavior) return;
    _clipBehavior = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || geometry == null || geometry!.paintExtent <= 0) {
      return;
    }
    final clipRect =
        Offset.zero & Size(constraints.crossAxisExtent, geometry!.scrollExtent);
    context.pushClipRRect(
      needsCompositing,
      offset,
      clipRect,
      _borderRadius.resolve(_textDirection).toRRect(clipRect),
      super.paint,
      clipBehavior: _clipBehavior,
    );
  }
}
