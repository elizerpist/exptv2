import 'package:flutter/material.dart';

import '../../../core/debug/debug_console.dart';
import '../../../core/theme/app_colors.dart';
import '../../settings/models/app_theme_settings.dart';
import '../models/recurring_ghost_record.dart';
import '../models/transaction_category.dart';
import '../models/transaction_log_entry.dart';
import '../models/transaction_record.dart';
import 'recurring_ghost_log_box.dart';
import 'transaction_log_box.dart';

class TransactionLogList extends StatefulWidget {
  const TransactionLogList({
    super.key,
    this.records = const [],
    this.ghostRecords = const [],
    this.entries,
    this.categories = const [],
    this.categoriesById = const <int, TransactionCategory>{},
    this.surfaceColor = AppColors.white,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.avatarSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.ghostSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.ghostLogboxSettings = const GhostLogboxSettings(
      borderStyle: GhostLogboxBorderStyle.dashed,
      backgroundOpacityEnabled: true,
      avatarOpacityEnabled: false,
      textOpacityEnabled: false,
      avatarBadgeEnabled: true,
      textTone: GhostLogboxTextTone.normal,
      expectedLabelEnabled: true,
    ),
    required this.onFastFilter,
    required this.onRecordTap,
    required this.onDeleteRequested,
    required this.onCategoryFilter,
    this.onRenameMerchant,
    this.onResetMerchantName,
    this.onLoadMore,
    this.hasMore = false,
  });

  final List<TransactionRecord> records;
  final List<RecurringGhostRecord> ghostRecords;
  final List<TransactionLogEntry>? entries;
  final List<TransactionCategory> categories;
  final Map<int, TransactionCategory> categoriesById;
  final Color surfaceColor;
  final ExpenseSurfaceInteraction surfaceStyle;
  final ExpenseSurfaceInteraction avatarSurfaceStyle;
  final ExpenseSurfaceInteraction ghostSurfaceStyle;
  final GhostLogboxSettings ghostLogboxSettings;
  final TransactionLogContextCallback onFastFilter;
  final ValueChanged<TransactionRecord> onRecordTap;
  final TransactionDeleteRequest onDeleteRequested;
  final ValueChanged<TransactionCategory> onCategoryFilter;
  final TransactionRenameCallback? onRenameMerchant;
  final TransactionRecordAction? onResetMerchantName;
  final VoidCallback? onLoadMore;
  final bool hasMore;

  @override
  State<TransactionLogList> createState() => _TransactionLogListState();
}

class _TransactionLogListState extends State<TransactionLogList> {
  static const _loadMoreThreshold = 320.0;
  static const _logListPrefetchExtent = 360.0;
  static const _dateHeaderExtent = 34.0;
  static const _logRowExtent = 80.0;

  bool _loadMoreScheduled = false;
  bool _loadMorePending = false;
  int? _lastRequestedEntryCount;
  int _buildPassId = 0;
  int? _lastLoggedBuildEntryCount;
  bool? _lastLoggedBuildHasMore;
  DateTime? _lastScrollStartedAt;
  DateTime? _lastScrollEventAt;
  DateTime? _lastScrollUpdateLogAt;
  double? _lastScrollPixels;
  var _scrollUpdateCount = 0;
  var _scrollMinExtentAfter = double.infinity;
  var _scrollMaxSpeed = 0.0;

  @override
  void didUpdateWidget(covariant TransactionLogList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sourceEntryCount(oldWidget) != _sourceEntryCount(widget) ||
        oldWidget.hasMore != widget.hasMore) {
      _loadMoreScheduled = false;
      _loadMorePending = false;
      _lastRequestedEntryCount = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logEntries = widget.entries ?? _entries();
    final buildPassId = _beginBuildPass();
    _logBuildMetrics(logEntries.length, buildPassId);
    if (logEntries.isEmpty) {
      return const Center(
        child: Text(
          'Nincs megjeleníthető tranzakció',
          style: TextStyle(color: AppColors.gray500),
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) =>
          _handleScrollNotification(notification, logEntries.length),
      child: ListView.builder(
        // ignore: deprecated_member_use
        cacheExtent: _logListPrefetchExtent,
        itemExtentBuilder: (index, _) => _extentFor(logEntries[index]),
        addAutomaticKeepAlives: false,
        addSemanticIndexes: false,
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: logEntries.length,
        itemBuilder: (context, index) {
          final entry = logEntries[index];
          final header = entry.header;
          if (header != null) {
            return _DateHeader(date: header);
          }
          final ghost = entry.ghost;
          if (ghost != null) {
            return RecurringGhostLogBox(
              key: ValueKey('recurring-ghost-log-row-${ghost.id}'),
              ghost: ghost,
              category: _categoryForId(ghost.categoryId),
              surfaceColor: widget.surfaceColor,
              surfaceStyle: widget.ghostSurfaceStyle,
              avatarSurfaceStyle: widget.avatarSurfaceStyle,
              settings: widget.ghostLogboxSettings,
            );
          }
          final record = entry.record!;
          final category = _categoryForId(record.transactionCategoryID);
          return TransactionLogBox(
            key: ValueKey('transaction-log-row-${record.id}'),
            record: record,
            category: category,
            surfaceColor: widget.surfaceColor,
            surfaceStyle: widget.surfaceStyle,
            avatarSurfaceStyle: widget.avatarSurfaceStyle,
            onFastFilter: widget.onFastFilter,
            onTap: widget.onRecordTap,
            onDeleteRequested: widget.onDeleteRequested,
            onCategoryFilter: widget.onCategoryFilter,
            onRenameMerchant: widget.onRenameMerchant,
            onResetMerchantName: widget.onResetMerchantName,
          );
        },
      ),
    );
  }

  bool _handleScrollNotification(
    ScrollNotification notification,
    int entryCount,
  ) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }

    _logScrollNotification(notification, entryCount);

    if (notification is ScrollEndNotification && _loadMorePending) {
      _scheduleLoadMore(entryCount, notification.metrics, reason: 'scroll-end');
      return false;
    }

    if (!_canRequestLoadMore(entryCount, notification.metrics)) return false;

    _loadMorePending = true;
    _lastRequestedEntryCount = entryCount;
    final metrics = notification.metrics;
    DebugConsole.log(
      '[Perf] LogScroll load-more pending '
      'entries=$entryCount pixels=${_fmt(metrics.pixels)} '
      'extentAfter=${_fmt(metrics.extentAfter)} '
      'threshold=${_fmt(_loadMoreThreshold)} '
      'lastRequested=${_lastRequestedEntryCount ?? -1}',
    );
    if (notification is ScrollEndNotification) {
      _scheduleLoadMore(entryCount, metrics, reason: 'scroll-end');
    }
    return false;
  }

  bool _canRequestLoadMore(int entryCount, ScrollMetrics metrics) {
    return widget.hasMore &&
        widget.onLoadMore != null &&
        metrics.extentAfter < _loadMoreThreshold &&
        !_loadMoreScheduled &&
        !_loadMorePending &&
        _lastRequestedEntryCount != entryCount;
  }

  void _scheduleLoadMore(
    int entryCount,
    ScrollMetrics metrics, {
    required String reason,
  }) {
    if (_loadMoreScheduled) return;
    final scheduledAt = DateTime.now();
    DebugConsole.log(
      '[Perf] LogScroll load-more schedule '
      'reason=$reason entries=$entryCount pixels=${_fmt(metrics.pixels)} '
      'extentAfter=${_fmt(metrics.extentAfter)} '
      'threshold=${_fmt(_loadMoreThreshold)} '
      'lastRequested=${_lastRequestedEntryCount ?? -1}',
    );
    _loadMoreScheduled = true;

    void fireLoadMore() {
      if (!mounted) return;
      _loadMoreScheduled = false;
      _loadMorePending = false;
      final frameElapsed = DateTime.now()
          .difference(scheduledAt)
          .inMilliseconds;
      DebugConsole.log(
        '[Perf] LogScroll load-more fire '
        'reason=$reason entries=$entryCount frameElapsed=${frameElapsed}ms '
        'hasMore=${widget.hasMore}',
      );
      if (!widget.hasMore) return;
      final stopwatch = Stopwatch()..start();
      widget.onLoadMore?.call();
      DebugConsole.log(
        '[Perf] LogScroll load-more callback '
        'elapsed=${stopwatch.elapsedMilliseconds}ms',
      );
    }

    if (reason == 'scroll-end') {
      fireLoadMore();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => fireLoadMore());
    }
  }

  int _beginBuildPass() {
    _buildPassId += 1;
    return _buildPassId;
  }

  void _logBuildMetrics(int entryCount, int buildPassId) {
    if (_lastLoggedBuildEntryCount == entryCount &&
        _lastLoggedBuildHasMore == widget.hasMore) {
      return;
    }
    _lastLoggedBuildEntryCount = entryCount;
    _lastLoggedBuildHasMore = widget.hasMore;
    final startedAt = DateTime.now();
    DebugConsole.log(
      '[Perf] LogList build entries=$entryCount hasMore=${widget.hasMore} '
      'cache=${_fmt(_logListPrefetchExtent)} threshold=${_fmt(_loadMoreThreshold)} '
      'extentMode=builder header=${_fmt(_dateHeaderExtent)} row=${_fmt(_logRowExtent)}',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
      DebugConsole.log(
        '[Perf] LogList frame id=$buildPassId entries=$entryCount elapsed=${elapsed}ms '
        'jank=${elapsed > 32}',
      );
    });
  }

  void _logScrollNotification(ScrollNotification notification, int entryCount) {
    final metrics = notification.metrics;
    if (notification is ScrollStartNotification) {
      final now = DateTime.now();
      _lastScrollStartedAt = now;
      _lastScrollEventAt = now;
      _lastScrollUpdateLogAt = null;
      _lastScrollPixels = metrics.pixels;
      _scrollUpdateCount = 0;
      _scrollMinExtentAfter = metrics.extentAfter;
      _scrollMaxSpeed = 0;
      DebugConsole.log(
        '[Perf] LogScroll start entries=$entryCount pixels=${_fmt(metrics.pixels)} '
        'extentAfter=${_fmt(metrics.extentAfter)} viewport=${_fmt(metrics.viewportDimension)} '
        'max=${_fmt(metrics.maxScrollExtent)} hasMore=${widget.hasMore}',
      );
      return;
    }

    if (notification is ScrollUpdateNotification) {
      final now = DateTime.now();
      final previousAt = _lastScrollEventAt ?? now;
      final previousPixels = _lastScrollPixels ?? metrics.pixels;
      final dt = now.difference(previousAt).inMilliseconds;
      final dp = metrics.pixels - previousPixels;
      final speed = dt <= 0 ? 0.0 : (dp.abs() / dt);
      _lastScrollEventAt = now;
      _lastScrollPixels = metrics.pixels;
      _scrollUpdateCount += 1;
      _scrollMinExtentAfter = mathMin(
        _scrollMinExtentAfter,
        metrics.extentAfter,
      );
      _scrollMaxSpeed = mathMax(_scrollMaxSpeed, speed);

      final lastLogAt = _lastScrollUpdateLogAt;
      final elapsedSinceLog = lastLogAt == null
          ? 999999
          : now.difference(lastLogAt).inMilliseconds;
      final nearLoadMore = metrics.extentAfter <= _loadMoreThreshold * 1.5;
      if (_scrollUpdateCount == 1 || nearLoadMore || elapsedSinceLog >= 120) {
        _lastScrollUpdateLogAt = now;
        DebugConsole.log(
          '[Perf] LogScroll update entries=$entryCount updates=$_scrollUpdateCount '
          'pixels=${_fmt(metrics.pixels)} dp=${_fmt(dp)} dt=${dt}ms '
          'speed=${speed.toStringAsFixed(2)} extentAfter=${_fmt(metrics.extentAfter)} '
          'scheduled=$_loadMoreScheduled hasMore=${widget.hasMore}',
        );
      }
      return;
    }

    if (notification is ScrollEndNotification) {
      final now = DateTime.now();
      final startedAt = _lastScrollStartedAt ?? now;
      final elapsed = now.difference(startedAt).inMilliseconds;
      _scrollMinExtentAfter = mathMin(
        _scrollMinExtentAfter,
        metrics.extentAfter,
      );
      DebugConsole.log(
        '[Perf] LogScroll end entries=$entryCount updates=$_scrollUpdateCount '
        'elapsed=${elapsed}ms pixels=${_fmt(metrics.pixels)} '
        'minExtentAfter=${_fmt(_scrollMinExtentAfter)} '
        'maxSpeed=${_scrollMaxSpeed.toStringAsFixed(2)} '
        'scheduled=$_loadMoreScheduled hasMore=${widget.hasMore}',
      );
    }
  }

  double mathMin(double left, double right) => left < right ? left : right;

  double mathMax(double left, double right) => left > right ? left : right;

  String _fmt(double value) => value.toStringAsFixed(1);

  double _extentFor(TransactionLogEntry entry) {
    if (entry.header != null) return _dateHeaderExtent;
    return _logRowExtent;
  }

  List<TransactionLogEntry> _entries() {
    final entries = <TransactionLogEntry>[];
    String? previousDate;
    final rows = <TransactionLogEntry>[
      for (final record in widget.records) TransactionLogEntry.record(record),
      for (final ghost in widget.ghostRecords) TransactionLogEntry.ghost(ghost),
    ];
    rows.sort(_compareEntries);
    for (final row in rows) {
      if (row.date != previousDate) {
        entries.add(TransactionLogEntry.header(row.date));
        previousDate = row.date;
      }
      entries.add(row);
    }
    return entries;
  }

  TransactionCategory? _categoryForId(int? id) {
    if (id == null) return null;
    final indexed = widget.categoriesById[id];
    if (indexed != null) return indexed;
    for (final category in widget.categories) {
      if (category.transactionCategoryID == id) return category;
    }
    return null;
  }

  int _sourceEntryCount(TransactionLogList list) =>
      list.entries?.length ?? list.records.length + list.ghostRecords.length;
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('transaction-date-group-$date'),
      height: _TransactionLogListState._dateHeaderExtent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        child: Text(
          date,
          style: const TextStyle(
            color: AppColors.gray500,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

int _compareEntries(TransactionLogEntry left, TransactionLogEntry right) {
  final date = right.date.compareTo(left.date);
  if (date != 0) return date;
  final time = right.time.compareTo(left.time);
  if (time != 0) return time;
  return right.sortId.compareTo(left.sortId);
}
