import 'package:flutter/material.dart';
import '../../application/dashboard_balance_daily_insights_projection.dart';

enum BalanceDailyMonthImpactState {
  decreasedStillPositive,
  crossedToPositive,
  crossedToNegative,
  increasedStillNegative,
  increasedStillPositive,
  decreasedStillNegative,
  reachedNeutral,
  unchanged,
  unavailable,
}

/// Sampled from napi.png; financial meaning is resolved before drawing.
abstract final class BalanceDailyMonthImpactColors {
  static const ink = Color(0xff141d50);
  static const copy = Color(0xff57518f);
  static const purple = Color(0xffaaa0f5);
  static const pink = Color(0xfff064a0);
  static const mint = Color(0xff6bd2dc);
  static const negative = Color(0xffdc286d);
  static const positive = Color(0xff027c88);
  static const pinkPanel = Color(0xfffae6f0);
  static const mintPanel = Color(0xffe0f2f6);
  static const purplePanel = Color(0xffeae6ff);
}

@immutable
final class BalanceDailyMonthImpactPresentation {
  BalanceDailyMonthImpactPresentation.fromData(this.source) {
    final before = source?.ratioBeforePercent;
    final after = source?.ratioAfterPercent;
    final delta = source?.dailyImpactPp;
    state =
        source?.available != true ||
            before == null ||
            after == null ||
            delta == null
        ? BalanceDailyMonthImpactState.unavailable
        : delta.abs() < 1e-10
        ? BalanceDailyMonthImpactState.unchanged
        : after.abs() < 1e-10
        ? BalanceDailyMonthImpactState.reachedNeutral
        : before <= 0 && after > 0
        ? BalanceDailyMonthImpactState.crossedToPositive
        : before >= 0 && after < 0
        ? BalanceDailyMonthImpactState.crossedToNegative
        : delta > 0 && after < 0
        ? BalanceDailyMonthImpactState.increasedStillNegative
        : delta > 0
        ? BalanceDailyMonthImpactState.increasedStillPositive
        : after > 0
        ? BalanceDailyMonthImpactState.decreasedStillPositive
        : BalanceDailyMonthImpactState.decreasedStillNegative;
  }
  final DashboardBalanceDailyMonthImpactPresentation? source;
  late final BalanceDailyMonthImpactState state;
  bool get available => state != BalanceDailyMonthImpactState.unavailable;
  double? get beforePercent => source?.ratioBeforePercent;
  double? get afterPercent => source?.ratioAfterPercent;
  double? get deltaPp => available ? source!.dailyImpactPp : null;
  double get direction =>
      !available || state == BalanceDailyMonthImpactState.unchanged
      ? 0
      : deltaPp! > 0
      ? 1
      : -1;
  Color get valueColor => direction > 0
      ? BalanceDailyMonthImpactColors.positive
      : direction < 0
      ? BalanceDailyMonthImpactColors.negative
      : const Color(0xff6b60b8);
  Color get leftColor => (beforePercent ?? 0) < 0
      ? BalanceDailyMonthImpactColors.pink
      : BalanceDailyMonthImpactColors.purple;
  Color get rightColor =>
      state == BalanceDailyMonthImpactState.increasedStillNegative
      ? BalanceDailyMonthImpactColors.purple
      : direction > 0 && (afterPercent ?? 0) > 0
      ? BalanceDailyMonthImpactColors.mint
      : direction < 0
      ? BalanceDailyMonthImpactColors.pink
      : BalanceDailyMonthImpactColors.purple;
  Color get statusColor =>
      state == BalanceDailyMonthImpactState.increasedStillNegative ||
          direction == 0
      ? BalanceDailyMonthImpactColors.purplePanel
      : direction > 0
      ? BalanceDailyMonthImpactColors.mintPanel
      : BalanceDailyMonthImpactColors.pinkPanel;
  String get deltaLabel =>
      deltaPp == null ? '— pp' : '${_number(deltaPp!, fixed: true)} pp';
  String get beforeLabel =>
      beforePercent == null ? '—' : '${_number(beforePercent!)}%';
  String get afterLabel =>
      afterPercent == null ? '—' : '${_number(afterPercent!)}%';
  String get explanation => !available
      ? 'Még nincs összehasonlítható\nhavi nettóarány.'
      : direction == 0
      ? 'A nap nem változtatta meg\na havi nettóarányt.'
      : 'A nap ${_number(deltaPp!.abs(), signed: false)} százalékponttal ${direction > 0 ? 'növelte' : 'csökkentette'}\na havi nettóarányt.';
  String get statusLabel => switch (state) {
    BalanceDailyMonthImpactState.decreasedStillPositive =>
      'Csökkent, de pozitív maradt.',
    BalanceDailyMonthImpactState.crossedToPositive =>
      'A nap pozitívba fordította\na havi nettóarányt.',
    BalanceDailyMonthImpactState.crossedToNegative =>
      'A nap negatívba fordította\na havi nettóarányt.',
    BalanceDailyMonthImpactState.increasedStillNegative =>
      'Javult, de negatív maradt.',
    BalanceDailyMonthImpactState.increasedStillPositive =>
      'Javult a pozitív havi nettóarány.',
    BalanceDailyMonthImpactState.decreasedStillNegative =>
      'Tovább csökkent a negatív havi nettóarány.',
    BalanceDailyMonthImpactState.reachedNeutral =>
      'A nap nullszaldóba hozta\na havi nettóarányt.',
    BalanceDailyMonthImpactState.unchanged =>
      'A havi nettóarány nem változott.',
    BalanceDailyMonthImpactState.unavailable =>
      'Még nincs összehasonlítható havi nettóarány.',
  };
}

String _number(double value, {bool signed = true, bool fixed = false}) {
  final zero = double.parse(value.toStringAsFixed(1)) == 0;
  var amount = (zero ? 0.0 : value.abs()).toStringAsFixed(1);
  if (!fixed) amount = amount.replaceAll(RegExp(r'\.0$'), '');
  return '${zero || !signed
      ? ''
      : value > 0
      ? '+'
      : '−'}${amount.replaceAll('.', ',')}';
}
