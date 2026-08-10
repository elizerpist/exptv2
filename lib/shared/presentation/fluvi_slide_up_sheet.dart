import 'package:flutter/material.dart';

/// Query-agnostic application sheet shell shared by transient Fluvi flows.
///
/// It owns layering and route-local interaction only. Feature content,
/// persistence and navigation remain outside this widget.
final class FluviSlideUpSheet extends StatefulWidget {
  const FluviSlideUpSheet({
    super.key,
    required this.isOpen,
    required this.child,
    this.stickyFooter,
    this.onDismiss,
    this.dismissOnScrimTap = true,
    this.duration = const Duration(milliseconds: 260),
    this.curve = const Cubic(0.2, 0.85, 0.25, 1),
  });

  static const sheetKey = ValueKey<String>('fluvi-slide-up-sheet');
  static const scrimKey = ValueKey<String>('fluvi-slide-up-sheet-scrim');

  final bool isOpen;
  final Widget child;
  final Widget? stickyFooter;
  final VoidCallback? onDismiss;
  final bool dismissOnScrimTap;
  final Duration duration;
  final Curve curve;

  @override
  State<FluviSlideUpSheet> createState() => _FluviSlideUpSheetState();
}

final class _FluviSlideUpSheetState extends State<FluviSlideUpSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late CurvedAnimation _sheetAnimation;
  bool _mountedInLayer = false;

  @override
  void initState() {
    super.initState();
    _mountedInLayer = widget.isOpen;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _sheetAnimation = CurvedAnimation(parent: _controller, curve: widget.curve);
    if (widget.isOpen) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant FluviSlideUpSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.curve != widget.curve) {
      _sheetAnimation.dispose();
      _sheetAnimation = CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      );
    }
    if (widget.isOpen == oldWidget.isOpen) return;
    if (widget.isOpen) {
      setState(() => _mountedInLayer = true);
      _controller.forward();
      return;
    }
    _controller.reverse().whenComplete(() {
      if (mounted && !widget.isOpen) setState(() => _mountedInLayer = false);
    });
  }

  @override
  void dispose() {
    _sheetAnimation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_mountedInLayer) return const SizedBox.shrink();
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !widget.isOpen && _controller.isDismissed,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FadeTransition(
              opacity: _sheetAnimation,
              child: GestureDetector(
                key: FluviSlideUpSheet.scrimKey,
                behavior: HitTestBehavior.opaque,
                onTap: widget.dismissOnScrimTap ? widget.onDismiss : null,
                child: const ColoredBox(color: Color(0x8F0D172E)),
              ),
            ),
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1.02),
                end: Offset.zero,
              ).animate(_sheetAnimation),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: RepaintBoundary(
                  child: Material(
                    key: FluviSlideUpSheet.sheetKey,
                    color: Colors.white,
                    clipBehavior: Clip.antiAlias,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: viewInsets.bottom),
                        child: FocusScope(
                          autofocus: widget.isOpen,
                          child: Column(
                            children: [
                              const _SheetGrabber(),
                              Expanded(child: widget.child),
                              ?widget.stickyFooter,
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
    );
  }
}

final class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 12, bottom: 14),
    child: SizedBox(
      width: 37,
      height: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFFB8C2D3),
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
      ),
    ),
  );
}
