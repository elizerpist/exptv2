import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_border_profile.dart';
import '../../../../core/design/dashboard_corner_profile.dart';
import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_global_appearance.dart';
import '../../application/dashboard_balance_presentation.dart';
import '../../application/dashboard_balance_header_context_presentation.dart';
import '../../application/dashboard_balance_closings_momentum_projection.dart';
import '../../application/dashboard_balance_primary_projection.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import 'balance_alternative_extended_sheet_cards.dart';
import 'balance_alternative_day_cards.dart';
import 'balance_alternative_scope_presentation.dart';
import 'balance_alternative_sum_cards.dart';
import 'balance_sum_focused_layout.dart';
import 'balance_alternative_visual_tokens.dart';
import 'balance_extended_sheet_layout.dart';
import 'balance_year_focused_layout.dart';
import 'balance_month_focused_layout.dart';
import 'balance_day_focused_layout.dart';
import '../dashboard_day_rhythm_navigation.dart';
import 'balance_four_section_layout.dart';
import 'balance_focused_cascade.dart';
import 'balance_unified_mother_card_geometry.dart';
import 'dashboard_joined_mother_card_material.dart';
import 'balance_header_history_chart.dart';
import 'balance_header_glass_bar.dart';
import 'balance_header_income_expense_partition.dart';
import 'balance_presentation_settings.dart';
import '../widgets/dashboard_header_trend_visual_kernel.dart';
import 'dashboard_core_mode_presentation.dart';
import 'dashboard_core_mode_surface_primitives.dart';
import 'dashboard_header_visual_engine.dart';
import '../dashboard_border_style.dart';
import '../dashboard_corner_roundness.dart';
import '../dashboard_shadow_style.dart';

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

/// Balance owns its Header data seam and one persistent analytical Mother Card.
/// Physical material and inner content follow the same master collapse frame.
class BalanceDashboardCoreSurface extends StatefulWidget {
  const BalanceDashboardCoreSurface({
    super.key,
    required this.presentation,
    this.balancePresentation,
    this.balanceLinkedPresentation,
    this.headerVisualController,
    this.headerVisualFrame,
    this.presentationSettings,
    this.adaptiveScope = const AllTimeScope(),
    this.headerHistoryChartPointerObserver,
    this.dayRhythmNavigation,
  });

  final DashboardDayRhythmNavigation? dayRhythmNavigation;
  final DashboardCoreModePresentation presentation;
  final ValueListenable<DashboardBalancePresentation?>? balancePresentation;
  final ValueListenable<DashboardBalanceLinkedPresentation?>?
  balanceLinkedPresentation;
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
  final _headerContextProjection = DashboardBalanceHeaderContextProjection();
  BalanceMonthPerspective _monthPerspective =
      BalanceMonthPerspective.balanceTrend;
  BalanceYearPerspective _yearPerspective = BalanceYearPerspective.monthlyNet;

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
    final transition = BalanceUnifiedMotherCardGeometry.resolve(
      frame: geometry,
      headerRadius: headerRadius,
      contentRadius: contentRadius,
    );
    final seamShape = transition.shape;
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
              transition: transition,
              headerVisualFrame: widget.headerVisualFrame,
            ),
            _BalanceContentMotion(
              transition: transition,
              frame: geometry,
              child: _BalanceAlternativeScopeScaffold(
                dayRhythmNavigation: widget.dayRhythmNavigation,
                monthPerspective: () => _monthPerspective,
                onMonthPerspectiveChanged: (next) {
                  _monthPerspective = next;
                },
                yearPerspective: () => _yearPerspective,
                onYearPerspectiveChanged: (next) {
                  _yearPerspective = next;
                },
                geometry: geometry,
                presentation: widget.balanceLinkedPresentation,
                presentationSettings: widget.presentationSettings,
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
              borderRadiusOverride: seamShape.headerRadius,
              showsDepth: true,
              showsBorder: true,
              depthProgress: transition.separation,
              borderProgress: transition.separation,
              detail: _BalanceHeaderDetail(
                contextProjection: _headerContextProjection,
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

/// The stable material owner is independent from the analytical subtree.
final class _BalanceUnifiedHeaderContentSurface extends StatelessWidget {
  const _BalanceUnifiedHeaderContentSurface({
    required this.transition,
    required this.headerVisualFrame,
  });
  final BalanceUnifiedMotherCardGeometry transition;
  final ValueListenable<DashboardHeaderVisualFrame>? headerVisualFrame;
  @override
  Widget build(BuildContext context) {
    final depth = DashboardShadowStyleScope.profileOf(
      context,
    ).depthFor(DashboardCornerSurfaceFamily.contentCard);
    return DashboardJoinedMotherCardMaterial(
      headerBounds: transition.headerBounds,
      bodyBounds: transition.visibleBodyBounds,
      shape: transition.shape,
      separation: transition.separation,
      opacity: transition.opacity,
      headerBase: depth.surfaceColor ?? FluviVisualTokens.surface,
      shadows: depth.shadows,
      border: DashboardBorderScope.profileOf(
        context,
      ).borderFor(DashboardBorderSurface.balanceContent),
      semanticKey: const ValueKey('balance-unified-header-content-surface'),
      bodyKey: const ValueKey('balance-unified-moving-body'),
      child: Opacity(
        opacity: 1 - transition.separation,
        child: _BalanceUnifiedHeaderContentBridge(
          headerHeight: 0,
          bridgeHeight: transition.bridgeHeight,
          headerVisualFrame: headerVisualFrame,
        ),
      ),
    );
  }
}

/// Retains the real scope widget in one fixed parent. Physical clipping and
/// inner slide are resolved in the same viewport coordinates; chart state and
/// prepared financial samples survive every forward/reverse collapse frame.
final class _BalanceContentMotion extends StatelessWidget {
  const _BalanceContentMotion({
    required this.transition,
    required this.frame,
    required this.child,
  });
  final DashboardLayoutFrame frame;
  final BalanceUnifiedMotherCardGeometry transition;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = transition;
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: t.separation > .02,
        child: ClipPath(
          clipBehavior: Clip.hardEdge,
          clipper: _BalanceBodyClipper(
            t.visibleBodyBounds,
            t.shape.contentRadius,
          ),
          child: Transform(
            key: const ValueKey('balance-unified-content-transform'),
            alignment: Alignment.topLeft,
            transform: t.contentTransform,
            child: BalanceFocusedCascadeScope(
              frame: frame,
              lowerTransform: t.contentTransform,
              lowerOpacity: t.contentOpacity,
              child: Stack(clipBehavior: Clip.none, children: [child]),
            ),
          ),
        ),
      ),
    );
  }
}

final class _BalanceBodyClipper extends CustomClipper<Path> {
  const _BalanceBodyClipper(this.rect, this.radius);
  final Rect rect;
  final BorderRadius radius;
  @override
  Path getClip(Size size) => Path()..addRRect(radius.toRRect(rect));
  @override
  bool shouldReclip(_BalanceBodyClipper old) =>
      old.rect != rect || old.radius != radius;
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
final class _BalanceAlternativeScopeScaffold extends StatefulWidget {
  const _BalanceAlternativeScopeScaffold({
    this.dayRhythmNavigation,
    required this.monthPerspective,
    required this.onMonthPerspectiveChanged,
    required this.yearPerspective,
    required this.onYearPerspectiveChanged,
    required this.geometry,
    required this.presentation,
    required this.presentationSettings,
  });

  final DashboardDayRhythmNavigation? dayRhythmNavigation;
  final ValueGetter<BalanceMonthPerspective> monthPerspective;
  final ValueChanged<BalanceMonthPerspective> onMonthPerspectiveChanged;
  final ValueGetter<BalanceYearPerspective> yearPerspective;
  final ValueChanged<BalanceYearPerspective> onYearPerspectiveChanged;
  final DashboardLayoutFrame geometry;
  final ValueListenable<DashboardBalanceLinkedPresentation?>? presentation;
  final ValueListenable<BalancePresentationSettings>? presentationSettings;

  @override
  State<_BalanceAlternativeScopeScaffold> createState() =>
      _BalanceAlternativeScopeScaffoldState();
}

class _BalanceAlternativeScopeScaffoldState
    extends State<_BalanceAlternativeScopeScaffold> {
  DashboardBalanceLinkedPresentation? _preparedSource;
  BalanceAlternativeScopePresentation? _preparedScope;
  DashboardDayRhythmNavigation? get dayRhythmNavigation =>
      widget.dayRhythmNavigation;
  ValueGetter<BalanceMonthPerspective> get monthPerspective =>
      widget.monthPerspective;
  ValueChanged<BalanceMonthPerspective> get onMonthPerspectiveChanged =>
      widget.onMonthPerspectiveChanged;
  ValueGetter<BalanceYearPerspective> get yearPerspective =>
      widget.yearPerspective;
  ValueChanged<BalanceYearPerspective> get onYearPerspectiveChanged =>
      widget.onYearPerspectiveChanged;
  DashboardLayoutFrame get geometry => widget.geometry;
  ValueListenable<DashboardBalanceLinkedPresentation?>? get presentation =>
      widget.presentation;
  ValueListenable<BalancePresentationSettings>? get presentationSettings =>
      widget.presentationSettings;

  BalanceAlternativeScopePresentation _scopeFor(
    DashboardBalanceLinkedPresentation source,
  ) {
    // Presentation choices and collapse frames reuse the same prepared sample.
    // A new immutable Core publication invalidates the composition as a unit.
    if (!identical(source, _preparedSource)) {
      _preparedSource = source;
      _preparedScope = BalanceAlternativeScopePresentation.fromLinked(source);
    }
    return _preparedScope!;
  }

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
    final linked = presentation;
    if (linked == null) {
      return BalanceAlternativeChildCardScope(
        usesChildCards: settings.usesChildCards,
        child: _BalanceFourSectionScaffold(geometry: geometry),
      );
    }
    return ValueListenableBuilder<DashboardBalanceLinkedPresentation?>(
      valueListenable: linked,
      builder: (context, value, _) {
        if (value == null) {
          return BalanceAlternativeChildCardScope(
            usesChildCards: settings.usesChildCards,
            child: _BalanceFourSectionScaffold(geometry: geometry),
          );
        }
        final alternative = _scopeFor(value);
        return BalanceAlternativeChildCardScope(
          usesChildCards: settings.usesChildCards,
          child: switch (alternative) {
            BalanceAlternativeSumPresentation() =>
              settings.sumLayoutPresentation ==
                      BalanceSumLayoutPresentation.focused
                  ? _BalanceSumFocusedScaffold(
                      geometry: geometry,
                      presentation: alternative,
                      settings: settings,
                      onPerspectiveChanged:
                          presentationSettings is BalancePresentationController
                          ? (presentationSettings
                                    as BalancePresentationController)
                                .setSumFocusedPresentation
                          : null,
                    )
                  : _BalanceSumExtendedSheetScaffold(
                      geometry: geometry,
                      presentation: alternative,
                    ),
            BalanceAlternativeYearPresentation() =>
              settings.yearLayoutPresentation ==
                      BalanceYearLayoutPresentation.focused
                  ? _BalanceYearFocusedScaffold(
                      initialPerspective: yearPerspective(),
                      onPerspectiveChanged: onYearPerspectiveChanged,
                      geometry: geometry,
                      presentation: alternative,
                    )
                  : _BalanceYearExtendedSheetScaffold(
                      geometry: geometry,
                      presentation: alternative,
                      yearBarPresentation: settings.yearBarPresentation,
                    ),
            BalanceAlternativeMonthPresentation() =>
              settings.monthLayoutPresentation ==
                      BalanceMonthLayoutPresentation.focused
                  ? _BalanceMonthFocusedScaffold(
                      initialPerspective: monthPerspective(),
                      onPerspectiveChanged: onMonthPerspectiveChanged,
                      geometry: geometry,
                      presentation: alternative,
                    )
                  : _BalanceMonthExtendedSheetScaffold(
                      geometry: geometry,
                      presentation: alternative,
                      combinedCardPresentation:
                          settings.monthCombinedCardPresentation,
                      monthlySpendingChartPresentation:
                          settings.monthlySpendingChartPresentation,
                    ),
            BalanceAlternativeDayPresentation() =>
              settings.dayLayoutPresentation ==
                      BalanceDayLayoutPresentation.focused
                  ? _BalanceDayFocusedScaffold(
                      geometry: geometry,
                      presentation: alternative,
                      onFocusedPresentationChanged:
                          presentationSettings is BalancePresentationController
                          ? (presentationSettings
                                    as BalancePresentationController)
                                .setDayFocusedPresentation
                          : null,
                      focusedPresentation: settings.dayFocusedPresentation,
                      ratioPresentation: settings.dayRatioPresentation,
                      ratioViewPresentation: settings.dayRatioViewPresentation,
                      performanceVisualPresentation:
                          settings.dayPerformanceVisualPresentation,
                      showFocusedDayImpact: settings.showFocusedDayImpact,
                      navigation: dayRhythmNavigation,
                    )
                  : _BalanceDayExtendedSheetScaffold(
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
          padding: layout.childInsetsFor(layout.card3),
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
          padding: layout.childInsetsFor(mergedImpact),
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
          padding: layout.childInsetsFor(layout.combined),
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
          padding: layout.childInsetsFor(layout.card3),
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
          padding: layout.childInsetsFor(layout.card4),
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
          padding: layout.childInsetsFor(layout.card5),
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
          padding: layout.childInsetsFor(layout.combined),
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
    required this.monthlySpendingChartPresentation,
  });

  final DashboardLayoutFrame geometry;
  final BalanceAlternativeMonthPresentation presentation;
  final BalanceMonthCombinedCardPresentation combinedCardPresentation;
  final BalanceMonthlySpendingChartPresentation
  monthlySpendingChartPresentation;

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
          padding: layout.childInsetsFor(layout.card3),
          allocationKey: const ValueKey<String>('balance-tetris-slot-3'),
          surfaceKey: const ValueKey<String>('balance-tetris-card-3'),
          child: Semantics(
            label: 'Költés napi idősor',
            child: BalanceAlternativeDailySpendCard(
              presentation: dailySpend,
              timeScope: presentation.timeScope,
              chartPresentation: monthlySpendingChartPresentation,
            ),
          ),
        ),
        _BalanceAlternativeSectionSlot(
          slot: mergedSavings,
          padding: layout.childInsetsFor(mergedSavings),
          allocationKey: const ValueKey<String>('balance-tetris-slot-savings'),
          surfaceKey: const ValueKey<String>('balance-tetris-card-savings'),
          child: Semantics(
            label: 'Megtakarítás',
            child: BalanceAlternativeSavingsRingCard(
              presentation: savings,
              expandedRingMaximum: 148,
              expandedRingHorizontalInset: 0,
              expandedPercentageFontSize:
                  BalanceAlternativeSavingsRingCard.monthYearPercentageFontSize,
            ),
          ),
        ),
        _BalanceAlternativeSectionSlot(
          slot: layout.combined,
          padding: layout.childInsetsFor(layout.combined),
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

/// SUM alternative inside the existing Mother Card bounds.
final class _BalanceSumFocusedScaffold extends StatelessWidget {
  const _BalanceSumFocusedScaffold({
    required this.geometry,
    required this.presentation,
    required this.settings,
    this.onPerspectiveChanged,
  });
  final DashboardLayoutFrame geometry;
  final BalanceAlternativeSumPresentation presentation;
  final BalancePresentationSettings settings;
  final ValueChanged<BalanceSumFocusedPresentation>? onPerspectiveChanged;
  @override
  Widget build(BuildContext context) => _BalanceScopeFrame(
    geometry: geometry,
    focused: true,
    child: LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Positioned.fromRect(
            rect: _balanceAlternativeBodyRect(
              constraints,
              geometry.headerBounds.height,
            ),
            child: BalanceSumFocusedLayout(
              presentation: presentation,
              perspective: settings.sumFocusedPresentation,
              showSupplementaryStats: settings.showSumFocusedSupplementaryStats,
              onPerspectiveChanged: onPerspectiveChanged,
            ),
          ),
        ],
      ),
    ),
  );
}

final class _BalanceMonthFocusedScaffold extends StatelessWidget {
  const _BalanceMonthFocusedScaffold({
    required this.initialPerspective,
    required this.onPerspectiveChanged,
    required this.geometry,
    required this.presentation,
  });
  final BalanceMonthPerspective initialPerspective;
  final ValueChanged<BalanceMonthPerspective> onPerspectiveChanged;
  final DashboardLayoutFrame geometry;
  final BalanceAlternativeMonthPresentation presentation;

  @override
  Widget build(BuildContext context) => _BalanceScopeFrame(
    geometry: geometry,
    focused: true,
    child: LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Positioned.fromRect(
            rect: _balanceAlternativeBodyRect(
              constraints,
              geometry.headerBounds.height,
            ),
            child: BalanceMonthFocusedLayout(
              presentation: presentation,
              initialPerspective: initialPerspective,
              onPerspectiveChanged: onPerspectiveChanged,
            ),
          ),
        ],
      ),
    ),
  );
}

final class _BalanceDayFocusedScaffold extends StatelessWidget {
  const _BalanceDayFocusedScaffold({
    required this.geometry,
    required this.presentation,
    required this.focusedPresentation,
    required this.ratioPresentation,
    required this.ratioViewPresentation,
    required this.performanceVisualPresentation,
    required this.showFocusedDayImpact,
    this.navigation,
    this.onFocusedPresentationChanged,
  });
  final DashboardLayoutFrame geometry;
  final BalanceAlternativeDayPresentation presentation;
  final BalanceDayFocusedPresentation focusedPresentation;
  final BalanceDayRatioPresentation ratioPresentation;
  final BalanceDayRatioViewPresentation ratioViewPresentation;
  final BalanceDayPerformanceVisualPresentation performanceVisualPresentation;
  final bool showFocusedDayImpact;
  final DashboardDayRhythmNavigation? navigation;
  final ValueChanged<BalanceDayFocusedPresentation>?
  onFocusedPresentationChanged;
  @override
  Widget build(BuildContext context) => _BalanceScopeFrame(
    geometry: geometry,
    focused: true,
    child: LayoutBuilder(
      builder: (context, c) => Stack(
        children: [
          Positioned.fromRect(
            rect: _balanceAlternativeBodyRect(c, geometry.headerBounds.height),
            child: BalanceDayFocusedLayout(
              presentation: presentation.dailyInsights,
              focusedPresentation: focusedPresentation,
              ratioPresentation: ratioPresentation,
              ratioViewPresentation: ratioViewPresentation,
              performanceVisualPresentation: performanceVisualPresentation,
              showFocusedDayImpact: showFocusedDayImpact,
              navigation: navigation,
              onFocusedPresentationChanged: onFocusedPresentationChanged,
            ),
          ),
        ],
      ),
    ),
  );
}

final class _BalanceYearFocusedScaffold extends StatelessWidget {
  const _BalanceYearFocusedScaffold({
    required this.initialPerspective,
    required this.onPerspectiveChanged,
    required this.geometry,
    required this.presentation,
  });
  final BalanceYearPerspective initialPerspective;
  final ValueChanged<BalanceYearPerspective> onPerspectiveChanged;
  final DashboardLayoutFrame geometry;
  final BalanceAlternativeYearPresentation presentation;

  @override
  Widget build(BuildContext context) => _BalanceScopeFrame(
    geometry: geometry,
    focused: true,
    child: LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Positioned.fromRect(
            rect: _balanceAlternativeBodyRect(
              constraints,
              geometry.headerBounds.height,
            ),
            child: BalanceYearFocusedLayout(
              presentation: presentation,
              initialPerspective: initialPerspective,
              onPerspectiveChanged: onPerspectiveChanged,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Éves follows the same HTML extended-sheet allocation as Havi 2, but owns
/// the distinct annual bar/line close chart and income/expense chart payloads.
final class _BalanceYearExtendedSheetScaffold extends StatelessWidget {
  const _BalanceYearExtendedSheetScaffold({
    required this.geometry,
    required this.presentation,
    required this.yearBarPresentation,
  });

  final DashboardLayoutFrame geometry;
  final BalanceAlternativeYearPresentation presentation;
  final BalanceYearBarPresentation yearBarPresentation;

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
          padding: layout.childInsetsFor(layout.card3),
          allocationKey: const ValueKey<String>('balance-tetris-slot-3'),
          surfaceKey: const ValueKey<String>('balance-tetris-card-3'),
          child: Semantics(
            label: 'Éves alakulás havi zárásokkal',
            child: BalanceAlternativeAnnualClosingsCard(
              presentation: closings,
              timeScope: presentation.timeScope,
              yearBarPresentation: yearBarPresentation,
            ),
          ),
        ),
        _BalanceAlternativeSectionSlot(
          slot: mergedSavings,
          padding: layout.childInsetsFor(mergedSavings),
          allocationKey: const ValueKey<String>('balance-tetris-slot-savings'),
          surfaceKey: const ValueKey<String>('balance-tetris-card-savings'),
          child: Semantics(
            label: 'Megtakarítás',
            child: BalanceAlternativeSavingsRingCard(
              presentation: savings,
              expandedRingMaximum: 148,
              expandedRingHorizontalInset: 0,
              expandedPercentageFontSize:
                  BalanceAlternativeSavingsRingCard.monthYearPercentageFontSize,
            ),
          ),
        ),
        _BalanceAlternativeSectionSlot(
          slot: layout.combined,
          padding: layout.childInsetsFor(layout.combined),
          allocationKey: const ValueKey<String>('balance-tetris-slot-combined'),
          surfaceKey: const ValueKey<String>('balance-tetris-card-combined'),
          child: Semantics(
            label: 'Éves bevétel és kiadás összehasonlítás',
            child: BalanceAlternativeAnnualIncomeExpenseCard(
              presentation: incomeExpense,
              timeScope: presentation.timeScope,
              yearBarPresentation: yearBarPresentation,
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
    return _BalanceScopeFrame(
      geometry: geometry,
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
    return _BalanceScopeFrame(
      geometry: geometry,
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

/// Responsive authored canvas, never a switch to a different layout family.
/// At accepted dimensions this is an identity mapping. Compact viewports retain
/// the same live charts in a bounded, uniformly scaled canvas.
final class _BalanceScopeFrame extends StatelessWidget {
  const _BalanceScopeFrame({
    required this.geometry,
    required this.child,
    this.focused = false,
  });
  final bool focused;
  final DashboardLayoutFrame geometry;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final bounds = DashboardHeaderContentMotherCardBounds.resolve(
      geometry: geometry,
    );
    final width = math.max(
      bounds.width,
      BalanceFourSectionLayout.minimumRenderableBodyWidth,
    );
    final bodyHeight = math.max(
      geometry.canonicalMotherCardContentHeight,
      BalanceFourSectionLayout.minimumRenderableBodyHeight +
          BalanceAlternativeHtmlTokens.outerInset * 2,
    );
    final motion = BalanceFocusedCascadeScope.maybeOf(context);
    final canvasHeight = geometry.headerBounds.height + bodyHeight;
    final fitted =
        width != bounds.width ||
        bodyHeight != geometry.canonicalMotherCardContentHeight;
    final canvasScale = fitted
        ? math.min(bounds.width / width, bounds.height / canvasHeight)
        : 1.0;
    final authored = Matrix4.identity()
      ..translateByDouble(
        bounds.left + (bounds.width - width * canvasScale) / 2,
        bounds.top +
            (geometry.headerBounds.height +
                    BalanceAlternativeHtmlTokens.outerInset) *
                canvasScale,
        0,
        1,
      )
      ..scaleByDouble(canvasScale, canvasScale, 1, 1);
    final scopedChild = focused
        ? BalanceFocusedCanvasScope(localToViewport: authored, child: child)
        : Opacity(opacity: motion?.lowerOpacity ?? 1, child: child);
    return DashboardCoreModeFramePosition(
      bounds: bounds,
      child:
          width == bounds.width &&
              bodyHeight == geometry.canonicalMotherCardContentHeight
          ? scopedChild
          : FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: width,
                height: geometry.headerBounds.height + bodyHeight,
                child: scopedChild,
              ),
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
    0,
    headerHeight + outerInset,
    math.max(0.0, constraints.maxWidth),
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
    this.padding = const EdgeInsets.all(
      BalanceAlternativeHtmlTokens.halfGutter,
    ),
  });

  final Rect slot;
  final Key allocationKey;
  final Key surfaceKey;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    // Deflating every allocation by half a gutter makes one consistent shared
    // 6px visual seam without perturbing the mathematical slot boundaries.
    return Positioned.fromRect(
      rect: slot,
      child: SizedBox.expand(
        key: allocationKey,
        child: Padding(
          padding: padding,
          child: KeyedSubtree(key: surfaceKey, child: child),
        ),
      ),
    );
  }
}

final class _BalanceHeaderDetail extends StatelessWidget {
  const _BalanceHeaderDetail({
    required this.contextProjection,
    required this.balancePresentation,
    required this.headerVisualFrame,
    required this.expansionProgress,
    required this.expandedHeaderExtraHeight,
    required this.presentationSettings,
    required this.adaptiveScope,
    required this.pointerObserver,
  });

  final DashboardBalanceHeaderContextProjection contextProjection;
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
        contextProjection: contextProjection,
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
    required this.contextProjection,
    required this.balance,
    required this.headerVisualFrame,
    required this.expansionProgress,
    required this.expandedHeaderExtraHeight,
    required this.presentationSettings,
    required this.adaptiveScope,
    required this.pointerObserver,
  });

  final DashboardBalanceHeaderContextProjection contextProjection;
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
    final headerContext = contextProjection.project(
      source: balance,
      fallbackScope: adaptiveScope,
      dailyCalculationMode: settings.dailyCalculationMode,
    );
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // Header visuals are an expanded-only surface. In the collapsed end
        // state neither chart nor any glass/filter tree is mounted.
        if (expansionProgress > 0 &&
            settings.headerGraphPresentation ==
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
            showTimeLabels: false,
            adaptiveScope: balance?.headerTimeScope ?? adaptiveScope,
            pointerObserver: pointerObserver,
            layout: chartLayout,
          ),
        if (expansionProgress > 0 &&
            settings.headerGraphPresentation ==
                BalanceHeaderGraphPresentation.incomeExpensePartition &&
            headerContext != null)
          BalanceHeaderGlassBar(
            incomeMinor: headerContext.incomeTotalMinor,
            expenseMinor: headerContext.expenseTotalMinor,
            expansionProgress: expansionProgress,
            foreground: foreground,
            configuration: settings.headerGlassConfiguration,
            plotTop: chartLayout.plotTop,
            plotHeight: chartLayout.plotHeight,
            valueTop: chartLayout.valueTop,
          ),
        if (expansionProgress > 0 &&
            settings.headerGraphPresentation ==
                BalanceHeaderGraphPresentation.simpleIncomeExpensePartition &&
            headerContext != null)
          BalanceHeaderIncomeExpensePartition(
            incomeMinor: headerContext.incomeTotalMinor,
            expenseMinor: headerContext.expenseTotalMinor,
            expansionProgress: expansionProgress,
            foreground: foreground,
            plotTop: chartLayout.plotTop,
            plotHeight: chartLayout.plotHeight,
            valueTop: chartLayout.valueTop,
            verticalPosition:
                settings.headerGlassConfiguration.verticalPosition,
          ),
        if (chartLayout.showsModeLabelAboveValue)
          Positioned(
            left: DashboardHeaderTrendChartStyle.detailLeft,
            top: DashboardHeaderTrendChartStyle.detailTop,
            right: 16,
            child: Text(
              'Balance · ${headerContext?.contextLabel ?? 'Betöltés…'}',
              key: const ValueKey<String>('balance-header-mode-label'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.applyTo(
                DashboardHeaderTrendChartLayout.modeLabelTextMetrics.copyWith(
                  color: foreground,
                ),
              ),
            ),
          ),
        if (!chartLayout.showsModeLabelAboveValue && headerContext != null)
          Positioned(
            left: DashboardHeaderTrendChartStyle.detailLeft,
            right: 16,
            top: chartLayout.valueTop + 23,
            child: Text(
              headerContext.contextLabel,
              key: const ValueKey<String>('balance-header-context-label'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.applyTo(
                DashboardHeaderTrendChartLayout.modeLabelTextMetrics.copyWith(
                  color: foreground,
                ),
              ),
            ),
          ),
        if (headerContext case final headerContext?)
          Positioned(
            left: DashboardHeaderTrendChartStyle.detailLeft,
            top: chartLayout.valueTop,
            right: 16,
            child: Text(
              headerContext.formattedNetTotal,
              semanticsLabel:
                  '${headerContext.contextLabel}: ${headerContext.formattedNetTotal}',
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
