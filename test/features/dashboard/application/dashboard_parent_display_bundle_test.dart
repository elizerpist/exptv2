import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_parent_display_bundle.dart';
import 'package:fluvi/features/dashboard/logbox/domain/dashboard_log_models.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  final parent = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const MonthScope(YearMonth(year: 2026, month: 6)),
  );

  List<CurrentLedgerQueryScope> juneDays() =>
      List<CurrentLedgerQueryScope>.generate(
        30,
        (index) => parent.copyWith(
          timeScope: DayScope(LocalDate(year: 2026, month: 6, day: index + 1)),
        ),
      );

  DashboardParentDisplayBundle juneBundle() {
    final days = juneDays();
    return DashboardParentDisplayBundle.completeFinite(
      parentScope: parent,
      plane: TimePlane.month,
      coreRevision: 12,
      expectedChildren: days,
      snapshots: <DashboardLogPreviewSnapshot>[
        DashboardLogPreviewSnapshot.populated(
          scope: days[0],
          coreRevision: 12,
          totalMinor: 901489,
          entryCount: 1,
          groups: const [],
        ),
      ],
    );
  }

  test(
    'a June finite deck fills all absent days with explicit empty snapshots',
    () {
      final bundle = juneBundle();

      expect(bundle.isComplete, isTrue);
      expect(bundle.childDeck.snapshots, hasLength(30));
      for (final day in juneDays()) {
        expect(bundle.childDeck.snapshotFor(day), isNotNull);
      }
      final empty = bundle.childDeck.snapshotFor(juneDays()[25])!;
      expect(empty.entryCount, 0);
      expect(empty.groups, isEmpty);
      expect(empty.isExplicitEmpty, isTrue);
    },
  );

  test(
    'a pinned current finite bundle retains every child under eviction pressure',
    () {
      final current = juneBundle();
      final cache = DashboardParentDisplayBundleCache(capacity: 2);
      cache
        ..put(current)
        ..pin(current.key);

      for (final month in <int>[4, 5, 7, 8]) {
        final otherParent = parent.copyWith(
          timeScope: MonthScope(YearMonth(year: 2026, month: month)),
        );
        cache.put(
          DashboardParentDisplayBundle.completeFinite(
            parentScope: otherParent,
            plane: TimePlane.month,
            coreRevision: 12,
            expectedChildren: <CurrentLedgerQueryScope>[
              otherParent.copyWith(
                timeScope: DayScope(
                  LocalDate(year: 2026, month: month, day: 1),
                ),
              ),
            ],
            snapshots: const <DashboardLogPreviewSnapshot>[],
          ),
        );
      }

      expect(cache.lookup(current.key), same(current));
      for (var day = 1; day <= 30; day += 1) {
        final child = parent.copyWith(
          timeScope: DayScope(LocalDate(year: 2026, month: 6, day: day)),
        );
        expect(
          cache.lookup(current.key)!.childDeck.snapshotFor(child),
          isNotNull,
        );
      }
    },
  );

  test(
    'a complete current deck has zero misses in 500 cyclic preview lookups',
    () {
      final bundle = juneBundle();

      var misses = 0;
      for (var turn = 0; turn < 500; turn += 1) {
        final child = juneDays()[turn % 30];
        if (bundle.childDeck.snapshotFor(child) == null) misses += 1;
      }

      expect(misses, 0);
    },
  );

  test('content digest changes when a same-ID row changes visible data', () {
    DashboardLogPreviewSnapshot snapshotFor(String partnerDisplayName) =>
        DashboardLogPreviewSnapshot.populated(
          scope: juneDays().first,
          coreRevision: 12,
          totalMinor: 100,
          entryCount: 1,
          groups: [
            DashboardDayLogGroup(
              localDate: const LocalDate(year: 2026, month: 6, day: 1),
              rows: [
                DashboardLedgerEntry(
                  id: 'same-id',
                  partnerId: 'partner-1',
                  partnerDisplayName: partnerDisplayName,
                  categoryId: 'category-1',
                  categoryDisplayName: 'Kategória',
                  categoryColorId: 'color_01',
                  categoryIconId: 'icon_01',
                  direction: 'expense',
                  amountMinor: 100,
                  bookedLocalEpochDay: 20500,
                  bookedLocalTimeMinutes: 720,
                ),
              ],
            ),
          ],
        );

    expect(
      snapshotFor('Eredeti').contentDigest,
      isNot(snapshotFor('Megváltozott').contentDigest),
    );
  });
}
