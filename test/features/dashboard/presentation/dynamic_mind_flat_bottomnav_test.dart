import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_year_heatmap_palette_resolver.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_heatmap_palette_scope.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_shell_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_perceptual_color.dart';
import 'package:fluvi/features/dashboard/query/presentation/query_amount_range_control.dart';

void main() {
  const red = <Color>[
    Color(0xffffe7d6),
    Color(0xffffd0b3),
    Color(0xffffb28f),
    Color(0xffff916e),
    Color(0xffff6f58),
    Color(0xfff55449),
    Color(0xffe63a3d),
    Color(0xffc72b3c),
    Color(0xffa5223c),
    Color(0xff7e1f39),
  ];
  const redB3m = <Color>[
    Color(0xfffff0e4),
    Color(0xffffe0c8),
    Color(0xfffec7a6),
    Color(0xfffda77f),
    Color(0xfff7866c),
    Color(0xfff26862),
    Color(0xffe95276),
    Color(0xffd33f8d),
    Color(0xffb433a0),
    Color(0xff9227a8),
  ];
  const b3mMy3 = <Color>[
    Color(0xfff4f7fb),
    Color(0xffffeeda),
    Color(0xffffd5af),
    Color(0xffffb15c),
    Color(0xffff8d64),
    Color(0xffff6b6b),
    Color(0xfff536bd),
    Color(0xffd03cb0),
    Color(0xffa237bf),
    Color(0xff821ac2),
  ];
  const b3mMeadow = <Color>[
    Color(0xffeef1d2),
    Color(0xffd9e493),
    Color(0xffbed77a),
    Color(0xff9cc870),
    Color(0xff78b978),
    Color(0xff55a982),
    Color(0xff39998a),
    Color(0xff278790),
    Color(0xff206f86),
    Color(0xff195a75),
  ];
  const meadow = <Color>[
    Color(0xffd9ed92),
    Color(0xffb5e48c),
    Color(0xff99d98c),
    Color(0xff76c893),
    Color(0xff52b69a),
    Color(0xff34a0a4),
    Color(0xff168aad),
    Color(0xff1a759f),
    Color(0xff1e6091),
    Color(0xff184e77),
  ];

  test(
    'DMS-RED-01: Mind settings default to static scale and normal handles',
    () {
      const settings = MindYearHeatmapPresentationSettings.defaults();

      expect(settings.scaleMode, MindHeatmapScaleMode.existing);
      expect(settings.sliderHandleSize, MindSliderHandleSize.normal);

      final changed = settings.copyWith(
        scaleMode: MindHeatmapScaleMode.dynamicMixed,
        sliderHandleSize: MindSliderHandleSize.tenPercentSmaller,
      );
      expect(changed.paletteStyle, settings.paletteStyle);
      expect(changed.scaleResolution, settings.scaleResolution);
      expect(changed.scaleMode, MindHeatmapScaleMode.dynamicMixed);
      expect(changed.sliderHandleSize, MindSliderHandleSize.tenPercentSmaller);
    },
  );

  test('DMS-RED-02: exact dynamic mixed anchors and score clamping', () {
    final expected = <double, List<Color>>{
      18: red,
      35: redB3m,
      58: b3mMy3,
      70: b3mMeadow,
      82: meadow,
    };

    for (final entry in expected.entries) {
      expect(
        MindYearHeatmapPaletteResolver.resolveDynamicMixedScale(
          entry.key,
        ).stops,
        entry.value,
        reason: 'score ${entry.key}',
      );
    }
    expect(
      MindYearHeatmapPaletteResolver.resolveDynamicMixedScale(0).stops,
      red,
    );
    expect(
      MindYearHeatmapPaletteResolver.resolveDynamicMixedScale(100).stops,
      meadow,
    );
  });

  test(
    'DMS-RED-03: dynamic score interpolation preserves ordered stop roles',
    () {
      final middle = MindYearHeatmapPaletteResolver.resolveDynamicMixedScale(
        26.5,
      );
      expect(middle.stops, hasLength(10));
      for (var index = 0; index < 10; index += 1) {
        expect(
          middle.stops[index],
          DashboardHeaderPerceptualColorMath.mix(red[index], redB3m[index], .5),
        );
      }
    },
  );

  test(
    'DMS-RED-04: dynamic tiles and legend share active scale but empty stays neutral',
    () {
      final scale = MindYearHeatmapPaletteResolver.resolveDynamicMixedScale(70);
      final active = MindYearHeatmapPaletteResolver.resolveTile(
        style: MindYearHeatmapPaletteStyle.fluvi,
        isEmpty: false,
        intensity: 1,
        paletteIntensity: MindYearHeatmapPaletteIntensity.maximum,
        dynamicScale: scale,
      );
      final empty = MindYearHeatmapPaletteResolver.resolveTile(
        style: MindYearHeatmapPaletteStyle.fluvi,
        isEmpty: true,
        intensity: 1,
        paletteIntensity: MindYearHeatmapPaletteIntensity.empty,
        dynamicScale: scale,
      );

      expect(active.background, b3mMeadow.last);
      expect(empty.background, FluviVisualTokens.mindHeatmapEmpty);
      expect(
        MindYearHeatmapPaletteResolver.legendSamples(
          MindYearHeatmapPaletteStyle.fluvi,
          dynamicScale: scale,
        ).map((sample) => sample.background),
        b3mMeadow,
      );
    },
  );

  test('DMS-RED-05: Mind slider gradient is local to its active range', () {
    final scale = MindYearHeatmapPaletteResolver.resolveDynamicMixedScale(58);
    final wide = QueryAmountRangeGradientGeometry.resolve(
      trackRect: const Rect.fromLTWH(20, 5, 300, 4),
      startFraction: .2,
      endFraction: .8,
      stops: scale.stops,
    );
    final narrow = QueryAmountRangeGradientGeometry.resolve(
      trackRect: const Rect.fromLTWH(20, 5, 300, 4),
      startFraction: .4,
      endFraction: .6,
      stops: scale.stops,
    );

    expect(wide.activeRect.left, 80);
    expect(wide.activeRect.right, 260);
    expect(narrow.activeRect.left, 140);
    expect(narrow.activeRect.right, 200);
    expect(wide.gradientRect, wide.activeRect);
    expect(narrow.gradientRect, narrow.activeRect);
    expect(wide.startHandleColor, b3mMy3.first);
    expect(wide.endHandleColor, b3mMy3.last);
    expect(narrow.startHandleColor, b3mMy3.first);
    expect(narrow.endHandleColor, b3mMy3.last);
  });

  testWidgets('DMS-RED-05B: dynamic scale morphs one shared paint scope', (
    tester,
  ) async {
    MindHeatmapResolvedScale redScale =
        MindYearHeatmapPaletteResolver.resolveDynamicMixedScale(18);
    MindHeatmapResolvedScale meadowScale =
        MindYearHeatmapPaletteResolver.resolveDynamicMixedScale(82);
    Widget host(MindHeatmapResolvedScale target) => MaterialApp(
      home: MindHeatmapPaletteTransition(
        target: target,
        animates: true,
        child: Builder(
          builder: (context) => ColoredBox(
            key: const ValueKey<String>('dynamic-mind-scope-probe'),
            color: MindHeatmapPaletteScope.maybeOf(context)!.colorAt(.5),
          ),
        ),
      ),
    );

    await tester.pumpWidget(host(redScale));
    Color color() => tester
        .widget<ColoredBox>(
          find.byKey(const ValueKey<String>('dynamic-mind-scope-probe')),
        )
        .color;
    expect(color(), redScale.colorAt(.5));

    await tester.pumpWidget(host(meadowScale));
    await tester.pump(const Duration(milliseconds: 175));
    expect(color(), isNot(redScale.colorAt(.5)));
    expect(color(), isNot(meadowScale.colorAt(.5)));
    await tester.pump(const Duration(milliseconds: 200));
    expect(color(), meadowScale.colorAt(.5));
  });

  test(
    'DMS-RED-06: compact Mind handles reduce only painted diameter by ten percent',
    () {
      expect(
        QueryAmountRangeHandleGeometry.visibleDiameterFor(
          tenPercentSmaller: false,
        ),
        20,
      );
      expect(
        QueryAmountRangeHandleGeometry.visibleDiameterFor(
          tenPercentSmaller: true,
        ),
        18,
      );
      expect(
        QueryAmountRangeHandleGeometry.minimumHitDiameter,
        greaterThanOrEqualTo(20),
      );
    },
  );

  group('flat BottomNav stretch', () {
    const metrics = DashboardLayoutMetrics.reference;
    const viewport = Size(412, 892);

    DashboardShellPresentationSettings settingsFor({
      DashboardBottomNavEdgeShape edge = DashboardBottomNavEdgeShape.straight,
      DashboardBottomNavLayoutStyle layout =
          DashboardBottomNavLayoutStyle.containedFlat,
      DashboardFlatBottomNavBodyStretch stretch =
          DashboardFlatBottomNavBodyStretch.off,
    }) => DashboardShellPresentationSettings(
      bottomNavEdgeShape: edge,
      bottomNavLayoutStyle: layout,
      flatBottomNavBodyStretch: stretch,
    );

    DashboardFlatBottomNavStretchLayout layoutFor(
      DashboardShellPresentationSettings settings, {
      Size deviceViewport = viewport,
    }) {
      final baseline = DashboardGeometryResolver.resolve(
        metrics: metrics,
        mode: DashboardModeSpec.balance,
        collapseProgress: 0,
        isRailExpanded: false,
      );
      return DashboardFlatBottomNavStretchLayout.resolve(
        viewport: deviceViewport,
        safeBottomInset: 0,
        metrics: metrics,
        logBoxHeaderTop: baseline.logBoxHeaderBounds.top,
        settings: settings,
      );
    }

    test('FBS-RED-01: default stays off and stored target is independent', () {
      const defaults = DashboardShellPresentationSettings.defaults;
      expect(
        defaults.flatBottomNavBodyStretch,
        DashboardFlatBottomNavBodyStretch.off,
      );

      final next = settingsFor(
        stretch: DashboardFlatBottomNavBodyStretch.modeContent,
      );
      expect(next.bottomNavEdgeShape, DashboardBottomNavEdgeShape.straight);
      expect(
        next.bottomNavLayoutStyle,
        DashboardBottomNavLayoutStyle.containedFlat,
      );
      expect(
        next.flatBottomNavBodyStretch,
        DashboardFlatBottomNavBodyStretch.modeContent,
      );
    });

    test('FBS-RED-02: only straight contained BottomNav is eligible', () {
      expect(layoutFor(settingsFor()).isEligible, isTrue);
      expect(
        layoutFor(settingsFor(edge: DashboardBottomNavEdgeShape.rounded)).delta,
        0,
      );
      expect(
        layoutFor(
          settingsFor(layout: DashboardBottomNavLayoutStyle.raisedFab),
        ).delta,
        0,
      );
      expect(
        layoutFor(
          settingsFor(
            edge: DashboardBottomNavEdgeShape.rounded,
            layout: DashboardBottomNavLayoutStyle.raisedFab,
          ),
        ).delta,
        0,
      );
    });

    test(
      'FBS-RED-03: both stretch targets align real SearchPill top to nav top',
      () {
        for (final stretch in <DashboardFlatBottomNavBodyStretch>[
          DashboardFlatBottomNavBodyStretch.expandedHeader,
          DashboardFlatBottomNavBodyStretch.modeContent,
        ]) {
          final shell = settingsFor(stretch: stretch);
          for (final deviceViewport in <Size>[const Size(428, 926), viewport]) {
            final layout = layoutFor(shell, deviceViewport: deviceViewport);
            for (final mode in DashboardModeSpec.values) {
              final frame = DashboardGeometryResolver.resolve(
                metrics: metrics,
                mode: mode,
                collapseProgress: 0,
                isRailExpanded: false,
                expandedHeaderExtraHeight:
                    stretch == DashboardFlatBottomNavBodyStretch.expandedHeader
                    ? layout.delta
                    : 0,
                principalModeContentExtraHeight:
                    stretch == DashboardFlatBottomNavBodyStretch.modeContent
                    ? layout.delta
                    : 0,
              );
              final searchPillTop = layout.searchPillTopFor(
                logBoxHeaderTop: frame.logBoxHeaderBounds.top,
              );
              expect(searchPillTop, closeTo(layout.physicalBottomNavTop, .001));
              expect(
                layout.physicalBottomNavTop -
                    layout.countBottomFor(
                      logBoxHeaderTop: frame.logBoxHeaderBounds.top,
                    ),
                closeTo(layout.scaledCountToSearchGap, .001),
              );
            }
          }
        }
      },
    );

    test(
      'FBS-RED-04: header stretch interpolates without changing collapsed Header',
      () {
        final layout = layoutFor(
          settingsFor(
            stretch: DashboardFlatBottomNavBodyStretch.expandedHeader,
          ),
        );
        final collapsed = DashboardGeometryResolver.resolve(
          metrics: metrics,
          mode: DashboardModeSpec.balance,
          collapseProgress: metrics.collapseTravel,
          isRailExpanded: false,
          expandedHeaderExtraHeight: layout.delta,
        );
        final midpoint = DashboardGeometryResolver.resolve(
          metrics: metrics,
          mode: DashboardModeSpec.balance,
          collapseProgress: metrics.collapseTravel / 2,
          isRailExpanded: false,
          expandedHeaderExtraHeight: layout.delta,
        );
        final expanded = DashboardGeometryResolver.resolve(
          metrics: metrics,
          mode: DashboardModeSpec.balance,
          collapseProgress: 0,
          isRailExpanded: false,
          expandedHeaderExtraHeight: layout.delta,
        );

        expect(collapsed.headerBounds.height, metrics.headerCollapsedHeight);
        expect(collapsed.expandedHeaderExtraHeight, 0);
        expect(
          expanded.headerBounds.height,
          metrics.headerExpandedHeight + layout.delta,
        );
        expect(expanded.expandedHeaderExtraHeight, layout.delta);
        expect(
          midpoint.headerBounds.height,
          closeTo(
            (collapsed.headerBounds.height + expanded.headerBounds.height) / 2,
            .001,
          ),
        );
        expect(
          midpoint.expandedHeaderExtraHeight,
          closeTo(layout.delta / 2, .001),
        );
      },
    );

    test(
      'FBS-RED-05: mode content stretch is absent when collapsed and reveals continuously',
      () {
        final layout = layoutFor(
          settingsFor(stretch: DashboardFlatBottomNavBodyStretch.modeContent),
        );
        for (final mode in DashboardModeSpec.values) {
          DashboardBounds modeBounds(double collapseProgress) =>
              DashboardGeometryResolver.resolve(
                metrics: metrics,
                mode: mode,
                collapseProgress: collapseProgress,
                isRailExpanded: false,
                principalModeContentExtraHeight: layout.delta,
              ).modeContentBounds;

          final baseline = DashboardGeometryResolver.resolve(
            metrics: metrics,
            mode: mode,
            collapseProgress: metrics.collapseTravel,
            isRailExpanded: false,
          ).modeContentBounds;
          final collapsed = modeBounds(metrics.collapseTravel);
          final midpoint = modeBounds(metrics.collapseTravel / 2);
          final expanded = modeBounds(0);

          expect(collapsed.height, baseline.height);
          expect(
            expanded.height - baseline.height,
            closeTo(layout.delta, .001),
          );
          expect(
            midpoint.height - baseline.height,
            closeTo(layout.delta / 2, .001),
          );
        }
      },
    );

    test(
      'FBS-RED-06: integrated handles and seamless Mind retain exact Ledger alignment',
      () {
        const shell = DashboardShellPresentationSettings(
          bottomNavEdgeShape: DashboardBottomNavEdgeShape.straight,
          bottomNavLayoutStyle: DashboardBottomNavLayoutStyle.containedFlat,
          flatBottomNavBodyStretch:
              DashboardFlatBottomNavBodyStretch.modeContent,
        );
        for (final configuration in <({DashboardModeSpec mode, bool seamless})>[
          (mode: DashboardModeSpec.balance, seamless: false),
          (mode: DashboardModeSpec.mind, seamless: true),
          (mode: DashboardModeSpec.budget, seamless: false),
        ]) {
          final baseline = DashboardGeometryResolver.resolve(
            metrics: metrics,
            mode: configuration.mode,
            collapseProgress: 0,
            isRailExpanded: false,
            hasStandaloneCollapseHandle: false,
            seamlessHeaderContent: configuration.seamless,
          );
          final layout = DashboardFlatBottomNavStretchLayout.resolve(
            viewport: viewport,
            safeBottomInset: 0,
            metrics: metrics,
            logBoxHeaderTop: baseline.logBoxHeaderBounds.top,
            settings: shell,
          );
          final stretched = DashboardGeometryResolver.resolve(
            metrics: metrics,
            mode: configuration.mode,
            collapseProgress: 0,
            isRailExpanded: false,
            hasStandaloneCollapseHandle: false,
            seamlessHeaderContent: configuration.seamless,
            principalModeContentExtraHeight: layout.delta,
          );
          expect(
            layout.searchPillTopFor(
              logBoxHeaderTop: stretched.logBoxHeaderBounds.top,
            ),
            closeTo(layout.physicalBottomNavTop, .001),
          );
        }
      },
    );
  });
}
