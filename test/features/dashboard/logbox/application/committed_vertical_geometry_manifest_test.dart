import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_logbox_layout_profile.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_vertical_geometry_manifest.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  final queryKey = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const AllTimeScope(),
  ).key;

  test(
    'compiles exact page geometry from daily counts across page boundaries',
    () {
      final manifest = CommittedVerticalGeometryManifest.compile(
        queryKey: queryKey,
        coreRevision: 9,
        pageSize: 24,
        totalEntryCount: 80,
        dayBuckets: const <CommittedVerticalGeometryDayBucket>[
          CommittedVerticalGeometryDayBucket(
            bookedLocalEpochDay: 30,
            entryCount: 30,
          ),
          CommittedVerticalGeometryDayBucket(
            bookedLocalEpochDay: 29,
            entryCount: 10,
          ),
          CommittedVerticalGeometryDayBucket(
            bookedLocalEpochDay: 28,
            entryCount: 40,
          ),
        ],
      );

      expect(manifest.totalPageCount, 4);
      expect(manifest.pages.map((page) => page.rowCount), <int>[24, 24, 24, 8]);
      expect(
        manifest.pages.map((page) => page.groupCount),
        <int>[1, 3, 1, 1],
        reason: 'A day spanning a page boundary contributes once per page.',
      );
      expect(manifest.pages.map((page) => page.top), <double>[
        0,
        1340,
        2740,
        4080,
      ]);
      expect(manifest.pages.map((page) => page.extent), <double>[
        1340,
        1400,
        1340,
        460,
      ]);
      expect(manifest.totalExtent, 4540);
      expect(manifest.pageOrdinalForOffset(0), 0);
      expect(manifest.pageOrdinalForOffset(2739.9), 1);
      expect(manifest.pageOrdinalForOffset(2740), 2);
      expect(manifest.pageOrdinalForOffset(999999), 3);
    },
  );

  test('keeps adjacent days separate at an exact page boundary', () {
    final manifest = CommittedVerticalGeometryManifest.compile(
      queryKey: queryKey,
      coreRevision: 9,
      pageSize: 24,
      totalEntryCount: 25,
      dayBuckets: const <CommittedVerticalGeometryDayBucket>[
        CommittedVerticalGeometryDayBucket(
          bookedLocalEpochDay: 30,
          entryCount: 24,
        ),
        CommittedVerticalGeometryDayBucket(
          bookedLocalEpochDay: 29,
          entryCount: 1,
        ),
      ],
    );

    expect(manifest.pages.map((page) => page.groupCount), <int>[1, 1]);
    expect(manifest.pages.map((page) => page.extent), <double>[1340, 75]);
    expect(manifest.totalExtent, 1415);
  });

  test('one layout profile drives row, page and terminal extent geometry', () {
    final baseline = CommittedVerticalGeometryManifest.compile(
      queryKey: queryKey,
      coreRevision: 9,
      pageSize: 24,
      totalEntryCount: 25,
      dayBuckets: const <CommittedVerticalGeometryDayBucket>[
        CommittedVerticalGeometryDayBucket(
          bookedLocalEpochDay: 30,
          entryCount: 24,
        ),
        CommittedVerticalGeometryDayBucket(
          bookedLocalEpochDay: 29,
          entryCount: 1,
        ),
      ],
    );
    final taller = CommittedVerticalGeometryManifest.compile(
      queryKey: queryKey,
      coreRevision: 9,
      pageSize: 24,
      totalEntryCount: 25,
      dayBuckets: baseline.dayBuckets,
      layoutProfile: const DashboardLogBoxLayoutProfile(
        DashboardLogBoxHeight.one,
      ),
    );

    expect(
      taller.pages.map((page) => page.rowCount),
      baseline.pages.map((page) => page.rowCount),
    );
    expect(
      taller.pages.map((page) => page.groupCount),
      baseline.pages.map((page) => page.groupCount),
    );
    expect(
      taller.layoutProfile.rowHeight,
      baseline.layoutProfile.rowHeight * 1.5,
    );
    expect(
      taller.totalExtent - baseline.totalExtent,
      closeTo(
        25 *
            (taller.layoutProfile.rowHeight - baseline.layoutProfile.rowHeight),
        .001,
      ),
    );
    expect(taller.pageForOrdinal(1)!.top, taller.pageForOrdinal(0)!.bottom);
  });

  test('represents an empty exact scope without a synthetic page', () {
    final manifest = CommittedVerticalGeometryManifest.compile(
      queryKey: queryKey,
      coreRevision: 9,
      pageSize: 24,
      totalEntryCount: 0,
      dayBuckets: const <CommittedVerticalGeometryDayBucket>[],
    );

    expect(manifest.totalPageCount, 0);
    expect(manifest.pages, isEmpty);
    expect(manifest.totalExtent, 0);
  });
}
