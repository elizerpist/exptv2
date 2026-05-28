import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SlideUpMenuCard extends StatefulWidget {
  const SlideUpMenuCard({
    super.key,
    required this.cardKey,
    required this.child,
    this.onDismissed,
    this.zIndexShadow = true,
  });

  final Key cardKey;
  final Widget child;
  final VoidCallback? onDismissed;
  final bool zIndexShadow;

  @override
  State<SlideUpMenuCard> createState() => _SlideUpMenuCardState();
}

class _SlideUpMenuCardState extends State<SlideUpMenuCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  double _dragDy = 0;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 192),
      reverseDuration: const Duration(milliseconds: 160),
    )..forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        return AnimatedBuilder(
          animation: _entry,
          builder: (context, child) {
            final entryOffset =
                (1 - Curves.easeOutCubic.transform(_entry.value)) * height;
            return Transform.translate(
              key: widget.cardKey,
              offset: Offset(0, entryOffset + _dragDy),
              child: child,
            );
          },
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _handlePointerDown,
            onPointerMove: _handlePointerMove,
            onPointerUp: _handlePointerUp,
            onPointerCancel: (_) => _snapBack(),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                border: Border.all(color: AppColors.gray200),
                boxShadow: widget.zIndexShadow
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          offset: const Offset(0, -2),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_closing) return;
    _dragDy = 0;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_closing) return;
    setState(() {
      _dragDy = (_dragDy + event.delta.dy).clamp(-42.0, 220.0).toDouble();
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_dragDy > 90) {
      _dismiss();
      return;
    }
    _snapBack();
  }

  void _snapBack() {
    if (!mounted || _closing) return;
    setState(() => _dragDy = 0);
  }

  Future<void> _dismiss() async {
    if (_closing) return;
    _closing = true;
    setState(() => _dragDy = 0);
    await _entry.reverse();
    if (mounted) widget.onDismissed?.call();
  }
}
