import 'dart:math' as math;

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
    final amount = prepareDashboardLogBoxTextPainter(
      row.formattedAmount,
      FluviVisualTokens.logBoxRowAmountTextStyle.copyWith(color: amountColor),
      rightColumnMaxWidth,
      textAlign: TextAlign.right,
    );
    final time = prepareDashboardLogBoxTextPainter(
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
      title: prepareDashboardLogBoxTextPainter(
        row.displayName,
        FluviVisualTokens.logBoxRowTitleTextStyle,
        leftColumnWidth,
      ),
      secondary: prepareDashboardLogBoxTextPainter(
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
