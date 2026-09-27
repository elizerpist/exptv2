import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_carousel_wave_motion.dart';

void main() {
  group('Balance carousel wave motion', () {
    test(
      'BWA-STARTUP RED: the physical default enables the ambient wave clock while retaining a user toggle',
      () {
        const defaults = BalancePresentationSettings.defaults();
        expect(defaults.balanceCarouselWaveAnimationEnabled, isTrue);
        final controller = BalancePresentationController(initial: defaults);
        controller.setBalanceCarouselWaveAnimationEnabled(false);
        expect(controller.value.balanceCarouselWaveAnimationEnabled, isFalse);
        controller.dispose();
      },
    );

    test(
      'BWA-PROFILE RED: card identity resolves one stable authored profile',
      () {
        final first = BalanceCarouselWaveMotion.profileForCardId(
          'top-category',
        );
        final rebuilt = BalanceCarouselWaveMotion.profileForCardId(
          'top-category',
        );
        final sideThenCenter = BalanceCarouselWaveMotion.profileForCardId(
          'top-category',
        );

        expect(rebuilt, first);
        expect(sideThenCenter, first);
        expect(first.cardId, 'top-category');
        expect(first.phaseOffset, inInclusiveRange(0.0, 1.0));
      },
    );

    test(
      'BWA-DIVERSITY RED: representative cards resolve distinct authored control geometry at one shared clock time',
      () {
        final leftProfile = BalanceCarouselWaveMotion.profileForCardId(
          'top-partner',
        );
        final centerProfile = BalanceCarouselWaveMotion.profileForCardId(
          'cashflow',
        );
        final rightProfile = BalanceCarouselWaveMotion.profileForCardId(
          'closings',
        );
        final left = BalanceCarouselWaveMotion.geometryFor(
          profile: leftProfile,
          clockPhase: .37,
        );
        final center = BalanceCarouselWaveMotion.geometryFor(
          profile: centerProfile,
          clockPhase: .37,
        );
        final right = BalanceCarouselWaveMotion.geometryFor(
          profile: rightProfile,
          clockPhase: .37,
        );

        expect(
          leftProfile,
          BalanceCarouselWaveMotion.profileForCardId('top-partner'),
        );
        expect(
          centerProfile,
          BalanceCarouselWaveMotion.profileForCardId('cashflow'),
        );
        expect(
          rightProfile,
          BalanceCarouselWaveMotion.profileForCardId('closings'),
        );
        expect(leftProfile.phaseOffset, isNot(centerProfile.phaseOffset));
        expect(centerProfile.phaseOffset, isNot(rightProfile.phaseOffset));
        expect(leftProfile.cadencePhase, isNot(centerProfile.cadencePhase));
        expect(centerProfile.cadencePhase, isNot(rightProfile.cadencePhase));
        expect(
          leftProfile.cadenceAmplitude,
          isNot(centerProfile.cadenceAmplitude),
        );

        expect(
          left.normalizedControlPoints,
          isNot(equals(center.normalizedControlPoints)),
        );
        expect(
          center.normalizedControlPoints,
          isNot(equals(right.normalizedControlPoints)),
        );
        expect(
          left.normalizedControlPoints,
          isNot(equals(right.normalizedControlPoints)),
        );
      },
    );

    test(
      'BWA-SEAM RED: periodic geometry and its near-boundary tangent are continuous across the shared clock loop',
      () {
        final profile = BalanceCarouselWaveMotion.profileForCardId(
          'top-category',
        );
        final start = BalanceCarouselWaveMotion.geometryFor(
          profile: profile,
          clockPhase: 0,
        );
        final end = BalanceCarouselWaveMotion.geometryFor(
          profile: profile,
          clockPhase: 1,
        );
        expect(
          end.normalizedControlPoints,
          equals(start.normalizedControlPoints),
        );

        const epsilon = .00001;
        final forward = BalanceCarouselWaveMotion.geometryFor(
          profile: profile,
          clockPhase: epsilon,
        );
        final beforeEnd = BalanceCarouselWaveMotion.geometryFor(
          profile: profile,
          clockPhase: 1 - epsilon,
        );
        final beginningVelocity = _delta(
          forward.normalizedControlPoints,
          start.normalizedControlPoints,
        );
        final seamVelocity = _delta(
          end.normalizedControlPoints,
          beforeEnd.normalizedControlPoints,
        );
        for (var index = 0; index < beginningVelocity.length; index += 1) {
          expect(
            seamVelocity[index],
            closeTo(beginningVelocity[index], .00001),
          );
        }
      },
    );

    test(
      'BWA-CLIP: authored control geometry stays inside the card interior at representative phases',
      () {
        for (final cardId in <String>['top-partner', 'cashflow', 'closings']) {
          final profile = BalanceCarouselWaveMotion.profileForCardId(cardId);
          for (final phase in <double>[0, .37, .99]) {
            final points = BalanceCarouselWaveMotion.geometryFor(
              profile: profile,
              clockPhase: phase,
            ).normalizedControlPoints;
            for (final point in points) {
              expect(point, inInclusiveRange(0.0, 1.0));
            }
          }
        }
      },
    );

    test(
      'WV-RED: the actual card-sized painted boundary moves materially between distant phases',
      () {
        final profile = BalanceCarouselWaveMotion.profileForCardId('cashflow');
        final early = BalanceCarouselWaveMotion.visibleBoundaryFor(
          profile: profile,
          globalPhase: .02,
          size: const Size(137.6, 79.4),
        );
        final late = BalanceCarouselWaveMotion.visibleBoundaryFor(
          profile: profile,
          globalPhase: .75,
          size: const Size(137.6, 79.4),
        );

        expect(early.localPhase, isNot(late.localPhase));
        expect(early.boundaryHash, isNot(late.boundaryHash));
        expect(
          early.maxVerticalDeltaTo(late),
          greaterThanOrEqualTo(3),
          reason:
              'A changing normalized digest is insufficient: the actual '
              'visible Canvas edge must move by several logical pixels.',
        );
      },
    );
  });
}

List<double> _delta(List<double> later, List<double> earlier) =>
    List<double>.generate(
      later.length,
      (index) => later[index] - earlier[index],
      growable: false,
    );
