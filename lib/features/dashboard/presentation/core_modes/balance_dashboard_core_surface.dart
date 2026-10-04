import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_border_profile.dart';
import '../../../../core/design/dashboard_corner_profile.dart';
import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_global_appearance.dart';
import '../../../../core/design/header_cascade_motion.dart';
import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/categories/presentation/category_avatar_palette_catalog.dart';
import '../../../../core/categories/presentation/category_avatar_palette_scope.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../../application/dashboard_balance_presentation.dart';
import '../../application/dashboard_balance_closings_momentum_projection.dart';
import '../../application/dashboard_balance_primary_projection.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import 'balance_carousel_wave_motion.dart';
import 'balance_carousel_wave_diagnostics.dart';
import 'balance_alternative_extended_sheet_cards.dart';
import 'balance_alternative_day_cards.dart';
import 'balance_alternative_scope_presentation.dart';
import 'balance_alternative_sum_cards.dart';
import 'balance_alternative_visual_tokens.dart';
import 'balance_extended_sheet_layout.dart';
import 'balance_four_section_layout.dart';
import 'balance_header_history_chart.dart';
import 'balance_header_income_expense_partition.dart';
import 'balance_insight_indicators.dart';
import 'balance_category_visual_badge.dart';
import 'balance_category_movers_presentation.dart';
import 'balance_category_movers_visual_tokens.dart';
import 'balance_linked_detail_card.dart';
import 'balance_cashflow_stability_card.dart';
import 'balance_momentum_card.dart';
import 'balance_presentation_settings.dart';
import 'balance_retention_card.dart';
import '../widgets/dashboard_placeholder_card.dart';
import '../widgets/dashboard_render_diagnostic_probe.dart';
import '../widgets/dashboard_header_trend_visual_kernel.dart';
import 'dashboard_core_mode_presentation.dart';
import 'dashboard_core_mode_surface_primitives.dart';
import 'dashboard_header_visual_engine.dart';
import '../dashboard_border_style.dart';
import '../dashboard_corner_roundness.dart';
import '../dashboard_shadow_style.dart';

String _indicatorIdFor(BalanceLinkedDetailTopic topic) =>
    _kindForTopic(topic).stableId;

BalanceCarouselCardKind _kindForTopic(BalanceLinkedDetailTopic topic) =>
    switch (topic) {
      BalanceLinkedDetailTopic.cashflow => BalanceCarouselCardKind.cashflow,
      BalanceLinkedDetailTopic.closings => BalanceCarouselCardKind.closings,
      BalanceLinkedDetailTopic.momentum => BalanceCarouselCardKind.momentum,
      BalanceLinkedDetailTopic.retention => BalanceCarouselCardKind.retention,
      BalanceLinkedDetailTopic.stability => BalanceCarouselCardKind.stability,
      BalanceLinkedDetailTopic.ghost => BalanceCarouselCardKind.ghost,
      BalanceLinkedDetailTopic.forecast => BalanceCarouselCardKind.forecast,
      BalanceLinkedDetailTopic.latestTransaction =>
        BalanceCarouselCardKind.latestTransaction,
      BalanceLinkedDetailTopic.categoryMovers =>
        BalanceCarouselCardKind.categoryMovers,
      BalanceLinkedDetailTopic.topCategory =>
        BalanceCarouselCardKind.topCategory,
      BalanceLinkedDetailTopic.topPartner => BalanceCarouselCardKind.topPartner,
    };

BalanceLinkedDetailTopic _topicForKind(BalanceCarouselCardKind kind) =>
    switch (kind) {
      BalanceCarouselCardKind.cashflow => BalanceLinkedDetailTopic.cashflow,
      BalanceCarouselCardKind.closings => BalanceLinkedDetailTopic.closings,
      BalanceCarouselCardKind.momentum => BalanceLinkedDetailTopic.momentum,
      BalanceCarouselCardKind.retention => BalanceLinkedDetailTopic.retention,
      BalanceCarouselCardKind.stability => BalanceLinkedDetailTopic.stability,
      BalanceCarouselCardKind.ghost => BalanceLinkedDetailTopic.ghost,
      BalanceCarouselCardKind.forecast => BalanceLinkedDetailTopic.forecast,
      BalanceCarouselCardKind.latestTransaction =>
        BalanceLinkedDetailTopic.latestTransaction,
      BalanceCarouselCardKind.categoryMovers =>
        BalanceLinkedDetailTopic.categoryMovers,
      BalanceCarouselCardKind.topCategory =>
        BalanceLinkedDetailTopic.topCategory,
      BalanceCarouselCardKind.topPartner => BalanceLinkedDetailTopic.topPartner,
    };

/// Resolves membership before it reaches the carousel datasource. Keeping the
/// result pure makes selection fallback testable and prevents hidden items
/// becoming geometry/semantic ghost slots.
@visibleForTesting
List<BalanceCarouselCardKind> visibleBalanceCarouselCardKindsFor(
  BalancePresentationSettings settings,
) => List<BalanceCarouselCardKind>.unmodifiable(
  BalanceCarouselCardKind.values.where(settings.isBalanceCarouselCardVisible),
);

@visibleForTesting
BalanceCarouselCardKind resolveVisibleBalanceCarouselCardKind({
  required BalanceCarouselCardKind selected,
  required BalancePresentationSettings settings,
}) {
  if (settings.isBalanceCarouselCardVisible(selected)) return selected;
  final visible = visibleBalanceCarouselCardKindsFor(settings);
  assert(visible.isNotEmpty, 'Balance carousel must retain one visible card.');
  final index = BalanceCarouselCardKind.values.indexOf(selected);
  for (
    var next = index + 1;
    next < BalanceCarouselCardKind.values.length;
    next += 1
  ) {
    final candidate = BalanceCarouselCardKind.values[next];
    if (settings.isBalanceCarouselCardVisible(candidate)) return candidate;
  }
  for (var previous = index - 1; previous >= 0; previous -= 1) {
    final candidate = BalanceCarouselCardKind.values[previous];
    if (settings.isBalanceCarouselCardVisible(candidate)) return candidate;
  }
  return visible.first;
}

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
    this.categoryColorId,
    this.categoryIconId,
  });

  final String id;
  final BalanceCarouselCardKind kind;
  final String title;
  final String amount;
  final String? detail;
  final String? categoryColorId;
  final String? categoryIconId;
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
      id: BalanceCarouselCardKind.cashflow.stableId,
      kind: BalanceCarouselCardKind.cashflow,
      title: 'Cashflow',
      amount: presentation == null
          ? '—'
          : DashboardPreparedFormatter.compactAmountMinor(
              presentation.cashflow.netTotalMinor,
            ),
      detail: 'Nettó cashflow',
    ),
    BalanceCarouselCard._(
      id: BalanceCarouselCardKind.closings.stableId,
      kind: BalanceCarouselCardKind.closings,
      title: 'Zárások',
      amount: closings == null ? '—' : balanceClosingsCompactSummary(closings),
      detail: 'Pozitív zárások',
    ),
    BalanceCarouselCard._(
      id: BalanceCarouselCardKind.momentum.stableId,
      kind: BalanceCarouselCardKind.momentum,
      title: 'Balance momentum',
      amount: momentum == null || !momentum.isAvailable
          ? 'Nincs adat'
          : formatBalanceMomentumRate(momentum.momentum, momentum.unit),
      detail: momentum == null
          ? 'Állapot nem elérhető'
          : balanceMomentumStateLabel(momentum.state),
    ),
    BalanceCarouselCard._(
      id: BalanceCarouselCardKind.retention.stableId,
      kind: BalanceCarouselCardKind.retention,
      title: 'Megtakarítási arány',
      amount: formatBalanceRetentionPeriod(retention?.selectedPeriod),
      detail: 'bevételből megtartva',
    ),
    BalanceCarouselCard._(
      id: BalanceCarouselCardKind.stability.stableId,
      kind: BalanceCarouselCardKind.stability,
      title: 'Cashflow stabilitás',
      amount: stability == null || !stability.isAvailable
          ? 'Nincs elég adat'
          : formatBalanceStabilityDeviation(
              stability.typicalDeviationTimesTwo!,
            ),
      detail: 'tipikus havi kilengés',
    ),
    BalanceCarouselCard._(
      id: BalanceCarouselCardKind.ghost.stableId,
      kind: BalanceCarouselCardKind.ghost,
      title: 'Fix terhek',
      amount: 'Hamarosan',
      detail: 'Ghost tranzakciók',
    ),
    BalanceCarouselCard._(
      id: BalanceCarouselCardKind.forecast.stableId,
      kind: BalanceCarouselCardKind.forecast,
      title: 'Forecast',
      amount: 'Hamarosan',
      detail: 'Várható zárás',
    ),
    BalanceCarouselCard._(
      id: BalanceCarouselCardKind.latestTransaction.stableId,
      kind: BalanceCarouselCardKind.latestTransaction,
      title: 'Utolsó tranzakció',
      amount: latest?.title ?? 'Nincs tétel',
      detail: latest == null
          ? 'Nincs összeg'
          : DashboardPreparedFormatter.compactAmountMinor(
              latest.amountMinor.abs(),
            ),
      categoryColorId: latest?.categoryColorId,
      categoryIconId: latest?.categoryIconId,
    ),
    BalanceCarouselCard._(
      id: BalanceCarouselCardKind.categoryMovers.stableId,
      kind: BalanceCarouselCardKind.categoryMovers,
      title: 'Legnagyobb kategóriaváltozás',
      amount: topMover?.label ?? 'Nincs kategóriaváltozás',
      detail: topMover == null
          ? 'Nincs összehasonlítható időszak'
          : balanceCategoryMoverPercentageLabel(topMover),
      categoryColorId: topMover?.categoryColorId,
      categoryIconId: topMover?.categoryIconId,
    ),
    BalanceCarouselCard._(
      id: BalanceCarouselCardKind.topCategory.stableId,
      kind: BalanceCarouselCardKind.topCategory,
      title: 'Top kategória',
      amount: topCategory?.label ?? 'Nincs adat',
      detail: topCategory == null
          ? 'Nincs összeg'
          : DashboardPreparedFormatter.compactAmountMinor(
              topCategory.amountMinor.abs(),
            ),
      categoryColorId: topCategory?.categoryColorId,
      categoryIconId: topCategory?.categoryIconId,
    ),
    BalanceCarouselCard._(
      id: BalanceCarouselCardKind.topPartner.stableId,
      kind: BalanceCarouselCardKind.topPartner,
      title: 'Top partner',
      amount: topPartner?.label ?? 'Nincs adat',
      detail: topPartner == null
          ? 'Nincs összeg'
          : DashboardPreparedFormatter.compactAmountMinor(
              topPartner.amountMinor.abs(),
            ),
      categoryColorId: topPartner?.categoryColorId,
      categoryIconId: topPartner?.categoryIconId,
    ),
  ]);
}

List<BalanceCarouselCard> _visibleBalanceCarouselCardsFor(
  DashboardBalanceLinkedPresentation? presentation,
  BalancePresentationSettings settings,
) => List<BalanceCarouselCard>.unmodifiable(
  balanceCarouselCardsFor(
    presentation,
  ).where((card) => settings.isBalanceCarouselCardVisible(card.kind)),
);

/// Maps the already selected semantic detail topic back to its canonical rail
/// item. This keeps content-card coloring on the same accent resolver as the
/// accepted mini-card system without adding a second topic palette.
BalanceCarouselCard _balanceCarouselCardForTopic(
  DashboardBalanceLinkedPresentation? presentation,
  BalanceLinkedDetailTopic topic,
) {
  final id = _indicatorIdFor(topic);
  return balanceCarouselCardsFor(
    presentation,
  ).firstWhere((card) => card.id == id);
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
  ValueListenable<BalancePresentationSettings>? _boundSettings;

  @override
  void initState() {
    super.initState();
    _bindPresentationSettings();
    _reconcileVisibleSelection();
  }

  @override
  void didUpdateWidget(covariant BalanceDashboardCoreSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentationSettings != widget.presentationSettings) {
      _boundSettings?.removeListener(_reconcileVisibleSelection);
      _bindPresentationSettings();
      _reconcileVisibleSelection();
    }
  }

  @override
  void dispose() {
    _boundSettings?.removeListener(_reconcileVisibleSelection);
    super.dispose();
  }

  void _bindPresentationSettings() {
    _boundSettings = widget.presentationSettings;
    _boundSettings?.addListener(_reconcileVisibleSelection);
  }

  void _reconcileVisibleSelection() {
    final settings =
        _boundSettings?.value ?? const BalancePresentationSettings.defaults();
    final resolved = _topicForKind(
      resolveVisibleBalanceCarouselCardKind(
        selected: _kindForTopic(_selectedTopic),
        settings: settings,
      ),
    );
    if (!mounted) return;
    // The outer Balance surface style is presentation state too. Rebuild the
    // local shell on every setting publication, while retaining the old
    // stable carousel/listenable topology below it. The carousel and dots
    // still own their dedicated settings listeners, so this never creates a
    // financial publication path.
    setState(() {
      _selectedTopic = resolved;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _withSettings(
      context,
      widget.presentationSettings?.value ??
          const BalancePresentationSettings.defaults(),
    );
  }

  Widget _withSettings(
    BuildContext context,
    BalancePresentationSettings settings,
  ) {
    final geometry = widget.presentation.geometry;
    final local = _BalanceLocalGeometry.resolve(geometry);
    final contentProgress = geometry.zone2Opacity.clamp(0.0, 1.0).toDouble();
    // Keep Balance's accepted two-card cascade during an in-flight collapse.
    // The parent shell is a fully expanded endpoint owner only, exactly as in
    // Budget: a giant static white rectangle must not cross the reveal lane.
    final isHeaderLinked =
        settings.contentSurfaceStyle ==
            BalanceContentSurfaceStyle.unifiedCard &&
        contentProgress >= .999 &&
        geometry.collapseProgress <= .001;
    final combinedBounds = DashboardHeaderContentMotherCardBounds.resolve(
      geometry: geometry,
    );
    final fourSectionBodyRect = _balanceAlternativeBodyRect(
      BoxConstraints.tightFor(
        width: combinedBounds.width,
        height: combinedBounds.height,
      ),
      geometry.headerBounds.height,
    );
    final showsTetris =
        isHeaderLinked &&
        settings.unifiedBodyLayout ==
            BalanceUnifiedBodyLayout.fourSectionTetris &&
        BalanceFourSectionLayout.canRenderWithin(fourSectionBodyRect);
    final headerRadius = DashboardCornerRoundnessScope.profileOf(context)
        .borderRadiusFor(
          DashboardCornerSurfaceFamily.header,
          size: Size(geometry.headerBounds.width, geometry.headerBounds.height),
        );
    final contentRadius = DashboardCornerRoundnessScope.profileOf(context)
        .borderRadiusFor(
          DashboardCornerSurfaceFamily.contentCard,
          size: Size(
            geometry.modeContentBounds.width,
            geometry.modeContentBounds.height,
          ),
        );
    final seamShape = DashboardHeaderContentSeamShape.resolve(
      seamless: isHeaderLinked,
      headerRadius: headerRadius,
      contentRadius: contentRadius,
      expansionProgress: contentProgress,
    );
    // The carousel's accepted dimensions were historically solved from the
    // standard gap below an upstream Summary. The new default body order puts
    // mode content before Summary, so that positional relationship is no
    // longer meaningful. Keep user-selected upstream orders intact, while
    // using the same scaled standard-gap reference for downstream Summary
    // orders. This decouples the rail's visual geometry from body ordering.
    final summaryToUpperGap =
        geometry.summaryBounds.bottom <= local.upperBounds.top
        ? local.upperBounds.top - geometry.summaryBounds.bottom
        : geometry.zone2Bounds.top - geometry.subheaderOneBounds.bottom;
    return KeyedSubtree(
      key: const ValueKey('dashboard-core-mode-balance'),
      // Balance geometry is resolved against the dashboard viewport. Make
      // that contract explicit even for isolated hosts (previews/tests); a
      // loose ancestor must not collapse every positioned mode region to a
      // one-pixel rail. Dashboard production already supplies these bounds,
      // so this does not alter its resolved physical geometry.
      child: SizedBox.expand(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _BalanceUnifiedHeaderContentSurface(
              geometry: geometry,
              settings: settings,
              selectedTopic: _selectedTopic,
              headerVisualFrame: widget.headerVisualFrame,
              seamShape: seamShape,
              isHeaderLinked: isHeaderLinked,
            ),
            DashboardCoreModeCascadeCard(
              bounds: local.lowerBounds,
              motion: local.lowerMotion,
              semanticKey: const ValueKey('dashboard-core-mode-balance-card-2'),
              showPlaceholderSurface: false,
              content: showsTetris
                  ? const SizedBox.shrink()
                  : _BalancePrimaryCardHost(
                      bounds: local.lowerBounds,
                      presentation: widget.balanceLinkedPresentation,
                      presentationSettings: widget.presentationSettings,
                      selectedTopic: _selectedTopic,
                      rankedListExtraHeight:
                          geometry.principalModeContentExtraHeight,
                      unifiedSurface: isHeaderLinked,
                    ),
            ),
            DashboardCoreModeCascadeCard(
              bounds: local.upperBounds,
              motion: local.upperMotion,
              semanticKey: const ValueKey('dashboard-core-mode-balance-card-1'),
              showPlaceholderSurface: false,
              content: showsTetris
                  ? const SizedBox.shrink()
                  : _BalanceUpperCarouselHost(
                      presentation: widget.balanceLinkedPresentation,
                      presentationSettings: widget.presentationSettings,
                      summaryToUpperGap: summaryToUpperGap,
                      selectedCardId: _indicatorIdFor(_selectedTopic),
                      onMotionInterrupted: widget.onCarouselMotionInterrupted,
                      onCardSelected: (card) {
                        final selected = _topicForKind(card.kind);
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
              child: showsTetris
                  ? const SizedBox.shrink()
                  : _BalanceVisibleInsightIndicators(
                      bounds: geometry.zone2IndicatorBounds,
                      activeItemId: _indicatorIdFor(_selectedTopic),
                      presentationSettings: widget.presentationSettings,
                    ),
            ),
            if (showsTetris)
              _BalanceAlternativeScopeScaffold(
                geometry: geometry,
                presentation: widget.balanceLinkedPresentation,
                usesChildCards: settings.usesChildCards,
                monthCombinedCardPresentation:
                    settings.monthCombinedCardPresentation,
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
              borderRadiusOverride: seamShape.headerRadius,
              showsDepth: !isHeaderLinked,
              showsBorder: !isHeaderLinked,
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
      ),
    );
  }
}

/// Dots share the exact member filter used by the carousel datasource. This
/// prevents a hidden-but-unselected item from leaving a visual ghost dot.
final class _BalanceVisibleInsightIndicators extends StatelessWidget {
  const _BalanceVisibleInsightIndicators({
    required this.bounds,
    required this.activeItemId,
    required this.presentationSettings,
  });

  final DashboardBounds bounds;
  final String activeItemId;
  final ValueListenable<BalancePresentationSettings>? presentationSettings;

  @override
  Widget build(BuildContext context) {
    final settings = presentationSettings;
    if (settings == null) {
      return _build(const BalancePresentationSettings.defaults());
    }
    return ValueListenableBuilder<BalancePresentationSettings>(
      valueListenable: settings,
      builder: (context, value, _) => _build(value),
    );
  }

  Widget _build(BalancePresentationSettings settings) =>
      BalanceInsightIndicators(
        bounds: bounds,
        itemIds: visibleBalanceCarouselCardKindsFor(
          settings,
        ).map((kind) => kind.stableId).toList(growable: false),
        activeItemId: activeItemId,
      );
}

/// Keeps the existing zone2 envelope as the one Balance primary-card surface.
/// Day intentionally retains a normal empty card until it receives its own
/// product specification.
final class _BalancePrimaryCardHost extends StatelessWidget {
  const _BalancePrimaryCardHost({
    required this.bounds,
    required this.presentation,
    required this.presentationSettings,
    required this.selectedTopic,
    required this.rankedListExtraHeight,
    this.unifiedSurface = false,
  });

  final DashboardBounds bounds;
  final ValueListenable<DashboardBalanceLinkedPresentation?>? presentation;
  final ValueListenable<BalancePresentationSettings>? presentationSettings;
  final BalanceLinkedDetailTopic selectedTopic;
  final double rankedListExtraHeight;
  final bool unifiedSurface;

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
    if (listenable == null) return _placeholder(context, settings);
    return ValueListenableBuilder<DashboardBalanceLinkedPresentation?>(
      valueListenable: listenable,
      builder: (context, value, _) {
        if (value == null ||
            (selectedTopic == BalanceLinkedDetailTopic.cashflow &&
                value.cashflow.mode ==
                    DashboardBalancePrimaryMode.unsupportedDay)) {
          return _placeholder(context, settings);
        }
        if (unifiedSurface) {
          return BalanceLinkedDetailCard(
            presentation: value,
            topic: selectedTopic,
            rankedListExtraHeight: rankedListExtraHeight,
          );
        }
        return DashboardPlaceholderCard(
          bounds: bounds,
          fillParent: true,
          semanticKey: const ValueKey<String>('balance-primary-card'),
          // Category Movers is a reference-locked two-page surface. Its
          // 22px outer contour must remain stable even when the global
          // content-card roundness tuner is set to another family value.
          borderRadiusOverride:
              selectedTopic == BalanceLinkedDetailTopic.categoryMovers
              ? BorderRadius.circular(
                  BalanceCategoryMoversVisualTokens.outerRadius,
                )
              : null,
          borderOverride: _balanceContentBorder(
            context: context,
            settings: settings,
            card: _balanceCarouselCardForTopic(value, selectedTopic),
          ),
          child: BalanceLinkedDetailCard(
            presentation: value,
            topic: selectedTopic,
            rankedListExtraHeight: rankedListExtraHeight,
          ),
        );
      },
    );
  }

  Widget _placeholder(
    BuildContext context,
    BalancePresentationSettings settings,
  ) => unifiedSurface
      ? const SizedBox.shrink()
      : DashboardPlaceholderCard(
          bounds: bounds,
          fillParent: true,
          semanticKey: const ValueKey<String>(
            'balance-primary-card-placeholder',
          ),
          borderRadiusOverride:
              selectedTopic == BalanceLinkedDetailTopic.categoryMovers
              ? BorderRadius.circular(
                  BalanceCategoryMoversVisualTokens.outerRadius,
                )
              : null,
          borderOverride: _balanceContentBorder(
            context: context,
            settings: settings,
            card: _balanceCarouselCardForTopic(null, selectedTopic),
          ),
        );
}

BoxBorder? _balanceContentBorder({
  required BuildContext context,
  required BalancePresentationSettings settings,
  required BalanceCarouselCard card,
}) {
  final configured = DashboardBorderScope.profileOf(
    context,
  ).borderFor(DashboardBorderSurface.balanceContent);
  if (!settings.balanceContentCardColoredBorderEnabled) return configured;
  final base = configured is Border
      ? configured
      : DashboardBorderProfile.searchPillSourceBorder;
  final accent = card.kind == BalanceCarouselCardKind.categoryMovers
      ? BalanceCategoryMoversVisualTokens.purpleLight
      : _BalanceCarouselReferenceAccent.resolve(context, card).color;
  BorderSide colored(BorderSide side) => side.copyWith(
    color: accent.withValues(alpha: settings.balanceContentCardBorderOpacity),
  );
  return Border(
    top: colored(base.top),
    right: colored(base.right),
    bottom: colored(base.bottom),
    left: colored(base.left),
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

/// A settled-only Balance surface using the same Header/content contract as
/// Budget. The established Balance cascade remains the physical owner during
/// every in-flight collapse, avoiding an opaque slab through that lane.
final class _BalanceUnifiedHeaderContentSurface extends StatelessWidget {
  const _BalanceUnifiedHeaderContentSurface({
    required this.geometry,
    required this.settings,
    required this.selectedTopic,
    required this.headerVisualFrame,
    required this.seamShape,
    required this.isHeaderLinked,
  });

  final DashboardLayoutFrame geometry;
  final BalancePresentationSettings settings;
  final BalanceLinkedDetailTopic selectedTopic;
  final ValueListenable<DashboardHeaderVisualFrame>? headerVisualFrame;
  final DashboardHeaderContentSeamShape seamShape;
  final bool isHeaderLinked;

  @override
  Widget build(BuildContext context) {
    if (!isHeaderLinked || !settings.alternativeMotherCardVisible) {
      return const SizedBox.shrink();
    }
    final combinedBounds = DashboardHeaderContentMotherCardBounds.resolve(
      geometry: geometry,
    );
    final bridgeHeight =
        (geometry.modeContentBounds.top - geometry.headerBounds.bottom + 34)
            .clamp(0.0, combinedBounds.height - geometry.headerBounds.height)
            .toDouble();
    return DashboardCoreModeFramePosition(
      bounds: combinedBounds,
      child: DashboardRenderDiagnosticProbe(
        candidate: 'balanceUnifiedHeaderContentSurface',
        material: 'surface=DashboardPlaceholderCard header+balance-content',
        clip: 'outer rounded surface; carousel descendants retain overflow',
        zOrder: 'unifiedSurface<carousel/detail/dots<header',
        child: DashboardPlaceholderCard(
          bounds: combinedBounds,
          fillParent: true,
          semanticKey: const ValueKey<String>(
            'balance-unified-header-content-surface',
          ),
          cornerFamily: DashboardCornerSurfaceFamily.contentCard,
          borderSurface: DashboardBorderSurface.balanceContent,
          borderRadiusOverride: seamShape.outerRadius,
          borderOverride: _balanceContentBorder(
            context: context,
            settings: settings,
            card: _balanceCarouselCardForTopic(null, selectedTopic),
          ),
          child: _BalanceUnifiedHeaderContentBridge(
            headerHeight: geometry.headerBounds.height,
            bridgeHeight: bridgeHeight,
            headerVisualFrame: headerVisualFrame,
          ),
        ),
      ),
    );
  }
}

/// A shallow non-interactive live Header-color bridge. It is intentionally
/// restricted to the seam rather than tinting the whole Balance body.
final class _BalanceUnifiedHeaderContentBridge extends StatelessWidget {
  const _BalanceUnifiedHeaderContentBridge({
    required this.headerHeight,
    required this.bridgeHeight,
    required this.headerVisualFrame,
  });

  final double headerHeight;
  final double bridgeHeight;
  final ValueListenable<DashboardHeaderVisualFrame>? headerVisualFrame;

  @override
  Widget build(BuildContext context) {
    final frames = headerVisualFrame;
    if (frames == null || bridgeHeight <= 0) return const SizedBox.expand();
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned(
          left: 0,
          right: 0,
          top: headerHeight,
          height: bridgeHeight,
          child: IgnorePointer(
            child: ValueListenableBuilder<DashboardHeaderVisualFrame>(
              valueListenable: frames,
              builder: (context, frame, _) => DecoratedBox(
                key: const ValueKey('balance-unified-header-color-bleed'),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      frame.colorB.withValues(alpha: .14),
                      frame.colorA.withValues(alpha: .04),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Selects a distinct alternative body composition from canonical scope
/// identity.  Only the immutable existing Balance primary presentation crosses
/// this UI boundary; it never asks for a second projection or query.
final class _BalanceAlternativeScopeScaffold extends StatelessWidget {
  const _BalanceAlternativeScopeScaffold({
    required this.geometry,
    required this.presentation,
    required this.usesChildCards,
    required this.monthCombinedCardPresentation,
  });

  final DashboardLayoutFrame geometry;
  final ValueListenable<DashboardBalanceLinkedPresentation?>? presentation;
  final bool usesChildCards;
  final BalanceMonthCombinedCardPresentation monthCombinedCardPresentation;

  @override
  Widget build(BuildContext context) {
    final linked = presentation;
    if (linked == null) {
      return BalanceAlternativeChildCardScope(
        usesChildCards: usesChildCards,
        child: _BalanceFourSectionScaffold(geometry: geometry),
      );
    }
    return ValueListenableBuilder<DashboardBalanceLinkedPresentation?>(
      valueListenable: linked,
      builder: (context, value, _) {
        if (value == null) {
          return BalanceAlternativeChildCardScope(
            usesChildCards: usesChildCards,
            child: _BalanceFourSectionScaffold(geometry: geometry),
          );
        }
        final alternative = BalanceAlternativeScopePresentation.fromLinked(
          value,
        );
        return BalanceAlternativeChildCardScope(
          usesChildCards: usesChildCards,
          child: switch (alternative) {
            BalanceAlternativeSumPresentation() =>
              _BalanceSumExtendedSheetScaffold(
                geometry: geometry,
                presentation: alternative,
              ),
            BalanceAlternativeYearPresentation() =>
              _BalanceYearExtendedSheetScaffold(
                geometry: geometry,
                presentation: alternative,
              ),
            BalanceAlternativeMonthPresentation() =>
              _BalanceMonthExtendedSheetScaffold(
                geometry: geometry,
                presentation: alternative,
                combinedCardPresentation: monthCombinedCardPresentation,
              ),
            BalanceAlternativeDayPresentation() =>
              _BalanceDayExtendedSheetScaffold(
                geometry: geometry,
                presentation: alternative,
              ),
          },
        );
      },
    );
  }
}

/// Napi 4 preserves the shared extended Mother Card but follows its own source
/// truth composition: coordinate field, one merged vertical impact card and
/// the full-width shared-data rhythm strip.
final class _BalanceDayExtendedSheetScaffold extends StatelessWidget {
  const _BalanceDayExtendedSheetScaffold({
    required this.geometry,
    required this.presentation,
  });

  final DashboardLayoutFrame geometry;
  final BalanceAlternativeDayPresentation presentation;

  @override
  Widget build(BuildContext context) => _BalanceExtendedSheetFrame(
    geometry: geometry,
    scopeKey: 'day',
    childrenFor: (layout) {
      final insights = presentation.dailyInsights;
      final mergedImpact = Rect.fromLTRB(
        layout.card4.left,
        layout.card4.top,
        layout.card5.right,
        layout.card5.bottom,
      );
      return <Widget>[
        _BalanceAlternativeSectionSlot(
          slot: layout.card3,
          allocationKey: const ValueKey<String>('balance-tetris-slot-3'),
          surfaceKey: const ValueKey<String>('balance-tetris-card-3'),
          child: Semantics(
            label: insights.momentum.available
                ? 'Pénzügyi koordinátarendszer: ${insights.momentum.selected.quadrant.label}'
                : 'Pénzügyi koordinátarendszer még nem elérhető',
            child: BalanceAlternativeDailyMomentumCoordinateCard(
              presentation: insights.momentum,
            ),
          ),
        ),
        _BalanceAlternativeSectionSlot(
          slot: mergedImpact,
          allocationKey: const ValueKey<String>(
            'balance-tetris-slot-daily-impact',
          ),
          surfaceKey: const ValueKey<String>(
            'balance-tetris-card-daily-impact',
          ),
          child: Semantics(
            label: insights.impact.available
                ? 'Napi hatás ${insights.impact.valuePercent!.round()} százalék'
                : 'Napi hatás még nem hasonlítható össze',
            child: BalanceAlternativeDailyImpactCard(
              presentation: insights.impact,
            ),
          ),
        ),
        _BalanceAlternativeSectionSlot(
          slot: layout.combined,
          allocationKey: const ValueKey<String>('balance-tetris-slot-combined'),
          surfaceKey: const ValueKey<String>('balance-tetris-card-combined'),
          child: Semantics(
            label: 'Összehasonlító ritmuscsík',
            child: BalanceAlternativeDailyMomentumRhythmCard(
              presentation: insights.momentum,
            ),
          ),
        ),
      ];
    },
  );
}

/// SUM uses the same canonical extended-sheet body allocation as Havi 2 and
/// Éves. This is deliberately a new composition only: the Mother Card bounds,
/// outer inset and 70/30/40 child geometry remain in their shared owners.
final class _BalanceSumExtendedSheetScaffold extends StatelessWidget {
  const _BalanceSumExtendedSheetScaffold({
    required this.geometry,
    required this.presentation,
  });

  final DashboardLayoutFrame geometry;
  final BalanceAlternativeSumPresentation presentation;

  @override
  Widget build(BuildContext context) => _BalanceExtendedSheetFrame(
    geometry: geometry,
    scopeKey: 'sum',
    childrenFor: (layout) {
      final distribution = presentation.distribution;
      return <Widget>[
        _BalanceAlternativeSectionSlot(
          slot: layout.card3,
          allocationKey: const ValueKey<String>('balance-tetris-slot-3'),
          surfaceKey: const ValueKey<String>('balance-tetris-card-3'),
          child: Semantics(
            label:
                'Havi eredmények eloszlása ${distribution.histogram.sampleCount} lezárt hónapból',
            child: BalanceAlternativeSumHistogramCard(
              presentation: distribution.histogram,
            ),
          ),
        ),
        _BalanceAlternativeSectionSlot(
          slot: layout.card4,
          allocationKey: const ValueKey<String>('balance-tetris-slot-4'),
          surfaceKey: const ValueKey<String>('balance-tetris-card-4'),
          child: Semantics(
            label:
                'Leghosszabb pozitív széria: ${distribution.longestPositiveStreak.length} hónap',
            child: BalanceAlternativePositiveStreakCard(
              presentation: distribution.longestPositiveStreak,
            ),
          ),
        ),
        _BalanceAlternativeSectionSlot(
          slot: layout.card5,
          allocationKey: const ValueKey<String>('balance-tetris-slot-5'),
          surfaceKey: const ValueKey<String>('balance-tetris-card-5'),
          child: Semantics(
            label: 'Megtakarítási arány',
            child: BalanceAlternativeSavingsRingCard(
              presentation: presentation.savings,
              minimumContentSize:
                  BalanceAlternativeHtmlTokens.sumSideCardMinimumContentSize,
            ),
          ),
        ),
        _BalanceAlternativeSectionSlot(
          slot: layout.combined,
          allocationKey: const ValueKey<String>('balance-tetris-slot-combined'),
          surfaceKey: const ValueKey<String>('balance-tetris-card-combined'),
          child: Semantics(
            label:
                'Cashflow stabilitás ${distribution.cashflowBand.sampleCount} lezárt hónapból',
            child: BalanceAlternativeCashflowStabilityBandCard(
              presentation: distribution.cashflowBand,
            ),
          ),
        ),
      ];
    },
  );
}

/// Havi 2 is the approved monthly alternative: one daily-spend Card 3, two
/// small factual cards in the top-right, and one lower combined strip. It is
/// deliberately separate from [BalanceFiveSectionLayout], whose Card 1/2
/// allocations remain independent for the earlier SUM phase.
final class _BalanceMonthExtendedSheetScaffold extends StatelessWidget {
  const _BalanceMonthExtendedSheetScaffold({
    required this.geometry,
    required this.presentation,
    required this.combinedCardPresentation,
  });

  final DashboardLayoutFrame geometry;
  final BalanceAlternativeMonthPresentation presentation;
  final BalanceMonthCombinedCardPresentation combinedCardPresentation;

  @override
  Widget build(BuildContext context) => _BalanceExtendedSheetFrame(
    geometry: geometry,
    scopeKey: 'month',
    childrenFor: (layout) {
      final dailySpend = presentation.dailySpend;
      final savings = presentation.savings;
      final incomeExpense = presentation.incomeExpense;
      final mergedSavings = Rect.fromLTRB(
        layout.card4.left,
        layout.card4.top,
        layout.card5.right,
        layout.card5.bottom,
      );
      return <Widget>[
        _BalanceAlternativeSectionSlot(
          slot: layout.card3,
          allocationKey: const ValueKey<String>('balance-tetris-slot-3'),
          surfaceKey: const ValueKey<String>('balance-tetris-card-3'),
          child: Semantics(
            label: 'Költés napi idősor',
            child: BalanceAlternativeDailySpendCard(
              presentation: dailySpend,
              timeScope: presentation.timeScope,
            ),
          ),
        ),
        _BalanceAlternativeSectionSlot(
          slot: mergedSavings,
          allocationKey: const ValueKey<String>('balance-tetris-slot-savings'),
          surfaceKey: const ValueKey<String>('balance-tetris-card-savings'),
          child: Semantics(
            label: 'Megtakarítás',
            child: BalanceAlternativeSavingsRingCard(presentation: savings),
          ),
        ),
        _BalanceAlternativeSectionSlot(
          slot: layout.combined,
          allocationKey: const ValueKey<String>('balance-tetris-slot-combined'),
          surfaceKey: const ValueKey<String>('balance-tetris-card-combined'),
          child: switch (combinedCardPresentation) {
            BalanceMonthCombinedCardPresentation.incomeExpense => Semantics(
              label: 'Bevétel és kiadás összehasonlítás',
              child: BalanceAlternativeIncomeExpenseStripCard(
                presentation: incomeExpense,
              ),
            ),
            BalanceMonthCombinedCardPresentation.spendingRhythm => Semantics(
              label: 'Napi költési ritmus',
              child: BalanceAlternativeMonthlySpendingRhythmCard(
                presentation: dailySpend,
              ),
            ),
          },
        ),
      ];
    },
  );
}

/// Éves follows the same HTML extended-sheet allocation as Havi 2, but owns
/// the distinct annual bar/line close chart and income/expense chart payloads.
final class _BalanceYearExtendedSheetScaffold extends StatelessWidget {
  const _BalanceYearExtendedSheetScaffold({
    required this.geometry,
    required this.presentation,
  });

  final DashboardLayoutFrame geometry;
  final BalanceAlternativeYearPresentation presentation;

  @override
  Widget build(BuildContext context) => _BalanceExtendedSheetFrame(
    geometry: geometry,
    scopeKey: 'year',
    childrenFor: (layout) {
      final closings = presentation.closings;
      final savings = presentation.savings;
      final incomeExpense = presentation.incomeExpense;
      final mergedSavings = Rect.fromLTRB(
        layout.card4.left,
        layout.card4.top,
        layout.card5.right,
        layout.card5.bottom,
      );
      return <Widget>[
        _BalanceAlternativeSectionSlot(
          slot: layout.card3,
          allocationKey: const ValueKey<String>('balance-tetris-slot-3'),
          surfaceKey: const ValueKey<String>('balance-tetris-card-3'),
          child: Semantics(
            label: 'Éves alakulás havi zárásokkal',
            child: BalanceAlternativeAnnualClosingsCard(
              presentation: closings,
              timeScope: presentation.timeScope,
            ),
          ),
        ),
        _BalanceAlternativeSectionSlot(
          slot: mergedSavings,
          allocationKey: const ValueKey<String>('balance-tetris-slot-savings'),
          surfaceKey: const ValueKey<String>('balance-tetris-card-savings'),
          child: Semantics(
            label: 'Megtakarítás',
            child: BalanceAlternativeSavingsRingCard(presentation: savings),
          ),
        ),
        _BalanceAlternativeSectionSlot(
          slot: layout.combined,
          allocationKey: const ValueKey<String>('balance-tetris-slot-combined'),
          surfaceKey: const ValueKey<String>('balance-tetris-card-combined'),
          child: Semantics(
            label: 'Éves bevétel és kiadás összehasonlítás',
            child: BalanceAlternativeAnnualIncomeExpenseCard(
              presentation: incomeExpense,
              timeScope: presentation.timeScope,
            ),
          ),
        ),
      ];
    },
  );
}

/// One geometric frame shared by Havi 2 and Éves. Data is injected by the
/// scope router; no repository, Query, or projection path enters this widget.
final class _BalanceExtendedSheetFrame extends StatelessWidget {
  const _BalanceExtendedSheetFrame({
    required this.geometry,
    required this.scopeKey,
    required this.childrenFor,
  });

  final DashboardLayoutFrame geometry;
  final String scopeKey;
  final List<Widget> Function(BalanceExtendedSheetLayout layout) childrenFor;

  @override
  Widget build(BuildContext context) {
    final combinedBounds = DashboardHeaderContentMotherCardBounds.resolve(
      geometry: geometry,
    );
    return DashboardCoreModeFramePosition(
      bounds: combinedBounds,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          key: ValueKey<String>('balance-alternative-$scopeKey-layout'),
          clipBehavior: Clip.none,
          children: childrenFor(
            BalanceExtendedSheetLayout.resolve(
              _balanceAlternativeBodyRect(
                constraints,
                geometry.headerBounds.height,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Existing four-section alternative layout.  MONTH and DAY intentionally
/// remain on this exact composition until their dedicated visual phases.
final class _BalanceFourSectionScaffold extends StatelessWidget {
  const _BalanceFourSectionScaffold({required this.geometry});

  final DashboardLayoutFrame geometry;

  @override
  Widget build(BuildContext context) {
    final combinedBounds = DashboardHeaderContentMotherCardBounds.resolve(
      geometry: geometry,
    );
    return DashboardCoreModeFramePosition(
      bounds: combinedBounds,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bodyRect = _balanceAlternativeBodyRect(
            constraints,
            geometry.headerBounds.height,
          );
          final layout = BalanceFourSectionLayout.resolve(bodyRect);
          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              _BalanceFourSectionSlot(
                slot: layout.card1,
                label: 'Card 1',
                semanticsLabel: 'Balance alternatív szekció 1',
                allocationKey: const ValueKey<String>('balance-tetris-slot-1'),
                surfaceKey: const ValueKey<String>('balance-tetris-card-1'),
              ),
              _BalanceFourSectionSlot(
                slot: layout.card2,
                label: 'Card 2',
                semanticsLabel: 'Balance alternatív szekció 2',
                allocationKey: const ValueKey<String>('balance-tetris-slot-2'),
                surfaceKey: const ValueKey<String>('balance-tetris-card-2'),
              ),
              _BalanceFourSectionSlot(
                slot: layout.card3,
                label: 'Card 3',
                semanticsLabel: 'Balance alternatív szekció 3',
                allocationKey: const ValueKey<String>('balance-tetris-slot-3'),
                surfaceKey: const ValueKey<String>('balance-tetris-card-3'),
              ),
              _BalanceFourSectionSlot(
                slot: layout.card4,
                label: 'Card 4',
                semanticsLabel: 'Balance alternatív szekció 4',
                allocationKey: const ValueKey<String>('balance-tetris-slot-4'),
                surfaceKey: const ValueKey<String>('balance-tetris-card-4'),
              ),
            ],
          );
        },
      ),
    );
  }
}

Rect _balanceAlternativeBodyRect(
  BoxConstraints constraints,
  double headerHeight,
) {
  const outerInset = BalanceAlternativeHtmlTokens.outerInset;
  final bodyHeight = math.max(0.0, constraints.maxHeight - headerHeight);
  return Rect.fromLTWH(
    outerInset,
    headerHeight + outerInset,
    math.max(0.0, constraints.maxWidth - outerInset * 2),
    math.max(0.0, bodyHeight - outerInset * 2),
  );
}

final class _BalanceFourSectionSlot extends StatelessWidget {
  const _BalanceFourSectionSlot({
    required this.slot,
    required this.label,
    required this.semanticsLabel,
    required this.allocationKey,
    required this.surfaceKey,
  });

  final Rect slot;
  final String label;
  final String semanticsLabel;
  final Key allocationKey;
  final Key surfaceKey;

  @override
  Widget build(BuildContext context) {
    return _BalanceAlternativeSectionSlot(
      slot: slot,
      allocationKey: allocationKey,
      surfaceKey: surfaceKey,
      child: Semantics(
        label: semanticsLabel,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: FluviVisualTokens.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: FluviVisualTokens.textSecondary.withValues(alpha: .14),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: FluviVisualTokens.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _BalanceAlternativeSectionSlot extends StatelessWidget {
  const _BalanceAlternativeSectionSlot({
    required this.slot,
    required this.allocationKey,
    required this.surfaceKey,
    required this.child,
  });

  final Rect slot;
  final Key allocationKey;
  final Key surfaceKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Deflating every allocation by half a gutter makes one consistent shared
    // 6px visual seam without perturbing the mathematical slot boundaries.
    return Positioned.fromRect(
      rect: slot,
      child: SizedBox.expand(
        key: allocationKey,
        child: Padding(
          padding: const EdgeInsets.all(
            BalanceAlternativeHtmlTokens.halfGutter,
          ),
          child: KeyedSubtree(key: surfaceKey, child: child),
        ),
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
    final history = balance?.history;
    final balancePresentation = balance;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (settings.headerGraphPresentation ==
                BalanceHeaderGraphPresentation.lineChart &&
            history != null)
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
        if (settings.headerGraphPresentation ==
                BalanceHeaderGraphPresentation.incomeExpensePartition &&
            balancePresentation != null)
          BalanceHeaderIncomeExpensePartition(
            incomeMinor: balancePresentation.incomeTotalMinor,
            expenseMinor: balancePresentation.expenseTotalMinor,
            heightPercent: settings.headerPartitionHeightPercent,
            plotTop: chartLayout.plotTop,
            plotHeight: chartLayout.plotHeight,
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
        if (balance case final balance?)
          Positioned(
            left: DashboardHeaderTrendChartStyle.detailLeft,
            top: chartLayout.valueTop,
            child: Text(
              balance.formattedNetTotal,
              key: const ValueKey<String>('balance-header-net-amount'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.applyTo(
                DefaultTextStyle.of(context).style
                    .merge(
                      DashboardHeaderTrendChartStyle.primaryValueTextMetrics,
                    )
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
    required this.selectedCardId,
    required this.onMotionInterrupted,
    required this.onCardSelected,
  });

  final ValueListenable<DashboardBalanceLinkedPresentation?>? presentation;
  final ValueListenable<BalancePresentationSettings>? presentationSettings;
  final double summaryToUpperGap;
  final String selectedCardId;
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
        cards: _visibleBalanceCarouselCardsFor(null, settings),
        presentationSettings: settings,
        summaryToUpperGap: summaryToUpperGap,
        selectedCardId: selectedCardId,
        onMotionInterrupted: onMotionInterrupted,
        onCardSelected: onCardSelected,
      );
    }
    return ValueListenableBuilder<DashboardBalanceLinkedPresentation?>(
      valueListenable: listenable,
      builder: (context, presentation, _) {
        return _BalanceUpperCarousel(
          cards: _visibleBalanceCarouselCardsFor(presentation, settings),
          presentationSettings: settings,
          summaryToUpperGap: summaryToUpperGap,
          selectedCardId: selectedCardId,
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
    required this.presentationSettings,
    required this.summaryToUpperGap,
    required this.selectedCardId,
    required this.onMotionInterrupted,
    required this.onCardSelected,
  });

  final List<BalanceCarouselCard> cards;
  final BalancePresentationSettings presentationSettings;
  final double summaryToUpperGap;
  final String selectedCardId;
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
      inwardVisualOffset <= cardWidth * (1 - _neighborScale) / 2 + .001,
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

final class _BalanceUpperCarouselState extends State<_BalanceUpperCarousel>
    with SingleTickerProviderStateMixin {
  late final CenteredCarouselController _controller;
  late final AnimationController _wavePhaseController = AnimationController(
    vsync: this,
    duration: balanceCarouselWaveBaseDuration,
  );
  late final BalanceCarouselWaveRuntimeDiagnostics _waveDiagnostics =
      BalanceCarouselWaveRuntimeDiagnostics(
        clockOwner: '_BalanceUpperCarouselState',
        configuredDuration: _wavePhaseController.duration!,
      );
  late final String _waveMarkerOwner;
  late final Map<String, Object?> Function() _waveMarkerContext;
  Duration? _appliedWavePeriod;
  double _appliedWaveSpeed = balanceCarouselWaveDefaultSpeedMultiplier;
  var _waveBuildRevision = 0;

  @override
  void initState() {
    super.initState();
    // A fresh rail can follow the parent-owned stable topic immediately.
    // This matters when the temporary four-section scaffold is dismissed:
    // recreating the renderer must restore the selected visible topic, not
    // initialise a second source of truth at Cashflow.  The generic carousel
    // performs its own first configuration after build, so an initial index
    // is the correct pre-configuration API (not semantic-domain installation).
    final selectedIndex = widget.cards.indexWhere(
      (card) => card.id == widget.selectedCardId,
    );
    _controller = CenteredCarouselController(
      initialIndex: selectedIndex < 0 ? 0 : selectedIndex,
    );
    _waveMarkerOwner = 'balanceWave.${identityHashCode(this)}';
    _waveMarkerContext = () => _waveDiagnostics.snapshot.toMarkerContext();
    _wavePhaseController.addListener(_sampleWaveClock);
    FluviDiagnosticLogger.registerUserMarkerContext(
      _waveMarkerOwner,
      _waveMarkerContext,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncWaveAnimation();
  }

  @override
  void didUpdateWidget(covariant _BalanceUpperCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cardMembershipChanged = !listEquals(
      _cardIds(oldWidget.cards),
      _cardIds(widget.cards),
    );
    if (cardMembershipChanged && widget.cards.isNotEmpty) {
      final selectedIndex = widget.cards.indexWhere(
        (card) => card.id == widget.selectedCardId,
      );
      _controller.installSemanticDomain(
        dataMode: _dataModeForCards(widget.cards),
        finiteLength: widget.cards.length,
        selectedLogicalIndex: selectedIndex < 0 ? 0 : selectedIndex,
        policy:
            CenteredCarouselSemanticInstallPolicy.reconcileCanonicalSelection,
      );
    }
    _syncWaveAnimation();
  }

  List<String> _cardIds(List<BalanceCarouselCard> cards) =>
      cards.map((card) => card.id).toList(growable: false);

  CenteredCarouselDataMode _dataModeForCards(List<BalanceCarouselCard> cards) =>
      cards.length <= 2
      ? CenteredCarouselDataMode.bounded
      : CenteredCarouselDataMode.cyclic;

  void _syncWaveAnimation() {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shouldAnimate =
        widget.presentationSettings.balanceCarouselWaveAnimationEnabled &&
        !reducedMotion;
    final requestedSpeed =
        widget.presentationSettings.balanceCarouselWaveSpeedMultiplier;
    final requestedPeriod = balanceCarouselWaveEffectiveDuration(
      requestedSpeed,
    );
    if (shouldAnimate) {
      final requiresNewRate = _appliedWavePeriod != requestedPeriod;
      if (!_wavePhaseController.isAnimating || requiresNewRate) {
        final phaseBefore = _wavePhaseController.value;
        // AnimationController.repeat(period:) begins the new periodic rate at
        // its current value. The controller, profile identities and local
        // offsets remain stable, so speed changes cannot reset the silhouette.
        _wavePhaseController.repeat(period: requestedPeriod);
        final phaseAfter = _wavePhaseController.value;
        if (_appliedWavePeriod != null && requiresNewRate) {
          _waveDiagnostics.speedChanged(
            oldMultiplier: _appliedWaveSpeed,
            newMultiplier: requestedSpeed,
            phaseBefore: phaseBefore,
            phaseAfter: phaseAfter,
            effectiveDuration: requestedPeriod,
            controllerRecreated: false,
          );
        }
        _appliedWavePeriod = requestedPeriod;
        _appliedWaveSpeed = requestedSpeed;
      }
    } else {
      _wavePhaseController.stop();
      // Phase zero is the authored, reference-locked static wave. Returning
      // here makes both the explicit toggle and reduced-motion state fully
      // static instead of freezing a partially deformed animation frame.
      if (_wavePhaseController.value != 0) _wavePhaseController.value = 0;
    }
    if (!_waveDiagnostics.isBound) {
      _waveDiagnostics.bind(
        animationEnabled:
            widget.presentationSettings.balanceCarouselWaveAnimationEnabled,
        reducedMotion: reducedMotion,
        clockRunning: _wavePhaseController.isAnimating,
        waveOpacity: widget.presentationSettings.balanceCarouselWaveOpacity,
        backgroundOpacity:
            widget.presentationSettings.balanceCarouselBackgroundOpacity,
        speedMultiplier: requestedSpeed,
        effectiveDuration: requestedPeriod,
      );
    } else {
      _waveDiagnostics.settingsChanged(
        animationEnabled:
            widget.presentationSettings.balanceCarouselWaveAnimationEnabled,
        reducedMotion: reducedMotion,
        clockRunning: _wavePhaseController.isAnimating,
        waveOpacity: widget.presentationSettings.balanceCarouselWaveOpacity,
        backgroundOpacity:
            widget.presentationSettings.balanceCarouselBackgroundOpacity,
        borderOpacity: widget.presentationSettings.balanceCarouselBorderOpacity,
        speedMultiplier: requestedSpeed,
        effectiveDuration: requestedPeriod,
      );
    }
  }

  void _sampleWaveClock() => _waveDiagnostics.onTick(
    elapsed: _wavePhaseController.lastElapsedDuration ?? Duration.zero,
    phase: _wavePhaseController.value,
    buildRevision: _waveBuildRevision,
  );

  @override
  void dispose() {
    FluviDiagnosticLogger.unregisterUserMarkerContext(
      _waveMarkerOwner,
      _waveMarkerContext,
    );
    _wavePhaseController.removeListener(_sampleWaveClock);
    _wavePhaseController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _waveBuildRevision += 1;
    return LayoutBuilder(
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
          dataSource: widget.cards.length <= 2
              ? BoundedCarouselDataSource<BalanceCarouselCard>(widget.cards)
              : CyclicCarouselDataSource<BalanceCarouselCard>(widget.cards),
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
              'Megtakarítási arány: ${card.amount}',
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
          itemBuilder: (context, card, metrics) =>
              _BalanceCarouselPressFeedback(
                child: Transform.translate(
                  offset: Offset(geometry.inwardOffsetFor(metrics), 0),
                  transformHitTests: true,
                  child: _BalanceCarouselCard(
                    card: card,
                    width: geometry.cardWidth,
                    itemHeight: carouselHeight,
                    isSelected: metrics.isSelected,
                    presentationSettings: widget.presentationSettings,
                    wavePhase: _wavePhaseController,
                    waveDiagnostics: _waveDiagnostics,
                  ),
                ),
              ),
        );
      },
    );
  }
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
    required this.isSelected,
    required this.presentationSettings,
    required this.wavePhase,
    required this.waveDiagnostics,
  });

  final BalanceCarouselCard card;
  final double width;
  final double itemHeight;
  final bool isSelected;
  final BalancePresentationSettings presentationSettings;
  final Animation<double> wavePhase;
  final BalanceCarouselWaveRuntimeDiagnostics waveDiagnostics;

  @override
  Widget build(BuildContext context) {
    // The selected card owns the full structural upper-card height in real
    // layout/hit bounds. The shared carousel keeps it at scale 1 and scales
    // only its neighbours down, so no selected visual relies on paint-only
    // overflow or an undersized interactive parent.
    final visualSpec = _BalanceCarouselReferenceVisualSpec.resolve(
      size: Size(width, itemHeight),
    );
    final accent = _BalanceCarouselReferenceAccent.resolve(context, card);
    final paint = _BalanceCarouselReferencePaint.resolve(
      visualSpec: visualSpec,
      isSelected: isSelected,
      presentationSettings: presentationSettings,
    );
    final waveProfile = BalanceCarouselWaveMotion.profileForCardId(card.id);
    waveDiagnostics.bindProfile(waveProfile, selected: isSelected);
    return SizedBox(
      key: ValueKey<String>('balance-carousel-card-${card.id}'),
      width: width,
      height: itemHeight,
      child: Builder(
        builder: (context) {
          final depth = DashboardShadowStyleScope.profileOf(
            context,
          ).depthFor(DashboardCornerSurfaceFamily.contentCard);
          final borderRadius = DashboardCornerRoundnessScope.profileOf(context)
              .borderRadiusFor(
                DashboardCornerSurfaceFamily.contentCard,
                size: Size(width, itemHeight),
              );
          return DecoratedBox(
            key: ValueKey<String>('balance-carousel-card-surface-${card.id}'),
            decoration: BoxDecoration(
              color: depth.surfaceColor ?? FluviVisualTokens.surface,
              border: DashboardBorderScope.profileOf(
                context,
              ).borderFor(DashboardBorderSurface.balanceContent),
              borderRadius: borderRadius,
              boxShadow: depth.shadows,
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Stack(
                key: ValueKey<String>(
                  'balance-carousel-card-decoration-stack-${card.id}',
                ),
                fit: StackFit.expand,
                children: <Widget>[
                  DecoratedBox(
                    key: ValueKey<String>(
                      'balance-carousel-card-reference-tint-${card.id}',
                    ),
                    decoration: BoxDecoration(
                      color: accent.color.withValues(alpha: paint.tintOpacity),
                    ),
                  ),
                  KeyedSubtree(
                    key: ValueKey<String>(
                      'balance-carousel-card-wave-layer-${card.id}',
                    ),
                    child: _BalanceCarouselAmbientWave(
                      paintKey: ValueKey<String>(
                        'balance-carousel-card-reference-wave-${card.id}',
                      ),
                      phase: wavePhase,
                      animated:
                          presentationSettings
                              .balanceCarouselWaveAnimationEnabled &&
                          !(MediaQuery.maybeOf(context)?.disableAnimations ??
                              false),
                      accentColor: accent.color,
                      profile: waveProfile,
                      opacity: paint.waveOpacity,
                      finalTintOpacity: paint.tintOpacity,
                      diagnostics: waveDiagnostics,
                    ),
                  ),
                  KeyedSubtree(
                    key: ValueKey<String>(
                      'balance-carousel-card-content-layer-${card.id}',
                    ),
                    child: _BalanceCarouselMiniCardContent(
                      card: card,
                      visualSpec: visualSpec,
                      accent: accent,
                    ),
                  ),
                  KeyedSubtree(
                    key: ValueKey<String>(
                      'balance-carousel-card-outline-layer-${card.id}',
                    ),
                    child: IgnorePointer(
                      child: DecoratedBox(
                        key: ValueKey<String>(
                          'balance-carousel-card-reference-shell-${card.id}',
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: accent.color.withValues(
                              alpha: paint.outlineOpacity,
                            ),
                            width: paint.outlineWidth,
                          ),
                          borderRadius: borderRadius,
                        ),
                      ),
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

/// The sole reference-derived metric source for every Balance mini card. The
/// shared carousel owns all focus/side scaling; this object owns only the
/// internal card anatomy and scales it as one unit for constrained embeds.
@immutable
final class _BalanceCarouselReferenceVisualSpec {
  const _BalanceCarouselReferenceVisualSpec._({
    required this.horizontalPadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.titleTrailingGap,
    required this.iconTileSize,
    required this.iconGlyphSizeFactor,
    required this.iconTileCornerRadiusFactor,
    required this.titleFontSize,
    required this.primaryFontSize,
    required this.secondaryFontSize,
    required this.primaryToSecondaryGap,
    required this.normalTintOpacity,
    required this.selectedTintOpacity,
    required this.normalOutlineOpacity,
    required this.selectedOutlineOpacity,
    required this.normalOutlineWidth,
    required this.selectedOutlineWidth,
    required this.normalWaveOpacity,
    required this.selectedWaveOpacity,
  });

  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final double titleTrailingGap;
  final double iconTileSize;
  final double iconGlyphSizeFactor;
  final double iconTileCornerRadiusFactor;
  final double titleFontSize;
  final double primaryFontSize;
  final double secondaryFontSize;
  final double primaryToSecondaryGap;
  final double normalTintOpacity;
  final double selectedTintOpacity;
  final double normalOutlineOpacity;
  final double selectedOutlineOpacity;
  final double normalOutlineWidth;
  final double selectedOutlineWidth;
  final double normalWaveOpacity;
  final double selectedWaveOpacity;

  static _BalanceCarouselReferenceVisualSpec resolve({required Size size}) {
    // The existing outer envelope is intentionally preserved. The reference
    // grammar is therefore fitted inside the established 72px normal height,
    // then uniformly reduced only for genuinely constrained embeddings.
    final scale = (size.height / 72).clamp(.55, 1.0).toDouble();
    return _BalanceCarouselReferenceVisualSpec._(
      horizontalPadding: 12 * scale,
      topPadding: 9 * scale,
      bottomPadding: 6 * scale,
      titleTrailingGap: 7 * scale,
      iconTileSize: 24 * scale,
      iconGlyphSizeFactor: .52,
      iconTileCornerRadiusFactor: .30,
      titleFontSize: 9.5 * scale,
      primaryFontSize: 17 * scale,
      secondaryFontSize: 14 * scale,
      primaryToSecondaryGap: 1 * scale,
      normalTintOpacity: .055,
      selectedTintOpacity: .075,
      normalOutlineOpacity: .30,
      selectedOutlineOpacity: .58,
      normalOutlineWidth: 1,
      selectedOutlineWidth: 1.35,
      // Field evidence showed the former .095/.15 fill alphas were too close
      // to the white/tinted card surface to reveal the moving edge. These
      // remain translucent, but make the materially moving 4–8px silhouette
      // perceptible at the actual 79px center-card height.
      normalWaveOpacity: .13,
      selectedWaveOpacity: .20,
    );
  }

  double tintOpacityFor(bool isSelected) =>
      isSelected ? selectedTintOpacity : normalTintOpacity;

  double outlineOpacityFor(bool isSelected) =>
      isSelected ? selectedOutlineOpacity : normalOutlineOpacity;

  double outlineWidthFor(bool isSelected) =>
      isSelected ? selectedOutlineWidth : normalOutlineWidth;

  double waveOpacityFor(bool isSelected) =>
      isSelected ? selectedWaveOpacity : normalWaveOpacity;
}

/// Resolves only paint alpha from the immutable user choices. The accepted
/// reference metric source above remains the owner of every card dimension and
/// wave-coordinate value, so settings cannot perturb carousel geometry.
@immutable
final class _BalanceCarouselReferencePaint {
  const _BalanceCarouselReferencePaint._({
    required this.tintOpacity,
    required this.outlineOpacity,
    required this.outlineWidth,
    required this.waveOpacity,
  });

  final double tintOpacity;
  final double outlineOpacity;
  final double outlineWidth;
  final double waveOpacity;

  factory _BalanceCarouselReferencePaint.resolve({
    required _BalanceCarouselReferenceVisualSpec visualSpec,
    required bool isSelected,
    required BalancePresentationSettings presentationSettings,
  }) {
    final authoredTint = visualSpec.tintOpacityFor(isSelected);
    final authoredOutline = visualSpec.outlineOpacityFor(isSelected);
    final authoredWave = visualSpec.waveOpacityFor(isSelected);
    return _BalanceCarouselReferencePaint._(
      tintOpacity: presentationSettings.balanceCarouselTintedBackgroundEnabled
          ? authoredTint * presentationSettings.balanceCarouselBackgroundOpacity
          : 0,
      outlineOpacity: presentationSettings.balanceCarouselBorderEnabled
          ? authoredOutline * presentationSettings.balanceCarouselBorderOpacity
          : 0,
      outlineWidth: visualSpec.outlineWidthFor(isSelected),
      waveOpacity:
          authoredWave * presentationSettings.balanceCarouselWaveOpacity,
    );
  }
}

@immutable
final class _BalanceCarouselReferenceAccent {
  const _BalanceCarouselReferenceAccent._({
    required this.gradient,
    required this.color,
  });

  final LinearGradient gradient;
  final Color color;

  static _BalanceCarouselReferenceAccent resolve(
    BuildContext context,
    BalanceCarouselCard card,
  ) {
    final colorId = card.categoryColorId;
    final gradient = colorId == null
        ? FluviVisualTokens.appHighlightGradient
        : CategoryAvatarPaletteCatalog.gradientFor(
            CategoryAvatarColorProfileScope.profileOf(context),
            CategoryColorCatalog.handleOf(colorId),
          );
    final colors = gradient.colors;
    return _BalanceCarouselReferenceAccent._(
      gradient: gradient,
      color: colors[colors.length ~/ 2],
    );
  }
}

/// One canonical reference grammar for all Balance carousel topics. Topic
/// differences are supplied only by immutable copy and accent identity.
final class _BalanceCarouselMiniCardContent extends StatelessWidget {
  const _BalanceCarouselMiniCardContent({
    required this.card,
    required this.visualSpec,
    required this.accent,
  });

  final BalanceCarouselCard card;
  final _BalanceCarouselReferenceVisualSpec visualSpec;
  final _BalanceCarouselReferenceAccent accent;

  @override
  Widget build(BuildContext context) {
    // The carousel-wide canonical grammar deliberately takes precedence over
    // the older Latest-specific presentation choice: every topic exposes its
    // semantic primary on line one and compact context on line two.
    final primary = card.amount;
    final secondary = card.detail ?? '—';
    return Stack(
      children: <Widget>[
        Positioned(
          left: visualSpec.horizontalPadding,
          top: visualSpec.topPadding,
          right:
              visualSpec.horizontalPadding +
              visualSpec.iconTileSize +
              visualSpec.titleTrailingGap,
          child: Text(
            card.title,
            key: ValueKey<String>('balance-carousel-card-title-${card.id}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: FluviVisualTokens.textSecondary,
              fontSize: visualSpec.titleFontSize,
              height: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Positioned(
          top: visualSpec.topPadding,
          right: visualSpec.horizontalPadding,
          child: _BalanceCarouselIconTile(
            key: ValueKey<String>('balance-carousel-card-icon-tile-${card.id}'),
            card: card,
            accent: accent,
            size: visualSpec.iconTileSize,
            visualSpec: visualSpec,
          ),
        ),
        Positioned(
          left: visualSpec.horizontalPadding,
          right: visualSpec.horizontalPadding,
          bottom: visualSpec.bottomPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                primary,
                key: ValueKey<String>(
                  'balance-carousel-card-primary-${card.id}',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: FluviVisualTokens.textPrimary,
                  fontSize: visualSpec.primaryFontSize,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: visualSpec.primaryToSecondaryGap),
              Text(
                secondary,
                key: ValueKey<String>(
                  'balance-carousel-card-secondary-${card.id}',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent.color,
                  fontSize: visualSpec.secondaryFontSize,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _BalanceCarouselIconTile extends StatelessWidget {
  const _BalanceCarouselIconTile({
    super.key,
    required this.card,
    required this.accent,
    required this.size,
    required this.visualSpec,
  });

  final BalanceCarouselCard card;
  final _BalanceCarouselReferenceAccent accent;
  final double size;
  final _BalanceCarouselReferenceVisualSpec visualSpec;

  @override
  Widget build(BuildContext context) {
    final colorId = card.categoryColorId;
    final iconId = card.categoryIconId;
    if (colorId != null && iconId != null) {
      return SizedBox(
        width: size,
        height: size,
        child: BalanceCategoryVisualBadge(
          key: ValueKey<String>('balance-carousel-card-visual-${card.id}'),
          semanticLabel: card.amount,
          categoryColorId: colorId,
          categoryIconId: iconId,
          size: size,
          iconSize: size * visualSpec.iconGlyphSizeFactor,
        ),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        key: ValueKey<String>('balance-carousel-card-visual-${card.id}'),
        decoration: BoxDecoration(
          gradient: accent.gradient,
          borderRadius: BorderRadius.circular(
            size * visualSpec.iconTileCornerRadiusFactor,
          ),
        ),
        child: Icon(
          _iconFor(card.kind),
          color: Colors.white,
          size: size * visualSpec.iconGlyphSizeFactor,
        ),
      ),
    );
  }

  IconData _iconFor(BalanceCarouselCardKind kind) => switch (kind) {
    BalanceCarouselCardKind.cashflow => Icons.account_balance_wallet_rounded,
    BalanceCarouselCardKind.closings => Icons.event_available_rounded,
    BalanceCarouselCardKind.momentum => Icons.trending_up_rounded,
    BalanceCarouselCardKind.retention => Icons.savings_rounded,
    BalanceCarouselCardKind.stability => Icons.monitor_heart_rounded,
    BalanceCarouselCardKind.ghost => Icons.repeat_rounded,
    BalanceCarouselCardKind.forecast => Icons.auto_graph_rounded,
    BalanceCarouselCardKind.latestTransaction ||
    BalanceCarouselCardKind.categoryMovers ||
    BalanceCarouselCardKind.topCategory ||
    BalanceCarouselCardKind.topPartner => Icons.category_rounded,
  };
}

final class _BalanceCarouselSoftWavePainter extends CustomPainter {
  _BalanceCarouselSoftWavePainter({
    required this.accentColor,
    required this.opacity,
    required this.finalTintOpacity,
    required this.profile,
    required Animation<double>? phaseClock,
    required this.staticPhase,
    required this.diagnostics,
  }) : _phaseClock = phaseClock,
       super(repaint: phaseClock);

  final Color accentColor;
  final double opacity;
  final double finalTintOpacity;
  final BalanceCarouselWaveProfile profile;
  final Animation<double>? _phaseClock;
  final double staticPhase;
  final BalanceCarouselWaveRuntimeDiagnostics diagnostics;
  final Path _path = Path();
  final Paint _paint = Paint()..style = PaintingStyle.fill;
  var _paintRevision = 0;

  /// Exposed to focused presentation tests: the live geometry is identity
  /// based and periodic, never selected-position based.
  double get phase => _phaseClock?.value ?? staticPhase;

  BalanceCarouselWaveGeometry get geometry =>
      BalanceCarouselWaveMotion.geometryFor(
        profile: profile,
        clockPhase: phase,
      );

  @override
  void paint(Canvas canvas, Size size) {
    _paintRevision += 1;
    final waveGeometry = geometry;
    final path = _path;
    BalanceCarouselWaveMotion.writeFilledPath(
      path: path,
      geometry: waveGeometry,
      size: size,
    );
    canvas.drawPath(
      path,
      _paint..color = accentColor.withValues(alpha: opacity),
    );
    diagnostics.onPaint(
      profile: profile,
      globalPhase: phase,
      paintBounds: size,
      geometry: waveGeometry,
      effectiveWaveAlpha: opacity,
      finalTintAlpha: finalTintOpacity,
      painterRevision: _paintRevision,
    );
  }

  @override
  bool shouldRepaint(covariant _BalanceCarouselSoftWavePainter oldDelegate) =>
      oldDelegate.accentColor != accentColor ||
      oldDelegate.opacity != opacity ||
      oldDelegate.finalTintOpacity != finalTintOpacity ||
      oldDelegate.profile != profile ||
      oldDelegate._phaseClock != _phaseClock ||
      oldDelegate.staticPhase != staticPhase ||
      oldDelegate.diagnostics != diagnostics;
}

/// Paint-only wrapper around the carousel-owned clock. [CustomPainter.repaint]
/// makes phase ticks repaint just this boundary rather than rebuilding card
/// layout, content, carousel geometry, or financial projections.
final class _BalanceCarouselAmbientWave extends StatelessWidget {
  const _BalanceCarouselAmbientWave({
    required this.paintKey,
    required this.phase,
    required this.animated,
    required this.accentColor,
    required this.profile,
    required this.opacity,
    required this.finalTintOpacity,
    required this.diagnostics,
  });

  final Key paintKey;
  final Animation<double> phase;
  final bool animated;
  final Color accentColor;
  final BalanceCarouselWaveProfile profile;
  final double opacity;
  final double finalTintOpacity;
  final BalanceCarouselWaveRuntimeDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      key: paintKey,
      painter: _BalanceCarouselSoftWavePainter(
        accentColor: accentColor,
        opacity: opacity,
        finalTintOpacity: finalTintOpacity,
        profile: profile,
        phaseClock: animated ? phase : null,
        staticPhase: 0,
        diagnostics: diagnostics,
      ),
    ),
  );
}
