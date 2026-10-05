import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_scope_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/fluvi_topographic_wave_chart.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// Synthetic, explicitly labelled reference-shaped and sparse stress datasets.
// They never enter application production data or the normal APK entrypoint.
List<int> waveSparseForints(int days, {int peak = 1}) => List<int>.generate(
  days,
  (index) => index == peak
      ? 268000
      : index == 18
      ? 132000
      : index == 20
      ? 29000
      : index == 9
      ? 14000
      : index % 4 == 0
      ? 1000
      : 0,
);

const waveReferenceForints = <int>[
  700,
  1100,
  2600,
  8400,
  9800,
  4700,
  1800,
  2500,
  4400,
  2500,
  1400,
  2300,
  7100,
  10100,
  12000,
  10200,
  4800,
  2200,
  3900,
  4700,
  3600,
  1800,
  1100,
  2300,
  7100,
  9400,
  4800,
  6800,
  3300,
  1200,
  600,
];

DashboardBalanceLinkedPresentation waveLinked(
  List<int> forints, {
  int year = 2026,
  int month = 7,
  int revision = 1,
}) {
  final scope = MonthScope(YearMonth(year: year, month: month));
  final identity = DashboardBalancePrimaryIdentity(
    upstreamScopeKey: 'wave-test-$year-$month',
    indexGeneration: 1,
    coreRevision: revision,
  );
  final start = DateTime.utc(year, month).difference(DateTime.utc(1970)).inDays;
  final cashflow = DashboardBalancePrimaryProjection.build(
    identity: identity,
    timeScope: scope,
    incomeEntries: <DashboardLedgerEntry>[
      DashboardLedgerEntry(
        id: 'test-income',
        partnerId: 'fixture',
        categoryId: 'fixture',
        direction: 'income',
        amountMinor: 70700000,
        bookedLocalEpochDay: start,
        bookedLocalTimeMinutes: 0,
      ),
    ],
    expenseEntries: <DashboardLedgerEntry>[
      for (var day = 0; day < forints.length; day++)
        if (forints[day] != 0)
          DashboardLedgerEntry(
            id: 'test-expense-$day',
            partnerId: 'fixture',
            categoryId: 'fixture',
            direction: 'expense',
            amountMinor: forints[day] * 100,
            bookedLocalEpochDay: start + day,
            bookedLocalTimeMinutes: 0,
          ),
    ],
  );
  return DashboardBalanceLinkedPresentation(
    identity: identity,
    timeScope: scope,
    selectedDirection: LedgerDirection.expense,
    cashflow: cashflow,
    latestTransactions: const [],
    topCategories: const [],
    topPartners: const [],
  );
}

List<FluviTopographicWaveDatum> waveData(
  DashboardBalanceLinkedPresentation linked,
) {
  final month =
      BalanceAlternativeScopePresentation.fromLinked(linked)
          as BalanceAlternativeMonthPresentation;
  return <FluviTopographicWaveDatum>[
    for (final point in month.dailySpend.points)
      FluviTopographicWaveDatum(
        key: point.day,
        value: point.expenseMinor,
        label: '${point.day}',
      ),
  ];
}

Widget waveProductionParent({
  required ValueNotifier<DashboardBalanceLinkedPresentation?> linked,
  required BalancePresentationController settings,
  Size viewport = const Size(412, 892),
  Widget Function(Widget)? wrap,
}) => MaterialApp(
  home: Scaffold(
    backgroundColor: const Color(0xfff5f7ff),
    body: RepaintBoundary(
      key: const ValueKey('wave-production-parent'),
      child: (wrap ?? (child) => child)(
        BalanceDashboardCoreSurface(
          presentation: DashboardCoreModePresentation(
            geometry: DashboardGeometryResolver.resolve(
              metrics: DashboardLayoutMetrics.reference.fitToViewport(viewport),
              mode: DashboardModeSpec.balance,
              collapseProgress: 0,
              isRailExpanded: false,
              hasPhysicalRail: false,
            ),
            palette: DashboardModePaletteResolver.resolve(
              DashboardModeSpec.balance,
            ),
          ),
          balanceLinkedPresentation: linked,
          presentationSettings: settings,
        ),
      ),
    ),
  ),
);

Future<ui.Image> waveCapture(WidgetTester tester, Finder finder) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(finder);
  return (await tester.runAsync(() => boundary.toImage(pixelRatio: 2)))!;
}

Future<void> waveWriteEvidence(
  WidgetTester tester,
  ui.Image image,
  String name,
  Map<String, Object?> metadata,
) async {
  const output = String.fromEnvironment('FLUVI_WAVE_EVIDENCE');
  if (output.isEmpty) return;
  await tester.runAsync(() async {
    final directory = Directory(output)..createSync(recursive: true);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    File(
      '${directory.path}/$name.png',
    ).writeAsBytesSync(png.buffer.asUint8List());
    final head = Process.runSync('git', [
      'rev-parse',
      'HEAD',
    ]).stdout.toString().trim();
    final diff = Process.runSync('git', [
      'diff',
      '--',
      'lib',
      'shaders',
    ]).stdout.toString();
    File('${directory.path}/$name.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'head': head,
        'trackedProductionDiffEmpty': diff.isEmpty,
        'chartSourceHashes': Process.runSync('sha256sum', [
          'lib/features/dashboard/presentation/core_modes/fluvi_topographic_wave_chart.dart',
          'lib/features/dashboard/presentation/core_modes/fluvi_wave_render_probe.dart',
          'shaders/fluvi_wave_surface.frag',
        ]).stdout.toString(),
        'backend': 'flutter_test software rasterizer; not physical Android',
        'width': image.width,
        'height': image.height,
        'pixelRatio': 2,
        ...metadata,
      }),
    );
  });
}
