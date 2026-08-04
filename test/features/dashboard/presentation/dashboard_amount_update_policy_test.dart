import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_amount_update_policy.dart';

void main() {
  test('equal rail preview amount is a no-op with zero duration', () {
    final decision = DashboardAmountUpdatePolicy.resolve(
      previousAmount: 80000,
      targetAmount: 80000,
      isPreview: true,
      isRailMotionActive: true,
    );

    expect(decision.mode, DashboardAmountUpdateMode.noOp);
    expect(decision.duration, Duration.zero);
    expect(decision.animationStarted, isFalse);
    expect(decision.presentationNotify, isFalse);
  });

  test('changed rail preview amount uses direct update with zero duration', () {
    final decision = DashboardAmountUpdatePolicy.resolve(
      previousAmount: 80000,
      targetAmount: 81000,
      isPreview: true,
      isRailMotionActive: true,
    );

    expect(decision.mode, DashboardAmountUpdateMode.directPreview);
    expect(decision.duration, Duration.zero);
    expect(decision.animationStarted, isFalse);
    expect(decision.presentationNotify, isTrue);
  });

  test('non-motion changed amount remains eligible for semantic animation', () {
    final decision = DashboardAmountUpdatePolicy.resolve(
      previousAmount: 80000,
      targetAmount: 81000,
      isPreview: false,
      isRailMotionActive: false,
    );

    expect(decision.mode, DashboardAmountUpdateMode.semanticAnimated);
    expect(decision.duration, const Duration(milliseconds: 120));
    expect(decision.animationStarted, isTrue);
    expect(decision.presentationNotify, isTrue);
  });
}
