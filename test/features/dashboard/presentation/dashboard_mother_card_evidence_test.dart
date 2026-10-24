// Explicit opt-in artifact generation; actual production surfaces, no snapshots.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'budget_unified_detachment_test.dart' as budget;
import 'mind_unified_detachment_test.dart' as mind;
import 'balance_dashboard_core_surface_test.dart' as balance;
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';

import 'package:fluvi/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';

import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  testWidgets(
    'render mother card comparison evidence',
    (tester) async {
      const stage = String.fromEnvironment(
        'MOTHER_CARD_EVIDENCE',
        defaultValue: '',
      );
      await tester.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await (FontLoader('Inter')
            ..addFont(rootBundle.load('assets/fonts/inter/InterVariable.ttf')))
          .load();
      final changes = ChangeNotifier();
      addTearDown(changes.dispose);
      final visual = DashboardHeaderVisualController(vsync: tester)
        ..selectEffect(DashboardHeaderEffectId.staticEffect);
      final headerFrame = ValueNotifier<DashboardHeaderVisualFrame>(
        const DashboardHeaderVisualFrame(
          colors: <Color>[Color(0xff9b426a), Color(0xff632f8d)],
          stops: <double>[0, 1],
          opacity: 1,
          colorA: Color(0xff9b426a),
          colorB: Color(0xff632f8d),
          foregroundTextColor: Colors.white,
          chartColor: Colors.white,
        ),
      );
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        balance.motherCardComparisonBalanceFixture(),
      );
      addTearDown(linked.dispose);
      final year = ValueNotifier<MindYearHeatmapFrame?>(
        MindYearHeatmapProjection.build(
          identity: const MindYearHeatmapIdentity(
            upstreamScopeKey: 'evidence|year:2025',
            indexGeneration: 1,
            coreRevision: 1,
            year: 2025,
            navigationEpoch: 1,
          ),
          entries: [
            for (var month = 1; month <= 12; month++)
              DashboardLedgerEntry(
                id: '$month',
                partnerId: 'p',
                categoryId: 'c',
                direction: 'expense',
                amountMinor: month * 100000,
                bookedLocalEpochDay: LocalDate(
                  year: 2025,
                  month: month,
                  day: 2,
                ).epochDay,
                bookedLocalTimeMinutes: 120,
              ),
          ],
        ).preview(
          const QueryAmountRangeValues(
            minimumScaled100: 0,
            maximumScaled100: 100000000,
            lowerScaled100: 0,
            upperScaled100: 100000000,
          ),
        ),
      );
      addTearDown(year.dispose);
      final focused = ValueNotifier(
        (const BalancePresentationSettings.defaults()).copyWith(
          monthLayoutPresentation: BalanceMonthLayoutPresentation.focused,
        ),
      );
      addTearDown(focused.dispose);
      final progressSamples = stage == 'phase3-shadow-avatar'
          ? const <double>[
              0,
              .02,
              .05,
              .10,
              .20,
              .35,
              .50,
              .65,
              .80,
              .95,
              1,
            ]
          : const <double>[0, .05, .2, .35, .5, .65, .8, 1];
      for (final mode in ['budget', 'balance', 'balance-focused', 'mind']) {
        for (final progress in progressSamples) {
          final travel = progress * 180;
          if (mode.startsWith('balance')) {
            await tester.pumpWidget(
              MaterialApp(
                theme: ThemeData(fontFamily: 'Inter'),
                home: Scaffold(
                  backgroundColor: const Color(0xffe9edf6),
                  body: RepaintBoundary(
                    key: const ValueKey('balance-evidence'),
                    child: SizedBox(
                      width: 412,
                      height: 700,
                      child: Stack(
                        children: [
                          BalanceDashboardCoreSurface(
                            balanceLinkedPresentation: linked,
                            headerVisualController: visual,
                            headerVisualFrame: headerFrame,
                            presentationSettings: mode == 'balance-focused'
                                ? focused
                                : null,
                            presentation: DashboardCoreModePresentation(
                              geometry: DashboardGeometryResolver.resolve(
                                metrics: DashboardLayoutMetrics.reference,
                                mode: DashboardModeSpec.balance,
                                collapseProgress: travel,
                                isRailExpanded: false,
                                hasPhysicalRail: false,
                              ),
                              palette: DashboardModePaletteResolver.resolve(
                                DashboardModeSpec.balance,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else if (mode == 'budget') {
            await budget.pump(
              tester,
              travel,
              visual: visual,
              colors: headerFrame,
            );
          } else {
            await mind.pumpMind(
              tester,
              travel,
              changes,
              year: year,
              visual: visual,
              colors: headerFrame,
            );
          }
          await tester.pump();
          expect(tester.takeException(), isNull);
          final key = mode.startsWith('balance')
              ? const ValueKey('balance-evidence')
              : mode == 'budget'
              ? budget.capture
              : mind.capture;
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(key),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File(
              'docs/superpowers/evidence/2026-10-24-shared-motion/$stage-$mode-${(progress * 100000).round()}.png',
            );
            file.parent.createSync(recursive: true);
            file.writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      visual.dispose();
      headerFrame.dispose();
    },
    skip: const String.fromEnvironment('MOTHER_CARD_EVIDENCE').isEmpty,
  );
}
