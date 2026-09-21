import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../../application/dashboard_balance_presentation.dart';
import '../widgets/dashboard_placeholder_card.dart';
import 'dashboard_core_mode_presentation.dart';
import 'dashboard_core_mode_surface_primitives.dart';
import 'dashboard_header_visual_engine.dart';

/// The finite presentation domain of Balance's upper prototype rail.
enum BalanceCarouselCardKind { latestTransaction, emptyPrototype }

/// One render-only Balance carousel item. Financial data is supplied in the
/// prepared [DashboardBalancePresentation] and never fetched by this widget.
@immutable
final class BalanceCarouselCard {
  const BalanceCarouselCard._({
    required this.id,
    required this.kind,
    required this.title,
    required this.amount,
  });

  final String id;
  final BalanceCarouselCardKind kind;
  final String title;
  final String amount;
}

List<BalanceCarouselCard> balanceCarouselCardsFor(
  DashboardBalancePresentation? presentation,
) {
  final latest = presentation?.latestTransaction;
  return List<BalanceCarouselCard>.unmodifiable(<BalanceCarouselCard>[
    BalanceCarouselCard._(
      id: 'latest-transaction',
      kind: BalanceCarouselCardKind.latestTransaction,
      title: latest?.title ?? 'Legutóbbi tétel',
      amount: latest?.formattedAmount ?? '—',
    ),
    for (var index = 1; index <= 4; index += 1)
      BalanceCarouselCard._(
        id: 'prototype-$index',
        kind: BalanceCarouselCardKind.emptyPrototype,
        title: 'Prototípus',
        amount: '—',
      ),
  ]);
}

/// Balance owns its Header data seam and the upper finite carousel. Its lower
/// large zone stays the existing placeholder structural surface.
class BalanceDashboardCoreSurface extends StatelessWidget {
  const BalanceDashboardCoreSurface({
    super.key,
    required this.presentation,
    this.balancePresentation,
    this.onCarouselMotionInterrupted,
    this.headerVisualController,
    this.headerVisualFrame,
  });

  final DashboardCoreModePresentation presentation;
  final ValueListenable<DashboardBalancePresentation?>? balancePresentation;
  @visibleForTesting
  final VoidCallback? onCarouselMotionInterrupted;
  final DashboardHeaderVisualController? headerVisualController;
  final ValueListenable<DashboardHeaderVisualFrame>? headerVisualFrame;

  @override
  Widget build(BuildContext context) {
    final geometry = presentation.geometry;
    return KeyedSubtree(
      key: const ValueKey('dashboard-core-mode-balance'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DashboardCoreModeCascadeCard(
            bounds: geometry.zone2Bounds,
            motion: geometry.lowerCardMotion!,
            semanticKey: const ValueKey('dashboard-core-mode-balance-card-2'),
          ),
          DashboardCoreModeCascadeCard(
            bounds: geometry.subheaderOneBounds,
            motion: geometry.upperCardMotion!,
            semanticKey: const ValueKey('dashboard-core-mode-balance-card-1'),
            content: _BalanceUpperCarouselHost(
              balancePresentation: balancePresentation,
              onMotionInterrupted: onCarouselMotionInterrupted,
            ),
          ),
          DashboardCoreModeOpacityPosition(
            bounds: geometry.zone2IndicatorBounds,
            opacity: geometry.zone2Opacity,
            offset: Offset(0, geometry.zone2Shift),
            child: DashboardPlaceholderDots(
              bounds: geometry.zone2IndicatorBounds,
              semanticKey: const ValueKey('dashboard-core-mode-balance-dots'),
            ),
          ),
          DashboardCoreModeHeaderScaffold(
            bounds: geometry.headerBounds,
            surfaceColor: presentation.palette.upcomingHeaderTone,
            headerKey: const ValueKey('dashboard-core-mode-balance-header'),
            labelKey: const ValueKey('dashboard-core-mode-label-balance'),
            label: 'balance',
            visualController: headerVisualController,
            visualFrameListenable: headerVisualFrame,
            detail: _BalanceHeaderAmount(
              balancePresentation: balancePresentation,
            ),
            detailLeft: 16,
            detailRight: 16,
            detailTop: 20,
            detailBottom: 8,
          ),
        ],
      ),
    );
  }
}

final class _BalanceHeaderAmount extends StatelessWidget {
  const _BalanceHeaderAmount({required this.balancePresentation});

  final ValueListenable<DashboardBalancePresentation?>? balancePresentation;

  @override
  Widget build(BuildContext context) {
    final listenable = balancePresentation;
    if (listenable == null) return const SizedBox.shrink();
    return ValueListenableBuilder<DashboardBalancePresentation?>(
      valueListenable: listenable,
      builder: (context, balance, _) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          balance?.formattedNetTotal ?? '—',
          key: const ValueKey<String>('balance-header-net-amount'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: FluviVisualTokens.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

final class _BalanceUpperCarouselHost extends StatelessWidget {
  const _BalanceUpperCarouselHost({
    required this.balancePresentation,
    required this.onMotionInterrupted,
  });

  final ValueListenable<DashboardBalancePresentation?>? balancePresentation;
  final VoidCallback? onMotionInterrupted;

  @override
  Widget build(BuildContext context) {
    final listenable = balancePresentation;
    if (listenable == null) return const SizedBox.shrink();
    return ValueListenableBuilder<DashboardBalancePresentation?>(
      valueListenable: listenable,
      builder: (context, presentation, _) => _BalanceUpperCarousel(
        cards: balanceCarouselCardsFor(presentation),
        onMotionInterrupted: onMotionInterrupted,
      ),
    );
  }
}

final class _BalanceUpperCarousel extends StatefulWidget {
  const _BalanceUpperCarousel({
    required this.cards,
    required this.onMotionInterrupted,
  });

  final List<BalanceCarouselCard> cards;
  final VoidCallback? onMotionInterrupted;

  @override
  State<_BalanceUpperCarousel> createState() => _BalanceUpperCarouselState();
}

final class _BalanceUpperCarouselState extends State<_BalanceUpperCarousel> {
  late final CenteredCarouselController _controller =
      CenteredCarouselController(initialIndex: 0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final itemExtent = math.max(1.0, constraints.maxWidth / 3);
      final carouselHeight = math.max(1.0, constraints.maxHeight);
      final spec = CenteredCarouselSpec(
        itemExtent: itemExtent,
        visibleItemCount: 3,
        selectorHeight: carouselHeight,
        minScale: .70,
        maxScale: 1,
        neighborScale: .78,
        outerScale: .70,
        minOpacity: .74,
        maxOpacity: 1,
        neighborOpacity: .88,
        outerOpacity: .74,
        influenceRadiusItems: 2,
        motionProfile: CenteredCarouselMotionProfiles.timeRefinementRail,
        enableHaptics: true,
        clipBehavior: Clip.none,
      );
      return CenteredCarousel<BalanceCarouselCard>(
        key: const ValueKey<String>('balance-carousel'),
        dataSource: CyclicCarouselDataSource<BalanceCarouselCard>(widget.cards),
        controller: _controller,
        spec: spec,
        height: carouselHeight,
        viewportKey: const ValueKey<String>('balance-carousel-viewport'),
        onMotionInterrupted: widget.onMotionInterrupted,
        semanticsLabelBuilder: (card) =>
            card.kind == BalanceCarouselCardKind.latestTransaction
            ? 'Legutóbbi tranzakció: ${card.title}, ${card.amount}'
            : 'Üres Balance prototípus',
        itemBuilder: (context, card, metrics) => _BalanceCarouselPressFeedback(
          child: _BalanceCarouselCard(
            card: card,
            itemExtent: itemExtent,
            itemHeight: math.min(52, carouselHeight),
          ),
        ),
      );
    },
  );
}

/// Input feedback intentionally mirrors Budget's accepted local interaction
/// shell; the shared [CenteredCarousel] remains gesture/physics owner.
final class _BalanceCarouselPressFeedback extends StatefulWidget {
  const _BalanceCarouselPressFeedback({required this.child});

  final Widget child;

  @override
  State<_BalanceCarouselPressFeedback> createState() =>
      _BalanceCarouselPressFeedbackState();
}

final class _BalanceCarouselPressFeedbackState
    extends State<_BalanceCarouselPressFeedback> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (!mounted || pressed == _pressed) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _setPressed(true),
    onPointerUp: (_) => _setPressed(false),
    onPointerCancel: (_) => _setPressed(false),
    child: AnimatedScale(
      key: const ValueKey<String>('balance-carousel-press-scale'),
      scale: _pressed ? .8 : 1,
      duration: const Duration(milliseconds: 115),
      curve: Curves.easeOutQuad,
      child: widget.child,
    ),
  );
}

final class _BalanceCarouselCard extends StatelessWidget {
  const _BalanceCarouselCard({
    required this.card,
    required this.itemExtent,
    required this.itemHeight,
  });

  final BalanceCarouselCard card;
  final double itemExtent;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    // The unscaled selected visual is deliberately smaller than its item
    // canvas. The full selected card therefore has real layout/hit bounds and
    // never needs a paint-only overflow or clipping exception.
    final width = math.max(1.0, itemExtent * .82);
    final compact = itemHeight < 42;
    return SizedBox(
      key: ValueKey<String>('balance-carousel-card-${card.id}'),
      width: width,
      height: itemHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 4 : 8,
            vertical: compact ? 2 : 7,
          ),
          child: compact
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    card.amount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: FluviVisualTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      card.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: FluviVisualTokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.amount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: FluviVisualTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
