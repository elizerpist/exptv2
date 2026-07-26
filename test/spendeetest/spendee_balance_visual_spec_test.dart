import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_visual_spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    '0726 permanent Balance source-of-truth grid is frozen at 412 by 892',
    () {
      expect(SpendeeBalanceVisualSpec.viewport, const Size(412, 892));
      expect(SpendeeBalanceVisualSpec.canvas, const Size(410, 890));
      expect(SpendeeBalanceVisualSpec.screenBorderWidth, 1);
      expect(SpendeeBalanceVisualSpec.screenRadius, 34);
      expect(SpendeeBalanceVisualSpec.contentWidth, 378);
      expect(SpendeeBalanceVisualSpec.pageBackground, const Color(0xFFF1F5F9));
      expect(SpendeeBalanceVisualSpec.horizontalInset, 16);
      expect(SpendeeBalanceVisualSpec.brandTop, 48);
      expect(SpendeeBalanceVisualSpec.heroTop, 104);
      expect(SpendeeBalanceVisualSpec.heroExpandedHeight, 126);
      expect(SpendeeBalanceVisualSpec.heroCollapsedHeight, 104);
      expect(SpendeeBalanceVisualSpec.menuTop, 118);
      expect(SpendeeBalanceVisualSpec.menuRight, 36);
      expect(SpendeeBalanceVisualSpec.insightTop, 241);
      expect(SpendeeBalanceVisualSpec.insightHeight, 104);
      expect(SpendeeBalanceVisualSpec.detailTop, 356);
      expect(SpendeeBalanceVisualSpec.detailStageHeight, 218);
      expect(SpendeeBalanceVisualSpec.detailCardHeight, 208);
      expect(SpendeeBalanceVisualSpec.detailPaginationGap, 4);
      expect(SpendeeBalanceVisualSpec.actionTop, 585);
      expect(SpendeeBalanceVisualSpec.actionHeight, 42);
      expect(SpendeeBalanceVisualSpec.summaryTop, 638);
      expect(SpendeeBalanceVisualSpec.summaryHeight, 59);
      expect(SpendeeBalanceVisualSpec.searchTop, 708);
      expect(SpendeeBalanceVisualSpec.searchHeight, 39);
      expect(SpendeeBalanceVisualSpec.timeRailTop, 758);
      expect(SpendeeBalanceVisualSpec.timeRailHeight, 79);
      expect(SpendeeBalanceVisualSpec.bottomNavHeight, 80);
      expect(
        SpendeeBalanceVisualSpec.detailTop +
            SpendeeBalanceVisualSpec.detailStageHeight +
            SpendeeBalanceVisualSpec.stackGap,
        SpendeeBalanceVisualSpec.actionTop,
        reason: 'the 208px card stage must never overlap the action pills',
      );
    },
  );

  test('hero and FAB gradients preserve exact colors and stops', () {
    final hero = SpendeeBalanceVisualSpec.heroGradient;
    final fab = SpendeeBalanceVisualSpec.fabGradient;
    final heroLine = hero.endpointsFor(const Rect.fromLTWH(0, 0, 378, 126));
    final fabLine = fab.endpointsFor(const Rect.fromLTWH(0, 0, 58, 58));

    expect(hero.cssDegrees, 118);
    expect(heroLine.start.dx, closeTo(15.53, .05));
    expect(heroLine.start.dy, closeTo(-29.20, .05));
    expect(heroLine.end.dx, closeTo(362.47, .05));
    expect(heroLine.end.dy, closeTo(155.20, .05));
    expect(hero.colors, const [
      Color(0xFF8079E9),
      Color(0xFFA879EE),
      Color(0xFFE985D9),
      Color(0xFFFF8CAD),
    ]);
    expect(hero.stops, const [0, .38, .69, 1]);

    expect(fab.cssDegrees, 140);
    expect(fabLine.start.dx, closeTo(2.74, .05));
    expect(fabLine.start.dy, closeTo(-2.30, .05));
    expect(fabLine.end.dx, closeTo(55.26, .05));
    expect(fabLine.end.dy, closeTo(60.30, .05));
    expect(fab.colors, const [
      Color(0xFF6065F5),
      Color(0xFF8C5CEF),
      Color(0xFFF25CBF),
    ]);
    expect(fab.stops, const [0, .52, 1]);
  });

  test('exact component geometry does not inherit Material defaults', () {
    expect(SpendeeBalanceVisualSpec.heroRadius, 24);
    expect(SpendeeBalanceVisualSpec.insightGap, 9);
    expect(SpendeeBalanceVisualSpec.detailDotInactive, 4);
    expect(SpendeeBalanceVisualSpec.detailDotActive, 6);
    expect(SpendeeBalanceVisualSpec.actionSideInset, 4);
    expect(SpendeeBalanceVisualSpec.actionGap, 10);
    expect(SpendeeBalanceVisualSpec.actionRadius, 16);
    expect(SpendeeBalanceVisualSpec.summaryRadius, 20);
    expect(
      SpendeeBalanceVisualSpec.summarySettleDuration,
      const Duration(milliseconds: 160),
    );
    expect(SpendeeBalanceVisualSpec.searchGap, 9);
    expect(SpendeeBalanceVisualSpec.filterWidth, 40);
    expect(SpendeeBalanceVisualSpec.filterRadius, 17);
    expect(SpendeeBalanceVisualSpec.handleSize, const Size(92, 21));
    expect(SpendeeBalanceVisualSpec.handleBarSize, const Size(22, 3));
    expect(SpendeeBalanceVisualSpec.timeRailViewportHeight, 37);
    expect(SpendeeBalanceVisualSpec.timeRailSlotDistance, 69.2);
    expect(SpendeeBalanceVisualSpec.timeRailVisibleLogicalDistance, 2);
    expect(SpendeeBalanceVisualSpec.yearPillSize, const Size(49, 30));
    expect(SpendeeBalanceVisualSpec.activeYearPillSize, const Size(68, 37));
    expect(SpendeeBalanceVisualSpec.railDotSize, 5);
    expect(SpendeeBalanceVisualSpec.dayCardRadius, 18);
    expect(SpendeeBalanceVisualSpec.transactionRowMinHeight, 55);
    expect(SpendeeBalanceVisualSpec.transactionAvatarSize, 34);
    expect(SpendeeBalanceVisualSpec.transactionEditSize, 24);
  });

  test('Inter variable weights preserve authored 750 850 and 950 values', () {
    expect(SpendeeBalanceVisualSpec.weight750.single.axis, 'wght');
    expect(SpendeeBalanceVisualSpec.weight750.single.value, 750);
    expect(SpendeeBalanceVisualSpec.weight850.single.axis, 'wght');
    expect(SpendeeBalanceVisualSpec.weight850.single.value, 850);
    expect(SpendeeBalanceVisualSpec.weight950.single.axis, 'wght');
    expect(SpendeeBalanceVisualSpec.weight950.single.value, 950);
  });
}
