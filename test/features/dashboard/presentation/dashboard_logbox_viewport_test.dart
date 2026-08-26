import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_logbox_layout_profile.dart';
import 'package:fluvi/core/design/dashboard_corner_profile.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/core/design/fluvi_rounded_box.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_vertical_geometry_manifest.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_corner_roundness.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_header.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_partner_swipe.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_menu_data.dart';
import 'package:fluvi/features/dashboard/runtime/application/explicit_committed_paging_controller.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/application/dashboard_visible_frame_store.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

import '../../../support/dashboard_render_resources.dart';

void main() {
  setUpAll(prepareDashboardTestRenderResources);

  testWidgets('SearchPill resolves the global Search family', (tester) async {
    final store = DashboardVisibleFrameStore();
    final roundness = DashboardCornerRoundnessController()
      ..setPosition(DashboardCornerSurfaceFamily.logBoxGroup, 1);
    addTearDown(store.dispose);
    addTearDown(roundness.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardCornerRoundnessScope(
          controller: roundness,
          child: SizedBox(
            width: 378,
            child: DashboardLogBoxHeader(
              bounds: const DashboardBounds(
                left: 0,
                top: 0,
                width: 378,
                height: DashboardLayoutMetrics.referenceLogBoxHeaderHeight,
              ),
              visibleFrames: store,
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<FluviRoundedBox>(
            find.descendant(
              of: find.byKey(const ValueKey('dashboard-logbox-search-pill')),
              matching: find.byType(FluviRoundedBox),
            ),
          )
          .decoration
          .borderRadius,
      DashboardCornerProfile(
        DashboardCornerSettings.defaults.withPosition(
          DashboardCornerSurfaceFamily.logBoxGroup,
          1,
        ),
      ).borderRadiusFor(
        DashboardCornerSurfaceFamily.searchPill,
        size: const Size(378, DashboardLogBoxTokens.ledgerSearchPillHeight),
      ),
    );
  });

  testWidgets(
    'Ledger chrome orders count, SearchPill, and scroll lane without a result amount',
    (tester) async {
      final fixture = await _readyFixture(tester, totalRows: 94);
      addTearDown(fixture.dispose);

      final count = find.byKey(const ValueKey('dashboard-logbox-entry-count'));
      final search = find.byKey(const ValueKey('dashboard-logbox-search-pill'));
      final scroll = find.byKey(const ValueKey('dashboard-logbox-scroll-view'));

      expect(
        find.byKey(const ValueKey('dashboard-logbox-result-amount')),
        findsNothing,
      );
      expect(count, findsOneWidget);
      expect(search, findsOneWidget);
      expect(
        tester.getRect(count).bottom,
        lessThan(tester.getRect(search).top),
      );
      expect(
        tester.getRect(search).bottom,
        lessThanOrEqualTo(tester.getRect(scroll).top),
      );
      expect(
        find.descendant(of: search, matching: find.byType(FluviRoundedBox)),
        findsOneWidget,
      );
      final searchSemantics = tester.widget<Semantics>(search);
      expect(searchSemantics.properties.button, isTrue);
      expect(searchSemantics.properties.enabled, isFalse);
    },
  );

  testWidgets('Ledger count tracks one committed frame across query states', (
    tester,
  ) async {
    final store = DashboardVisibleFrameStore();
    addTearDown(store.dispose);
    final incomeScope = CurrentLedgerQueryScope(
      direction: LedgerDirection.income,
      timeScope: MonthScope(const YearMonth(year: 2026, month: 7)),
    );
    store.publish(
      _frame(
        totalRows: 6,
        totalMinor: 70700000,
        formattedAmount: '707000,00 Ft',
        scope: incomeScope,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 378,
          child: DashboardLogBoxHeader(
            bounds: const DashboardBounds(
              left: 0,
              top: 0,
              width: 378,
              height: DashboardLayoutMetrics.referenceLogBoxHeaderHeight,
            ),
            visibleFrames: store,
          ),
        ),
      ),
    );
    expect(find.text('6 tranzakció listázva'), findsOneWidget);

    final expenseScope = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const YearScope(2026),
    );
    store.publish(
      _frame(
        totalRows: 1,
        totalMinor: -100000,
        formattedAmount: '-1000,00 Ft',
        scope: expenseScope,
        coreRevision: 2,
        presentationEpoch: 2,
      ),
    );
    await tester.pump();
    expect(find.text('1 tranzakció listázva'), findsOneWidget);

    final filteredScope = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const DayScope(LocalDate(year: 2026, month: 7, day: 25)),
      categoryIds: const <String>{'category-filtered'},
    );
    store.publish(
      _frame(
        totalRows: 0,
        totalMinor: 0,
        formattedAmount: '0,00 Ft',
        scope: filteredScope,
        coreRevision: 3,
        presentationEpoch: 3,
      ),
    );
    await tester.pump();
    expect(find.text('0 tranzakció listázva'), findsOneWidget);
  });

  testWidgets(
    'Ledger chrome keeps count and SearchPill inside scaled structural slots',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      addTearDown(store.dispose);
      store.publish(
        _frame(
          totalRows: 123456,
          totalMinor: 98765432100,
          formattedAmount: '987654321,00 Ft',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Center(
              child: SizedBox(
                width: 189,
                child: DashboardLogBoxHeader(
                  bounds: const DashboardBounds(
                    left: 0,
                    top: 0,
                    width: 189,
                    height:
                        DashboardLayoutMetrics.referenceLogBoxHeaderHeight / 2,
                  ),
                  visibleFrames: store,
                ),
              ),
            ),
          ),
        ),
      );

      final count = find.byKey(const ValueKey('dashboard-logbox-entry-count'));
      final search = find.byKey(const ValueKey('dashboard-logbox-search-pill'));

      expect(
        tester.getRect(count).bottom,
        lessThanOrEqualTo(tester.getRect(search).top),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the LogBox scroll viewport owns a hard physical paint clip', (
    tester,
  ) async {
    final fixture = await _readyFixture(tester, totalRows: 94);
    addTearDown(fixture.dispose);

    final scrollView = tester.widget<CustomScrollView>(
      find.byKey(const ValueKey('dashboard-logbox-scroll-view')),
    );

    expect(scrollView.clipBehavior, Clip.hardEdge);

    final viewportFinder = find.descendant(
      of: find.byKey(const ValueKey('dashboard-logbox-scroll-view')),
      matching: find.byType(Viewport),
    );
    expect(viewportFinder, findsOneWidget);
    expect(
      tester.renderObject<RenderViewport>(viewportFinder).clipBehavior,
      Clip.hardEdge,
    );
  });
  testWidgets(
    'a raw LogBox pointer forwards foreground intent before drag recognition',
    (tester) async {
      final fixture = await _readyFixture(tester, totalRows: 94);
      addTearDown(fixture.dispose);
      final started = <int>[];
      final ended = <String>[];

      await tester.pumpWidget(
        _viewport(
          store: fixture.store,
          cache: fixture.cache,
          railScenes: fixture.railScenes,
          onLoadNextPage: (_) {},
          onVerticalPointerIntentStarted: started.add,
          onVerticalPointerIntentEnded: (pointer, {required cancelled}) {
            ended.add('$pointer:$cancelled');
          },
        ),
      );
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey('dashboard-logbox-scroll-view')),
        ),
      );
      expect(started, hasLength(1));
      expect(ended, isEmpty);

      await gesture.up();
      await tester.pump();
      expect(ended, <String>['${started.single}:false']);

      final cancelledGesture = await tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey('dashboard-logbox-scroll-view')),
        ),
      );
      await cancelledGesture.cancel();
      await tester.pump();
      expect(ended.last, '${started.last}:true');
    },
  );

  testWidgets(
    'RED: the first single vertical partner-row move after direct Query publication advances the existing scrollable',
    (tester) async {
      final partnerSwipe = DashboardLogBoxPartnerSwipeController(
        vsync: TestVSync(),
      );
      addTearDown(partnerSwipe.dispose);
      final fixture = await _readyFixture(
        tester,
        totalRows: 94,
        partnerSwipe: partnerSwipe,
      );
      addTearDown(fixture.dispose);
      FluviDiagnosticLogger.clear();

      final directChipRemovalScope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: MonthScope(const YearMonth(year: 2026, month: 7)),
        categoryIds: const <String>{'category-after-chip-removal'},
      );
      final directlyPublished = _frame(
        totalRows: 94,
        scope: directChipRemovalScope,
        coreRevision: 2,
        presentationEpoch: 2,
      );
      fixture.store.publish(directlyPublished);
      fixture.paging.commitMetadata(
        directlyPublished,
        geometryManifest: _manifest(directlyPublished),
      );
      fixture.cache.configureSurfaceWidth(378);
      expect(
        await fixture.paging.prepareReadyAheadAtIdle(
          reason: 'directQueryPublication',
        ),
        isTrue,
      );
      await _prepareRailScene(fixture.railScenes, directlyPublished);
      await tester.pump();
      expect(fixture.cache.queryKey, directChipRemovalScope.key);
      expect(fixture.cache.contiguousReadyRowCount, 94);
      expect(fixture.cache.highestReadyPageOrdinal, greaterThanOrEqualTo(3));

      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      final surface = find.byKey(
        const ValueKey('dashboard-logbox-stable-render-surface'),
      );
      final surfaceRect = tester.getRect(surface);
      final partnerRowCenter = Offset(
        surfaceRect.center.dx,
        surfaceRect.top +
            DashboardLogBoxTokens.dayHeaderHeight +
            DashboardLogBoxTokens.rowHeight / 2,
      );

      final gesture = await tester.startGesture(partnerRowCenter);
      await gesture.moveBy(
        const Offset(0, -192),
        timeStamp: const Duration(milliseconds: 8),
      );
      await gesture.up(timeStamp: const Duration(milliseconds: 9));
      await tester.pumpAndSettle();

      expect(
        scrollable.position.pixels,
        greaterThan(0),
        reason:
            'The sole pre-arena vertical move must belong to the existing '
            'framework Scrollable immediately after the exact direct Query '
            'publication; a second move or gesture is not available to repair '
            'this fast fling.',
      );
      expect(partnerSwipe.isActive, isFalse);
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'PARTNER_FOCUS_REQUESTED',
        ),
        isEmpty,
      );
      final input = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'VERTICAL_INPUT_SAMPLE_SUMMARY')
          .single;
      expect(input.message, contains('moveEventCount=1'));
      expect(input.message, contains('netDy=-192'));
      expect(
        FluviDiagnosticLogger.entries.any(
          (event) => event.stage == 'VERTICAL_INTERACTION_SESSION_STARTED',
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'the physical hard-edge host begins at screen left while the resting LogBox surface remains inset',
    (tester) async {
      final fixture = await _readyFixture(
        tester,
        totalRows: 94,
        dashboardLeft: 17,
        screenWidth: 412,
      );
      addTearDown(fixture.dispose);

      final physicalHost = find.byKey(
        const ValueKey('dashboard-logbox-physical-scroll-host'),
      );
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );
      final staticSurface = find.byKey(
        const ValueKey('dashboard-logbox-stable-render-surface'),
      );
      final hostRect = tester.getRect(physicalHost);
      final scrollRect = tester.getRect(scrollView);
      final staticRect = tester.getRect(staticSurface);

      expect(hostRect.left, 0);
      expect(scrollRect.left, 0);
      expect(hostRect.top, scrollRect.top);
      expect(hostRect.bottom, scrollRect.bottom);
      expect(staticRect.left, 17);
      expect(staticRect.width, 378);
      expect(
        tester
            .renderObject<RenderViewport>(
              find.descendant(of: scrollView, matching: find.byType(Viewport)),
            )
            .clipBehavior,
        Clip.hardEdge,
      );
    },
  );

  testWidgets(
    'the active canonical segment crosses the resting inset inside the same hard-edged vertical viewport',
    (tester) async {
      final swipe = DashboardLogBoxPartnerSwipeController(vsync: TestVSync());
      addTearDown(swipe.dispose);
      final fixture = await _readyFixture(
        tester,
        totalRows: 94,
        dashboardLeft: 17,
        screenWidth: 412,
        partnerSwipe: swipe,
      );
      addTearDown(fixture.dispose);

      final surface = find.byKey(
        const ValueKey('dashboard-logbox-stable-render-surface'),
      );
      final surfaceRect = tester.getRect(surface);
      final rowTop = surfaceRect.top + DashboardLogBoxTokens.dayHeaderHeight;
      final target = DashboardLogBoxRowHitTarget(
        row: _row(0),
        globalRowBounds: Rect.fromLTWH(
          surfaceRect.left,
          rowTop,
          surfaceRect.width,
          DashboardLogBoxTokens.rowHeight,
        ),
        globalAvatarBounds: Rect.fromLTWH(
          surfaceRect.left + DashboardLogBoxTokens.rowHorizontalInset,
          rowTop + DashboardLogBoxTokens.rowVerticalInset,
          DashboardLogBoxTokens.avatarSize,
          DashboardLogBoxTokens.avatarSize,
        ),
        localRowTop: DashboardLogBoxTokens.dayHeaderHeight,
        blockSegmentRole: DashboardLogBoxBlockSegmentRole.singleton,
      );

      expect(swipe.begin(target), isTrue);
      swipe.update(-25);
      await tester.pump();

      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );
      final activeSegment = find.byKey(
        const ValueKey('dashboard-logbox-active-canonical-segment'),
      );
      expect(activeSegment, findsOneWidget);
      final scrollRect = tester.getRect(scrollView);
      final activeRect = tester.getRect(activeSegment);
      expect(activeRect.left, lessThan(0));
      expect(scrollRect.left, 0);
      expect(activeRect.right, greaterThan(scrollRect.left));
      expect(activeRect.top, greaterThanOrEqualTo(scrollRect.top));
      expect(activeRect.bottom, lessThanOrEqualTo(scrollRect.bottom));
      expect(
        find.ancestor(of: activeSegment, matching: find.byType(Viewport)),
        findsOneWidget,
        reason:
            'The leased segment must share the outer hard-edge vertical '
            'viewport instead of escaping through a dashboard overlay.',
      );
    },
  );

  testWidgets(
    'RED: the LogBox scroll viewport begins below its structural count header',
    (tester) async {
      final fixture = await _readyFixture(tester, totalRows: 94);
      addTearDown(fixture.dispose);

      final header = find.byKey(const ValueKey('dashboard-logbox-header'));
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );

      expect(header, findsOneWidget);
      expect(scrollView, findsOneWidget);
      expect(
        tester.getRect(scrollView).top,
        greaterThanOrEqualTo(tester.getRect(header).bottom),
        reason:
            'The scrollable must begin after the count header, not behind an '
            'overlay compensated by an in-scroll spacer.',
      );
    },
  );
  testWidgets(
    'RED: the LogBox scroll viewport begins below active Query facet chips',
    (tester) async {
      final fixture = await _readyFixture(tester, totalRows: 94);
      final query = CurrentQueryController(
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: MonthScope(YearMonth(year: 2026, month: 7)),
          categoryIds: const <String>{'food'},
        ),
      );
      addTearDown(fixture.dispose);
      addTearDown(query.dispose);
      query.apply(
        query.scope,
        facetPresentation: const QueryMenuData(
          result: QueryMenuResultSummary(entryCount: 94, amountScaled100: 1),
          amountDomain: QueryMenuAmountDomain(
            minimumAmountScaled100: 0,
            maximumAmountScaled100: 1,
          ),
          availableMonths: <QueryMenuAvailableMonth>[],
          categories: <QueryMenuCategoryFacet>[
            QueryMenuCategoryFacet(
              id: 'food',
              displayName: 'Étel',
              colorId: 'color_15',
              iconId: 'icon_02',
              entryCount: 94,
            ),
          ],
          partners: <QueryMenuPartnerFacet>[],
        ),
      );

      await tester.pumpWidget(
        _viewport(
          store: fixture.store,
          cache: fixture.cache,
          railScenes: fixture.railScenes,
          onLoadNextPage: (_) {},
          currentQuery: query,
        ),
      );
      await tester.pump();

      final chips = find.byKey(const ValueKey('dashboard-query-facet-chips'));
      final search = find.byKey(const ValueKey('dashboard-logbox-search-pill'));
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );

      expect(chips, findsOneWidget);
      expect(
        tester.getRect(search).bottom,
        lessThanOrEqualTo(tester.getRect(chips).top),
        reason: 'Applied Query facets remain after the Ledger SearchPill.',
      );
      expect(
        tester.getRect(scrollView).top,
        greaterThanOrEqualTo(tester.getRect(chips).bottom + 6),
        reason:
            'Active facets need a small dedicated breathing gap before the '
            'structural scroll viewport.',
      );
    },
  );

  testWidgets(
    'RED: an exact virtual extent is authoritative before the first vertical drag',
    (tester) async {
      final fixture = await _readyFixture(tester, totalRows: 94);
      addTearDown(fixture.dispose);
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      final maxAtRest = position.maxScrollExtent;
      final minAtRest = position.minScrollExtent;
      final physicsAtRest = position.physics;
      expect(minAtRest, 0);

      expect(fixture.cache.isVerticalRenderingActive, isFalse);
      expect(
        maxAtRest,
        closeTo(
          fixture.cache.contentHeight -
              position.viewportDimension +
              DashboardLogBoxTokens.terminalBottomBreathingRoom,
          0.1,
        ),
        reason:
            'The full immutable virtual geometry is already known while '
            'railPreview paints the prepared root. Its only extra scroll '
            'extent is the terminal navigation/shadow tail, so a first drag '
            'may switch paint domain but cannot install dimensions.',
      );

      await tester.drag(scrollView, const Offset(0, -80));
      await tester.pump();

      expect(position.maxScrollExtent, maxAtRest);
      final scrollableAfterDrag = tester.state<ScrollableState>(
        find.byType(Scrollable),
      );
      expect(identical(scrollableAfterDrag.position, position), isTrue);
      expect(
        identical(scrollableAfterDrag.position.physics, physicsAtRest),
        isTrue,
      );
      expect(position.minScrollExtent, minAtRest);
    },
  );

  testWidgets(
    'first real vertical gesture activates already-armed committed resources only',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final fixture = await _readyFixture(tester, totalRows: 89);
      addTearDown(fixture.dispose);
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );
      final preparedRowsBeforePointer = fixture.cache.preparedTextRowCount;
      final preparedHeadersBeforePointer = fixture.cache.preparedDayHeaderCount;

      expect(fixture.cache.isVerticalRenderingActive, isFalse);
      expect(fixture.cache.isVerticalInteractionArmed, isTrue);

      await tester.drag(scrollView, const Offset(0, -96));
      await tester.pump();

      expect(fixture.cache.isVerticalRenderingActive, isTrue);
      expect(fixture.cache.preparedTextRowCount, preparedRowsBeforePointer);
      expect(
        fixture.cache.preparedDayHeaderCount,
        preparedHeadersBeforePointer,
      );
      final activation = FluviDiagnosticLogger.entries.lastWhere(
        (event) => event.stage == 'VERTICAL_RENDER_ACTIVATION_COMPLETED',
      );
      expect(
        activation.message,
        allOf(contains('wasArmed=true'), contains('newPreparedPageCount=0')),
      );
    },
  );

  testWidgets(
    'a genuinely unavailable committed virtual page remains fail-closed',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      final cache = CommittedLogViewportCache(
        pageSize: 24,
        pagePreparationPolicy: const CommittedPagePreparationPolicy(
          contiguousUiBudgetMicros: 1000000,
        ),
      );
      final railScenes = DashboardLogBoxPreparedSceneCache();
      final counters = DashboardPerformanceCounters();
      addTearDown(store.dispose);
      addTearDown(cache.dispose);
      addTearDown(railScenes.dispose);
      final frame = _frame(totalRows: 67);
      store.publish(frame);
      cache.seed(
        _rootPage(frame),
        generation: 1,
        geometryManifest: _manifest(frame),
      );
      cache.configureSurfaceWidth(378);
      await _prepareRailScene(railScenes, frame);
      expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);

      await tester.pumpWidget(
        _viewport(
          store: store,
          cache: cache,
          railScenes: railScenes,
          performanceCounters: counters,
          onLoadNextPage: (_) {},
        ),
      );
      await tester.pump();
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      final virtualExtent = cache.contentHeight;
      position.jumpTo(cache.pageTopForOrdinal(1) + 12);
      await tester.pump();

      expect(cache.pageForOrdinal(1), isNull);
      expect(cache.preparedPageForOrdinal(1), isNull);
      expect(cache.virtualPageMissCount, 1);
      expect(counters.value(DashboardPerformanceMetric.verticalCacheMiss), 1);
      expect(
        counters.value(DashboardPerformanceMetric.logTextLayoutFallback),
        1,
        reason:
            'The renderer records the exact cache miss; it does not create '
            'a paint-time text layout or borrow a neighbouring page.',
      );
      expect(cache.contentHeight, virtualExtent);
    },
  );

  testWidgets(
    'interaction summaries retain a current visible resource gap after virtual-miss deduplication',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final store = DashboardVisibleFrameStore();
      final cache = CommittedLogViewportCache(pageSize: 24);
      final railScenes = DashboardLogBoxPreparedSceneCache();
      addTearDown(store.dispose);
      addTearDown(cache.dispose);
      addTearDown(railScenes.dispose);
      final frame = _frame(totalRows: 67);
      store.publish(frame);
      cache.seed(
        _rootPage(frame),
        generation: 1,
        geometryManifest: _manifest(frame),
      );
      cache.configureSurfaceWidth(378);
      await _prepareRailScene(railScenes, frame);
      expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);
      final pageOneOffset = cache.pageTopForOrdinal(1) + 12;
      cache.recordVirtualPageMiss(
        ordinal: 1,
        scrollOffset: pageOneOffset,
        direction: 'forward',
      );
      cache.recordVirtualPageMiss(
        ordinal: 1,
        scrollOffset: pageOneOffset,
        direction: 'forward',
      );
      expect(cache.virtualPageMissCount, 1);

      await tester.pumpWidget(
        _viewport(
          store: store,
          cache: cache,
          railScenes: railScenes,
          onLoadNextPage: (_) {},
        ),
      );
      await tester.pump();
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );
      final context = tester.element(scrollView);
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: cache.drawableExtent,
        pixels: pageOneOffset,
        viewportDimension: 420,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      );
      ScrollStartNotification(
        metrics: metrics,
        context: context,
        dragDetails: DragStartDetails(globalPosition: Offset.zero),
      ).dispatch(context);
      ScrollEndNotification(
        metrics: metrics,
        context: context,
        dragDetails: DragEndDetails(
          velocity: Velocity.zero,
          primaryVelocity: 0,
        ),
      ).dispatch(context);
      await tester.pump();

      final interaction = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'VERTICAL_INTERACTION_PERF_SUMMARY')
          .single;
      for (final expected in <String>[
        'firstVisibleOrdinalAtStart=1',
        'highestReadyOrdinalAtStart=0',
        'readyDrawableAheadPixelsAtStart=0',
        'visibleMissingPageCountAtStart=1',
        'firstVisibleMissingOrdinalAtStart=1',
        'visibleMissingPageCountAtEnd=1',
        'firstVisibleMissingOrdinalAtEnd=1',
        'virtualPageMissCount=0',
      ]) {
        expect(interaction.message, contains(expected));
      }
      final scrollSummary = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'VERTICAL_SCROLL_SUMMARY')
          .single;
      expect(
        scrollSummary.message,
        allOf(
          contains('readyDrawableAheadPixels=0'),
          contains('missingVisibleOrdinals=[1]'),
          contains('missingVisiblePageCount=1'),
          contains('firstVisibleMissingOrdinal=1'),
        ),
      );
    },
  );

  testWidgets(
    'a common fling adopts the idle-ready bank without foreground reads or identity replacement',
    (tester) async {
      final fixture = await _readyFixture(tester, totalRows: 94);
      addTearDown(fixture.dispose);
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      final position = scrollable.position;
      final physics = position.physics;
      final readsBeforeInteraction =
          fixture.repository.requestedOrdinals.length;

      await tester.fling(scrollView, const Offset(0, -180), 5000);
      await tester.pump();

      expect(fixture.cache.isVerticalRenderingActive, isTrue);
      expect(fixture.cache.contiguousReadyRowCount, 94);
      expect(
        fixture.repository.requestedOrdinals,
        hasLength(readsBeforeInteraction),
        reason: 'a visible page inside the exact ready bank needs no read',
      );
      expect(identical(scrollable.position, position), isTrue);
      expect(identical(position.physics, physics), isTrue);
      expect(
        fixture.counters.value(DashboardPerformanceMetric.verticalCacheMiss),
        0,
      );
      expect(
        fixture.counters.value(DashboardPerformanceMetric.textLayoutMiss),
        0,
      );
    },
  );

  testWidgets(
    'one interaction emits one aggregate ready-ahead summary without per-frame logs',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final fixture = await _readyFixture(tester, totalRows: 94);
      addTearDown(fixture.dispose);

      await tester.drag(
        find.byKey(const ValueKey('dashboard-logbox-scroll-view')),
        const Offset(0, -120),
      );
      await tester.pump();

      final summaries = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'VERTICAL_INTERACTION_PERF_SUMMARY')
          .toList(growable: false);
      expect(summaries, hasLength(1));
      for (final expected in <String>[
        'repositoryReadsStartedDuringInteraction=0',
        'readyDrawableAheadPagesAtStart=',
        'readyDrawableAheadPagesMinimum=',
        'readyDrawableAheadPixelsAtStart=',
        'readyDrawableAheadPixelsMinimum=',
        'virtualRemainingPixelsAtStart=',
        'virtualRemainingPixelsMinimum=',
        'firstVisibleOrdinalAtStart=',
        'lastVisibleOrdinalAtStart=',
        'highestReadyOrdinalAtStart=',
        'visibleMissingPageCountAtStart=0',
        'firstVisibleMissingOrdinalAtStart=none',
        'deferredPresentationOrdinalAtStart=none',
        'visibleMissingPageCountAtEnd=0',
        'firstVisibleMissingOrdinalAtEnd=none',
        'deferredPresentationOrdinalAtEnd=none',
        'contentDimensionChangeCount=',
        'verticalCacheMissCount=0',
        'verticalRootNotDrawableCount=0',
      ]) {
        expect(summaries.single.message, contains(expected));
      }
      expect(summaries.single.message, isNot(contains('preparedAheadPixels=')));
      expect(summaries.single.message, contains('virtualPageMissCount=0'));
      expect(
        summaries.single.message,
        contains('virtualGeometryMismatchCount=0'),
      );
    },
  );

  testWidgets(
    'RED: interaction diagnostics keep preparation, pointer, and ballistic scopes explicit',
    (tester) async {
      FluviDiagnosticLogger.clear();
      var clock = 0;
      final fixture = await _readyFixture(
        tester,
        totalRows: 94,
        cache: CommittedLogViewportCache(
          pageSize: 24,
          pagePreparationPolicy: CommittedPagePreparationPolicy(
            contiguousUiBudgetMicros: 1000000,
            nowMicros: () => ++clock,
          ),
        ),
      );
      addTearDown(fixture.dispose);
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );

      await tester.fling(scrollView, const Offset(0, -120), 5000);
      await tester.pumpAndSettle();

      final summary = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'VERTICAL_INTERACTION_PERF_SUMMARY')
          .single;
      final input = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'VERTICAL_INPUT_SAMPLE_SUMMARY')
          .single;
      final release = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'VERTICAL_DRAG_RELEASED')
          .single;
      final sessionStarted = FluviDiagnosticLogger.entries
          .where(
            (event) => event.stage == 'VERTICAL_INTERACTION_SESSION_STARTED',
          )
          .single;

      expect(summary.message, contains('pagePreparationUiMicros=0'));
      expect(
        summary.message,
        contains('largestPagePreparationUiSliceMicrosDuringInteraction=0'),
      );
      expect(
        summary.message,
        contains('largestPagePreparationUiSliceMicrosForCommittedScope='),
      );
      expect(input.message, contains('pointerInputDurationMs='));
      expect(input.message, contains('interactionDurationMs='));
      expect(input.message, isNot(contains('eventDurationMs=')));
      expect(input.message, contains('rawReleaseVelocity='));
      expect(input.message, contains('appliedBallisticVelocity='));
      expect(release.message, contains('appliedBallisticVelocity='));
      expect(
        sessionStarted.message,
        contains('pointerDownToInteractionStartMicros='),
      );
      expect(
        sessionStarted.message,
        contains('pagePreparationUiMicrosAfterPointerDown='),
      );
    },
  );

  testWidgets(
    'RED: a no-scroll pointer summary cannot inherit an older ballistic velocity',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final fixture = await _readyFixture(tester, totalRows: 94);
      addTearDown(fixture.dispose);
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );

      await tester.fling(scrollView, const Offset(0, -120), 5000);
      await tester.pumpAndSettle();
      expect(
        FluviDiagnosticLogger.entries.any(
          (event) =>
              event.stage == 'VERTICAL_DRAG_RELEASED' &&
              !(event.message?.contains('appliedBallisticVelocity=0') ?? true),
        ),
        isTrue,
      );

      final replacement = _frame(
        totalRows: 94,
        scope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: const AllTimeScope(),
          categoryIds: const <String>{'replacement'},
        ),
        coreRevision: 2,
        presentationEpoch: 2,
      );
      fixture.store.publish(replacement);
      await tester.pump();
      FluviDiagnosticLogger.clear();

      final pointer = await tester.startGesture(tester.getCenter(scrollView));
      await pointer.up();
      await tester.pump();

      final summary = FluviDiagnosticLogger.entries.singleWhere(
        (event) => event.stage == 'VERTICAL_INPUT_SAMPLE_SUMMARY',
      );
      expect(summary.message, contains('interactionGeneration=none'));
      expect(summary.message, contains('rawReleaseVelocity=unavailable'));
      expect(summary.message, contains('appliedBallisticVelocity=unavailable'));
      expect(
        summary.message,
        contains('ballisticSuppressionReason=noFormalVerticalInteraction'),
      );
    },
  );

  testWidgets(
    'a boundary-suppressed framework handoff has one no-ballistic terminal classification',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final fixture = await _readyFixture(tester, totalRows: 94);
      addTearDown(fixture.dispose);
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );

      // This outward fling begins at the min boundary. Framework physics is
      // still the authority; the viewport may only report its final outcome.
      await tester.fling(scrollView, const Offset(0, 160), 5000);
      await tester.pumpAndSettle();

      final ended = FluviDiagnosticLogger.entries
          .where(
            (event) => event.stage == 'VERTICAL_DRAG_ENDED_WITHOUT_BALLISTIC',
          )
          .toList(growable: false);
      final releases = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'VERTICAL_DRAG_RELEASED')
          .toList(growable: false);
      expect(ended, hasLength(1));
      expect(ended.single.message, contains('ballisticSuppressionReason='));
      expect(releases, isEmpty);
    },
  );

  testWidgets(
    'page resource commits do not change full virtual extent or restart ballistic metrics',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final fixture = await _readyFixture(
        tester,
        totalRows: 192,
        cache: CommittedLogViewportCache(
          pageSize: 24,
          pagePreparationPolicy: const CommittedPagePreparationPolicy(
            // This test isolates geometry notifications. The separate cache
            // test exercises resumable yielding with an injected clock.
            contiguousUiBudgetMicros: 1000000,
          ),
        ),
      );
      addTearDown(fixture.dispose);
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );

      await tester.fling(scrollView, const Offset(0, -180), 5000);
      await tester.pump(const Duration(milliseconds: 16));
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      final extentBefore = fixture.cache.contentHeight;
      final maxBefore = position.maxScrollExtent;
      final geometryGeneration = fixture.cache.geometryGeneration;

      expect(
        await fixture.cache.prepareAndCommit(
          _page(fixture.store.value!, ordinal: 6, totalRows: 192),
          canPublish: () => true,
        ),
        isTrue,
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(fixture.cache.contentHeight, extentBefore);
      expect(fixture.cache.geometryGeneration, geometryGeneration);
      expect(position.maxScrollExtent, maxBefore);

      await tester.pumpAndSettle();
      final summary = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'VERTICAL_INTERACTION_PERF_SUMMARY')
          .single;
      expect(summary.message, contains('contentDimensionChangeCount=0'));
      expect(summary.message, contains('goBallisticInvocationCount=1'));
    },
  );

  testWidgets(
    'RED: a row-height geometry generation keeps the same logical page anchor and scroll owner',
    (tester) async {
      final fixture = await _readyFixture(tester, totalRows: 192);
      addTearDown(fixture.dispose);
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      final position = scrollable.position;
      final controller = scrollable.widget.controller;
      final oldManifest = fixture.cache.geometryManifest!;
      const ordinal = 3;
      final oldPage = oldManifest.pageForOrdinal(ordinal)!;
      const localFraction = .4;
      position.jumpTo(oldPage.top + oldPage.extent * localFraction);
      await tester.pump();

      final nextManifest = CommittedVerticalGeometryManifest.compile(
        queryKey: oldManifest.queryKey,
        coreRevision: oldManifest.coreRevision,
        pageSize: oldManifest.pageSize,
        totalEntryCount: oldManifest.totalEntryCount,
        dayBuckets: oldManifest.dayBuckets,
        layoutProfile: const DashboardLogBoxLayoutProfile(
          DashboardLogBoxHeight.one,
        ),
      );
      expect(fixture.cache.replaceGeometryManifest(nextManifest), isTrue);
      await tester.pump();

      final after = tester.state<ScrollableState>(find.byType(Scrollable));
      final nextPage = nextManifest.pageForOrdinal(ordinal)!;
      expect(identical(after.position, position), isTrue);
      expect(identical(after.widget.controller, controller), isTrue);
      expect(
        after.position.pixels,
        closeTo(nextPage.top + nextPage.extent * localFraction, 1),
      );
      expect(
        after.position.pixels,
        inInclusiveRange(
          after.position.minScrollExtent,
          after.position.maxScrollExtent,
        ),
      );
      expect(controller!.positions, hasLength(1));
    },
  );

  testWidgets(
    'deferred exact-page presentation during ballistic preserves scroll identities and geometry',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      final cache = CommittedLogViewportCache(
        pageSize: 24,
        pagePreparationPolicy: const CommittedPagePreparationPolicy(
          contiguousUiBudgetMicros: 1000000,
        ),
      );
      final railScenes = DashboardLogBoxPreparedSceneCache();
      final repository = _ImmediateRepository(
        totalRows: 67,
        holdPageReads: true,
      );
      var pointerIntentActive = false;
      var verticalInteractionActive = false;
      final paging = ExplicitCommittedPagingController(
        repository: repository,
        visibleFrames: store,
        committedViewport: cache,
        pageSize: 24,
        isVerticalPointerIntentActive: () => pointerIntentActive,
        isVerticalInteractionActive: () => verticalInteractionActive,
        canRunBackgroundPrewarm: () =>
            !pointerIntentActive && !verticalInteractionActive,
      );
      addTearDown(paging.dispose);
      addTearDown(store.dispose);
      addTearDown(cache.dispose);
      addTearDown(railScenes.dispose);
      final frame = _frame(totalRows: 67);
      store.publish(frame);
      paging.commitMetadata(frame, geometryManifest: _manifest(frame));
      cache.configureSurfaceWidth(378);
      await _prepareRailScene(railScenes, frame);
      expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);

      await tester.pumpWidget(
        _viewport(
          store: store,
          cache: cache,
          railScenes: railScenes,
          onLoadNextPage: (_) {},
        ),
      );
      await tester.pump();
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      final position = scrollable.position;
      final scrollController = scrollable.widget.controller;
      final physics = position.physics;
      final virtualExtent = cache.contentHeight;
      final maxScrollExtent = position.maxScrollExtent;
      final geometryGeneration = cache.geometryGeneration;

      final readyAhead = paging.requestForwardDemand(2);
      await tester.pump();
      expect(repository.requestedOrdinals, <int>[1]);
      pointerIntentActive = true;
      verticalInteractionActive = true;
      repository.completeNextHeldRead();
      expect(await readyAhead, isFalse);
      expect(paging.committedPageDataPendingPresentation, isTrue);

      pointerIntentActive = false;
      expect(
        await paging.resumeDeferredPagePresentation(reason: 'pointerReleased'),
        isTrue,
      );
      await tester.pump();

      final after = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(verticalInteractionActive, isTrue);
      expect(cache.pageForOrdinal(1), isNotNull);
      expect(repository.requestedOrdinals, <int>[1]);
      expect(identical(after, scrollable), isTrue);
      expect(identical(after.position, position), isTrue);
      expect(identical(after.widget.controller, scrollController), isTrue);
      expect(identical(after.position.physics, physics), isTrue);
      expect(cache.contentHeight, virtualExtent);
      expect(cache.geometryGeneration, geometryGeneration);
      expect(after.position.maxScrollExtent, maxScrollExtent);
    },
  );

  testWidgets(
    'only a signed backward update asks for an immediate reverse page',
    (tester) async {
      const totalRows = 240;
      final store = DashboardVisibleFrameStore();
      final cache = CommittedLogViewportCache(pageSize: 24);
      final railScenes = DashboardLogBoxPreparedSceneCache();
      addTearDown(store.dispose);
      addTearDown(cache.dispose);
      addTearDown(railScenes.dispose);
      final frame = _frame(totalRows: totalRows);
      store.publish(frame);
      cache.seed(
        _rootPage(frame),
        generation: 1,
        geometryManifest: _manifest(frame),
      );
      cache.configureSurfaceWidth(378);
      cache.updateForwardDemand(7, trigger: 'test');
      for (var ordinal = 1; ordinal <= 7; ordinal += 1) {
        cache.updateVisibleRowWindow(
          start: ordinal * cache.pageSize,
          end: (ordinal + 1) * cache.pageSize,
        );
        expect(
          cache.commit(_page(frame, ordinal: ordinal, totalRows: totalRows)),
          isTrue,
        );
      }
      expect(cache.lowestRetainedOrdinal, greaterThan(0));
      expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);
      await _prepareRailScene(railScenes, frame);

      final reverseRequests = <int>[];
      await tester.pumpWidget(
        _viewport(
          store: store,
          cache: cache,
          railScenes: railScenes,
          onLoadNextPage: (_) {},
          onLoadPreviousPage: () => reverseRequests.add(1),
        ),
      );
      await tester.pump();
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );
      final context = tester.element(scrollView);
      final boundary = cache.lowestRetainedOrdinal;
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: cache.drawableExtent,
        pixels: cache.pageTopForOrdinal(boundary),
        viewportDimension: 420,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      );
      ScrollStartNotification(
        metrics: metrics,
        context: context,
        dragDetails: DragStartDetails(globalPosition: Offset.zero),
      ).dispatch(context);
      ScrollUpdateNotification(
        metrics: metrics,
        context: context,
        scrollDelta: 48,
      ).dispatch(context);
      await tester.pump();
      expect(reverseRequests, isEmpty);
      expect(
        cache.report()['visibleStart'],
        boundary * cache.pageSize,
        reason:
            'The header is structural chrome, so a page top is already a '
            'content-local ScrollMetrics offset.',
      );

      ScrollUpdateNotification(
        metrics: metrics,
        context: context,
        scrollDelta: -48,
      ).dispatch(context);
      await tester.pump();
      expect(reverseRequests, <int>[1]);
    },
  );
}

final class _ReadyFixture {
  _ReadyFixture({
    required this.store,
    required this.cache,
    required this.railScenes,
    required this.paging,
    required this.repository,
    required this.counters,
  });

  final DashboardVisibleFrameStore store;
  final CommittedLogViewportCache cache;
  final DashboardLogBoxPreparedSceneCache railScenes;
  final ExplicitCommittedPagingController paging;
  final _ImmediateRepository repository;
  final DashboardPerformanceCounters counters;

  void dispose() {
    paging.dispose();
    railScenes.dispose();
    cache.dispose();
    store.dispose();
  }
}

Future<_ReadyFixture> _readyFixture(
  WidgetTester tester, {
  required int totalRows,
  CommittedLogViewportCache? cache,
  DashboardLogBoxPartnerSwipeController? partnerSwipe,
  double dashboardLeft = 0,
  double screenWidth = 378,
}) async {
  final store = DashboardVisibleFrameStore();
  final committedCache =
      cache ??
      CommittedLogViewportCache(
        pageSize: 24,
        // Widget tests cover scroll metrics, not host stopwatch granularity.
        // The cache unit tests own deterministic yield/resume coverage with
        // their injected work probe.
        pagePreparationPolicy: const CommittedPagePreparationPolicy(
          contiguousUiBudgetMicros: 1000000,
        ),
      );
  final railScenes = DashboardLogBoxPreparedSceneCache();
  final repository = _ImmediateRepository(totalRows: totalRows);
  final counters = DashboardPerformanceCounters();
  var verticalInteractionActive = false;
  final paging = ExplicitCommittedPagingController(
    repository: repository,
    visibleFrames: store,
    committedViewport: committedCache,
    pageSize: 24,
    isVerticalInteractionActive: () => verticalInteractionActive,
  );
  final frame = _frame(totalRows: totalRows);
  store.publish(frame);
  paging.commitMetadata(frame, geometryManifest: _manifest(frame));
  committedCache.configureSurfaceWidth(378);
  expect(
    await paging.prepareReadyAheadAtIdle(reason: 'viewportTestIdle'),
    isTrue,
  );
  expect(committedCache.contiguousReadyRowCount, totalRows.clamp(0, 144));
  await _prepareRailScene(railScenes, frame);
  await tester.pumpWidget(
    _viewport(
      store: store,
      cache: committedCache,
      railScenes: railScenes,
      performanceCounters: counters,
      onLoadNextPage: (_) {},
      onVerticalScrollStarted: () => verticalInteractionActive = true,
      onVerticalScrollEnded: () => verticalInteractionActive = false,
      dashboardLeft: dashboardLeft,
      screenWidth: screenWidth,
      partnerSwipe: partnerSwipe,
    ),
  );
  await tester.pump();
  return _ReadyFixture(
    store: store,
    cache: committedCache,
    railScenes: railScenes,
    paging: paging,
    repository: repository,
    counters: counters,
  );
}

Widget _viewport({
  required DashboardVisibleFrameStore store,
  required CommittedLogViewportCache cache,
  required DashboardLogBoxPreparedSceneCache railScenes,
  required ValueChanged<int> onLoadNextPage,
  VoidCallback? onLoadPreviousPage,
  VoidCallback? onVerticalScrollStarted,
  VoidCallback? onVerticalScrollEnded,
  ValueChanged<int>? onVerticalPointerIntentStarted,
  void Function(int pointer, {required bool cancelled})?
  onVerticalPointerIntentEnded,
  DashboardPerformanceCounters? performanceCounters,
  CurrentQueryController? currentQuery,
  DashboardLogBoxPartnerSwipeController? partnerSwipe,
  double dashboardLeft = 0,
  double screenWidth = 378,
}) => MaterialApp(
  home: SizedBox(
    width: screenWidth,
    height: 420,
    child: Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          left: dashboardLeft,
          top: 0,
          bottom: 0,
          width: 378,
          child: DashboardLogBoxViewport(
            bounds: DashboardBounds(
              left: dashboardLeft,
              top: 28,
              width: 378,
              height: DashboardLayoutMetrics.referenceLogBoxHeaderHeight,
            ),
            visibleFrames: store,
            committedViewport: cache,
            preparedSceneCache: railScenes,
            preparedRasters: PreparedVectorAssetAtlas.instance.logBoxRastersFor(
              3,
            ),
            onLoadNextPage: onLoadNextPage,
            onLoadPreviousPage: onLoadPreviousPage,
            onVerticalScrollStarted: onVerticalScrollStarted,
            onVerticalScrollEnded: onVerticalScrollEnded,
            onVerticalPointerIntentStarted: onVerticalPointerIntentStarted,
            onVerticalPointerIntentEnded: onVerticalPointerIntentEnded,
            performanceCounters: performanceCounters,
            currentQuery: currentQuery,
            partnerSwipe: partnerSwipe,
            onRemoveQueryCategory: currentQuery == null ? null : (_) {},
            onRemoveQueryPartner: currentQuery == null ? null : (_) {},
            onClearQuery: currentQuery == null ? null : () {},
          ),
        ),
      ],
    ),
  ),
);
Future<void> _prepareRailScene(
  DashboardLogBoxPreparedSceneCache railScenes,
  DashboardVisibleFrame frame,
) async {
  final window = DashboardLogBoxSceneWindow(
    identity: 'viewport-test-${frame.queryKey.value}',
    payloads: <DashboardLogViewportState>[frame.logBox],
  );
  await railScenes.prepareWindow(window: window, surfaceWidth: 378);
  railScenes.activateWindow(window);
}

DashboardVisibleFrame _frame({
  required int totalRows,
  CurrentLedgerQueryScope? scope,
  int coreRevision = 1,
  int presentationEpoch = 1,
  int totalMinor = 1,
  String formattedAmount = '1 Ft',
}) {
  final resolvedScope =
      scope ??
      CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: MonthScope(YearMonth(year: 2026, month: 7)),
      );
  final rootRows = List<DashboardLogRowViewModel>.generate(
    totalRows.clamp(0, 24).toInt(),
    (index) => _row(index),
    growable: false,
  );
  final logBox = DashboardLogViewportState(
    queryKey: resolvedScope.key,
    revision: coreRevision,
    groups: <DashboardDayLogGroupViewModel>[
      DashboardDayLogGroupViewModel(
        dateKey: '2026-07-01',
        dayLabel: '2026. július 1.',
        rows: rootRows,
      ),
    ],
    entryCount: totalRows,
    nextCursor: totalRows > 24 ? _cursor(0) : null,
    direction: resolvedScope.direction,
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: resolvedScope,
    parentQueryKey: resolvedScope.key,
    coreRevision: coreRevision,
    totalMinor: totalMinor,
    formattedAmount: formattedAmount,
    entryCount: totalRows,
    formattedEntryCount: '$totalRows',
    logBox: logBox,
    presentationDigest: totalRows,
  );
  return DashboardVisibleFrame.fromPrepared(
    prepared,
    parentQueryKey: resolvedScope.key,
    plane: TimePlane.month,
    railOpen: false,
    semanticIndex: 0,
    childLabel: '2026. július',
    navigationEpoch: presentationEpoch,
    presentationEpoch: presentationEpoch,
    frameGeneration: presentationEpoch,
    mode: DashboardVisibleMode.committed,
  );
}

CommittedLogPage _rootPage(DashboardVisibleFrame frame) => CommittedLogPage(
  queryKey: frame.queryKey,
  coreRevision: frame.coreRevision,
  generation: 1,
  ordinal: 0,
  startCursor: null,
  previousStartCursor: null,
  payload: frame.logBox,
);

CommittedLogPage _page(
  DashboardVisibleFrame frame, {
  required int ordinal,
  required int totalRows,
}) {
  final start = ordinal * 24;
  final count = (totalRows - start).clamp(0, 24);
  final rows = List<DashboardLogRowViewModel>.generate(
    count,
    (index) => _row(start + index),
    growable: false,
  );
  return CommittedLogPage(
    queryKey: frame.queryKey,
    coreRevision: frame.coreRevision,
    generation: 1,
    ordinal: ordinal,
    startCursor: _cursor(ordinal - 1),
    previousStartCursor: ordinal < 2 ? null : _cursor(ordinal - 2),
    payload: DashboardLogViewportState(
      queryKey: frame.queryKey,
      revision: frame.coreRevision,
      groups: <DashboardDayLogGroupViewModel>[
        DashboardDayLogGroupViewModel(
          dateKey: '2026-07-01',
          dayLabel: '2026. július 1.',
          rows: rows,
        ),
      ],
      entryCount: totalRows,
      nextCursor: start + count < totalRows ? _cursor(ordinal) : null,
      direction: frame.scope.direction,
    ),
  );
}

final class _ImmediateRepository implements DashboardCommittedPageRepository {
  _ImmediateRepository({required this.totalRows, this.holdPageReads = false});

  final int totalRows;
  final bool holdPageReads;
  final List<int> requestedOrdinals = <int>[];
  final List<_HeldCommittedPageRead> _heldReads = <_HeldCommittedPageRead>[];

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) {
    requestedOrdinals.add(request.pageOrdinal);
    final page = _pageFor(request);
    if (!holdPageReads) return Future<CommittedLogPage>.value(page);
    final completion = Completer<CommittedLogPage>();
    _heldReads.add(_HeldCommittedPageRead(request, completion));
    return completion.future;
  }

  void completeNextHeldRead() {
    if (_heldReads.isEmpty) {
      throw StateError('No committed page read is being held.');
    }
    final held = _heldReads.removeAt(0);
    held.completion.complete(_pageFor(held.request));
  }

  CommittedLogPage _pageFor(DashboardCommittedPageRequest request) {
    final start = request.pageOrdinal * request.pageSize;
    final count = (totalRows - start).clamp(0, request.pageSize);
    final rows = List<DashboardLogRowViewModel>.generate(
      count,
      (index) => _row(start + index),
      growable: false,
    );
    return CommittedLogPage(
      queryKey: request.scope.key,
      coreRevision: request.coreRevision,
      generation: request.commitGeneration,
      ordinal: request.pageOrdinal,
      startCursor: request.startCursor,
      previousStartCursor: request.previousStartCursor,
      payload: DashboardLogViewportState(
        queryKey: request.scope.key,
        revision: request.coreRevision,
        groups: <DashboardDayLogGroupViewModel>[
          DashboardDayLogGroupViewModel(
            dateKey: '2026-07-01',
            dayLabel: '2026. július 1.',
            rows: rows,
          ),
        ],
        entryCount: totalRows,
        nextCursor: start + count < totalRows
            ? _cursor(request.pageOrdinal)
            : null,
        direction: request.scope.direction,
      ),
    );
  }
}

final class _HeldCommittedPageRead {
  const _HeldCommittedPageRead(this.request, this.completion);

  final DashboardCommittedPageRequest request;
  final Completer<CommittedLogPage> completion;
}

DashboardLogRowViewModel _row(int index) => DashboardLogRowViewModel(
  entryId: 'paged-$index',
  displayName: 'Partner $index',
  categoryDisplayName: 'Category',
  formattedAmount: '-1,00 Ft',
  displayTime: '12:00',
  amountStyle: LogAmountStyle.expense,
  categoryColorId: 'fallback',
  categoryIconId: 'fallback',
  semanticLabel: 'Partner $index, -1,00 Ft, kiadás, Category',
  partnerId: 'partner-$index',
  partnerDisplayName: 'Partner $index',
);

Map<String, Object?> _cursor(int ordinal) => <String, Object?>{
  'bookedLocalEpochDay': 20_000 - ordinal,
  'bookedLocalTimeMinutes': 600,
  'entryId': 'paged-${ordinal * 24 + 23}',
};

CommittedVerticalGeometryManifest _manifest(DashboardVisibleFrame frame) =>
    CommittedVerticalGeometryManifest.compile(
      queryKey: frame.queryKey,
      coreRevision: frame.coreRevision,
      pageSize: 24,
      totalEntryCount: frame.logBox.entryCount,
      dayBuckets: <CommittedVerticalGeometryDayBucket>[
        if (frame.logBox.entryCount > 0)
          CommittedVerticalGeometryDayBucket(
            bookedLocalEpochDay: 20_000,
            entryCount: frame.logBox.entryCount,
          ),
      ],
    );
