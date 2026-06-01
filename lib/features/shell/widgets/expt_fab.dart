import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/debug/debug_console.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';

class ExptFab extends StatefulWidget {
  const ExptFab({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.onDoubleTap,
  });

  static const doubleTapWindow = Duration(milliseconds: 120);

  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;

  @override
  State<ExptFab> createState() => _ExptFabState();
}

class _ExptFabState extends State<ExptFab> {
  Timer? _singleTapTimer;
  DateTime? _pendingTapStartedAt;

  @override
  void dispose() {
    _singleTapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: const ValueKey('expt-fab'),
      dimension: AppDimensions.fabSize,
      child: Material(
        color: AppColors.primary,
        elevation: 5,
        shadowColor: AppColors.fabShadow,
        shape: const CircleBorder(),
        child: InkResponse(
          containedInkWell: true,
          customBorder: const CircleBorder(),
          highlightColor: Colors.white30,
          onTap: _handleTap,
          onLongPress: _handleLongPress,
          child: Icon(
            Icons.add,
            color: AppColors.white,
            size: AppDimensions.fabSize * AppDimensions.fabIconScale,
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    final pending = _singleTapTimer;
    if (pending != null && pending.isActive) {
      pending.cancel();
      final elapsed = _elapsedMs(_pendingTapStartedAt);
      _pendingTapStartedAt = null;
      DebugConsole.log('[FAB] double tap dispatch elapsed=${elapsed}ms');
      (widget.onDoubleTap ?? widget.onPressed).call();
      return;
    }

    _pendingTapStartedAt = DateTime.now();
    DebugConsole.log(
      '[FAB] tap received single pending window=${ExptFab.doubleTapWindow.inMilliseconds}ms',
    );
    _singleTapTimer?.cancel();
    _singleTapTimer = Timer(ExptFab.doubleTapWindow, () {
      if (!mounted) return;
      final elapsed = _elapsedMs(_pendingTapStartedAt);
      _pendingTapStartedAt = null;
      DebugConsole.log('[FAB] single tap dispatch delay=${elapsed}ms');
      widget.onPressed();
    });
  }

  void _handleLongPress() {
    _singleTapTimer?.cancel();
    _pendingTapStartedAt = null;
    DebugConsole.log('[FAB] long press dispatch');
    widget.onLongPress?.call();
  }

  int _elapsedMs(DateTime? startedAt) {
    if (startedAt == null) return 0;
    return DateTime.now().difference(startedAt).inMilliseconds;
  }
}
