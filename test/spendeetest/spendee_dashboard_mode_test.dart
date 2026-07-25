import 'dart:math' as math;

import 'package:exptv2/features/transactions/widgets/experimental/spendee_dashboard_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Balance mode exposes the exact 140 degree FAB gradient', () {
    final gradient = SpendeeDashboardMode.balance.fabGradient;

    expect(gradient, isNotNull);
    expect(gradient!.colors, const <Color>[
      Color(0xFF6065F5),
      Color(0xFF8C5CEF),
      Color(0xFFF25CBF),
    ]);
    expect(gradient.stops, const <double>[0, 0.52, 1]);
    expect(_cssAngleDegrees(gradient), closeTo(140, 0.000001));
  });

  test('Budget and Mind modes keep the FAB solid', () {
    expect(SpendeeDashboardMode.budget.fabGradient, isNull);
    expect(SpendeeDashboardMode.mind.fabGradient, isNull);
  });
}

double _cssAngleDegrees(LinearGradient gradient) {
  final begin = gradient.begin.resolve(TextDirection.ltr);
  final end = gradient.end.resolve(TextDirection.ltr);
  final dx = end.x - begin.x;
  final dy = end.y - begin.y;
  var degrees = math.atan2(dx, -dy) * 180 / math.pi;
  if (degrees < 0) degrees += 360;
  return degrees;
}
