import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_focused_cascade.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_unified_mother_card_geometry.dart';

import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  for (final entry in <String, LedgerTimeScope>{
    'sum': const AllTimeScope(),
    'year': const YearScope(2025),
    'month': const MonthScope(YearMonth(year: 2025, month: 5)),
    'day': const DayScope(LocalDate(year: 2025, month: 5, day: 12)),
  }.entries) {
    testWidgets(
      '${entry.key} actual focused selector follows upper track, stable on reverse; Eddigi remains lower-only',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(412, 892));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final settings = BalancePresentationController()
          ..setSumLayoutPresentation(BalanceSumLayoutPresentation.focused)
          ..setYearLayoutPresentation(BalanceYearLayoutPresentation.focused)
          ..setMonthLayoutPresentation(BalanceMonthLayoutPresentation.focused)
          ..setDayLayoutPresentation(BalanceDayLayoutPresentation.focused);
        final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
          DashboardBalanceLinkedProjection.build(
            identity: const DashboardBalancePrimaryIdentity(
              upstreamScopeKey: 'cascade-test',
              indexGeneration: 1,
              coreRevision: 1,
            ),
            timeScope: entry.value,
            selectedDirection: LedgerDirection.expense,
            incomeEntries: const [],
            expenseEntries: const [],
            logicalAsOfDate: const LocalDate(year: 2026, month: 6, day: 15),
          ),
        );
        addTearDown(settings.dispose);
        addTearDown(linked.dispose);
        final selector = find.byKey(
          ValueKey(
            'balance-${entry.key}-focused-${entry.key == 'day' ? 'top-section' : 'selector-zone'}',
          ),
        );
        Element? firstElement;
        Rect? expanded;
        Rect? expandedChart;
        String? selectedLabel;
        for (final separation in [
          0.0,
          .05,
          .10,
          .20,
          .35,
          .50,
          .65,
          .80,
          1.0,
          .35,
          .10,
          .70,
          0.0,
        ]) {
          final frame = DashboardGeometryResolver.resolve(
            metrics: DashboardLayoutMetrics.reference,
            mode: DashboardModeSpec.balance,
            collapseProgress:
                separation * DashboardLayoutMetrics.reference.collapseTravel,
            isRailExpanded: false,
          );
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: BalanceDashboardCoreSurface(
                  presentation: DashboardCoreModePresentation(
                    geometry: frame,
                    palette: DashboardModePaletteResolver.resolve(
                      DashboardModeSpec.balance,
                    ),
                  ),
                  balanceLinkedPresentation: linked,
                  presentationSettings: settings,
                  adaptiveScope: entry.value,
                ),
              ),
            ),
          );
          expect(selector, findsOneWidget);
          if (selectedLabel == null) {
            final buttons = find.descendant(
              of: selector,
              matching: find.byType(GestureDetector),
            );
            await tester.tap(buttons.last);
            await tester.pump();
            selectedLabel = tester
                .widgetList<Semantics>(
                  find.descendant(
                    of: selector,
                    matching: find.byType(Semantics),
                  ),
                )
                .firstWhere((widget) => widget.properties.selected == true)
                .properties
                .label;
          }
          expect(
            tester
                .widgetList<Semantics>(
                  find.descendant(
                    of: selector,
                    matching: find.byType(Semantics),
                  ),
                )
                .firstWhere((widget) => widget.properties.selected == true)
                .properties
                .label,
            selectedLabel,
          );

          firstElement ??= tester.element(selector);
          expect(identical(firstElement, tester.element(selector)), isTrue);
          final box = tester.renderObject<RenderBox>(selector);
          final matrix = box.getTransformTo(null);
          final geometry = BalanceUnifiedMotherCardGeometry.resolve(
            frame: frame,
            headerRadius: BorderRadius.zero,
            contentRadius: BorderRadius.zero,
          );
          final scope = BalanceFocusedCascadeScope(
            frame: frame,
            lowerTransform: geometry.contentTransform,
            lowerOpacity: geometry.contentOpacity,
            child: const SizedBox(),
          );
          expect(
            matrix.storage[0],
            closeTo(scope.upperTransform.storage[0], 1e-7),
          );
          final lowerChart = find
              .descendant(
                of: find.byKey(ValueKey('balance-${entry.key}-focused-layout')),
                matching: find.byType(RepaintBoundary),
              )
              .first;
          final lowerBox = tester.renderObject<RenderBox>(lowerChart);
          expect(
            lowerBox.getTransformTo(null).storage[0],
            closeTo(geometry.contentTransform.storage[0], 1e-7),
          );
          final upperRect = tester.getRect(selector);
          final lowerRect = tester.getRect(lowerChart);
          final lowerOrigin = MatrixUtils.transformPoint(
            geometry.contentTransform,
            Offset(frame.headerBounds.left, frame.headerBounds.bottom),
          ).dy;
          expect(
            upperRect.top,
            closeTo(
              lowerOrigin +
                  frame.motherCardCascade.upper.top -
                  frame.motherCardCascadeGeometry.upperExpandedTop +
                  12 * scope.upperTransform.storage[0],
              1e-7,
            ),
          );
          expect(upperRect.isFinite && lowerRect.isFinite, isTrue);
          if (separation == 0) expandedChart ??= lowerRect;
          if (entry.key == 'month' &&
              (separation == .35 || separation == .50)) {
            final upperDisplacement = expanded!.top - upperRect.top;
            final lowerDisplacement = expandedChart!.top - lowerRect.top;
            expect(
              upperDisplacement,
              greaterThan(lowerDisplacement),
              reason:
                  'the selector must advance before the chart at $separation',
            );
            expect(
              lowerRect.top - upperRect.bottom,
              greaterThanOrEqualTo(expandedChart.top - expanded.bottom),
              reason: 'the chart must not overtake the selector caption',
            );
          }

          if (separation > 0 && separation < .8) {
            expect(
              matrix.storage[0],
              isNot(closeTo(geometry.contentTransform.storage[0], 1e-7)),
            );
          }
          final opacity = tester.widget<BalanceCascadeOpacity>(
            find.byKey(const ValueKey('balance-upper-cascade-opacity')),
          );
          expect(opacity.opacity, frame.motherCardCascade.upper.opacity);
          if (separation == 0) {
            expanded ??= tester.getRect(selector);
            expect(tester.getRect(selector), expanded);
          }
          expect(tester.takeException(), isNull);
        }
        settings
          ..setSumLayoutPresentation(BalanceSumLayoutPresentation.current)
          ..setYearLayoutPresentation(BalanceYearLayoutPresentation.current)
          ..setMonthLayoutPresentation(BalanceMonthLayoutPresentation.current)
          ..setDayLayoutPresentation(BalanceDayLayoutPresentation.current);
        await tester.pump();
        expect(
          find.byKey(const ValueKey('balance-upper-cascade-transform')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  const samples = [0.0, .05, .10, .20, .35, .50, .65, .80, 1.0];
  for (final compactScale in [1.0, .67]) {
    for (final padding in [12.0, 14.0]) {
      test(
        'selector compensation composes once, compact=$compactScale padding=$padding',
        () {
          for (final separation in samples) {
            final frame = DashboardGeometryResolver.resolve(
              metrics: DashboardLayoutMetrics.reference,
              mode: DashboardModeSpec.balance,
              collapseProgress:
                  separation * DashboardLayoutMetrics.reference.collapseTravel,
              isRailExpanded: false,
            );
            final geometry = BalanceUnifiedMotherCardGeometry.resolve(
              frame: frame,
              headerRadius: BorderRadius.circular(20),
              contentRadius: BorderRadius.circular(20),
            );
            final scope = BalanceFocusedCascadeScope(
              frame: frame,
              lowerTransform: geometry.contentTransform,
              lowerOpacity: geometry.contentOpacity,
              child: const SizedBox(),
            );
            final authored = Matrix4.identity()
              ..translateByDouble(
                23 + padding * compactScale,
                frame.headerBounds.bottom + 12 * compactScale,
                0,
                1,
              )
              ..scaleByDouble(compactScale, compactScale, 1, 1);
            final actual = Matrix4.copy(scope.lowerTransform)
              ..multiply(authored)
              ..multiply(scope.selectorCompensation(authored));
            final expected = Matrix4.copy(scope.upperTransform)
              ..multiply(authored);
            for (var i = 0; i < 16; i++) {
              expect(actual.storage[i], closeTo(expected.storage[i], 1e-8));
            }
            expect(
              frame.motherCardCascade.upper.opacity,
              closeTo(1 - separation, 1e-8),
            );
            if (separation > 0 && separation < .8) {
              expect(
                scope.upperTransform.storage[13],
                isNot(closeTo(scope.lowerTransform.storage[13], 1e-5)),
              );
            }
            if (separation == 0) {
              final identity = scope.selectorCompensation(authored);
              for (var i = 0; i < 16; i++) {
                expect(
                  identity.storage[i],
                  closeTo(Matrix4.identity().storage[i], 1e-8),
                );
              }
            }
          }
        },
      );
    }
  }

  testWidgets(
    'independent opacity and reverse frames retain live selector state and flex geometry',
    (tester) async {
      const upperKey = ValueKey('live-upper');
      const lowerKey = ValueKey('live-lower');
      State? initial;
      Rect? expandedUpper;
      for (final separation in [0.0, .35, .10, .70, 1.0, 0.0]) {
        final frame = DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: DashboardModeSpec.balance,
          collapseProgress:
              separation * DashboardLayoutMetrics.reference.collapseTravel,
          isRailExpanded: false,
        );
        final geometry = BalanceUnifiedMotherCardGeometry.resolve(
          frame: frame,
          headerRadius: BorderRadius.circular(20),
          contentRadius: BorderRadius.circular(20),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 320,
              height: 400,
              child: Transform(
                transform: geometry.contentTransform,
                alignment: Alignment.topLeft,
                child: BalanceFocusedCascadeScope(
                  frame: frame,
                  lowerTransform: geometry.contentTransform,
                  lowerOpacity: geometry.contentOpacity,
                  child: BalanceFocusedCanvasScope(
                    localToViewport: Matrix4.identity(),
                    child: BalanceFocusedCascadeColumn(
                      horizontalPadding: 0,
                      children: const [
                        SizedBox(
                          height: 80,
                          child: _LiveSelector(key: upperKey),
                        ),
                        Expanded(child: SizedBox(key: lowerKey)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        initial ??= tester.state(find.byKey(upperKey));
        expect(identical(initial, tester.state(find.byKey(upperKey))), isTrue);
        final opacity = tester.widget<BalanceCascadeOpacity>(
          find.byKey(const ValueKey('balance-upper-cascade-opacity')),
        );
        expect(
          opacity.opacity,
          closeTo(frame.motherCardCascade.upper.opacity, 1e-8),
        );
        final lowerOpacity = tester.widget<BalanceCascadeOpacity>(
          find
              .ancestor(
                of: find.byKey(lowerKey),
                matching: find.byType(BalanceCascadeOpacity),
              )
              .first,
        );
        expect(lowerOpacity.opacity, geometry.contentOpacity);
        if (separation == 0) {
          final rect = tester.getRect(find.byKey(upperKey));
          expandedUpper ??= rect;
          expect(rect, expandedUpper);
        }
        expect(tester.takeException(), isNull);
      }
    },
  );
}

class _LiveSelector extends StatefulWidget {
  const _LiveSelector({super.key});
  @override
  State<_LiveSelector> createState() => _LiveSelectorState();
}

class _LiveSelectorState extends State<_LiveSelector> {
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
