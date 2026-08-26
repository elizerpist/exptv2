import 'package:flutter/foundation.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/dashboard_logbox_layout_profile.dart';
import '../../query/domain/current_ledger_query_scope.dart';

/// Compact, UI-neutral aggregate for one exact filtered ledger day.
///
/// The prepared-index transport owns these records. They deliberately exclude
/// transaction payload, labels and paragraph resources: an immutable manifest
/// needs only the cardinality of each day to determine exact LogBox geometry.
@immutable
final class CommittedVerticalGeometryDayBucket {
  const CommittedVerticalGeometryDayBucket({
    required this.bookedLocalEpochDay,
    required this.entryCount,
  }) : assert(entryCount > 0);

  final int bookedLocalEpochDay;
  final int entryCount;

  @override
  bool operator ==(Object other) =>
      other is CommittedVerticalGeometryDayBucket &&
      other.bookedLocalEpochDay == bookedLocalEpochDay &&
      other.entryCount == entryCount;

  @override
  int get hashCode => Object.hash(bookedLocalEpochDay, entryCount);
}

/// Exact immutable metadata for one logical committed page.
///
/// It contains no row values or text resources. [top], [extent] and [bottom]
/// remain stable for the full lifetime of the exact committed scope.
@immutable
final class CommittedVerticalPageGeometry {
  const CommittedVerticalPageGeometry({
    required this.ordinal,
    required this.rowStart,
    required this.rowCount,
    required this.groupCount,
    required this.top,
    required this.extent,
  }) : assert(ordinal >= 0),
       assert(rowStart >= 0),
       assert(rowCount > 0),
       assert(groupCount > 0),
       assert(top >= 0),
       assert(extent > 0);

  final int ordinal;
  final int rowStart;
  final int rowCount;
  final int groupCount;
  final double top;
  final double extent;

  double get bottom => top + extent;
}

/// Immutable full-world geometry for one exact committed vertical scope.
///
/// The manifest is compiled from daily counts before the committed vertical
/// surface becomes authoritative. It is intentionally unrelated to which
/// page payloads or TextPainters are currently retained, so a page resource
/// commit cannot mutate Flutter scroll metrics.
@immutable
final class CommittedVerticalGeometryManifest {
  CommittedVerticalGeometryManifest._({
    required this.queryKey,
    required this.coreRevision,
    required this.pageSize,
    required this.totalEntryCount,
    required this.layoutProfile,
    required List<CommittedVerticalGeometryDayBucket> dayBuckets,
    required List<CommittedVerticalPageGeometry> pages,
  }) : dayBuckets = List<CommittedVerticalGeometryDayBucket>.unmodifiable(
         dayBuckets,
       ),
       pages = List<CommittedVerticalPageGeometry>.unmodifiable(pages),
       totalExtent = pages.isEmpty ? 0 : pages.last.bottom {
    if (coreRevision <= 0 || pageSize <= 0 || totalEntryCount < 0) {
      throw ArgumentError('Committed vertical manifest identity is invalid.');
    }
    if (pages.isEmpty != (totalEntryCount == 0)) {
      throw ArgumentError(
        'Committed vertical manifest page coverage is invalid.',
      );
    }
    if (pages.fold<int>(0, (sum, page) => sum + page.rowCount) !=
        totalEntryCount) {
      throw ArgumentError(
        'Committed vertical manifest row coverage is invalid.',
      );
    }
  }

  /// Compiles exact page-local day-group geometry from a newest-to-oldest
  /// aggregate seed. A day spanning several pages is intentionally a group in
  /// each affected page because committed payload pages are independently
  /// grouped and painted.
  factory CommittedVerticalGeometryManifest.compile({
    required LedgerQueryKey queryKey,
    required int coreRevision,
    required int pageSize,
    required int totalEntryCount,
    required List<CommittedVerticalGeometryDayBucket> dayBuckets,
    DashboardLogBoxLayoutProfile layoutProfile =
        DashboardLogBoxLayoutProfile.baseline,
  }) {
    if (coreRevision <= 0 || pageSize <= 0 || totalEntryCount < 0) {
      throw ArgumentError('Committed vertical manifest input is invalid.');
    }
    var previousDay = 1 << 62;
    var countedRows = 0;
    for (final bucket in dayBuckets) {
      if (bucket.entryCount <= 0 || bucket.bookedLocalEpochDay >= previousDay) {
        throw ArgumentError(
          'Geometry day buckets must be nonempty and strictly newest-first.',
        );
      }
      previousDay = bucket.bookedLocalEpochDay;
      countedRows += bucket.entryCount;
    }
    if (countedRows != totalEntryCount) {
      throw ArgumentError(
        'Geometry seed rows ($countedRows) do not match committed total '
        '($totalEntryCount).',
      );
    }

    final pages = <CommittedVerticalPageGeometry>[];
    var pageRows = 0;
    var pageGroups = 0;
    var rowStart = 0;
    var top = 0.0;

    void finishPage() {
      if (pageRows == 0) return;
      final extent = _pageExtent(
        pageRows,
        pageGroups,
        rowHeight: layoutProfile.rowHeight,
      );
      pages.add(
        CommittedVerticalPageGeometry(
          ordinal: pages.length,
          rowStart: rowStart,
          rowCount: pageRows,
          groupCount: pageGroups,
          top: top,
          extent: extent,
        ),
      );
      rowStart += pageRows;
      top += extent;
      pageRows = 0;
      pageGroups = 0;
    }

    for (final bucket in dayBuckets) {
      var remainingForDay = bucket.entryCount;
      while (remainingForDay > 0) {
        if (pageRows == pageSize) finishPage();
        final available = pageSize - pageRows;
        final taken = remainingForDay < available ? remainingForDay : available;
        // Every nonempty slice of a daily bucket is one page-local group.
        pageGroups += 1;
        pageRows += taken;
        remainingForDay -= taken;
        if (pageRows == pageSize) finishPage();
      }
    }
    finishPage();

    return CommittedVerticalGeometryManifest._(
      queryKey: queryKey,
      coreRevision: coreRevision,
      pageSize: pageSize,
      totalEntryCount: totalEntryCount,
      layoutProfile: layoutProfile,
      dayBuckets: dayBuckets,
      pages: pages,
    );
  }

  final LedgerQueryKey queryKey;
  final int coreRevision;
  final int pageSize;
  final int totalEntryCount;
  final DashboardLogBoxLayoutProfile layoutProfile;
  final List<CommittedVerticalGeometryDayBucket> dayBuckets;
  final List<CommittedVerticalPageGeometry> pages;
  final double totalExtent;

  int get totalPageCount => pages.length;

  int rowCountThrough(int ordinal) {
    final page = pageForOrdinal(ordinal);
    return page == null ? 0 : page.rowStart + page.rowCount;
  }

  int get estimatedBytes => dayBuckets.length * 16 + pages.length * 48 + 80;

  CommittedVerticalPageGeometry? pageForOrdinal(int ordinal) =>
      ordinal >= 0 && ordinal < pages.length ? pages[ordinal] : null;

  /// O(log n) page lookup for a virtual scroll offset.
  int pageOrdinalForOffset(double offset) {
    if (pages.isEmpty) return 0;
    if (offset <= 0) return 0;
    var low = 0;
    var high = pages.length - 1;
    while (low < high) {
      final middle = low + ((high - low + 1) >> 1);
      if (pages[middle].top <= offset) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    return low;
  }

  static double _pageExtent(
    int rowCount,
    int groupCount, {
    required double rowHeight,
  }) =>
      rowCount * rowHeight +
      groupCount * DashboardLogBoxTokens.dayHeaderHeight +
      (groupCount - 1) * DashboardLogBoxTokens.dayGroupGap;
}
