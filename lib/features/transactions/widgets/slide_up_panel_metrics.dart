import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'transaction_menu_metrics.dart';

class SlideUpPanelMetrics {
  const SlideUpPanelMetrics._();

  static const actionBottomInset = 24.0;
  static const horizontalInset = 20.0;
  static const keyboardInsetCap = 180.0;
  static const transactionCompactMaxHeight = 448.0;
  static const transactionCompactScreenFactor = 0.50;
  static const budgetBaseHeight = 440.0;

  static double fullHeightForScreen(double screenHeight) {
    return (screenHeight - TransactionMenuMetrics.overlayTop)
        .clamp(0.0, screenHeight)
        .toDouble();
  }

  static double fullHeight(BuildContext context) {
    return fullHeightForScreen(MediaQuery.sizeOf(context).height);
  }

  static double transactionHeight(
    BuildContext context, {
    required bool pickerOpen,
  }) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final compactHeight = math.min(
      transactionCompactMaxHeight,
      screenHeight * transactionCompactScreenFactor,
    );
    final baseHeight = pickerOpen
        ? fullHeightForScreen(screenHeight)
        : compactHeight;
    return (baseHeight + math.min(keyboardInset, keyboardInsetCap))
        .clamp(0.0, screenHeight)
        .toDouble();
  }

  static double budgetHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return (budgetBaseHeight + math.min(keyboardInset, keyboardInsetCap))
        .clamp(0.0, screenHeight)
        .toDouble();
  }
}
