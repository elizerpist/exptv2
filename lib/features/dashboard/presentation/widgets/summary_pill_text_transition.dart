import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../time_navigation/application/summary_timing_debug.dart';
import '../../time_navigation/presentation/summary_navigation_presentation.dart';

export '../../time_navigation/presentation/summary_navigation_presentation.dart'
    show SummaryTransitionDirection, SummaryTransitionAxis;

@immutable
class SummaryTextContent {
  const SummaryTextContent({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  bool operator ==(Object other) {
    return other is SummaryTextContent &&
        other.title == title &&
        other.subtitle == subtitle;
  }

  @override
  int get hashCode => Object.hash(title, subtitle);
}

@immutable
class SummaryPillTransitionOffsets {
  const SummaryPillTransitionOffsets({
    required this.incoming,
    required this.outgoing,
  });

  final Offset incoming;
  final Offset outgoing;
}

abstract final class SummaryPillTextTransitionMath {
  static SummaryPillTransitionOffsets verticalOffsets(
    double animationValue,
    SummaryTransitionDirection direction, {
    double incomingDistance = 12,
    double outgoingDistance = 8,
  }) {
    final signedDirection = direction == SummaryTransitionDirection.forward
        ? 1.0
        : -1.0;
    return SummaryPillTransitionOffsets(
      incoming: Offset(
        0,
        (1 - animationValue) * incomingDistance * signedDirection,
      ),
      outgoing: Offset(0, -animationValue * outgoingDistance * signedDirection),
    );
  }

  static SummaryPillTransitionOffsets horizontalOffsets(
    double animationValue,
    SummaryTransitionDirection direction,
  ) {
    final signedDirection = direction == SummaryTransitionDirection.forward
        ? 1.0
        : -1.0;
    return SummaryPillTransitionOffsets(
      incoming: Offset((1 - animationValue) * 10 * signedDirection, 0),
      outgoing: Offset(-animationValue * 8 * signedDirection, 0),
    );
  }
}

class SummaryPillTextTransition extends StatefulWidget {
  const SummaryPillTextTransition({
    super.key,
    required this.content,
    required this.axis,
    required this.direction,
    this.animate = true,
    this.animateTitle = true,
    this.compact = false,
    this.height = 36,
    this.duration = const Duration(milliseconds: 190),
  });

  final SummaryTextContent content;
  final SummaryTransitionAxis axis;
  final SummaryTransitionDirection direction;
  final bool animate;
  final bool animateTitle;
  final bool compact;
  final double height;
  final Duration duration;

  @override
  State<SummaryPillTextTransition> createState() =>
      _SummaryPillTextTransitionState();
}

class _SummaryPillTextTransitionState extends State<SummaryPillTextTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late SummaryTextContent _current;
  SummaryTextContent? _previous;
  int _generation = 0;
  AnimationStatusListener? _activeStatusListener;

  @override
  void initState() {
    super.initState();
    _current = widget.content;
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant SummaryPillTextTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    final contentChanged = oldWidget.content != widget.content;
    final shouldAnimate =
        widget.animate && widget.axis != SummaryTransitionAxis.none;
    if (!shouldAnimate) {
      _cancelActiveTransition();
      _current = widget.content;
      _previous = null;
      _animationController.value = 1;
      return;
    }
    if (!contentChanged) {
      final motionPolicyChanged =
          oldWidget.axis != widget.axis ||
          oldWidget.direction != widget.direction ||
          oldWidget.animate != widget.animate ||
          oldWidget.animateTitle != widget.animateTitle;
      if (motionPolicyChanged) {
        _cancelActiveTransition();
        _previous = null;
        _animationController.value = 1;
      }
      return;
    }

    _cancelActiveTransition();
    final generation = ++_generation;

    final previous = _current;
    _current = widget.content;
    _previous = widget.axis == SummaryTransitionAxis.none ? null : previous;
    _animationController.duration = widget.duration;

    if (_previous == null) {
      _animationController.value = 1;
      return;
    }

    DashboardSummaryTimingDebug.mark(
      'S8 committedTextTransitionStarted',
      value: widget.content.subtitle,
    );
    final listener = (AnimationStatus status) {
      if (status != AnimationStatus.completed || generation != _generation) {
        return;
      }
      if (!mounted) return;
      setState(() => _previous = null);
      _activeStatusListener = null;
    };
    _activeStatusListener = listener;
    _animationController.addStatusListener(listener);
    _animationController
      ..value = 0
      ..forward();
  }

  void _cancelActiveTransition() {
    final oldListener = _activeStatusListener;
    if (oldListener != null) {
      _animationController.removeStatusListener(oldListener);
      _activeStatusListener = null;
    }
    _animationController.stop();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        final value = Curves.easeOutCubic.transform(_animationController.value);
        if (_previous == null || widget.axis == SummaryTransitionAxis.none) {
          return _fixedContent(_current, animateTitle: widget.animateTitle);
        }

        final offsets = widget.axis == SummaryTransitionAxis.vertical
            ? SummaryPillTextTransitionMath.verticalOffsets(
                value,
                widget.direction,
                incomingDistance: widget.compact ? 5 : 12,
                outgoingDistance: widget.compact ? 4 : 8,
              )
            : SummaryPillTextTransitionMath.horizontalOffsets(
                value,
                widget.direction,
              );

        if (!widget.animateTitle) {
          return _fixedTitleWithSubtitleTransition(value, offsets);
        }

        return SizedBox(
          height: widget.height,
          width: double.infinity,
          child: ClipRect(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Opacity(
                  opacity: 1 - value,
                  child: Transform.translate(
                    offset: offsets.outgoing,
                    child: _textContent(_previous!),
                  ),
                ),
                Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: offsets.incoming,
                    child: _textContent(_current),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fixedContent(
    SummaryTextContent content, {
    required bool animateTitle,
  }) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: animateTitle
          ? _textContent(content)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_title(content.title), _subtitle(content.subtitle)],
            ),
    );
  }

  Widget _fixedTitleWithSubtitleTransition(
    double value,
    SummaryPillTransitionOffsets offsets,
  ) {
    final previous = _previous!;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(_current.title),
          SizedBox(
            height: 16,
            width: double.infinity,
            child: ClipRect(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Opacity(
                    opacity: 1 - value,
                    child: Transform.translate(
                      offset: offsets.outgoing,
                      child: _subtitle(previous.subtitle),
                    ),
                  ),
                  Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: offsets.incoming,
                      child: _subtitle(_current.subtitle),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textContent(SummaryTextContent content) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_title(content.title), _subtitle(content.subtitle)],
    );
  }

  Widget _title(String value) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: FluviVisualTokens.summaryTitleTextStyle,
    );
  }

  Widget _subtitle(String value) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: FluviVisualTokens.summaryPlaneTextStyle,
    );
  }
}
