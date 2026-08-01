import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';

/// Shared collapse handle that forwards supplied tap and vertical gesture intents.
class DashboardCollapseHandle extends StatefulWidget {
  const DashboardCollapseHandle({
    super.key,
    required this.bounds,
    required this.onTap,
    this.isDragging = false,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  final DashboardBounds bounds;
  final VoidCallback onTap;
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: isHighlighted
                  ? null
                  : FluviVisualTokens.appHighlightGradient,
              color: isHighlighted
                  ? FluviVisualTokens.appHighlightPressedColor
                  : null,
              borderRadius: FluviVisualTokens.handleRadius,
              boxShadow: const [FluviVisualTokens.appHighlightShadow],
            ),
            child: const SizedBox(
              width: FluviVisualTokens.handleBarWidth,
              height: FluviVisualTokens.handleBarHeight,
            ),
          ),
        ),
      ),
    );
  }
}
