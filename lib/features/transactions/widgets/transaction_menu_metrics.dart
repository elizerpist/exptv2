import 'header_card/transaction_header_metrics.dart';

class TransactionMenuMetrics {
  const TransactionMenuMetrics._();

  static const typePillTopPadding = 8.0;
  static const typePillBottomPadding = 12.0;
  static const typePillMinHeight = 52.0;

  static const summaryPillTop =
      TransactionHeaderMetrics.contentTop +
      typePillTopPadding +
      typePillMinHeight +
      typePillBottomPadding;
  static const overlayTop = summaryPillTop;
}
