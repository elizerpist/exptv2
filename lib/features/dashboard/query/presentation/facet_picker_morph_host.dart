import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'query_menu_tokens.dart';

/// One sheet-local expansion mechanism for both category and partner pickers.
///
/// It is deliberately an overlay inside the existing [FluviSlideUpSheet]
/// content, rather than a second bottom sheet or a route. The origin control
/// supplies the circle centre so opening and closing preserve context.
final class FacetPickerMorphHost<T> extends StatefulWidget {
  const FacetPickerMorphHost({
    super.key,
    required this.isOpen,
    required this.sourceKey,
    required this.title,
    required this.caption,
    required this.selectionLabel,
    required this.items,
    required this.rowBuilder,
    required this.onClose,
  });

  final bool isOpen;
  final GlobalKey sourceKey;
  final String title;
  final String caption;
  final String selectionLabel;
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) rowBuilder;
  final VoidCallback onClose;

  @override
  State<FacetPickerMorphHost<T>> createState() =>
      _FacetPickerMorphHostState<T>();
}

final class _FacetPickerMorphHostState<T> extends State<FacetPickerMorphHost<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _origin = const Offset(.5, .72);
  bool _mountedInStack = false;

  @override
  void initState() {
    super.initState();
    _mountedInStack = widget.isOpen;
    _controller = AnimationController(
      vsync: this,
      duration: QueryMenuTokens.morphDuration,
      reverseDuration: const Duration(milliseconds: 220),
    );
    if (widget.isOpen) {
      _controller.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _captureOrigin());
    }
  }

  @override
  void didUpdateWidget(covariant FacetPickerMorphHost<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOpen == widget.isOpen) return;
    if (widget.isOpen) {
      setState(() => _mountedInStack = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _captureOrigin();
        if (mounted) _controller.forward(from: 0);
      });
      return;
    }
    _controller.reverse().whenComplete(() {
      if (mounted && !widget.isOpen) setState(() => _mountedInStack = false);
    });
  }

  void _captureOrigin() {
    final host = context.findRenderObject();
    final source = widget.sourceKey.currentContext?.findRenderObject();
    if (host is! RenderBox || source is! RenderBox || !host.hasSize) return;
    final local = host.globalToLocal(
      source.localToGlobal(source.size.center(Offset.zero)),
    );
    setState(() => _origin = local);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_mountedInStack) return const SizedBox.shrink();
    final curve = CurvedAnimation(
      parent: _controller,
      curve: QueryMenuTokens.sheetCurve,
    );
    final content = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.28, 1, curve: Curves.easeOut),
      reverseCurve: const Interval(0, .72, curve: Curves.easeIn),
    );
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_controller.isAnimating && !widget.isOpen,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => ClipPath(
            clipper: _OriginCircleClipper(
              origin: _origin,
              progress: curve.value,
            ),
            child: ColoredBox(
              color: QueryMenuTokens.sheet,
              child: FadeTransition(
                opacity: content,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, .025),
                    end: Offset.zero,
                  ).animate(content),
                  child: _FacetPickerPage<T>(
                    title: widget.title,
                    caption: widget.caption,
                    selectionLabel: widget.selectionLabel,
                    items: widget.items,
                    rowBuilder: widget.rowBuilder,
                    onClose: widget.onClose,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _OriginCircleClipper extends CustomClipper<Path> {
  const _OriginCircleClipper({required this.origin, required this.progress});

  final Offset origin;
  final double progress;

  @override
  Path getClip(Size size) {
    final farthest = <double>[
      (origin - Offset.zero).distance,
      (origin - Offset(size.width, 0)).distance,
      (origin - Offset(0, size.height)).distance,
      (origin - Offset(size.width, size.height)).distance,
    ].reduce(math.max);
    final radius = 18 + (farthest + 24 - 18) * progress;
    return Path()..addOval(Rect.fromCircle(center: origin, radius: radius));
  }

  @override
  bool shouldReclip(_OriginCircleClipper oldClipper) =>
      oldClipper.origin != origin || oldClipper.progress != progress;
}

final class _FacetPickerPage<T> extends StatelessWidget {
  const _FacetPickerPage({
    required this.title,
    required this.caption,
    required this.selectionLabel,
    required this.items,
    required this.rowBuilder,
    required this.onClose,
  });

  final String title;
  final String caption;
  final String selectionLabel;
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) rowBuilder;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: QueryMenuTokens.screenInset,
          ),
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('facet-picker-back'),
                  onPressed: onClose,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: QueryMenuTokens.textPrimary,
                  tooltip: 'Vissza',
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: QueryMenuTokens.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.35,
                    ),
                  ),
                ),
                TextButton(
                  key: const ValueKey('facet-picker-done'),
                  onPressed: onClose,
                  child: const Text('Kész'),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              caption,
              style: const TextStyle(
                color: QueryMenuTokens.textSecondary,
                fontSize: 10,
                height: 1.5,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              selectionLabel,
              style: const TextStyle(
                color: QueryMenuTokens.textAccent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            key: const ValueKey('facet-picker-list'),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                rowBuilder(context, items[index], index),
          ),
        ),
      ],
    ),
  );
}
