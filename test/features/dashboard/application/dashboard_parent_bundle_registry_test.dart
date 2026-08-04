import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_parent_bundle_registry.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_parent_display_bundle.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_presentation_store.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_child_preview_bundle.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/time_child_summary.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  group('DashboardParentBundleRegistry', () {
    test(
      'reuses one complete entry for the same semantic key and revision',
      () {
        final entry = _entry(month: 6, revision: 7);
        final counters = DashboardPerformanceCounters();
        final registry = DashboardParentBundleRegistry(
          performanceCounters: counters,
        );

        expect(registry.put(entry), isTrue);

        final lookup = registry.lookup(entry.key, expectedRevision: 7);
        expect(lookup.entry, same(entry));
        expect(lookup.cacheHit, isTrue);
        expect(lookup.missReason, DashboardParentBundleMissReason.none);
        expect(registry.hitCount, 1);
        expect(registry.missCount, 0);
        expect(
          counters.value(DashboardPerformanceMetric.parentBundleLookup),
          1,
        );
        expect(counters.value(DashboardPerformanceMetric.parentBundleHit), 1);
        expect(counters.value(DashboardPerformanceMetric.parentBundleMiss), 0);
        final childKey = entry
            .displayBundle
            .childPreviewBundle!
            .childrenByQueryKey
            .keys
            .single;
        expect(entry.childLogViewports[childKey], isNotNull);
        expect(
          entry.childLogViewports[childKey]!.groups
              .expand((group) => group.rows)
              .length,
          entry
              .displayBundle
              .childPreviewBundle![childKey]!
              .result
              .entries
              .length,
        );
      },
    );

    test('keeps an explicit zero child as a cache hit', () {
      final entry = _entry(
        month: 8,
        revision: 3,
        parentAmount: 0,
        parentCount: 0,
        childAmount: 0,
        childCount: 0,
      );
      final registry = DashboardParentBundleRegistry()..put(entry);

      final lookup = registry.lookup(entry.key, expectedRevision: 3);
      final child = lookup.entry!.childSummaryIndex.values['2026-08-01'];

      expect(lookup.cacheHit, isTrue);
      expect(child, isNotNull);
      expect(child!.totalMinor, 0);
      expect(child.entryCount, 0);
    });

    test('reports revision mismatch without returning stale content', () {
      final entry = _entry(month: 6, revision: 7);
      final registry = DashboardParentBundleRegistry()..put(entry);

      final lookup = registry.lookup(entry.key, expectedRevision: 8);

      expect(lookup.entry, isNull);
      expect(lookup.cacheHit, isFalse);
      expect(
        lookup.missReason,
        DashboardParentBundleMissReason.revisionMismatch,
      );
      expect(lookup.storedRevision, 7);
    });

    test('accepts a newer complete entry than the displayed revision', () {
      final entry = _entry(month: 6, revision: 8);
      final registry = DashboardParentBundleRegistry()..put(entry);

      final lookup = registry.lookup(entry.key, expectedRevision: 7);

      expect(lookup.entry, same(entry));
      expect(lookup.cacheHit, isTrue);
      expect(lookup.missReason, DashboardParentBundleMissReason.none);
    });

    test('a late older bundle cannot overwrite a newer complete entry', () {
      final newer = _entry(month: 6, revision: 8);
      final older = _entry(month: 6, revision: 7);
      final registry = DashboardParentBundleRegistry();

      expect(registry.put(newer, pinCurrent: true), isTrue);
      expect(registry.put(older, pinCurrent: true), isFalse);

      final lookup = registry.lookup(newer.key, expectedRevision: 8);
      expect(lookup.entry, same(newer));
      expect(lookup.storedRevision, 8);
    });

    test('marked-stale entry cannot serve presentation', () {
      final entry = _entry(month: 6, revision: 7);
      final registry = DashboardParentBundleRegistry()..put(entry);

      expect(registry.markStale(entry.key), isTrue);
      final lookup = registry.lookup(entry.key, expectedRevision: 7);

      expect(lookup.entry, isNull);
      expect(lookup.missReason, DashboardParentBundleMissReason.stale);
    });

    test(
      'current parent remains pinned while adjacent entries are evicted',
      () {
        final june = _entry(month: 6, revision: 1);
        final july = _entry(month: 7, revision: 1);
        final august = _entry(month: 8, revision: 1);
        final registry = DashboardParentBundleRegistry(
          adjacentCapacity: 1,
          maxAdjacentBytes: july.estimatedBytes + august.estimatedBytes,
        );

        registry.put(june, pinCurrent: true);
        registry.put(july);
        registry.put(august);

        expect(
          registry.lookup(june.key, expectedRevision: 1).entry,
          same(june),
        );
        expect(
          registry.lookup(july.key).missReason,
          DashboardParentBundleMissReason.absent,
        );
        expect(registry.lookup(august.key).entry, same(august));
        expect(registry.pinnedKey, june.key);
        expect(registry.evictionCount, 1);
      },
    );

    test('adjacent entries obey the configured byte budget', () {
      final july = _entry(month: 7, revision: 1);
      final august = _entry(month: 8, revision: 1);
      final registry = DashboardParentBundleRegistry(
        adjacentCapacity: 4,
        maxAdjacentBytes: august.estimatedBytes,
      );

      registry.put(july);
      registry.put(august);

      expect(
        registry.adjacentEstimatedBytes,
        lessThanOrEqualTo(august.estimatedBytes),
      );
      expect(registry.lookup(july.key).cacheHit, isFalse);
      expect(registry.lookup(august.key).entry, same(august));
    });

    test(
      'semantic key distinguishes direction, filters, child kind and budget',
      () {
        final base = _scope(month: 6);
        final income = _scope(month: 6, direction: LedgerDirection.income);
        final filtered = _scope(month: 6, categoryIds: const <String>{'food'});

        final baseKey = DashboardParentBundleKey(
          parentQueryKey: base.key,
          childPeriod: TimeChildPeriod.day,
          previewPageSize: 24,
        );

        expect(
          baseKey,
          isNot(
            DashboardParentBundleKey(
              parentQueryKey: income.key,
              childPeriod: TimeChildPeriod.day,
              previewPageSize: 24,
            ),
          ),
        );
        expect(
          baseKey,
          isNot(
            DashboardParentBundleKey(
              parentQueryKey: filtered.key,
              childPeriod: TimeChildPeriod.day,
              previewPageSize: 24,
            ),
          ),
        );
        expect(
          baseKey,
          isNot(
            DashboardParentBundleKey(
              parentQueryKey: base.key,
              childPeriod: TimeChildPeriod.month,
              previewPageSize: 24,
            ),
          ),
        );
        expect(
          baseKey,
          isNot(
            DashboardParentBundleKey(
              parentQueryKey: base.key,
              childPeriod: TimeChildPeriod.day,
              previewPageSize: 12,
            ),
          ),
        );
      },
    );
  });
}

DashboardParentBundleEntry _entry({
  required int month,
  required int revision,
  int parentAmount = 1200,
  int parentCount = 4,
  int childAmount = 300,
  int childCount = 1,
}) {
  final parent = _scope(month: month);
  final yearMonth = YearMonth(year: 2026, month: month);
  final child = parent.copyWith(timeScope: DayScope(yearMonth.clampDay(1)));
  final childResult = DashboardLedgerResult(
    totalMinor: childAmount,
    entryCount: childCount,
    coreRevision: revision,
    scopeKey: child.key.value,
    direction: parent.direction.name,
  );
  final childBundle = DashboardChildPreviewBundle(
    parentScope: parent,
    childPeriod: TimeChildPeriod.day,
    coreRevision: revision,
    childrenByQueryKey: <LedgerQueryKey, DashboardChildPreview>{
      child.key: DashboardChildPreview(
        childPeriodValue: '${yearMonth.isoString}-01',
        scope: child,
        result: childResult,
      ),
    },
  );
  final parentSnapshot = DashboardPresentationSnapshot.fromResult(
    scope: parent,
    generation: 1,
    result: DashboardLedgerResult(
      totalMinor: parentAmount,
      entryCount: parentCount,
      coreRevision: revision,
      scopeKey: parent.key.value,
      direction: parent.direction.name,
    ),
  );
  return DashboardParentBundleEntry.fromDisplayBundle(
    DashboardParentDisplayBundle(
      parentSnapshot: parentSnapshot,
      childPreviewBundle: childBundle,
    ),
  );
}

CurrentLedgerQueryScope _scope({
  required int month,
  LedgerDirection direction = LedgerDirection.expense,
  Set<String> categoryIds = const <String>{},
}) => CurrentLedgerQueryScope(
  direction: direction,
  timeScope: MonthScope(YearMonth(year: 2026, month: month)),
  categoryIds: categoryIds,
);
