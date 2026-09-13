import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_live_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  const fullRange = QueryAmountRangeValues(
    minimumScaled100: 1,
    maximumScaled100: 1000,
    lowerScaled100: 1,
    upperScaled100: 1000,
  );
  const narrowedRange = QueryAmountRangeValues(
    minimumScaled100: 1,
    maximumScaled100: 1000,
    lowerScaled100: 500,
    upperScaled100: 1000,
  );

  test(
    'RED MYH-06: a stale generation cannot publish into a replacement identity',
    () {
      final live = MindYearHeatmapLiveProjection();
      addTearDown(live.dispose);
      final first = _projection(year: 2025, revision: 1);
      final replacement = _projection(year: 2026, revision: 2);

      live.install(first, fullRange);
      expect(live.publishPreview(first.identity, narrowedRange), isTrue);
      expect(live.value!.identity, first.identity);
      expect(live.value!.range, narrowedRange);

      live.install(replacement, fullRange);
      expect(live.publishPreview(first.identity, narrowedRange), isFalse);
      expect(live.value!.identity, replacement.identity);
      expect(live.value!.range, fullRange);
      expect(live.stalePublicationRejectCount, 1);
    },
  );

  test(
    'RED MYH-07: the terminal range can be synchronously flushed into the active frame',
    () {
      final live = MindYearHeatmapLiveProjection();
      addTearDown(live.dispose);
      final projection = _projection(year: 2025, revision: 1);

      live.install(projection, fullRange);
      expect(
        live.flushTerminalPreview(projection.identity, narrowedRange),
        isTrue,
      );
      expect(live.value!.range, narrowedRange);
      expect(live.value!.identity, projection.identity);
    },
  );
}

MindYearHeatmapProjection _projection({
  required int year,
  required int revision,
}) {
  final identity = MindYearHeatmapIdentity(
    upstreamScopeKey: 'expense|category:food|year:$year',
    indexGeneration: revision,
    coreRevision: revision,
    year: year,
    navigationEpoch: revision,
  );
  return MindYearHeatmapProjection.build(
    identity: identity,
    entries: <DashboardLedgerEntry>[
      DashboardLedgerEntry(
        id: 'entry-$year',
        partnerId: 'p',
        categoryId: 'food',
        direction: 'expense',
        amountMinor: 700,
        bookedLocalEpochDay: LocalDate(year: year, month: 1, day: 1).epochDay,
        bookedLocalTimeMinutes: 0,
      ),
    ],
  );
}
