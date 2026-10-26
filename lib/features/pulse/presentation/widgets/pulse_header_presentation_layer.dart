import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/pulse_delivery_coordinator.dart';
import '../../domain/pulse_models.dart';

/// Content-only adapter for the existing dashboard Header Card. It owns no
/// card geometry, palette, shader or ambient animation. Vertical drags are
/// explicitly forwarded to the existing Header gesture owner.
class PulseHeaderPresentationLayer extends StatefulWidget {
  const PulseHeaderPresentationLayer({
    super.key,
    required this.coordinator,
    required this.onOpenPulse,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    required this.onLayoutSupported,
  });

  final PulseDeliveryCoordinator coordinator;
  final VoidCallback onOpenPulse;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;
  final ValueChanged<bool> onLayoutSupported;

  @override
  State<PulseHeaderPresentationLayer> createState() =>
      _PulseHeaderPresentationLayerState();
}

class _PulseHeaderPresentationLayerState
    extends State<PulseHeaderPresentationLayer> {
  PulseHeaderPresentationReservation? _lastStarted;
  Timer? _presentedTimer;

  @override
  void initState() {
    super.initState();
    widget.coordinator.addListener(_onCoordinatorChanged);
  }

  @override
  void didUpdateWidget(covariant PulseHeaderPresentationLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.coordinator, widget.coordinator)) {
      oldWidget.coordinator.removeListener(_onCoordinatorChanged);
      widget.coordinator.addListener(_onCoordinatorChanged);
    }
  }

  @override
  void dispose() {
    _presentedTimer?.cancel();
    widget.coordinator.removeListener(_onCoordinatorChanged);
    super.dispose();
  }

  void _onCoordinatorChanged() {
    final value = widget.coordinator.presentation;
    if (value != null && value.attemptId != _lastStarted?.attemptId) {
      _lastStarted = value;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            value.attemptId != widget.coordinator.presentation?.attemptId) {
          return;
        }
        final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        unawaited(_startThenReportPresented(value, reduced));
      });
    }
    if (mounted) setState(() {});
  }

  Future<void> _startThenReportPresented(
    PulseHeaderPresentationReservation value,
    bool reduced,
  ) async {
    if (!await widget.coordinator.presentationStarted(value) || !mounted) {
      return;
    }
    _presentedTimer?.cancel();
    _presentedTimer = Timer(
      Duration(milliseconds: reduced ? 0 : 420),
      () => unawaited(widget.coordinator.presented(value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final presentation = widget.coordinator.presentation;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return LayoutBuilder(
      builder: (context, constraints) {
        final supported =
            presentation == null || _fits(presentation, constraints);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => widget.onLayoutSupported(supported),
        );
        if (!supported) {
          // The coordinator removes the unshown reservation; no shortened or
          // semantically damaged fallback copy is fabricated in Flutter.
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => unawaited(
              widget.coordinator.cancelPresentation(
                presentation,
                reason: 'header-layout-not-supported',
              ),
            ),
          );
        }
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            if (presentation != null) {
              await widget.coordinator.confirmVisibleTap();
            }
            widget.onOpenPulse();
          },
          onVerticalDragStart: widget.onVerticalDragStart,
          onVerticalDragUpdate: widget.onVerticalDragUpdate,
          onVerticalDragEnd: widget.onVerticalDragEnd,
          onVerticalDragCancel: () =>
              widget.onVerticalDragEnd(DragEndDetails()),
          child: AnimatedSwitcher(
            duration: disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) => Stack(
              fit: StackFit.expand,
              children: [...previousChildren, ?currentChild],
            ),
            child: presentation == null
                ? const SizedBox.expand(
                    key: ValueKey('pulse-header-financial-content'),
                  )
                : _PulseHeaderCopy(
                    key: ValueKey('pulse-header-${presentation.attemptId}'),
                    presentation: presentation,
                    coordinator: widget.coordinator,
                    onOpenPulse: widget.onOpenPulse,
                  ),
          ),
        );
      },
    );
  }

  bool _fits(
    PulseHeaderPresentationReservation value,
    BoxConstraints constraints,
  ) {
    final expanded = constraints.maxHeight >= 150;
    final availableWidth = (constraints.maxWidth - 88)
        .clamp(80, double.infinity)
        .toDouble();
    final headline = TextPainter(
      text: TextSpan(
        text: value.story.headline,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      maxLines: expanded ? 3 : 2,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: availableWidth);
    if (headline.didExceedMaxLines) return false;
    var neededHeight = 28 + 4 + headline.height;
    final detail = value.story.detail;
    if (expanded && detail != null) {
      final detailPainter = TextPainter(
        text: TextSpan(text: detail, style: const TextStyle(fontSize: 12)),
        maxLines: 2,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: availableWidth);
      if (detailPainter.didExceedMaxLines) return false;
      neededHeight += 3 + detailPainter.height;
    }
    return neededHeight <= constraints.maxHeight - 18;
  }
}

class _PulseHeaderCopy extends StatelessWidget {
  const _PulseHeaderCopy({
    super.key,
    required this.presentation,
    required this.coordinator,
    required this.onOpenPulse,
  });

  final PulseHeaderPresentationReservation presentation;
  final PulseDeliveryCoordinator coordinator;
  final VoidCallback onOpenPulse;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxHeight < 150;
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 72, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 28,
              child: Row(
                children: [
                  Text(
                    compact ? 'PULSE' : 'PULSE · AKTUÁLIS HÓNAP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: .45,
                    ),
                  ),
                  const Spacer(),
                  _HeaderActionButton(
                    key: const ValueKey('pulse-header-dismiss'),
                    tooltip: 'Elrejtés',
                    icon: Icons.close_rounded,
                    onPressed: coordinator.dismiss,
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<_PulseHeaderAction>(
                    key: const ValueKey('pulse-header-actions'),
                    tooltip: 'Pulse műveletek',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 28,
                    ),
                    icon: const Icon(Icons.more_horiz_rounded, size: 19),
                    onSelected: (value) => _onAction(context, value),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _PulseHeaderAction.details,
                        child: Text('Részletek'),
                      ),
                      PopupMenuItem(
                        value: _PulseHeaderAction.laterHour,
                        child: Text('Később · 1 óra'),
                      ),
                      PopupMenuItem(
                        value: _PulseHeaderAction.laterTomorrow,
                        child: Text('Később · holnap 09:00'),
                      ),
                      PopupMenuItem(
                        value: _PulseHeaderAction.mute,
                        child: Text('Cél némítása'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              presentation.story.headline,
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.clip,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!compact && presentation.story.detail != null) ...[
              const SizedBox(height: 3),
              Text(
                presentation.story.detail!,
                maxLines: 2,
                overflow: TextOverflow.clip,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      );
    },
  );

  Future<void> _onAction(
    BuildContext context,
    _PulseHeaderAction action,
  ) async {
    switch (action) {
      case _PulseHeaderAction.details:
        await coordinator.confirmVisibleTap();
        onOpenPulse();
      case _PulseHeaderAction.laterHour:
        await coordinator.snooze(const Duration(hours: 1));
      case _PulseHeaderAction.laterTomorrow:
        final local = DateTime.now();
        final tomorrow = DateTime(local.year, local.month, local.day + 1, 9);
        await coordinator.snooze(tomorrow.difference(local));
      case _PulseHeaderAction.mute:
        await coordinator.muteCurrentTarget(
          // The native target scope is deliberate and user-action scoped; it
          // is not inferred from a display label.
          presentation.targetScope,
        );
    }
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 28, height: 28),
    icon: Icon(icon, size: 18),
    onPressed: onPressed,
  );
}

enum _PulseHeaderAction { details, laterHour, laterTomorrow, mute }
