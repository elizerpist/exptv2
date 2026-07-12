import '../../../core/debug/debug_console.dart';
import '../../transactions/models/transaction_category.dart';
import '../../transactions/models/transaction_record.dart';
import 'stats_render_frame.dart';
import 'stats_render_frame_worker.dart';
import 'stats_year_data.dart';

class StatsRenderPrewarmer {
  StatsRenderPrewarmer({required this.cache, required this.worker});

  final StatsRenderFrameCache cache;
  final StatsRenderFrameWorker worker;
  final _inFlight = <StatsRenderFrameKey, Future<StatsRenderFrame>>{};

  Future<void> prewarmPrimary({
    required Object dataRevision,
    required List<TransactionRecord> transactions,
    required List<TransactionCategory> categories,
    required StatsSummaryScope summaryScope,
    required int year,
    required int month,
    required DateTime today,
    Set<String> vendorFilters = const <String>{},
    String reason = 'startup',
  }) async {
    await Future.wait(<Future<StatsRenderFrame>>[
      for (final type in const <TransactionType>[
        TransactionType.expense,
        TransactionType.income,
      ])
        prewarmRequest(
          StatsRenderFrameRequest(
            year: year,
            month: month,
            activeType: type,
            thresholdValue: defaultStatsThreshold,
            transactions: transactions,
            categories: categories,
            selectedCategoryIds: const <int>{},
            vendorFilters: vendorFilters,
            summaryScope: summaryScope,
            query: '',
            today: today,
          ),
          dataRevision: dataRevision,
          reason: reason,
        ),
    ]);
  }

  Future<StatsRenderFrame> prewarmRequest(
    StatsRenderFrameRequest request, {
    required Object dataRevision,
    required String reason,
  }) {
    final key = request.cacheKey(dataRevision: dataRevision);
    final cached = cache.lookup(key);
    if (cached != null) {
      DebugConsole.log(
        '[Perf] Stats prewarm cache hit reason=$reason '
        'type=${request.activeType.name}',
      );
      return Future<StatsRenderFrame>.value(cached);
    }
    final existing = _inFlight[key];
    if (existing != null) return existing;

    DebugConsole.log(
      '[Perf] Stats prewarm request reason=$reason '
      'type=${request.activeType.name} '
      'transactions=${request.transactions.length}',
    );
    late final Future<StatsRenderFrame> future;
    future = worker
        .build(request)
        .then((frame) {
          cache.seed(key, frame);
          final canonicalKey = key.withThreshold(frame.yearData.thresholdValue);
          if (canonicalKey != key) cache.seed(canonicalKey, frame);
          DebugConsole.log(
            '[Perf] Stats prewarm publish reason=$reason '
            'type=${request.activeType.name}',
          );
          return frame;
        })
        .whenComplete(() {
          if (identical(_inFlight[key], future)) _inFlight.remove(key);
        });
    _inFlight[key] = future;
    return future;
  }
}
