import 'package:flutter/foundation.dart';

enum DashboardAmountUpdateMode { directPreview, semanticAnimated, noOp }

@immutable
class DashboardAmountUpdateDecision {
  const DashboardAmountUpdateDecision({
    required this.mode,
    required this.duration,
    required this.animationStarted,
    required this.presentationNotify,
  });

  final DashboardAmountUpdateMode mode;
  final Duration duration;
  final bool animationStarted;
  final bool presentationNotify;
}

abstract final class DashboardAmountUpdatePolicy {
  static const animationDuration = Duration(milliseconds: 120);

  static DashboardAmountUpdateDecision resolve({
    required int? previousAmount,
    required int? targetAmount,
    required bool isPreview,
    required bool isRailMotionActive,
    bool requiresDirectReplacement = false,
  }) {
    if (previousAmount == targetAmount) {
      return const DashboardAmountUpdateDecision(
        mode: DashboardAmountUpdateMode.noOp,
        duration: Duration.zero,
        animationStarted: false,
        presentationNotify: false,
      );
    }
    if (isPreview || isRailMotionActive || requiresDirectReplacement) {
      return const DashboardAmountUpdateDecision(
        mode: DashboardAmountUpdateMode.directPreview,
        duration: Duration.zero,
        animationStarted: false,
        presentationNotify: true,
      );
    }
    return const DashboardAmountUpdateDecision(
      mode: DashboardAmountUpdateMode.semanticAnimated,
      duration: animationDuration,
      animationStarted: true,
      presentationNotify: true,
    );
  }
}
