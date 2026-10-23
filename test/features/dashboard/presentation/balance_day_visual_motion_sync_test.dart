import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_vertical_geometry_manifest.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/data/empty_dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/dashboard_focus_membership_seed.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/prepared/data/dashboard_prepared_formatter.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_day_momentum_rail.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_summary_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_temporal_component_carousel.dart';
import 'package:fluvi/features/dashboard/query/domain/query_temporal_filter.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

import '../../../support/dashboard_render_resources.dart';
import '../../../support/test_category_collection.dart';
import '../../../support/test_pump.dart';

const _summaryKey = ValueKey('summary-pill-segmented-day-selector');
const _rhythmKey = ValueKey('balance-day-rhythm-carousel');

Future<void> _frames(WidgetTester tester, [int count = 2]) async {
  for (var index = 0; index < count; index++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<DashboardCoreController> _setup(
  WidgetTester tester, {
  DateTime? date,
  bool richData = false,
  SummaryTemporalFlingPresentation presentation =
      SummaryTemporalFlingPresentation.dynamicTrio,
}) async {
  final core = DashboardCoreController(
    initialCoreRevision: 1,
    dataRepository: richData ? _PairedMotionRepository() : null,
    yearWindowRadius: richData ? 1 : 12,
    initialDate: date ?? DateTime(2026, 7, 16),
    initialPlane: TimePlane.month,
    initialRailOpen: true,
  );
  final modes = DashboardCoreModeController(
    initialMode: DashboardModeSpec.balance,
  );
  addTearDown(core.dispose);
  addTearDown(modes.dispose);
  await core.bootstrap();
  await pumpDashboardSurface(
    tester,
    RepaintBoundary(
      key: const ValueKey('paired-day-motion-scene'),
      child: Theme(
        data: ThemeData(fontFamily: 'Inter'),
        child: DefaultTextStyle(
          style: ThemeData(fontFamily: 'Inter').textTheme.bodyMedium!,
          child: CoreDashboard(
            controller: core,
            modeController: modes,
            categoryCollection: emptyTestCategoryCollection,
          ),
        ),
      ),
    ),
  );
  await _frames(tester, 4);
  final tuner = tester.widget<DashboardHeaderVisualTuner>(
    find.byType(DashboardHeaderVisualTuner),
  );
  tuner.balancePresentationSettings!.setDayLayoutPresentation(
    BalanceDayLayoutPresentation.focused,
  );
  tuner.summaryPresentation!.selectTemporalFlingPresentation(presentation);
  await _frames(tester, 6);
  expect(find.byKey(_summaryKey), findsOneWidget);
  expect(find.byKey(_rhythmKey), findsOneWidget);
  return core;
}

DashboardTemporalComponentCarousel _adapter(WidgetTester tester, Key key) =>
    tester.widget<DashboardTemporalComponentCarousel>(find.byKey(key));
DashboardTemporalComponentCarouselState _adapterState(
  WidgetTester tester,
  Key key,
) => tester.state<DashboardTemporalComponentCarouselState>(find.byKey(key));
Finder _summaryOriginText() => find.descendant(
  of: find.byKey(_summaryKey),
  matching: find.byKey(const ValueKey('summary-pill-dynamic-trio-0')),
);
BalanceDayMomentumRailPainter _painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.byKey(const ValueKey('balance-day-rhythm-bars')),
            )
            .painter!
        as BalanceDayMomentumRailPainter;

double _pitch(WidgetTester tester) {
  final carousel = _adapter(tester, _rhythmKey);
  return carousel.itemExtent ?? carousel.height;
}

Future<TestGesture> _subTick(
  WidgetTester tester, {
  required bool fromRail,
}) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(fromRail ? _rhythmKey : _summaryKey)),
  );
  await gesture.moveBy(fromRail ? const Offset(-25, 0) : const Offset(0, -25));
  await _frames(tester, 1);
  final distance = _pitch(tester) * .25;
  await gesture.moveBy(fromRail ? Offset(-distance, 0) : Offset(0, -distance));
  await _frames(tester, 1);
  return gesture;
}

void _expectSharedSubTick(
  WidgetTester tester, {
  required bool fromRail,
  required int originalDay,
  required double originalTextY,
}) {
  final summary = _adapterState(tester, _summaryKey).visualState;
  final rhythm = _adapterState(tester, _rhythmKey).visualState;
  final coordinator = _adapter(tester, _rhythmKey).coordinator!;
  final frame = coordinator.dayVisualMotion!;
  expect(frame.source.name, fromRail ? 'balanceRhythm' : 'summaryPill');
  expect(frame.isMoving, isTrue);
  expect(frame.rawIndex, greaterThan(0));
  expect(frame.rawIndex, lessThan(.5));
  expect(summary.rawIndex, closeTo(frame.rawIndex, .0001));
  expect(rhythm.rawIndex, closeTo(frame.rawIndex, .0001));
  expect(summary.origin.temporalAnchor.visibleDay, originalDay);
  expect(rhythm.origin.temporalAnchor.visibleDay, originalDay);
  expect(summary.isFollowing, fromRail);
  expect(rhythm.isFollowing, !fromRail);
  expect(_painter(tester).rawOffset.abs(), greaterThan(.001));
  expect(tester.getCenter(_summaryOriginText()).dy, lessThan(originalTextY));
}

Future<void> _settled(WidgetTester tester) async {
  for (var index = 0; index < 24; index++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await _frames(tester, 2);
}

void main() {
  final originalComparator = goldenFileComparator;
  setUpAll(() async {
    if (originalComparator is LocalFileComparator) {
      goldenFileComparator = _PairedMotionRasterComparator(
        originalComparator.basedir.resolve(
          'balance_day_visual_motion_sync_test.dart',
        ),
      );
    }
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/inter/InterVariable.ttf'))).load();
    await (FontLoader(
      'Roboto',
    )..addFont(rootBundle.load('assets/fonts/inter/InterVariable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await prepareDashboardTestRenderResources();
  });

  tearDownAll(() => goldenFileComparator = originalComparator);

  for (final presentation in SummaryTemporalFlingPresentation.values) {
    for (final fromRail in [false, true]) {
      testWidgets(
        '${presentation.name}: ${fromRail ? 'rhythm to Summary' : 'Summary to rhythm'} synchronizes before the first semantic tick and commits once',
        (tester) async {
          final core = await _setup(tester, presentation: presentation);
          final day = core.navigation.state.dayCursor;
          final epoch = core.navigation.state.navigationEpoch;
          final textY = tester.getCenter(_summaryOriginText()).dy;
          var canonicalPublications = 0;
          void count() => canonicalPublications++;
          core.navigation.addListener(count);
          addTearDown(() => core.navigation.removeListener(count));
          final gesture = await _subTick(tester, fromRail: fromRail);
          _expectSharedSubTick(
            tester,
            fromRail: fromRail,
            originalDay: day,
            originalTextY: textY,
          );
          expect(core.navigation.state.dayCursor, day);
          expect(
            canonicalPublications,
            0,
            reason: 'Passive visual following cannot navigate',
          );
          final distance = _pitch(tester);
          await gesture.moveBy(
            fromRail ? Offset(-distance, 0) : Offset(0, -distance),
          );
          await _frames(tester, 1);
          await gesture.up();
          await _settled(tester);
          expect(core.navigation.state.dayCursor, day + 1);
          expect(core.navigation.state.navigationEpoch, epoch + 1);
          expect(
            canonicalPublications,
            1,
            reason: 'A passive follower must not duplicate semantic settlement',
          );
          expect(
            (core.visibleFrames.value!.scope.timeScope as DayScope).date.day,
            day + 1,
          );
          expect(
            find.descendant(
              of: find.byKey(_summaryKey),
              matching: find.text('${day + 1}'),
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await _unmount(tester);
        },
      );
    }
  }

  testWidgets(
    'fast flights hand over both ways and stale owners cannot overwrite the replacement',
    (tester) async {
      final core = await _setup(tester);
      final coordinator = _adapter(tester, _rhythmKey).coordinator!;
      await tester.fling(find.byKey(_summaryKey), const Offset(0, -110), 1800);
      await _frames(tester, 2);
      expect(coordinator.dayVisualMotion!.source.name, 'summaryPill');
      final firstGeneration = coordinator.dayVisualMotion!.generation;
      final railGesture = await _subTick(tester, fromRail: true);
      expect(coordinator.dayVisualMotion!.source.name, 'balanceRhythm');
      expect(
        coordinator.dayVisualMotion!.generation,
        greaterThan(firstGeneration),
      );
      expect(
        _adapterState(tester, _summaryKey).visualState.isFollowing,
        isTrue,
      );
      await railGesture.up();
      await _settled(tester);
      await tester.fling(find.byKey(_rhythmKey), const Offset(-110, 0), 1800);
      await _frames(tester, 2);
      expect(coordinator.dayVisualMotion!.source.name, 'balanceRhythm');
      final railGeneration = coordinator.dayVisualMotion!.generation;
      final summaryGesture = await _subTick(tester, fromRail: false);
      expect(coordinator.dayVisualMotion!.source.name, 'summaryPill');
      expect(
        coordinator.dayVisualMotion!.generation,
        greaterThan(railGeneration),
      );
      expect(_adapterState(tester, _rhythmKey).visualState.isFollowing, isTrue);
      await summaryGesture.up();
      await _settled(tester);
      final finalDay = core.navigation.state.dayCursor;
      final finalEpoch = core.navigation.state.navigationEpoch;
      await _settled(tester);
      expect(core.navigation.state.dayCursor, finalDay);
      expect(core.navigation.state.navigationEpoch, finalEpoch);
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    },
  );

  for (final date in [
    DateTime(2025, 2, 28),
    DateTime(2024, 2, 29),
    DateTime(2026, 4, 30),
    DateTime(2026, 7, 31),
  ]) {
    testWidgets(
      'shared DAY motion preserves canonical ${date.day}-day month wrap',
      (tester) async {
        final core = await _setup(tester, date: date);
        final gesture = await _subTick(tester, fromRail: true);
        await gesture.moveBy(Offset(-_pitch(tester), 0));
        await _frames(tester, 1);
        final summary = _adapterState(tester, _summaryKey).visualState;
        final rhythm = _adapterState(tester, _rhythmKey).visualState;
        expect(summary.rawIndex, closeTo(rhythm.rawIndex, .0001));
        final summaryTarget = _adapter(
          tester,
          _summaryKey,
        ).candidateForOffset(summary.origin, 1)!;
        final rhythmTarget = _adapter(
          tester,
          _rhythmKey,
        ).candidateForOffset(rhythm.origin, 1)!;
        expect(summaryTarget.dayCursor, 1);
        expect(
          rhythmTarget.temporalAnchor.visibleYearMonth,
          summaryTarget.temporalAnchor.visibleYearMonth,
        );
        expect(rhythmTarget.dayCursor, 1);
        await gesture.up();
        await _settled(tester);
        expect(core.navigation.state.dayCursor, 1);
        expect(core.navigation.state.monthCursor.month, date.month);
        expect(core.navigation.state.yearCursor, date.year);
        expect(tester.takeException(), isNull);
        await _unmount(tester);
      },
    );
  }

  testWidgets(
    'applied day availability is identical on both synchronized surfaces',
    (tester) async {
      final core = await _setup(tester);
      final filter = QueryTemporalFilter.periods([
        QueryPeriodSelection.day(2026, 7, 2),
        QueryPeriodSelection.day(2026, 7, 7),
        QueryPeriodSelection.day(2026, 7, 16),
      ]);
      var complete = false;
      var accepted = false;
      core
          .applyQuery(core.currentQuery.scope.copyWith(temporalFilter: filter))
          .then((value) {
            accepted = value;
            complete = true;
          });
      for (var index = 0; index < 60 && !complete; index++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      expect(complete, isTrue);
      expect(accepted, isTrue);
      await _frames(tester, 4);
      expect(core.navigation.state.dayCursor, 16);
      final gesture = await _subTick(tester, fromRail: false);
      await gesture.moveBy(Offset(0, -_pitch(tester)));
      await _frames(tester, 1);
      final summary = _adapterState(tester, _summaryKey).visualState;
      final rhythm = _adapterState(tester, _rhythmKey).visualState;
      final summaryTarget = _adapter(
        tester,
        _summaryKey,
      ).candidateForOffset(summary.origin, 1)!;
      final rhythmTarget = _adapter(
        tester,
        _rhythmKey,
      ).candidateForOffset(rhythm.origin, 1)!;
      expect(summaryTarget.dayCursor, 2);
      expect(rhythmTarget.dayCursor, 2);
      await gesture.up();
      await _settled(tester);
      expect(core.navigation.state.dayCursor, 2);
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    },
  );
  testWidgets(
    'avatar perspective changes preserve a moving paired rail and Eddigi unmount revokes it',
    (tester) async {
      final core = await _setup(tester);
      final railState = _adapterState(tester, _rhythmKey);
      final coordinator = _adapter(tester, _rhythmKey).coordinator!;
      await tester.fling(find.byKey(_rhythmKey), const Offset(-110, 0), 1800);
      await _frames(tester, 2);
      expect(coordinator.dayVisualMotion!.isMoving, isTrue);
      final generation = coordinator.dayVisualMotion!.generation;
      final owner = coordinator.activeOwner;
      await tester.tap(
        find.byKey(
          const ValueKey('balance-day-perspective-financialComparison'),
        ),
      );
      await _frames(tester, 1);
      expect(identical(_adapterState(tester, _rhythmKey), railState), isTrue);
      expect(coordinator.dayVisualMotion!.generation, generation);
      expect(identical(coordinator.activeOwner, owner), isTrue);
      expect(
        _adapterState(tester, _summaryKey).visualState.isFollowing,
        isTrue,
      );
      final tuner = tester.widget<DashboardHeaderVisualTuner>(
        find.byType(DashboardHeaderVisualTuner),
      );
      expect(
        tuner.balancePresentationSettings!.value.dayFocusedPresentation,
        BalanceDayFocusedPresentation.financialComparison,
      );
      tuner.balancePresentationSettings!.setDayLayoutPresentation(
        BalanceDayLayoutPresentation.current,
      );
      await _frames(tester, 4);
      expect(find.byKey(_rhythmKey), findsNothing);
      expect(
        core.isMotionLaneActive(DashboardMotionLane.summaryShell),
        isFalse,
      );
      expect(
        _adapterState(tester, _summaryKey).visualState.isFollowing,
        isFalse,
      );
      final day = core.navigation.state.dayCursor;
      final epoch = core.navigation.state.navigationEpoch;
      expect(_adapterState(tester, _summaryKey).visualState.rawIndex, 0);
      final settledLabel = find.descendant(
        of: find.byKey(_summaryKey),
        matching: find.text('$day'),
      );
      expect(settledLabel, findsOneWidget);
      expect(
        tester.getCenter(settledLabel).dy,
        closeTo(tester.getCenter(find.byKey(_summaryKey)).dy, .01),
      );
      await _settled(tester);
      expect(core.navigation.state.dayCursor, day);
      expect(core.navigation.state.navigationEpoch, epoch);
      expect(
        core.isMotionLaneActive(DashboardMotionLane.summaryShell),
        isFalse,
      );
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    },
  );

  testWidgets(
    'intermediate paired motion frame shows Summary and rhythm moving together',
    (tester) async {
      final core = await _setup(tester, richData: true);
      final originalDay = core.navigation.state.dayCursor;
      final originalTextY = tester.getCenter(_summaryOriginText()).dy;
      final gesture = await _subTick(tester, fromRail: true);
      _expectSharedSubTick(
        tester,
        fromRail: true,
        originalDay: originalDay,
        originalTextY: originalTextY,
      );
      expect(core.navigation.state.dayCursor, originalDay);
      final pairedImage = await _capturePairedSurfaces(tester);
      try {
        await expectLater(
          pairedImage,
          matchesGoldenFile(
            '../../../goldens/balance_day_paired_motion_intermediate.png',
          ),
        );
      } finally {
        pairedImage.dispose();
      }
      await gesture.up();
      await _settled(tester);
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    },
  );
}

// Only acquisition is fixture data: Core's exact prepared membership, financial
// projections, scene binding and temporal acceptance remain production code.
final class _PairedMotionRepository implements DashboardDataRuntimeRepository {
  final rows = List<DashboardLedgerEntry>.unmodifiable([
    for (var offset = 0; offset < 120; offset++)
      for (final direction in ['income', 'expense'])
        DashboardLedgerEntry(
          id: '$direction-$offset',
          partnerId: 'partner-$direction',
          categoryId: 'day-$direction',
          direction: direction,
          amountMinor: direction == 'income'
              ? 200000 + (offset * 7 % 9) * 25000
              : 150000 + (offset * 5 % 11) * 18000,
          bookedLocalEpochDay:
              const LocalDate(year: 2026, month: 7, day: 16).epochDay - offset,
          bookedLocalTimeMinutes: 720,
          categoryDisplayName: direction == 'income'
              ? 'Napi bevétel'
              : 'Napi kiadás',
          partnerDisplayName: 'Napi pénzforgalom',
          categoryColorId: 'fallback',
          categoryIconId: 'fallback',
        ),
  ]);
  List<DashboardLedgerEntry> _rowsFor(CurrentLedgerQueryScope scope) {
    final boundaries = scope.timeScope.boundaries;
    return rows
        .where(
          (row) =>
              row.direction == scope.direction.name &&
              (boundaries == null ||
                  (row.bookedLocalEpochDay >=
                          boundaries.startInclusive.epochDay &&
                      row.bookedLocalEpochDay <
                          boundaries.endExclusive.epochDay)),
        )
        .toList(growable: false);
  }

  DashboardLogViewportState _payload(
    CurrentLedgerQueryScope scope,
    int revision,
  ) {
    final selected = _rowsFor(scope);
    return DashboardLogViewportState.deferredPreparedOrdered(
      scope: scope,
      revision: revision,
      entries: selected,
      entryCount: selected.length,
      nextCursor: null,
    );
  }

  @override
  Stream<int> watchCoreRevision() => Stream.value(1);
  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) async {
    final empty = await const EmptyDashboardDataRuntimeRepository()
        .prepareIndex(request, token);
    final scopes = <LedgerQueryKey, CurrentLedgerQueryScope>{
      for (final zero in empty.compactZeroFrames.values)
        zero.queryKey: zero.scope,
      for (final frame in empty.frames.values) frame.queryKey: frame.scope,
    };
    final frames = <LedgerQueryKey, DashboardPreparedFrame>{};
    for (final scope in scopes.values) {
      final selected = _rowsFor(scope);
      if (selected.isEmpty) continue;
      final amount = selected.fold<int>(0, (sum, row) => sum + row.amountMinor);
      frames[scope.key] = DashboardPreparedFrame.complete(
        scope: scope,
        parentQueryKey: dashboardPreparedParentQueryKey(scope),
        coreRevision: request.key.coreRevision,
        totalMinor: amount,
        formattedAmount: DashboardPreparedFormatter.amountMinor(amount),
        entryCount: selected.length,
        formattedEntryCount: '${selected.length}',
        logBox: _payload(scope, request.key.coreRevision),
        presentationDigest: Object.hash(scope.key, amount, selected.length),
      );
    }
    return PreparedDashboardIndex.complete(
      key: request.key,
      frames: frames,
      catalogs: empty.catalogs,
      scopes: scopes,
      geometrySeedsByDirection: {
        for (final direction in LedgerDirection.values)
          direction: [
            for (final row in rows.where(
              (row) => row.direction == direction.name,
            ))
              CommittedVerticalGeometryDayBucket(
                bookedLocalEpochDay: row.bookedLocalEpochDay,
                entryCount: 1,
              ),
          ],
      },
      focusMembershipSeedsByDirection: {
        for (final direction in LedgerDirection.values)
          direction: DashboardFocusMembershipSeed(
            rows
                .where((row) => row.direction == direction.name)
                .toList(growable: false),
          ),
      },
      generation: token.generation,
      contentDigest: Object.hash(request.key, rows.length),
      preparedAt: DateTime.utc(2026, 7, 16),
      buildMetrics: empty.buildMetrics,
    );
  }

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) async => CommittedLogPage(
    queryKey: request.scope.key,
    coreRevision: request.coreRevision,
    generation: request.commitGeneration,
    ordinal: request.pageOrdinal,
    startCursor: request.startCursor,
    previousStartCursor: request.previousStartCursor,
    payload: _payload(request.scope, request.coreRevision),
  );
  @override
  Map<String, Object?> performanceReport() => const {};
}

/// Crop the actual simultaneously mounted surfaces from one held-drag frame.
/// Integer bounds and equal source/destination extents preserve every pixel;
/// unrelated Header/LogBox paint is outside this feature's visual acceptance.
Future<ui.Image> _capturePairedSurfaces(WidgetTester tester) async {
  final boundaryFinder = find.byKey(const ValueKey('paired-day-motion-scene'));
  final boundary = tester.renderObject<RenderRepaintBoundary>(boundaryFinder);
  final origin = tester.getTopLeft(boundaryFinder);
  Rect region(Finder finder) {
    final rect = tester.getRect(finder).shift(-origin);
    return Rect.fromLTRB(
      rect.left.floorToDouble(),
      rect.top.floorToDouble(),
      rect.right.ceilToDouble(),
      rect.bottom.ceilToDouble(),
    );
  }

  final rail = region(find.byKey(const ValueKey('balance-day-momentum-rail')));
  final summary = region(find.byKey(_summaryKey));
  const padding = 16;
  final width =
      (rail.width > summary.width ? rail.width : summary.width).toInt() +
      padding * 2;
  final height = rail.height.toInt() + summary.height.toInt() + padding * 3;
  final railDestination = Offset(
    ((width - rail.width) / 2).floorToDouble(),
    padding.toDouble(),
  );
  final summaryDestination = Offset(
    ((width - summary.width) / 2).floorToDouble(),
    padding * 2 + rail.height,
  );
  debugPrint(
    'DAY_PAIRED_CAPTURE rail=$rail summary=$summary destinations=$railDestination,$summaryDestination size=$width,$height',
  );
  final full = await boundary.toImage(pixelRatio: 1);
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawColor(Colors.white, ui.BlendMode.src);
  final paint = ui.Paint()..filterQuality = ui.FilterQuality.none;
  canvas.drawImageRect(full, rail, railDestination & rail.size, paint);
  canvas.drawImageRect(full, summary, summaryDestination & summary.size, paint);
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(width, height);
  } finally {
    picture.dispose();
    full.dispose();
  }
}

/// CI evidence from 1410ce98: unchanged Header accounts for 11642 pixels;
/// outside it, the changed rail differs only at full-frame (336,569), one green
/// channel (ARM 220 / x64 219). The impact-tube pixel is outside these crops.
/// Permit only that measured quantization budget for this ONE filename: one
/// pixel and one total channel unit, never a percentage/global threshold.
final class _PairedMotionRasterComparator extends LocalFileComparator {
  _PairedMotionRasterComparator(super.testFile);
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    if (golden.pathSegments.last !=
        'balance_day_paired_motion_intermediate.png') {
      return super.compare(imageBytes, golden);
    }
    final actualCodec = await ui.instantiateImageCodec(imageBytes);
    final referenceCodec = await ui.instantiateImageCodec(
      Uint8List.fromList(await getGoldenBytes(golden)),
    );
    final actual = (await actualCodec.getNextFrame()).image;
    final reference = (await referenceCodec.getNextFrame()).image;
    actualCodec.dispose();
    referenceCodec.dispose();
    var accepted = false;
    try {
      if (actual.width == reference.width &&
          actual.height == reference.height) {
        final a = (await actual.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        final b = (await reference.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        var pixels = 0, channelUnits = 0;
        for (var index = 0; index < a.length; index += 4) {
          var different = false;
          for (var channel = 0; channel < 4; channel++) {
            final delta = (a[index + channel] - b[index + channel]).abs();
            channelUnits += delta;
            different = different || delta != 0;
          }
          if (different) pixels++;
        }
        accepted = pixels <= 1 && channelUnits <= 1;
        if (pixels != 0) {
          debugPrint(
            'Paired motion raster evidence: pixels=$pixels totalChannelUnits=$channelUnits accepted=$accepted',
          );
        }
      }
    } finally {
      actual.dispose();
      reference.dispose();
    }
    return accepted || await super.compare(imageBytes, golden);
  }
}
