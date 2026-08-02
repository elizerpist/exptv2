import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../time_navigation/application/summary_timing_debug.dart';
import '../../time_navigation/presentation/summary_navigation_presentation.dart';
import '../summary_text_content.dart';

export '../../time_navigation/presentation/summary_navigation_presentation.dart'
    show SummaryTransitionDirection, SummaryTransitionAxis;
export '../summary_text_content.dart';

/// The atomic mother-title and child/context-subtitle visual block.
class SummaryNavigationTextBlock extends StatelessWidget {
  const SummaryNavigationTextBlock({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: FluviVisualTokens.summaryTitleTextStyle,
        ),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: FluviVisualTokens.summaryPlaneTextStyle,
        ),
      ],
    );
  }
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
  /// Finds the controller input whose ease-out-cubic output equals the raw
  /// interactive drag progress. This keeps drag release position and opacity
  /// continuous when the committed transition takes over.
  static double easeOutCubicInputForVisualProgress(double visualProgress) {
    final safeProgress = visualProgress.clamp(0.0, 1.0).toDouble();
    var lower = 0.0;
    var upper = 1.0;
    for (var iteration = 0; iteration < 20; iteration += 1) {
      final midpoint = (lower + upper) / 2;
      if (Curves.easeOutCubic.transform(midpoint) < safeProgress) {
        lower = midpoint;
      } else {
        upper = midpoint;
      }
    }
    return (lower + upper) / 2;
  }

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
    this.initialProgress = 0,
    this.initialPreviousContent,
    this.onTransitionCompleted,
  });

  final SummaryTextContent content;
  final SummaryTransitionAxis axis;
  final SummaryTransitionDirection direction;
  final bool animate;
  final bool animateTitle;
  final bool compact;
  final double height;
  final Duration duration;
  final double initialProgress;
  final SummaryTextContent? initialPreviousContent;
  final VoidCallback? onTransitionCompleted;

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
    _previous = widget.initialPreviousContent;
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: _previous == null
          ? 1
          : widget.initialProgress.clamp(0.0, 1.0).toDouble(),
    );
    if (_previous != null) {
      final generation = ++_generation;
      _startTransition(generation);
    }
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

    _startTransition(generation);
  }

  void _startTransition(int generation) {
    DashboardSummaryTimingDebug.mark(
      'S8 committedTextTransitionStarted',
      value: _current.subtitle,
    );
    void listener(AnimationStatus status) {
      if (status != AnimationStatus.completed || generation != _generation) {
        return;
      }
      if (!mounted) return;
      setState(() => _previous = null);
      _activeStatusListener = null;
      widget.onTransitionCompleted?.call();
    }

    _activeStatusListener = listener;
    _animationController.addStatusListener(listener);
    final initialProgress = widget.initialProgress.clamp(0.0, 1.0).toDouble();
    _animationController.duration = Duration(
      microseconds: (widget.duration.inMicroseconds * (1 - initialProgress))
          .round()
          .clamp(1, widget.duration.inMicroseconds),
    );
    _animationController
      ..value = initialProgress
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
                    key: const ValueKey('summary-navigation-axis-outgoing'),
                    offset: offsets.outgoing,
                    child: _textContent(_previous!),
                  ),
                ),
                Opacity(
                  opacity: value,
                  child: Transform.translate(
                    key: const ValueKey('summary-navigation-axis-incoming'),
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
    return SummaryNavigationTextBlock(
      title: content.title,
      subtitle: content.subtitle,
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
