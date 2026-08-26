import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../application/dashboard_log_viewport_state.dart';

/// Shared exact-width paragraph resource used by both bounded LogBox domains.
///
/// It has no widget, scrolling, cache, or repository dependency. Callers must
/// create it during their explicit preparation phase and only call [paint] in
/// the render hot path.
final class DashboardPreparedLogBoxRowTextLayout {
  DashboardPreparedLogBoxRowTextLayout._({
    required this.contentIdentity,
    required this.contentLeft,
    required this.rightEdge,
    required this.title,
    required this.secondary,
    required this.amount,
    required this.time,
    required this.defaultAmountColor,
  });

  factory DashboardPreparedLogBoxRowTextLayout.prepare({
    required DashboardLogRowViewModel row,
    required double surfaceWidth,
    required int contentIdentity,
  }) {
    final preparation = _DashboardLogBoxRowTextLayoutPreparation(
      row: row,
      surfaceWidth: surfaceWidth,
      contentIdentity: contentIdentity,
    );
    try {
      preparation
        ..prepareAmount()
        ..prepareTime()
        ..prepareTitle()
        ..prepareSecondary();
      return preparation.complete();
    } on Object {
      preparation.disposePartial();
      rethrow;
    }
  }

  /// Prepares the same immutable row layout while allowing its scene owner to
  /// yield between independent paragraph layouts.  The returned row remains
  /// atomic: no caller can publish it until all four paragraphs exist.
  static Future<DashboardPreparedLogBoxRowTextLayout> prepareCooperatively({
    required DashboardLogRowViewModel row,
    required double surfaceWidth,
    required int contentIdentity,
    required bool Function() shouldCheckpoint,
    required Future<void> Function() checkpoint,
    void Function(String paragraph, int elapsedMicros)? onParagraphPrepared,
  }) async {
    final preparation = _DashboardLogBoxRowTextLayoutPreparation(
      row: row,
      surfaceWidth: surfaceWidth,
      contentIdentity: contentIdentity,
    );
    try {
      void prepareParagraph(String paragraph, void Function() work) {
        final startedAt = developer.Timeline.now;
        work();
        onParagraphPrepared?.call(
          paragraph,
          developer.Timeline.now - startedAt,
        );
      }

      prepareParagraph('amount', preparation.prepareAmount);
      // Each paragraph is an atomic work unit.  The owner may reserve part of
      // a slice for the next independently-expensive TextPainter rather than
      // waiting until the outer budget is already exhausted.  The completed
      // row is still published only after all four paragraphs exist.
      if (shouldCheckpoint()) await checkpoint();
      prepareParagraph('time', preparation.prepareTime);
      if (shouldCheckpoint()) await checkpoint();
      prepareParagraph('title', preparation.prepareTitle);
      if (shouldCheckpoint()) await checkpoint();
      prepareParagraph('secondary', preparation.prepareSecondary);
      return preparation.complete();
    } on Object {
      // A checkpoint can surface cancellation.  Paragraphs created before
      // that boundary never reached a staged bank, so this local owner must
      // release them immediately.
      preparation.disposePartial();
      rethrow;
    }
  }

  final int contentIdentity;
  final double contentLeft;
  final double rightEdge;
  final TextPainter title;
  final TextPainter secondary;
  final TextPainter amount;
  final TextPainter time;
  final Color defaultAmountColor;
  final Map<int, ui.Picture> _tintedAmountPictures = <int, ui.Picture>{};

  /// A palette recolour records at most one retained tiny picture per colour.
  /// The normal paint path neither builds an offscreen layer nor re-lays out
  /// a paragraph for each visible transaction.
  int get amountTintPictureBuildCount => _tintedAmountPictures.length;

  /// The foreground is a presentation-only compositing input. It paints a
  /// prepared paragraph without re-layout, so palette changes retain text and
  /// scene cache without creating a [TextPainter] in the paint hot path.
  void paint(
    Canvas canvas,
    double rowTop, {
    required double rowHeight,
    required Color amountForeground,
  }) {
    final leftHeight = title.height + secondary.height;
    final leftTop = rowTop + (rowHeight - leftHeight) / 2;
    title.paint(canvas, Offset(contentLeft, leftTop));
    secondary.paint(canvas, Offset(contentLeft, leftTop + title.height));

    final rightHeight = amount.height + time.height;
    final rightTop = rowTop + (rowHeight - rightHeight) / 2;
    final amountOffset = Offset(rightEdge - amount.width, rightTop);
    if (amountForeground == defaultAmountColor) {
      amount.paint(canvas, amountOffset);
    } else {
      final picture = _tintedAmountPictures.putIfAbsent(
        amountForeground.toARGB32(),
        () => _recordTintedAmountPicture(amountForeground),
      );
      canvas.save();
      canvas.translate(amountOffset.dx, amountOffset.dy);
      canvas.drawPicture(picture);
      canvas.restore();
    }
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
    for (final picture in _tintedAmountPictures.values) {
      picture.dispose();
    }
    _tintedAmountPictures.clear();
  }

  ui.Picture _recordTintedAmountPicture(Color foreground) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final bounds = Offset.zero & Size(amount.width, amount.height);
    canvas.saveLayer(
      bounds,
      Paint()..colorFilter = ColorFilter.mode(foreground, BlendMode.srcIn),
    );
    amount.paint(canvas, Offset.zero);
    canvas.restore();
    return recorder.endRecording();
  }
}

/// One row's private construction state.  It centralizes the exact-width
/// geometry for synchronous and cooperative callers without becoming another
/// cache or renderer owner.
final class _DashboardLogBoxRowTextLayoutPreparation {
  _DashboardLogBoxRowTextLayoutPreparation({
    required this.row,
    required double surfaceWidth,
    required this.contentIdentity,
  }) : contentLeft =
           DashboardLogBoxTokens.rowHorizontalInset +
           DashboardLogBoxTokens.avatarSize +
           DashboardLogBoxTokens.rowGap,
       rightEdge = DashboardLogBoxTokens.textTrailingEdge(
         surfaceWidth: surfaceWidth,
       );

  final DashboardLogRowViewModel row;
  final int contentIdentity;
  final double contentLeft;
  final double rightEdge;
  TextPainter? _amount;
  TextPainter? _time;
  TextPainter? _title;
  TextPainter? _secondary;

  Color get _defaultAmountColor => row.amountStyle == LogAmountStyle.expense
      ? FluviVisualTokens.logBoxExpenseAmount
      : FluviVisualTokens.logBoxIncomeAmount;

  double get _rightColumnMaxWidth =>
      math.max(0.0, (rightEdge - contentLeft) * .44);

  double get _leftColumnWidth {
    final amount = _amount;
    final time = _time;
    if (amount == null || time == null) {
      throw StateError('Right LogBox paragraphs must be prepared first.');
    }
    final rightLeft = rightEdge - math.max(amount.width, time.width);
    return math.max(
      0.0,
      rightLeft - DashboardLogBoxTokens.rowGap - contentLeft,
    );
  }

  void prepareAmount() {
    assert(_amount == null);
    _amount = prepareDashboardLogBoxTextPainter(
      row.formattedAmount,
      FluviVisualTokens.logBoxRowAmountTextStyle.copyWith(
        color: _defaultAmountColor,
      ),
      _rightColumnMaxWidth,
      textAlign: TextAlign.right,
    );
  }

  void prepareTime() {
    assert(_time == null);
    _time = prepareDashboardLogBoxTextPainter(
      row.displayTime,
      FluviVisualTokens.logBoxRowSecondaryTextStyle,
      _rightColumnMaxWidth,
      textAlign: TextAlign.right,
    );
  }

  void prepareTitle() {
    assert(_title == null);
    _title = prepareDashboardLogBoxTextPainter(
      row.displayName,
      FluviVisualTokens.logBoxRowTitleTextStyle,
      _leftColumnWidth,
    );
  }

  void prepareSecondary() {
    assert(_secondary == null);
    _secondary = prepareDashboardLogBoxTextPainter(
      row.categoryDisplayName,
      FluviVisualTokens.logBoxRowSecondaryTextStyle,
      _leftColumnWidth,
    );
  }

  DashboardPreparedLogBoxRowTextLayout complete() {
    final amount = _amount;
    final time = _time;
    final title = _title;
    final secondary = _secondary;
    if (amount == null || time == null || title == null || secondary == null) {
      throw StateError('A LogBox row layout must be complete before use.');
    }
    return DashboardPreparedLogBoxRowTextLayout._(
      contentIdentity: contentIdentity,
      contentLeft: contentLeft,
      rightEdge: rightEdge,
      title: title,
      secondary: secondary,
      amount: amount,
      time: time,
      defaultAmountColor: _defaultAmountColor,
    );
  }

  void disposePartial() {
    _amount?.dispose();
    _time?.dispose();
    _title?.dispose();
    _secondary?.dispose();
  }
}

TextPainter prepareDashboardLogBoxTextPainter(
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
