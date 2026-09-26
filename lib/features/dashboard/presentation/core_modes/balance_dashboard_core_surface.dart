import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_border_profile.dart';
import '../../../../core/design/dashboard_corner_profile.dart';
import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_global_appearance.dart';
import '../../../../core/design/header_cascade_motion.dart';
import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/categories/catalog/category_icon_catalog.dart';
import '../../../../core/categories/presentation/category_icon_view.dart';
import '../../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../../application/dashboard_balance_presentation.dart';
import '../../application/dashboard_balance_closings_momentum_projection.dart';
import '../../application/dashboard_balance_primary_projection.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import 'balance_header_history_chart.dart';
import 'balance_insight_indicators.dart';
import 'balance_category_visual_badge.dart';
import 'balance_category_movers_presentation.dart';
import 'balance_linked_detail_card.dart';
import 'balance_cashflow_stability_card.dart';
import 'balance_momentum_card.dart';
import 'balance_presentation_settings.dart';
import 'balance_retention_card.dart';
import '../widgets/dashboard_placeholder_card.dart';
import '../widgets/dashboard_header_trend_visual_kernel.dart';
import 'dashboard_core_mode_presentation.dart';
import 'dashboard_core_mode_surface_primitives.dart';
import 'dashboard_header_visual_engine.dart';
import '../dashboard_border_style.dart';
import '../dashboard_corner_roundness.dart';
import '../dashboard_shadow_style.dart';

/// The finite presentation domain of Balance's upper linked topic rail.
enum BalanceCarouselCardKind {
  cashflow,
  closings,
  momentum,
  retention,
  stability,
  ghost,
  forecast,
  latestTransaction,
  categoryMovers,
  topCategory,
  topPartner,
}

const _balanceInsightIndicatorIds = <String>[
  'cashflow',
  'closings',
  'momentum',
  'retention',
  'stability',
  'ghost',
  'forecast',
  'latest-transaction',
  'category-movers',
  'top-category',
  'top-partner',
];

String _indicatorIdFor(BalanceLinkedDetailTopic topic) => switch (topic) {
  BalanceLinkedDetailTopic.cashflow => 'cashflow',
  BalanceLinkedDetailTopic.closings => 'closings',
  BalanceLinkedDetailTopic.momentum => 'momentum',
  BalanceLinkedDetailTopic.retention => 'retention',
  BalanceLinkedDetailTopic.stability => 'stability',
  BalanceLinkedDetailTopic.ghost => 'ghost',
  BalanceLinkedDetailTopic.forecast => 'forecast',
  BalanceLinkedDetailTopic.latestTransaction => 'latest-transaction',
  BalanceLinkedDetailTopic.categoryMovers => 'category-movers',
  BalanceLinkedDetailTopic.topCategory => 'top-category',
  BalanceLinkedDetailTopic.topPartner => 'top-partner',
};

/// One render-only Balance carousel item. Financial data is supplied in the
/// prepared [DashboardBalanceLinkedPresentation] and never fetched by this
/// widget.
@immutable
final class BalanceCarouselCard {
  const BalanceCarouselCard._({
    required this.id,
    required this.kind,
    required this.title,
    required this.amount,
    this.detail,
    this.latestTransaction,
  });

  final String id;
  final BalanceCarouselCardKind kind;
  final String title;
  final String amount;
  final String? detail;
  final DashboardBalanceScopedTransaction? latestTransaction;
}

List<BalanceCarouselCard> balanceCarouselCardsFor(
  DashboardBalanceLinkedPresentation? presentation,
) {
  final latest = presentation?.latestTransactions.firstOrNull;
  final moverPresentation = presentation?.categoryMovers;
  final topMover = moverPresentation?.movers.firstOrNull;
  final topCategory = presentation?.topCategories.firstOrNull;
  final topPartner = presentation?.topPartners.firstOrNull;
  final closings = presentation?.closings;
  final momentum = presentation?.momentum;
  final retention = presentation?.retention;
  final stability = presentation?.stability;
  return List<BalanceCarouselCard>.unmodifiable(<BalanceCarouselCard>[
    BalanceCarouselCard._(
      id: 'cashflow',
      kind: BalanceCarouselCardKind.cashflow,
      title: 'Cashflow',
      amount: presentation == null
          ? '—'
          : DashboardPreparedFormatter.amountMinor(
              presentation.cashflow.netTotalMinor,
            ),
    ),
    BalanceCarouselCard._(
      id: 'closings',
      kind: BalanceCarouselCardKind.closings,
      title: 'Zárások',
      amount: closings == null ? '—' : balanceClosingsCompactSummary(closings),
    ),
    BalanceCarouselCard._(
      id: 'momentum',
      kind: BalanceCarouselCardKind.momentum,
      title: 'Balance momentum',
      amount: momentum == null || !momentum.isAvailable
          ? 'Nincs adat'
          : formatBalanceMomentumRate(momentum.momentum, momentum.unit),
      detail: momentum == null
          ? null
          : balanceMomentumStateLabel(momentum.state),
    ),
    BalanceCarouselCard._(
      id: 'retention',
      kind: BalanceCarouselCardKind.retention,
      title: 'Megtartási arány',
      amount: formatBalanceRetentionPeriod(retention?.selectedPeriod),
      detail: 'bevételből megtartva',
    ),
    BalanceCarouselCard._(
      id: 'stability',
      kind: BalanceCarouselCardKind.stability,
      title: 'Cashflow stabilitás',
      amount: stability == null || !stability.isAvailable
          ? 'Nincs elég adat'
          : formatBalanceStabilityDeviation(
              stability.typicalDeviationTimesTwo!,
            ),
      detail: 'tipikus havi kilengés',
    ),
    const BalanceCarouselCard._(
      id: 'ghost',
      kind: BalanceCarouselCardKind.ghost,
      title: 'Fix terhek',
      amount: 'Hamarosan',
      detail: 'Ghost tranzakciók',
    ),
    const BalanceCarouselCard._(
      id: 'forecast',
      kind: BalanceCarouselCardKind.forecast,
      title: 'Forecast',
      amount: 'Hamarosan',
      detail: 'Várható zárás',
    ),
    BalanceCarouselCard._(
      id: 'latest-transaction',
      kind: BalanceCarouselCardKind.latestTransaction,
      title: 'Utolsó tranzakció',
      amount: latest?.title ?? 'Nincs tétel',
      latestTransaction: latest,
    ),
    BalanceCarouselCard._(
      id: 'category-movers',
      kind: BalanceCarouselCardKind.categoryMovers,
      title: 'Legnagyobb kategóriaváltozás',
      amount: topMover?.label ?? 'Nincs kategóriaváltozás',
      detail: topMover == null
          ? null
          : '${balanceCategoryMoverPercentageLabel(topMover)} · '
                '${balanceCategoryMoverCompactComparisonLabel(moverPresentation!)}',
    ),
    BalanceCarouselCard._(
      id: 'top-category',
      kind: BalanceCarouselCardKind.topCategory,
      title: 'Top kategória',
      amount: topCategory?.label ?? 'Nincs adat',
    ),
    BalanceCarouselCard._(
      id: 'top-partner',
      kind: BalanceCarouselCardKind.topPartner,
      title: 'Top partner',
      amount: topPartner?.label ?? 'Nincs adat',
    ),
  ]);
}

/// Compact Closings wording is deliberately a read-only view of the exact
/// immutable bucket list supplied to the lower Closings renderer.
String balanceClosingsCompactSummary(
  DashboardBalanceClosingsPresentation closings,
) {
  if (closings.buckets.isEmpty) return 'Nincs adat';
  final unit = switch (closings.timeScope) {
    AllTimeScope() => 'év',
    YearScope() => 'hónap',
    MonthScope() => 'nap',
    DayScope() => 'napszak',
  };
  final denominator = switch (closings.timeScope) {
    AllTimeScope() => closings.buckets.length,
    YearScope() => 12,
    MonthScope() => closings.buckets.length,
    DayScope() => 6,
  };
  return '${closings.positiveBucketCount} / $denominator $unit pluszos';
}

/// Balance owns its Header data seam, upper finite carousel, and the existing
/// lower structural zone that now hosts the primary financial chart.
class BalanceDashboardCoreSurface extends StatefulWidget {
  const BalanceDashboardCoreSurface({
    super.key,
    required this.presentation,
    this.balancePresentation,
    this.balanceLinkedPresentation,
    this.onCarouselMotionInterrupted,
    this.headerVisualController,
    this.headerVisualFrame,
    this.presentationSettings,
    this.adaptiveScope = const AllTimeScope(),
    this.headerHistoryChartPointerObserver,
  });

  final DashboardCoreModePresentation presentation;
  final ValueListenable<DashboardBalancePresentation?>? balancePresentation;
  final ValueListenable<DashboardBalanceLinkedPresentation?>?
  balanceLinkedPresentation;
  @visibleForTesting
  final VoidCallback? onCarouselMotionInterrupted;
  final DashboardHeaderVisualController? headerVisualController;
  final ValueListenable<DashboardHeaderVisualFrame>? headerVisualFrame;
  final ValueListenable<BalancePresentationSettings>? presentationSettings;
  final LedgerTimeScope adaptiveScope;
  final BalanceHeaderHistoryChartPointerObserver?
  headerHistoryChartPointerObserver;

  @override
  State<BalanceDashboardCoreSurface> createState() =>
      _BalanceDashboardCoreSurfaceState();
}

final class _BalanceDashboardCoreSurfaceState
    extends State<BalanceDashboardCoreSurface> {
  BalanceLinkedDetailTopic _selectedTopic = BalanceLinkedDetailTopic.cashflow;

  @override
  Widget build(BuildContext context) {
    final geometry = widget.presentation.geometry;
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
            showPlaceholderSurface: false,
            content: _BalancePrimaryCardHost(
              bounds: local.lowerBounds,
              presentation: widget.balanceLinkedPresentation,
              selectedTopic: _selectedTopic,
            ),
          ),
          DashboardCoreModeCascadeCard(
            bounds: local.upperBounds,
            motion: local.upperMotion,
            semanticKey: const ValueKey('dashboard-core-mode-balance-card-1'),
            showPlaceholderSurface: false,
            content: _BalanceUpperCarouselHost(
              presentation: widget.balanceLinkedPresentation,
              presentationSettings: widget.presentationSettings,
              summaryToUpperGap:
                  local.upperBounds.top - geometry.summaryBounds.bottom,
              onMotionInterrupted: widget.onCarouselMotionInterrupted,
              onCardSelected: (card) {
                final selected = switch (card.kind) {
                  BalanceCarouselCardKind.cashflow =>
                    BalanceLinkedDetailTopic.cashflow,
                  BalanceCarouselCardKind.closings =>
                    BalanceLinkedDetailTopic.closings,
                  BalanceCarouselCardKind.momentum =>
                    BalanceLinkedDetailTopic.momentum,
                  BalanceCarouselCardKind.retention =>
                    BalanceLinkedDetailTopic.retention,
                  BalanceCarouselCardKind.stability =>
                    BalanceLinkedDetailTopic.stability,
                  BalanceCarouselCardKind.ghost =>
                    BalanceLinkedDetailTopic.ghost,
                  BalanceCarouselCardKind.forecast =>
                    BalanceLinkedDetailTopic.forecast,
                  BalanceCarouselCardKind.latestTransaction =>
                    BalanceLinkedDetailTopic.latestTransaction,
                  BalanceCarouselCardKind.categoryMovers =>
                    BalanceLinkedDetailTopic.categoryMovers,
                  BalanceCarouselCardKind.topCategory =>
                    BalanceLinkedDetailTopic.topCategory,
                  BalanceCarouselCardKind.topPartner =>
                    BalanceLinkedDetailTopic.topPartner,
                };
                if (selected != _selectedTopic) {
                  setState(() => _selectedTopic = selected);
                }
              },
            ),
          ),
          DashboardCoreModeOpacityPosition(
            bounds: geometry.zone2IndicatorBounds,
            opacity: geometry.zone2Opacity,
            offset: Offset(0, geometry.zone2Shift),
            child: BalanceInsightIndicators(
              bounds: geometry.zone2IndicatorBounds,
              itemIds: _balanceInsightIndicatorIds,
              activeItemId: _indicatorIdFor(_selectedTopic),
            ),
          ),
          DashboardCoreModeHeaderScaffold(
            bounds: geometry.headerBounds,
            surfaceColor: widget.presentation.palette.upcomingHeaderTone,
            headerKey: const ValueKey('dashboard-core-mode-balance-header'),
            labelKey: const ValueKey('dashboard-core-mode-label-balance'),
            label: 'balance',
            showModeLabel: false,
            visualController: widget.headerVisualController,
            visualFrameListenable: widget.headerVisualFrame,
            usesVisualForeground: true,
            detail: _BalanceHeaderDetail(
              balancePresentation: widget.balancePresentation,
              headerVisualFrame: widget.headerVisualFrame,
              expansionProgress: geometry.headerExpansionProgress,
              expandedHeaderExtraHeight: geometry.expandedHeaderExtraHeight,
              presentationSettings: widget.presentationSettings,
              adaptiveScope: widget.adaptiveScope,
              pointerObserver: widget.headerHistoryChartPointerObserver,
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

/// Keeps the existing zone2 envelope as the one Balance primary-card surface.
/// Day intentionally retains a normal empty card until it receives its own
/// product specification.
final class _BalancePrimaryCardHost extends StatelessWidget {
  const _BalancePrimaryCardHost({
    required this.bounds,
    required this.presentation,
    required this.selectedTopic,
  });

  final DashboardBounds bounds;
  final ValueListenable<DashboardBalanceLinkedPresentation?>? presentation;
  final BalanceLinkedDetailTopic selectedTopic;

  @override
  Widget build(BuildContext context) {
    final listenable = presentation;
    if (listenable == null) return _placeholder();
    return ValueListenableBuilder<DashboardBalanceLinkedPresentation?>(
      valueListenable: listenable,
      builder: (context, value, _) {
        if (value == null ||
            (selectedTopic == BalanceLinkedDetailTopic.cashflow &&
                value.cashflow.mode ==
                    DashboardBalancePrimaryMode.unsupportedDay)) {
          return _placeholder();
        }
        return DashboardPlaceholderCard(
          bounds: bounds,
          fillParent: true,
          semanticKey: const ValueKey<String>('balance-primary-card'),
          child: BalanceLinkedDetailCard(
            presentation: value,
            topic: selectedTopic,
          ),
        );
      },
    );
  }

  Widget _placeholder() => DashboardPlaceholderCard(
    bounds: bounds,
    fillParent: true,
    semanticKey: const ValueKey<String>('balance-primary-card-placeholder'),
  );
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
    required this.headerVisualFrame,
    required this.expansionProgress,
    required this.expandedHeaderExtraHeight,
    required this.presentationSettings,
    required this.adaptiveScope,
    required this.pointerObserver,
  });

  final ValueListenable<DashboardBalancePresentation?>? balancePresentation;
  final ValueListenable<DashboardHeaderVisualFrame>? headerVisualFrame;
  final double expansionProgress;
  final double expandedHeaderExtraHeight;
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
        headerVisualFrame: headerVisualFrame,
        expansionProgress: expansionProgress,
        expandedHeaderExtraHeight: expandedHeaderExtraHeight,
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
    required this.headerVisualFrame,
    required this.expansionProgress,
    required this.expandedHeaderExtraHeight,
    required this.presentationSettings,
    required this.adaptiveScope,
    required this.pointerObserver,
  });

  final DashboardBalancePresentation? balance;
  final ValueListenable<DashboardHeaderVisualFrame>? headerVisualFrame;
  final double expansionProgress;
  final double expandedHeaderExtraHeight;
  final ValueListenable<BalancePresentationSettings>? presentationSettings;
  final LedgerTimeScope adaptiveScope;
  final BalanceHeaderHistoryChartPointerObserver? pointerObserver;

  @override
  Widget build(BuildContext context) {
    final settings = presentationSettings;
    if (settings == null) {
      return _withFrame(context, const BalancePresentationSettings.defaults());
    }
    return ValueListenableBuilder<BalancePresentationSettings>(
      valueListenable: settings,
      builder: (context, value, _) => _withFrame(context, value),
    );
  }

  Widget _withFrame(
    BuildContext context,
    BalancePresentationSettings settings,
  ) {
    final frames = headerVisualFrame;
    if (frames == null) return _content(context, settings, null);
    return ValueListenableBuilder<DashboardHeaderVisualFrame>(
      valueListenable: frames,
      builder: (context, frame, _) => _content(context, settings, frame),
    );
  }

  Widget _content(
    BuildContext context,
    BalancePresentationSettings settings,
    DashboardHeaderVisualFrame? frame,
  ) {
    final chartLayout = DashboardHeaderTrendChartLayout(
      showsModeLabelAboveValue: frame?.showsHeaderModeLabelAboveValue ?? false,
      extraPlotHeight: expandedHeaderExtraHeight,
    );
    final typography = frame?.typography ?? FluviTypographyProfile.app;
    final foreground =
        frame?.foregroundTextColor ?? FluviVisualTokens.textOnAction;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (balance?.history case final history?)
          BalanceHeaderHistoryChart(
            series: history,
            expansionProgress: expansionProgress,
            chartMode: settings.chartMode,
            lineColor:
                frame?.chartColor ?? DashboardHeaderTrendChartStyle.lineColor,
            areaFadeColor:
                frame?.chartVeilColor ??
                DashboardHeaderTrendChartStyle.lineColor,
            showsAreaFade: frame?.showsChartVeil ?? true,
            showTimeLabels: settings.showsTimeLabels,
            adaptiveScope: adaptiveScope,
            pointerObserver: pointerObserver,
            layout: chartLayout,
          ),
        if (chartLayout.showsModeLabelAboveValue)
          Positioned(
            left: DashboardHeaderTrendChartStyle.detailLeft,
            top: DashboardHeaderTrendChartStyle.detailTop,
            child: Text(
              'Balance',
              key: const ValueKey<String>('balance-header-mode-label'),
              style: typography.applyTo(
                DashboardHeaderTrendChartLayout.modeLabelTextMetrics.copyWith(
                  color: foreground,
                ),
              ),
            ),
          ),
        Positioned(
          left: DashboardHeaderTrendChartStyle.detailLeft,
          top: chartLayout.valueTop,
          child: Text(
            balance?.formattedNetTotal ?? '—',
            key: const ValueKey<String>('balance-header-net-amount'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.applyTo(
              DefaultTextStyle.of(context).style
                  .merge(DashboardHeaderTrendChartStyle.primaryValueTextMetrics)
                  .copyWith(color: foreground),
            ),
          ),
        ),
      ],
    );
  }
}

final class _BalanceUpperCarouselHost extends StatelessWidget {
  const _BalanceUpperCarouselHost({
    required this.presentation,
    required this.presentationSettings,
    required this.summaryToUpperGap,
    required this.onMotionInterrupted,
    required this.onCardSelected,
  });

  final ValueListenable<DashboardBalanceLinkedPresentation?>? presentation;
  final ValueListenable<BalancePresentationSettings>? presentationSettings;
  final double summaryToUpperGap;
  final VoidCallback? onMotionInterrupted;
  final ValueChanged<BalanceCarouselCard> onCardSelected;

  @override
  Widget build(BuildContext context) {
    final settings = presentationSettings;
    if (settings == null) {
      return _withSettings(
        context,
        const BalancePresentationSettings.defaults(),
      );
    }
    return ValueListenableBuilder<BalancePresentationSettings>(
      valueListenable: settings,
      builder: (context, value, _) => _withSettings(context, value),
    );
  }

  Widget _withSettings(
    BuildContext context,
    BalancePresentationSettings settings,
  ) {
    final listenable = presentation;
    if (listenable == null) {
      return _BalanceUpperCarousel(
        cards: balanceCarouselCardsFor(null),
        latestTransactionPresentation:
            settings.latestTransactionCardPresentation,
        summaryToUpperGap: summaryToUpperGap,
        onMotionInterrupted: onMotionInterrupted,
        onCardSelected: onCardSelected,
      );
    }
    return ValueListenableBuilder<DashboardBalanceLinkedPresentation?>(
      valueListenable: listenable,
      builder: (context, presentation, _) {
        return _BalanceUpperCarousel(
          cards: balanceCarouselCardsFor(presentation),
          latestTransactionPresentation:
              settings.latestTransactionCardPresentation,
          summaryToUpperGap: summaryToUpperGap,
          onMotionInterrupted: onMotionInterrupted,
          onCardSelected: onCardSelected,
        );
      },
    );
  }
}

final class _BalanceUpperCarousel extends StatefulWidget {
  const _BalanceUpperCarousel({
    required this.cards,
    required this.latestTransactionPresentation,
    required this.summaryToUpperGap,
    required this.onMotionInterrupted,
    required this.onCardSelected,
  });

  final List<BalanceCarouselCard> cards;
  final BalanceLatestTransactionCardPresentation latestTransactionPresentation;
  final double summaryToUpperGap;
  final VoidCallback? onMotionInterrupted;
  final ValueChanged<BalanceCarouselCard> onCardSelected;

  @override
  State<_BalanceUpperCarousel> createState() => _BalanceUpperCarouselState();
}

/// Fixed Balance-only rail geometry. It retains the pre-retirement 30%/zero
/// outer-card envelope while solving the selected-card width and item extent
/// together from the actual Summary-to-rail vertical gap. The shared carousel
/// remains the sole scroll, gesture and semantics owner.
@immutable
final class _BalanceFixedCarouselGeometry {
  const _BalanceFixedCarouselGeometry({
    required this.cardWidth,
    required this.itemExtent,
    required this.viewportTrailingGap,
    required this.inwardVisualOffset,
  });

  static const _legacyCardFraction = .82 * 1.30;
  static const _neighborScale = .78;

  final double cardWidth;
  final double itemExtent;
  final double viewportTrailingGap;
  final double inwardVisualOffset;

  factory _BalanceFixedCarouselGeometry.resolve({
    required double availableWidth,
    required double summaryToUpperGap,
  }) {
    final neutralSlotExtent = math.max(1.0, availableWidth / 3);
    final legacyCardWidth = neutralSlotExtent * _legacyCardFraction;
    final targetGap = math.max(0.0, summaryToUpperGap);
    // At the legacy 30%/zero state, a side outer edge sits this far from the
    // selected center. The selected/neighbor interior gap is solved against
    // [targetGap], then the side cards are translated inward by the exact
    // compensation that keeps their viewport-facing edges fixed.
    final legacyOuterHalfDistance = legacyCardWidth * (1 + _neighborScale / 2);
    final solvedCardWidth =
        (legacyOuterHalfDistance - targetGap) / (.5 + _neighborScale);
    // A substantially collapsed Header can make its vertical reference gap
    // larger than the available inward-width budget. Keep the accepted legacy
    // outer envelope in that transient state rather than asserting or painting
    // a narrower/noninteractive rail. The settled production geometry still
    // uses the strictly wider solved width.
    final cardWidth = math.max(legacyCardWidth, solvedCardWidth);
    final inwardVisualOffset =
        cardWidth * (1 + _neighborScale / 2) - legacyOuterHalfDistance;
    assert(cardWidth >= legacyCardWidth);
    assert(inwardVisualOffset >= 0);
    assert(
      inwardVisualOffset <= cardWidth * (1 - _neighborScale) / 2,
      'The visual side-card shift must stay inside the interactive item slot.',
    );
    return _BalanceFixedCarouselGeometry(
      cardWidth: cardWidth,
      itemExtent: cardWidth,
      viewportTrailingGap: math.max(0.0, cardWidth * 3 - availableWidth),
      inwardVisualOffset: inwardVisualOffset,
    );
  }

  double inwardOffsetFor(CenteredCarouselItemMetrics metrics) {
    if (metrics.signedDistanceItems == 0) return 0;
    final boundedDistance = metrics.signedDistanceItems
        .clamp(-1.0, 1.0)
        .toDouble();
    // The shared scale wraps this local transform. Dividing by the current
    // scale keeps the on-screen edge lock continuous while every painted edge
    // remains within the existing interactive item extent.
    return -boundedDistance *
        inwardVisualOffset /
        math.max(.001, metrics.scale);
  }
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
      final geometry = _BalanceFixedCarouselGeometry.resolve(
        availableWidth: constraints.maxWidth,
        summaryToUpperGap: widget.summaryToUpperGap,
      );
      final carouselHeight = math.max(1.0, constraints.maxHeight);
      final spec = CenteredCarouselSpec(
        itemExtent: geometry.itemExtent,
        visibleItemCount: 3,
        viewportTrailingGap: geometry.viewportTrailingGap,
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
        onSelectedChanged: (logicalIndex) {
          final count = widget.cards.length;
          final itemIndex = ((logicalIndex % count) + count) % count;
          widget.onCardSelected(widget.cards[itemIndex]);
        },
        semanticsLabelBuilder: (card) => switch (card.kind) {
          BalanceCarouselCardKind.cashflow => 'Cashflow: ${card.amount}',
          BalanceCarouselCardKind.closings => 'Zárások: ${card.amount}',
          BalanceCarouselCardKind.momentum =>
            'Balance momentum: ${card.amount}',
          BalanceCarouselCardKind.retention =>
            'Megtartási arány: ${card.amount}',
          BalanceCarouselCardKind.stability =>
            'Cashflow stabilitás: ${card.amount}',
          BalanceCarouselCardKind.ghost => 'Fix terhek: ${card.amount}',
          BalanceCarouselCardKind.forecast => 'Forecast: ${card.amount}',
          BalanceCarouselCardKind.latestTransaction =>
            'Utolsó tranzakció: ${card.amount}',
          BalanceCarouselCardKind.categoryMovers =>
            'Legnagyobb kategóriaváltozás: ${card.amount}',
          BalanceCarouselCardKind.topCategory =>
            'Top kategória: ${card.amount}',
          BalanceCarouselCardKind.topPartner => 'Top partner: ${card.amount}',
        },
        itemBuilder: (context, card, metrics) => _BalanceCarouselPressFeedback(
          child: Transform.translate(
            offset: Offset(geometry.inwardOffsetFor(metrics), 0),
            transformHitTests: true,
            child: _BalanceCarouselCard(
              card: card,
              width: geometry.cardWidth,
              itemHeight: carouselHeight,
              latestTransactionPresentation:
                  widget.latestTransactionPresentation,
            ),
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
    required this.latestTransactionPresentation,
  });

  final BalanceCarouselCard card;
  final double width;
  final double itemHeight;
  final BalanceLatestTransactionCardPresentation latestTransactionPresentation;

  @override
  Widget build(BuildContext context) {
    // The selected card owns the full structural upper-card height in real
    // layout/hit bounds. The shared carousel keeps it at scale 1 and scales
    // only its neighbours down, so no selected visual relies on paint-only
    // overflow or an undersized interactive parent.
    final compact = itemHeight < 42;
    final latest = card.latestTransaction;
    // A transformed side-card can retain the normal logical item height while
    // receiving only a short physical content box. Preserve its primary value
    // and omit the optional Momentum state line there; the selected card keeps
    // the full preview at its normal height.
    final showDetail = !compact && itemHeight >= 60;
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
              padding:
                  !compact &&
                      card.kind == BalanceCarouselCardKind.latestTransaction &&
                      latest != null
                  ? _LatestCarouselReferenceVisualSpec.cardPadding
                  : EdgeInsets.symmetric(
                      horizontal: compact ? 4 : 8,
                      vertical: compact ? 2 : 7,
                    ),
              child: compact
                  ? card.kind == BalanceCarouselCardKind.latestTransaction &&
                            latest != null
                        ? _CompactLatestCarouselPreview(transaction: latest)
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              card.amount,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: FluviVisualTokens.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          )
                  : card.kind == BalanceCarouselCardKind.latestTransaction &&
                        latest != null
                  ? _LatestCarouselPreview(
                      transaction: latest,
                      presentation: latestTransactionPresentation,
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
                        if (showDetail)
                          if (card.detail case final detail?) ...<Widget>[
                            const SizedBox(height: 2),
                            Text(
                              detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: FluviVisualTokens.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

final class _CompactLatestCarouselPreview extends StatelessWidget {
  const _CompactLatestCarouselPreview({required this.transaction});

  final DashboardBalanceScopedTransaction transaction;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      BalanceCategoryVisualBadge(
        semanticLabel: transaction.categoryTitle,
        categoryColorId: transaction.categoryColorId,
        categoryIconId: transaction.categoryIconId,
        size: 15,
        iconSize: 8,
      ),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          transaction.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: FluviVisualTokens.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

final class _LatestCarouselPreview extends StatelessWidget {
  const _LatestCarouselPreview({
    required this.transaction,
    required this.presentation,
  });

  final DashboardBalanceScopedTransaction transaction;
  final BalanceLatestTransactionCardPresentation presentation;

  @override
  Widget build(BuildContext context) => switch (presentation) {
    BalanceLatestTransactionCardPresentation.avatarPartner =>
      _LatestAvatarPartnerPreview(transaction: transaction),
    BalanceLatestTransactionCardPresentation.threeLine =>
      _LatestThreeLinePreview(transaction: transaction),
  };
}

/// Approved source-parity tokens owned locally by the Fluvi renderer.
abstract final class _LatestCarouselReferenceVisualSpec {
  static const cardPadding = EdgeInsets.fromLTRB(9, 7, 9, 18);
  static const headerSize = 20.0;
  static const headerIconSize = 12.0;
  static const headerGap = 5.0;
  static const headerBodyGap = 3.0;
  static const headerTitle = TextStyle(
    color: Color(0xFF1B294D),
    fontSize: 8,
    height: 1.18,
    fontWeight: FontWeight.w900,
  );
  static const primaryText = TextStyle(
    color: Color(0xFF19274C),
    fontSize: 13,
    height: 1.05,
    fontWeight: FontWeight.w900,
    fontVariations: <FontVariation>[FontVariation('wght', 950)],
  );
  static const amountText = TextStyle(
    color: Color(0xFF526FC5),
    fontSize: 13,
    height: 1.05,
    fontWeight: FontWeight.w900,
    fontVariations: <FontVariation>[FontVariation('wght', 950)],
  );
  static const partnerText = TextStyle(
    color: Color(0xFF65718E),
    fontSize: 6.5,
    height: 1.1,
    fontWeight: FontWeight.w700,
    fontVariations: <FontVariation>[FontVariation('wght', 750)],
  );
  static const headerIconColor = Color(0xFF5277D3);
  static const headerIconBackground = Color(0xFFEDF3FF);
}

final class _LatestAvatarPartnerPreview extends StatelessWidget {
  const _LatestAvatarPartnerPreview({required this.transaction});

  final DashboardBalanceScopedTransaction transaction;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey<String>(
      'balance-carousel-latest-avatar-partner-preview',
    ),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _LatestCarouselHeader(transaction: transaction),
      const SizedBox(height: _LatestCarouselReferenceVisualSpec.headerBodyGap),
      SizedBox(
        height: 15,
        child: Row(
          key: const ValueKey<String>('balance-carousel-latest-primary-row'),
          children: <Widget>[
            BalanceCategoryVisualBadge(
              key: const ValueKey<String>(
                'balance-carousel-latest-avatar-partner',
              ),
              semanticLabel: transaction.categoryTitle,
              categoryColorId: transaction.categoryColorId,
              categoryIconId: transaction.categoryIconId,
              size: 15,
              iconSize: 8,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                transaction.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _LatestCarouselReferenceVisualSpec.primaryText,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

final class _LatestThreeLinePreview extends StatelessWidget {
  const _LatestThreeLinePreview({required this.transaction});

  final DashboardBalanceScopedTransaction transaction;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey<String>('balance-carousel-latest-three-line'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _LatestCarouselHeader(transaction: transaction),
      const SizedBox(height: _LatestCarouselReferenceVisualSpec.headerBodyGap),
      SizedBox(
        height: 14,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            DashboardPreparedFormatter.amountMinor(
              transaction.amountMinor.abs(),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _LatestCarouselReferenceVisualSpec.amountText,
          ),
        ),
      ),
      Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Text(
            transaction.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: _LatestCarouselReferenceVisualSpec.partnerText,
          ),
        ),
      ),
    ],
  );
}

final class _LatestCarouselHeader extends StatelessWidget {
  const _LatestCarouselHeader({required this.transaction});

  final DashboardBalanceScopedTransaction transaction;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey<String>('balance-carousel-latest-reference-header'),
    height: _LatestCarouselReferenceVisualSpec.headerSize,
    child: Row(
      key: const ValueKey<String>('balance-carousel-latest-topic-row'),
      children: <Widget>[
        DecoratedBox(
          key: const ValueKey<String>('balance-carousel-latest-topic-badge'),
          decoration: const BoxDecoration(
            color: _LatestCarouselReferenceVisualSpec.headerIconBackground,
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: _LatestCarouselReferenceVisualSpec.headerSize,
            height: _LatestCarouselReferenceVisualSpec.headerSize,
            child: _LatestTransactionCategoryHeaderIcon(
              categoryIconId: transaction.categoryIconId,
            ),
          ),
        ),
        const SizedBox(width: _LatestCarouselReferenceVisualSpec.headerGap),
        const Expanded(
          child: Text(
            'Utolsó tranzakció',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _LatestCarouselReferenceVisualSpec.headerTitle,
          ),
        ),
      ],
    ),
  );
}

final class _LatestTransactionCategoryHeaderIcon extends StatelessWidget {
  const _LatestTransactionCategoryHeaderIcon({required this.categoryIconId});

  final String categoryIconId;

  @override
  Widget build(BuildContext context) {
    final atlas = PreparedVectorAssetAtlas.instance;
    if (atlas.isReady) {
      return Center(
        child: CategoryIconView(
          key: const ValueKey<String>(
            'balance-carousel-latest-header-category-icon',
          ),
          picture: atlas.categoryIcon(
            CategoryIconCatalog.handleOf(categoryIconId),
          ),
          size: _LatestCarouselReferenceVisualSpec.headerIconSize,
          color: _LatestCarouselReferenceVisualSpec.headerIconColor,
          semanticsLabel: CategoryIconCatalog.resolve(
            categoryIconId,
          ).semanticName,
        ),
      );
    }
    return const Icon(
      Icons.category_rounded,
      key: ValueKey<String>('balance-carousel-latest-header-category-icon'),
      size: _LatestCarouselReferenceVisualSpec.headerIconSize,
      color: _LatestCarouselReferenceVisualSpec.headerIconColor,
    );
  }
}
