import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'transaction_menu_metrics.dart';

class SlideUpPanelMetrics {
  const SlideUpPanelMetrics._();

  static const actionBottomInset = 24.0;
  static const transactionActionBottomInset = 44.0;
  static const horizontalInset = 20.0;
  static const keyboardInsetCap = 180.0;
  static const transactionCompactMaxHeight = 540.0;
  static const transactionCompactScreenFactor = 0.90;
  static const budgetBaseHeight = 440.0;

  static double fullHeightForScreen(double screenHeight) {
    return (screenHeight - TransactionMenuMetrics.overlayTop)
        .clamp(0.0, screenHeight)
        .toDouble();
  }

  static double fullHeight(BuildContext context) {
    return fullHeightForScreen(_screenHeight(context));
  }

  static double transactionHeight(
    BuildContext context, {
    required bool pickerOpen,
  }) {
    final screenHeight = _screenHeight(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final compactHeight = math.min(
      transactionCompactMaxHeight,
      screenHeight * transactionCompactScreenFactor,
    );
    final baseHeight = pickerOpen
        ? math.max(fullHeightForScreen(screenHeight), compactHeight)
        : compactHeight;
    return (baseHeight + math.min(keyboardInset, keyboardInsetCap))
        .clamp(0.0, screenHeight)
        .toDouble();
  }

  static double budgetHeight(BuildContext context) {
    final screenHeight = _screenHeight(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return (budgetBaseHeight + math.min(keyboardInset, keyboardInsetCap))
        .clamp(0.0, screenHeight)
        .toDouble();
  }

  static double _screenHeight(BuildContext context) {
    final mediaHeight = MediaQuery.sizeOf(context).height;
    final view = View.of(context);
    final viewHeight = view.physicalSize.height / view.devicePixelRatio;
    return math.max(mediaHeight, viewHeight);
  }
}
