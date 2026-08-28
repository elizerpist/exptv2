import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/budget_section_order.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_summary_presentation.dart';

void main() {
  test(
    'Summary presentation defaults preserve the current visual contract',
    () {
      final controller = DashboardSummaryPresentationController();
      addTearDown(controller.dispose);

      expect(controller.value.showSeparators, isTrue);
      expect(
        controller.value.temporalFlingPresentation,
        SummaryTemporalFlingPresentation.current,
      );
      expect(
        controller.value.segmentedOrientation,
        SummarySegmentedOrientation.normal,
      );
    },
  );

  test('Summary presentation controls and Budget order are independent', () {
    final summary = DashboardSummaryPresentationController();
    final order = BudgetSectionOrderController();
    addTearDown(summary.dispose);
    addTearDown(order.dispose);

    summary
      ..setSeparatorsVisible(false)
      ..selectTemporalFlingPresentation(
        SummaryTemporalFlingPresentation.dynamicTrio,
      )
      ..selectSegmentedOrientation(SummarySegmentedOrientation.mirrored);
    order.select(BudgetSectionOrder.chartThenAvatars);

    expect(summary.value.showSeparators, isFalse);
    expect(
      summary.value.temporalFlingPresentation,
      SummaryTemporalFlingPresentation.dynamicTrio,
    );
    expect(
      summary.value.segmentedOrientation,
      SummarySegmentedOrientation.mirrored,
    );
    expect(order.value, BudgetSectionOrder.chartThenAvatars);

    summary.reset();
    expect(
      summary.value.segmentedOrientation,
      SummarySegmentedOrientation.normal,
    );
    expect(order.value, BudgetSectionOrder.chartThenAvatars);
  });

  test('Dynamic Trio scale is continuous and center-proximity ordered', () {
    const height = 50.0;
    expect(
      SummaryDynamicTrioGeometry.offsetsFor(rawIndex: 0, isMoving: false),
      <int>[0],
    );
    expect(
      SummaryDynamicTrioGeometry.offsetsFor(rawIndex: .5, isMoving: true),
      <int>[0, 1, 2],
    );

    final atCenter = SummaryDynamicTrioGeometry.itemFor(
      height: height,
      offset: 0,
      rawIndex: 0,
    );
    final outgoingAtQuarter = SummaryDynamicTrioGeometry.itemFor(
      height: height,
      offset: 0,
      rawIndex: .25,
    );
    final incomingAtQuarter = SummaryDynamicTrioGeometry.itemFor(
      height: height,
      offset: 1,
      rawIndex: .25,
    );
    final outgoingAtThreeQuarter = SummaryDynamicTrioGeometry.itemFor(
      height: height,
      offset: 0,
      rawIndex: .75,
    );
    final incomingAtThreeQuarter = SummaryDynamicTrioGeometry.itemFor(
      height: height,
      offset: 1,
      rawIndex: .75,
    );

    expect(atCenter.scale, SummaryDynamicTrioGeometry.maxScale);
    expect(
      outgoingAtQuarter.scale,
      greaterThan(outgoingAtThreeQuarter.scale),
      reason: 'the outgoing value shrinks continuously away from center',
    );
    expect(
      incomingAtQuarter.scale,
      lessThan(incomingAtThreeQuarter.scale),
      reason: 'the incoming value grows continuously toward center',
    );
    expect(
      incomingAtThreeQuarter.scale,
      greaterThan(outgoingAtThreeQuarter.scale),
      reason: 'the closer item may never be smaller than the farther item',
    );
  });
}
