import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_vertical_geometry_manifest.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_view_models.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/dashboard_directional_query_set.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/dashboard_ephemeral_focus_deriver.dart';
import 'package:fluvi/features/dashboard/runtime/domain/dashboard_focus_membership_seed.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  test(
    'RED: prepared focus critical projection does not build a semantic zero universe',
    () {
      final source = File(
        'lib/features/dashboard/runtime/domain/'
        'dashboard_ephemeral_focus_deriver.dart',
      ).readAsStringSync();
      final deriveFast = source.substring(
        source.indexOf(
          '  static DashboardEphemeralFocusDerivation deriveFast(',
        ),
        source.indexOf('/// Observable accounting for one prepared focus'),
      );

      expect(
        deriveFast,
        isNot(contains('PreparedDashboardIndexAssembly.zeroUniverse(')),
        reason:
            'A prepared membership hit must derive only the current root; a '
            '2014–2038 catalog build is not publication-critical work.',
      );
      expect(deriveFast, contains('currentRootProjectionMicros'));
      expect(deriveFast, contains('semanticUniverseBuildMicros'));
    },
  );

  test(
    'RED: derives a focused immutable presentation from base membership without mutating the base query',
    () {
      final base = _baseIndex();
      final baseScope = base.key.hasDirectionalFilters
          ? CurrentLedgerQueryScope(
              direction: LedgerDirection.income,
              timeScope: const AllTimeScope(),
              categoryIds: const <String>{'food', 'utilities'},
            )
          : throw StateError('Fixture must be directional.');
      final focusScope = baseScope.copyWith(
        categoryIds: const <String>{'utilities'},
      );
      final focusedQueries = DashboardDirectionalQuerySet(
        income: focusScope,
        expense: base.key.hasDirectionalFilters
            ? CurrentLedgerQueryScope(
                direction: LedgerDirection.expense,
                timeScope: const AllTimeScope(),
              )
            : throw StateError('Fixture must be directional.'),
      );

      final focused = DashboardEphemeralFocusDeriver.derive(
        base: base,
        effectiveQueries: focusedQueries,
        focusedDirection: LedgerDirection.income,
        categoryFocusId: 'utilities',
        partnerFocusId: null,
        initialYear: 2026,
        generation: 9,
      );

      final frame = focused.frameFor(focusScope);
      expect(frame.entryCount, 2);
      expect(frame.amount.totalMinor, 500);
      frame.logBox.materializeRichProjection();
      expect(frame.logBox.groups.expand((group) => group.rows), hasLength(2));
      expect(
        focused.committedVerticalGeometryFor(focusScope).totalEntryCount,
        2,
      );
      expect(base.frameFor(baseScope).entryCount, 3);
      expect(baseScope.categoryIds, const <String>{'food', 'utilities'});
      expect(focused.key.matchesScope(focusScope), isTrue);
    },
  );

  test(
    'derives the intersection of independent category and partner focus',
    () {
      final base = _baseIndex();
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'utilities'},
        partnerIds: const <String>{'partner-a'},
      );
      final focused = DashboardEphemeralFocusDeriver.derive(
        base: base,
        effectiveQueries: DashboardDirectionalQuerySet(
          income: scope,
          expense: CurrentLedgerQueryScope(
            direction: LedgerDirection.expense,
            timeScope: const AllTimeScope(),
          ),
        ),
        focusedDirection: LedgerDirection.income,
        categoryFocusId: 'utilities',
        partnerFocusId: 'partner-a',
        initialYear: 2026,
        generation: 10,
      );

      final frame = focused.frameFor(scope);
      expect(frame.entryCount, 1);
      frame.logBox.materializeRichProjection();
      expect(frame.logBox.groups.single.rows.single.entryId, 'u-a');
    },
  );

  test(
    'prepared membership fast path selects compact ordinals without worker or base scan',
    () {
      final base = _baseIndex();
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'utilities'},
      );
      final derived = DashboardEphemeralFocusDeriver.deriveFast(
        base: base,
        effectiveQueries: DashboardDirectionalQuerySet(
          income: scope,
          expense: CurrentLedgerQueryScope(
            direction: LedgerDirection.expense,
            timeScope: const AllTimeScope(),
          ),
        ),
        focusedDirection: LedgerDirection.income,
        categoryFocusId: 'utilities',
        partnerFocusId: null,
        initialYear: 2026,
        generation: 11,
      );

      expect(derived.membershipOrdinalCount, 2);
      expect(DashboardEphemeralFocusDerivation.workerDispatched, 0);
      expect(DashboardEphemeralFocusDerivation.fullBaseRowsScanned, 0);
      expect(DashboardEphemeralFocusDerivation.copiedPreparedRows, 0);
      expect(derived.index.frameFor(scope).entryCount, 2);
    },
  );

  test(
    'prepared focus materializes only its current root and lazily resolves a later temporal frame',
    () {
      final base = _baseIndex();
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'utilities'},
      );
      final derived = DashboardEphemeralFocusDeriver.deriveFast(
        base: base,
        effectiveQueries: DashboardDirectionalQuerySet(
          income: scope,
          expense: CurrentLedgerQueryScope(
            direction: LedgerDirection.expense,
            timeScope: const AllTimeScope(),
          ),
        ),
        focusedDirection: LedgerDirection.income,
        categoryFocusId: 'utilities',
        partnerFocusId: null,
        initialYear: 2026,
        generation: 13,
      );

      final overlay = derived.index.focusedTemporalOverlay!;
      expect(derived.semanticUniverseBuildMicros, 0);
      expect(derived.publicationCriticalFrameCount, 1);
      expect(overlay.materializedFrameCount, 1);
      final laterScope = derived.index.catalogFor(scope).entries.first.scope;

      final later = derived.index.frameFor(laterScope);

      expect(later.scope, laterScope);
      expect(overlay.materializedFrameCount, 2);
      expect(
        overlay.materializedFrameCount,
        lessThan(base.frames.length + base.compactZeroFrames.length),
        reason:
            'A focused rail request may memoize its exact next scope, never '
            'construct the full base temporal universe again.',
      );
    },
  );

  test(
    'focused derivation retains the untouched directional partition by identity',
    () {
      final base = _baseIndex();
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'utilities'},
      );

      final derived = DashboardEphemeralFocusDeriver.deriveFast(
        base: base,
        effectiveQueries: DashboardDirectionalQuerySet(
          income: scope,
          expense: CurrentLedgerQueryScope(
            direction: LedgerDirection.expense,
            timeScope: const AllTimeScope(),
          ),
        ),
        focusedDirection: LedgerDirection.income,
        categoryFocusId: 'utilities',
        partnerFocusId: null,
        initialYear: 2026,
        generation: 12,
      );

      expect(
        derived.index.partitionFor(LedgerDirection.expense),
        same(base.partitionFor(LedgerDirection.expense)),
        reason:
            'A category focus may replace its own directional view but may '
            'not copy/materialize the untouched opposite universe.',
      );
    },
  );
}

PreparedDashboardIndex _baseIndex() {
  final income = CurrentLedgerQueryScope(
    direction: LedgerDirection.income,
    timeScope: const AllTimeScope(),
    categoryIds: const <String>{'food', 'utilities'},
  );
  final expense = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const AllTimeScope(),
  );
  final queries = DashboardDirectionalQuerySet(
    income: income,
    expense: expense,
  );
  final key = PreparedDashboardIndexKey.fromDirectionalQuerySet(
    queries: queries,
    coreRevision: 3,
    pageSize: 24,
    yearWindowStart: 2025,
    yearWindowEndInclusive: 2027,
  );
  final universe = PreparedDashboardIndexAssembly.zeroUniverse(
    key: key,
    directionalQueries: queries,
    initialYear: 2026,
  );
  final rows = <DashboardLedgerEntry>[
    _row('u-a', 'utilities', 'partner-a', 300, 20500),
    _row('f-a', 'food', 'partner-a', 200, 20499),
    _row('u-b', 'utilities', 'partner-b', 200, 20499),
  ];
  final logBox = DashboardLogViewModelProjector.presentPreparedOrdered(
    scope: income,
    revision: 3,
    entries: rows,
    entryCount: rows.length,
    nextCursor: null,
  );
  final frame = DashboardPreparedFrame.complete(
    scope: income,
    parentQueryKey: dashboardPreparedParentQueryKey(income),
    coreRevision: 3,
    totalMinor: 700,
    formattedAmount: '700 Ft',
    entryCount: rows.length,
    formattedEntryCount: '${rows.length}',
    logBox: logBox,
    presentationDigest: 1,
  );
  return PreparedDashboardIndex.complete(
    key: key,
    frames: <LedgerQueryKey, DashboardPreparedFrame>{income.key: frame},
    catalogs: universe.catalogs,
    scopes: universe.scopes,
    geometrySeedsByDirection:
        <LedgerDirection, List<CommittedVerticalGeometryDayBucket>>{
          LedgerDirection.income: const <CommittedVerticalGeometryDayBucket>[
            CommittedVerticalGeometryDayBucket(
              bookedLocalEpochDay: 20500,
              entryCount: 1,
            ),
            CommittedVerticalGeometryDayBucket(
              bookedLocalEpochDay: 20499,
              entryCount: 2,
            ),
          ],
        },
    focusMembershipSeedsByDirection:
        <LedgerDirection, DashboardFocusMembershipSeed>{
          LedgerDirection.income: DashboardFocusMembershipSeed(rows),
        },
    generation: 1,
    contentDigest: 1,
    preparedAt: DateTime.utc(2026, 8, 15),
    buildMetrics: const PreparedDashboardIndexBuildMetrics.synthetic(),
  );
}

DashboardLedgerEntry _row(
  String id,
  String category,
  String partner,
  int amount,
  int day,
) => DashboardLedgerEntry(
  id: id,
  partnerId: partner,
  categoryId: category,
  direction: LedgerDirection.income.name,
  amountMinor: amount,
  bookedLocalEpochDay: day,
  bookedLocalTimeMinutes: 600,
  partnerDisplayName: partner,
  categoryDisplayName: category,
  categoryColorId: 'fallback',
  categoryIconId: 'fallback',
);
