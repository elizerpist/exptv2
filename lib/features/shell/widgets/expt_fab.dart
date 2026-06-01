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

  static const doubleTapWindow = Duration(milliseconds: 180);
  static const singleTapDispatchDelay = Duration.zero;

  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;

  @override
  State<ExptFab> createState() => _ExptFabState();
}

class _ExptFabState extends State<ExptFab> {
  Timer? _singleTapTimer;
  Timer? _doubleTapTimer;
  DateTime? _pendingTapStartedAt;
  var _singleTapDispatched = false;

  @override
  void dispose() {
    _singleTapTimer?.cancel();
    _doubleTapTimer?.cancel();
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
    if (_pendingTapStartedAt != null) {
      _singleTapTimer?.cancel();
      _doubleTapTimer?.cancel();
      final elapsed = _elapsedMs(_pendingTapStartedAt);
      final singleDispatched = _singleTapDispatched;
      _clearTapState();
      DebugConsole.log(
        '[FAB] double tap dispatch '
        'elapsed=${elapsed}ms singleDispatched=$singleDispatched',
      );
      widget.onDoubleTap?.call();
      return;
    }

    _pendingTapStartedAt = DateTime.now();
    _singleTapDispatched = true;
    DebugConsole.log(
      '[FAB] single tap immediate dispatch '
      'window=${ExptFab.doubleTapWindow.inMilliseconds}ms',
    );
    _singleTapTimer?.cancel();
    _doubleTapTimer?.cancel();
    widget.onPressed();
    _doubleTapTimer = Timer(ExptFab.doubleTapWindow, () {
      if (!mounted || _pendingTapStartedAt == null) return;
      final elapsed = _elapsedMs(_pendingTapStartedAt);
      _clearTapState();
      DebugConsole.log('[FAB] double tap window expired elapsed=${elapsed}ms');
    });
  }

  void _handleLongPress() {
    _singleTapTimer?.cancel();
    _doubleTapTimer?.cancel();
    _clearTapState();
    DebugConsole.log('[FAB] long press dispatch');
    widget.onLongPress?.call();
  }

  void _clearTapState() {
    _singleTapTimer = null;
    _doubleTapTimer = null;
    _pendingTapStartedAt = null;
    _singleTapDispatched = false;
  }

  int _elapsedMs(DateTime? startedAt) {
    if (startedAt == null) return 0;
    return DateTime.now().difference(startedAt).inMilliseconds;
  }
}
