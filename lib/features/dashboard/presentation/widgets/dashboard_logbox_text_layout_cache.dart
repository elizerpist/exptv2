import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../logbox/application/dashboard_log_viewport_state.dart';

typedef DashboardLogBoxCriticalPayloadProvider =
    List<DashboardLogViewportState> Function();

/// Width-specific, bounded paragraph owner for the rail-critical LogBox path.
///
/// This cache prepares text layout objects only. It never builds or paints an
/// offscreen widget, row, viewport or LogBox. The retained entries are capped
/// and replaced as one explicit pin set, so a large database cannot turn the
/// cache into an unbounded copy of every transaction.
final class DashboardLogBoxTextLayoutCache {
  DashboardLogBoxTextLayoutCache({this.maximumPinnedRows = 8192})
    : assert(maximumPinnedRows > 0);

  final int maximumPinnedRows;
  final Map<String, DashboardPreparedLogBoxRowTextLayout> _rows =
      <String, DashboardPreparedLogBoxRowTextLayout>{};
  final Map<String, TextPainter> _dayHeaders = <String, TextPainter>{};
  TextPainter? _empty;
  double? _surfaceWidth;
  bool _disposed = false;
  bool _prepared = false;
  int _generation = 0;
  int _estimatedBytes = 0;
  Completer<void>? _yieldCompleter;

  bool get isPrepared => _prepared;
  int get generation => _generation;
  int get preparedRowCount => _rows.length;
  int get preparedDayHeaderCount => _dayHeaders.length;
  int get estimatedBytes => _estimatedBytes;
  double? get surfaceWidth => _surfaceWidth;

  DashboardPreparedLogBoxRowTextLayout? rowFor(DashboardLogRowViewModel row) {
    final layout = _rows[row.entryId];
    return layout != null && layout.contentIdentity == row.textLayoutId
        ? layout
        : null;
  }

  TextPainter? dayHeaderFor(String label) => _dayHeaders[label];

  TextPainter? get empty => _empty;

  /// Replaces the pinned set and yields periodically while the readiness
  /// spinner still owns interaction. Existing identical row layouts survive a
  /// pin-window change; removed rows and obsolete widths are disposed.
  Future<void> preparePinned({
    required Iterable<DashboardLogViewportState> payloads,
    required double surfaceWidth,
    int yieldEveryRows = 64,
  }) async {
    if (_disposed) throw StateError('LogBox text layout cache is disposed.');
    if (!surfaceWidth.isFinite || surfaceWidth <= 0) {
      throw ArgumentError.value(surfaceWidth, 'surfaceWidth');
    }
    if (yieldEveryRows <= 0) {
      throw ArgumentError.value(yieldEveryRows, 'yieldEveryRows');
    }

    final desiredRows = <String, DashboardLogRowViewModel>{};
    final desiredHeaders = <String>{};
    for (final payload in payloads) {
      for (final item in payload.flatItems) {
        final existing = desiredRows[item.row.entryId];
        if (existing != null &&
            existing.textLayoutId != item.row.textLayoutId) {
          throw StateError(
            'One row identity resolved to different prepared LogBox text.',
          );
        }
        desiredRows[item.row.entryId] = item.row;
        final dayLabel = item.dayLabel;
        if (dayLabel != null) desiredHeaders.add(dayLabel);
      }
    }
    if (desiredRows.length > maximumPinnedRows) {
      throw StateError(
        'Rail-critical LogBox text pin set exceeded $maximumPinnedRows rows: '
        '${desiredRows.length}.',
      );
    }

    final widthChanged = _surfaceWidth != surfaceWidth;
    if (widthChanged) _clearLayouts();
    _surfaceWidth = surfaceWidth;
    _prepared = false;

    final removedRows = _rows.keys
        .where((entryId) => !desiredRows.containsKey(entryId))
        .toList(growable: false);
    for (final entryId in removedRows) {
      _rows.remove(entryId)?.dispose();
    }
    final removedHeaders = _dayHeaders.keys
        .where((label) => !desiredHeaders.contains(label))
        .toList(growable: false);
    for (final label in removedHeaders) {
      _dayHeaders.remove(label)?.dispose();
    }

    var preparedSinceYield = 0;
    for (final row in desiredRows.values) {
      final identity = row.textLayoutId;
      final existing = _rows[row.entryId];
      if (existing?.contentIdentity == identity) continue;
      existing?.dispose();
      _rows[row.entryId] = DashboardPreparedLogBoxRowTextLayout.prepare(
        row: row,
        surfaceWidth: surfaceWidth,
        contentIdentity: identity,
      );
      preparedSinceYield += 1;
      if (preparedSinceYield == yieldEveryRows) {
        preparedSinceYield = 0;
        await _yieldToEventLoop();
        if (_disposed) return;
      }
    }
    for (final label in desiredHeaders) {
      _dayHeaders.putIfAbsent(
        label,
        () => _preparedPainter(
          label,
          FluviVisualTokens.logBoxDayHeaderTextStyle,
          surfaceWidth,
        ),
      );
    }
    _empty ??= _preparedPainter(
      'Nincs tranzakció ebben az időszakban.',
      FluviVisualTokens.logBoxHeaderTextStyle,
      math.max(0, surfaceWidth - 32),
    );

    _estimatedBytes = _estimateBytes(desiredRows.values, desiredHeaders);
    _generation += 1;
    _prepared = true;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final yieldCompleter = _yieldCompleter;
    if (yieldCompleter != null && !yieldCompleter.isCompleted) {
      yieldCompleter.complete();
    }
    _yieldCompleter = null;
    _clearLayouts();
  }

  Future<void> _yieldToEventLoop() {
    final existing = _yieldCompleter;
    if (existing != null) return existing.future;
    final completer = Completer<void>();
    _yieldCompleter = completer;
    unawaited(
      SchedulerBinding.instance
          .scheduleTask<void>(
            () {},
            Priority.animation,
            debugLabel: 'DashboardLogBoxTextLayoutCache.yield',
          )
          .then((_) {
            if (!completer.isCompleted) completer.complete();
            if (identical(_yieldCompleter, completer)) {
              _yieldCompleter = null;
            }
          }),
    );
    return completer.future;
  }

  void _clearLayouts() {
    for (final layout in _rows.values) {
      layout.dispose();
    }
    for (final header in _dayHeaders.values) {
      header.dispose();
    }
    _empty?.dispose();
    _rows.clear();
    _dayHeaders.clear();
    _empty = null;
    _prepared = false;
    _estimatedBytes = 0;
  }

  static TextPainter _preparedPainter(
    String text,
    TextStyle style,
    double maxWidth, {
    TextAlign textAlign = TextAlign.left,
  }) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textAlign: textAlign,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);

  static int _estimateBytes(
    Iterable<DashboardLogRowViewModel> rows,
    Iterable<String> headers,
  ) {
    var utf16Units = 0;
    var rowCount = 0;
    for (final row in rows) {
      rowCount += 1;
      utf16Units +=
          row.entryId.length +
          row.displayName.length +
          row.categoryDisplayName.length +
          row.formattedAmount.length +
          row.displayTime.length;
    }
    for (final header in headers) {
      utf16Units += header.length;
    }
    // A conservative fixed bookkeeping/paragraph estimate plus retained text.
    return rowCount * 2048 + utf16Units * 2;
  }
}

/// Four immutable, already-laid-out paragraphs for one prepared row.
final class DashboardPreparedLogBoxRowTextLayout {
  DashboardPreparedLogBoxRowTextLayout._({
    required this.contentIdentity,
    required this.contentLeft,
    required this.rightEdge,
    required this.title,
    required this.secondary,
    required this.amount,
    required this.time,
  });

  factory DashboardPreparedLogBoxRowTextLayout.prepare({
    required DashboardLogRowViewModel row,
    required double surfaceWidth,
    required int contentIdentity,
  }) {
    final contentLeft =
        DashboardLogBoxTokens.rowHorizontalInset +
        DashboardLogBoxTokens.avatarSize +
        DashboardLogBoxTokens.rowGap;
    final rightEdge = surfaceWidth - DashboardLogBoxTokens.rowHorizontalInset;
    final rightColumnMaxWidth = math.max(0.0, (rightEdge - contentLeft) * .44);
    final amountColor = row.amountStyle == LogAmountStyle.expense
        ? FluviVisualTokens.logBoxExpenseAmount
        : FluviVisualTokens.logBoxIncomeAmount;
    final amount = DashboardLogBoxTextLayoutCache._preparedPainter(
      row.formattedAmount,
      FluviVisualTokens.logBoxRowAmountTextStyle.copyWith(color: amountColor),
      rightColumnMaxWidth,
      textAlign: TextAlign.right,
    );
    final time = DashboardLogBoxTextLayoutCache._preparedPainter(
      row.displayTime,
      FluviVisualTokens.logBoxRowSecondaryTextStyle,
      rightColumnMaxWidth,
      textAlign: TextAlign.right,
    );
    final rightWidth = math.max(amount.width, time.width);
    final rightLeft = rightEdge - rightWidth;
    final leftColumnWidth = math.max(
      0.0,
      rightLeft - DashboardLogBoxTokens.rowGap - contentLeft,
    );
    return DashboardPreparedLogBoxRowTextLayout._(
      contentIdentity: contentIdentity,
      contentLeft: contentLeft,
      rightEdge: rightEdge,
      title: DashboardLogBoxTextLayoutCache._preparedPainter(
        row.displayName,
        FluviVisualTokens.logBoxRowTitleTextStyle,
        leftColumnWidth,
      ),
      secondary: DashboardLogBoxTextLayoutCache._preparedPainter(
        row.categoryDisplayName,
        FluviVisualTokens.logBoxRowSecondaryTextStyle,
        leftColumnWidth,
      ),
      amount: amount,
      time: time,
    );
  }

  final int contentIdentity;
  final double contentLeft;
  final double rightEdge;
  final TextPainter title;
  final TextPainter secondary;
  final TextPainter amount;
  final TextPainter time;

  void paint(Canvas canvas, double rowTop) {
    final leftHeight = title.height + secondary.height;
    final leftTop = rowTop + (DashboardLogBoxTokens.rowHeight - leftHeight) / 2;
    title.paint(canvas, Offset(contentLeft, leftTop));
    secondary.paint(canvas, Offset(contentLeft, leftTop + title.height));

    final rightHeight = amount.height + time.height;
    final rightTop =
        rowTop + (DashboardLogBoxTokens.rowHeight - rightHeight) / 2;
    amount.paint(canvas, Offset(rightEdge - amount.width, rightTop));
    time.paint(
      canvas,
      Offset(rightEdge - time.width, rightTop + amount.height),
    );
  }

  void dispose() {
    title.dispose();
    secondary.dispose();
    amount.dispose();
    time.dispose();
  }
}
