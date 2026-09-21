import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_border_profile.dart';
import '../../../../core/design/dashboard_corner_profile.dart';
import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/header_cascade_motion.dart';
import '../../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../../application/dashboard_balance_presentation.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import 'balance_header_history_chart.dart';
import 'balance_presentation_settings.dart';
import '../widgets/dashboard_placeholder_card.dart';
import '../widgets/dashboard_header_trend_visual_kernel.dart';
import 'dashboard_core_mode_presentation.dart';
import 'dashboard_core_mode_surface_primitives.dart';
import 'dashboard_header_visual_engine.dart';
import '../dashboard_border_style.dart';
import '../dashboard_corner_roundness.dart';
import '../dashboard_shadow_style.dart';

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
    this.presentationSettings,
    this.adaptiveScope = const AllTimeScope(),
    this.headerHistoryChartPointerObserver,
  });

  final DashboardCoreModePresentation presentation;
  final ValueListenable<DashboardBalancePresentation?>? balancePresentation;
  @visibleForTesting
  final VoidCallback? onCarouselMotionInterrupted;
  final DashboardHeaderVisualController? headerVisualController;
  final ValueListenable<DashboardHeaderVisualFrame>? headerVisualFrame;
  final ValueListenable<BalancePresentationSettings>? presentationSettings;
  final LedgerTimeScope adaptiveScope;
  final BalanceHeaderHistoryChartPointerObserver?
  headerHistoryChartPointerObserver;

  @override
  Widget build(BuildContext context) {
    final geometry = presentation.geometry;
    final local = _BalanceLocalGeometry.resolve(geometry);
    return KeyedSubtree(
      key: const ValueKey('dashboard-core-mode-balance'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DashboardCoreModeCascadeCard(
            bounds: local.lowerBounds,
            motion: local.lowerMotion,
            semanticKey: const ValueKey('dashboard-core-mode-balance-card-2'),
          ),
          DashboardCoreModeCascadeCard(
            bounds: local.upperBounds,
            motion: local.upperMotion,
            semanticKey: const ValueKey('dashboard-core-mode-balance-card-1'),
            showPlaceholderSurface: false,
            content: _BalanceUpperCarouselHost(
              balancePresentation: balancePresentation,
              presentationSettings: presentationSettings,
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
            detail: _BalanceHeaderDetail(
              balancePresentation: balancePresentation,
              expansionProgress: geometry.headerExpansionProgress,
              presentationSettings: presentationSettings,
              adaptiveScope: adaptiveScope,
              pointerObserver: headerHistoryChartPointerObserver,
            ),
            detailLeft: 0,
            detailRight: 0,
            detailTop: 0,
            detailBottom: 0,
          ),
        ],
      ),
    );
  }
}

/// Balance-only transfer inside the existing split-card envelope. It neither
/// changes global metrics nor affects the Mind/Budget consumers of them.
final class _BalanceLocalGeometry {
  const _BalanceLocalGeometry({
    required this.upperBounds,
    required this.lowerBounds,
    required this.upperMotion,
    required this.lowerMotion,
  });

  final DashboardBounds upperBounds;
  final DashboardBounds lowerBounds;
  final CascadedCardMotion upperMotion;
  final CascadedCardMotion lowerMotion;

  static _BalanceLocalGeometry resolve(DashboardLayoutFrame geometry) {
    final upper = geometry.subheaderOneBounds;
    final lower = geometry.zone2Bounds;
    final delta = upper.height * .10;
    final localUpper = DashboardBounds(
      left: upper.left,
      top: upper.top,
      width: upper.width,
      height: upper.height + delta,
    );
    final localLower = DashboardBounds(
      left: lower.left,
      top: lower.top + delta,
      width: lower.width,
      height: lower.height - delta,
    );
    final originalLowerMotion = geometry.lowerCardMotion!;
    return _BalanceLocalGeometry(
      upperBounds: localUpper,
      lowerBounds: localLower,
      upperMotion: geometry.upperCardMotion!,
      // Shifting the lower cascade at every reveal state keeps its existing
      // relation to the newly taller Balance-only upper envelope.
      lowerMotion: CascadedCardMotion(
        top: originalLowerMotion.top + delta,
        left: originalLowerMotion.left,
        right: originalLowerMotion.right,
        opacity: originalLowerMotion.opacity,
        scale: originalLowerMotion.scale,
        progress: originalLowerMotion.progress,
      ),
    );
  }
}

final class _BalanceHeaderDetail extends StatelessWidget {
  const _BalanceHeaderDetail({
    required this.balancePresentation,
    required this.expansionProgress,
    required this.presentationSettings,
    required this.adaptiveScope,
    required this.pointerObserver,
  });

  final ValueListenable<DashboardBalancePresentation?>? balancePresentation;
  final double expansionProgress;
  final ValueListenable<BalancePresentationSettings>? presentationSettings;
  final LedgerTimeScope adaptiveScope;
  final BalanceHeaderHistoryChartPointerObserver? pointerObserver;

  @override
  Widget build(BuildContext context) {
    final listenable = balancePresentation;
    if (listenable == null) return const SizedBox.shrink();
    return ValueListenableBuilder<DashboardBalancePresentation?>(
      valueListenable: listenable,
      builder: (context, balance, _) => _BalanceHeaderDetailContents(
        balance: balance,
        expansionProgress: expansionProgress,
        presentationSettings: presentationSettings,
        adaptiveScope: adaptiveScope,
        pointerObserver: pointerObserver,
      ),
    );
  }
}

final class _BalanceHeaderDetailContents extends StatelessWidget {
  const _BalanceHeaderDetailContents({
    required this.balance,
    required this.expansionProgress,
    required this.presentationSettings,
    required this.adaptiveScope,
    required this.pointerObserver,
  });

  final DashboardBalancePresentation? balance;
  final double expansionProgress;
  final ValueListenable<BalancePresentationSettings>? presentationSettings;
  final LedgerTimeScope adaptiveScope;
  final BalanceHeaderHistoryChartPointerObserver? pointerObserver;

  @override
  Widget build(BuildContext context) {
    final settings = presentationSettings;
    if (settings == null) {
      return _content(context, const BalancePresentationSettings.defaults());
    }
    return ValueListenableBuilder<BalancePresentationSettings>(
      valueListenable: settings,
      builder: (context, value, _) => _content(context, value),
    );
  }

  Widget _content(BuildContext context, BalancePresentationSettings settings) =>
      Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (balance?.history case final history?)
            BalanceHeaderHistoryChart(
              series: history,
              expansionProgress: expansionProgress,
              chartMode: settings.chartMode,
              showTimeLabels: settings.showsTimeLabels,
              adaptiveScope: adaptiveScope,
              pointerObserver: pointerObserver,
            ),
          Positioned(
            left: DashboardHeaderTrendChartStyle.detailLeft,
            top: DashboardHeaderTrendChartStyle.detailTop,
            child: Text(
              balance?.formattedNetTotal ?? '—',
              key: const ValueKey<String>('balance-header-net-amount'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: FluviVisualTokens.textOnAction,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
}

final class _BalanceUpperCarouselHost extends StatelessWidget {
  const _BalanceUpperCarouselHost({
    required this.balancePresentation,
    required this.presentationSettings,
    required this.onMotionInterrupted,
  });

  final ValueListenable<DashboardBalancePresentation?>? balancePresentation;
  final ValueListenable<BalancePresentationSettings>? presentationSettings;
  final VoidCallback? onMotionInterrupted;

  @override
  Widget build(BuildContext context) {
    final listenable = balancePresentation;
    if (listenable == null) return const SizedBox.shrink();
    return ValueListenableBuilder<DashboardBalancePresentation?>(
      valueListenable: listenable,
      builder: (context, presentation, _) {
        final settings = presentationSettings;
        if (settings == null) {
          return _BalanceUpperCarousel(
            cards: balanceCarouselCardsFor(presentation),
            settings: const BalancePresentationSettings.defaults(),
            onMotionInterrupted: onMotionInterrupted,
          );
        }
        return ValueListenableBuilder<BalancePresentationSettings>(
          valueListenable: settings,
          builder: (context, value, _) => _BalanceUpperCarousel(
            cards: balanceCarouselCardsFor(presentation),
            settings: value,
            onMotionInterrupted: onMotionInterrupted,
          ),
        );
      },
    );
  }
}

final class _BalanceUpperCarousel extends StatefulWidget {
  const _BalanceUpperCarousel({
    required this.cards,
    required this.settings,
    required this.onMotionInterrupted,
  });

  final List<BalanceCarouselCard> cards;
  final BalancePresentationSettings settings;
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
      final neutralSlotExtent = math.max(1.0, constraints.maxWidth / 3);
      final cardWidth =
          neutralSlotExtent * .82 * (1 + widget.settings.cardWidthBoost);
      // At +30% the card consumes its full real slot (1.066× the neutral
      // slot); the trailing-gap compensation retains exactly three slots in
      // the same physical rail. Extra spacing can only increase that canvas,
      // so it cannot create painted-but-noninteractive card edges.
      final itemExtent =
          math.max(neutralSlotExtent, cardWidth) +
          neutralSlotExtent * widget.settings.carouselSpacingAdjustment;
      final viewportTrailingGap = math.max(
        0.0,
        itemExtent * 3 - constraints.maxWidth,
      );
      final carouselHeight = math.max(1.0, constraints.maxHeight);
      final spec = CenteredCarouselSpec(
        itemExtent: itemExtent,
        visibleItemCount: 3,
        viewportTrailingGap: viewportTrailingGap,
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
            width: cardWidth,
            itemHeight: carouselHeight,
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
    required this.width,
    required this.itemHeight,
  });

  final BalanceCarouselCard card;
  final double width;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    // The selected card owns the full structural upper-card height in real
    // layout/hit bounds. The shared carousel keeps it at scale 1 and scales
    // only its neighbours down, so no selected visual relies on paint-only
    // overflow or an undersized interactive parent.
    final compact = itemHeight < 42;
    return SizedBox(
      key: ValueKey<String>('balance-carousel-card-${card.id}'),
      width: width,
      height: itemHeight,
      child: Builder(
        builder: (context) {
          final depth = DashboardShadowStyleScope.profileOf(
            context,
          ).depthFor(DashboardCornerSurfaceFamily.contentCard);
          return DecoratedBox(
            key: ValueKey<String>('balance-carousel-card-surface-${card.id}'),
            decoration: BoxDecoration(
              color: depth.surfaceColor ?? FluviVisualTokens.surface,
              border: DashboardBorderScope.profileOf(
                context,
              ).borderFor(DashboardBorderSurface.balanceContent),
              borderRadius: DashboardCornerRoundnessScope.profileOf(context)
                  .borderRadiusFor(
                    DashboardCornerSurfaceFamily.contentCard,
                    size: Size(width, itemHeight),
                  ),
              boxShadow: depth.shadows,
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
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: FluviVisualTokens.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          card.amount,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: FluviVisualTokens.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
