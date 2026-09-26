import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_global_appearance.dart';

/// Shared collapse handle that forwards supplied tap and vertical gesture intents.
class DashboardCollapseHandle extends StatefulWidget {
  const DashboardCollapseHandle({
    super.key,
    required this.bounds,
    required this.onTap,
    this.style = FluviCollapseHandleStyle.standalone,
    this.isDragging = false,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  final DashboardBounds bounds;
  final VoidCallback onTap;
  final FluviCollapseHandleStyle style;
  final bool isDragging;
  final GestureDragStartCallback? onVerticalDragStart;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;

  @override
  State<DashboardCollapseHandle> createState() =>
      _DashboardCollapseHandleState();
}

class _DashboardCollapseHandleState extends State<DashboardCollapseHandle> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value || !mounted) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isHighlighted = _isPressed || widget.isDragging;
    final integrated = widget.style != FluviCollapseHandleStyle.standalone;
    final bar = DecoratedBox(
      decoration: BoxDecoration(
        color: isHighlighted
            ? FluviVisualTokens.appHighlightPressedColor
            : FluviVisualTokens.collapseHandleIdleColor,
        borderRadius: FluviVisualTokens.handleRadius,
        boxShadow: const [FluviVisualTokens.appHighlightShadow],
      ),
      child: const SizedBox(
        width: FluviVisualTokens.handleBarWidth,
        height: FluviVisualTokens.handleBarHeight,
      ),
    );
    return SizedBox(
      width: widget.bounds.width,
      height: widget.bounds.height,
      child: GestureDetector(
        key: const ValueKey('dashboard-collapse-handle'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onVerticalDragStart: widget.onVerticalDragStart,
        onVerticalDragUpdate: widget.onVerticalDragUpdate,
        onVerticalDragEnd: widget.onVerticalDragEnd,
        child: Center(
          child: integrated
              ? _IntegratedHandleChrome(style: widget.style, child: bar)
              : bar,
        ),
      ),
    );
  }
}

/// Visual chrome only. Gesture ownership remains the single parent detector.
final class _IntegratedHandleChrome extends StatelessWidget {
  const _IntegratedHandleChrome({required this.style, required this.child});

  final FluviCollapseHandleStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isNotch = style == FluviCollapseHandleStyle.headerNotch;
    return DecoratedBox(
      key: ValueKey<String>('dashboard-collapse-handle-${style.name}'),
      decoration: BoxDecoration(
        color: isNotch
            ? FluviVisualTokens.surface
            : Colors.white.withValues(alpha: .58),
        borderRadius: isNotch
            ? const BorderRadius.vertical(top: Radius.circular(14))
            : BorderRadius.circular(99),
        border: isNotch
            ? null
            : Border.all(color: Colors.white.withValues(alpha: .72)),
        boxShadow: isNotch
            ? const <BoxShadow>[]
            : const <BoxShadow>[
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: SizedBox.expand(child: Center(child: child)),
    );
  }
}
