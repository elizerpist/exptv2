import 'package:fluvi/core/design/dashboard_border_profile.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SearchPill border contract is the one shared dashboard contour', () {
    const profile = DashboardBorderProfile(DashboardBorderSettings.defaults);

    expect(
      profile.borderFor(DashboardBorderSurface.searchPill),
      const Border.fromBorderSide(
        BorderSide(color: FluviVisualTokens.border, width: 1),
      ),
    );
  });

  test('border defaults preserve each current outer-surface appearance', () {
    const settings = DashboardBorderSettings.defaults;

    expect(settings.isEnabled(DashboardBorderSurface.header), isTrue);
    expect(settings.isEnabled(DashboardBorderSurface.incomeDirection), isFalse);
    expect(
      settings.isEnabled(DashboardBorderSurface.expenseDirection),
      isFalse,
    );
    expect(settings.isEnabled(DashboardBorderSurface.summary), isFalse);
    expect(settings.isEnabled(DashboardBorderSurface.searchPill), isTrue);
    expect(settings.isEnabled(DashboardBorderSurface.balanceContent), isTrue);
    expect(settings.isEnabled(DashboardBorderSurface.mindContent), isTrue);
    expect(settings.isEnabled(DashboardBorderSurface.budgetContent), isTrue);
    expect(settings.isEnabled(DashboardBorderSurface.logBoxGroup), isFalse);
  });

  test('each component border setting is immutable and independent', () {
    const initial = DashboardBorderSettings.defaults;
    final changed = initial.copyWith(
      DashboardBorderSurface.incomeDirection,
      enabled: true,
    );

    expect(changed.isEnabled(DashboardBorderSurface.incomeDirection), isTrue);
    expect(changed.isEnabled(DashboardBorderSurface.expenseDirection), isFalse);
    expect(changed.isEnabled(DashboardBorderSurface.header), isTrue);
    expect(changed.isEnabled(DashboardBorderSurface.searchPill), isTrue);
  });
}
