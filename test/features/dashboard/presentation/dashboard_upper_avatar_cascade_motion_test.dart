import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/header_cascade_motion.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_upper_avatar_cascade_motion.dart';

void main() {
  test(
    'upper avatar retiming preserves endpoints and leaves lower cascade raw',
    () {
      const samples = [0.0, .05, .10, .20, .35, .50, .65, .80, .95, 1.0];
      for (final separation in samples) {
        final frame = DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: DashboardModeSpec.balance,
          collapseProgress:
              separation * DashboardLayoutMetrics.reference.collapseTravel,
          isRailExpanded: false,
        );
        final retimed = DashboardUpperAvatarCascadeMotion.resolve(frame);
        final raw = frame.motherCardCascade.upper;
        final expectedLower = HeaderCascadeMotion.calculate(
          masterProgress: frame.headerExpansionProgress,
          geometry: frame.motherCardCascadeGeometry,
        ).lower;

        expect(
          DashboardUpperAvatarCascadeMotion.retimedSeparation(separation),
          separation == 0 || separation == 1
              ? separation
              : lessThan(separation),
        );
        expect(
          retimed.progress,
          closeTo(
            1 - DashboardUpperAvatarCascadeMotion.retimedSeparation(separation),
            1e-8,
          ),
        );
        expect(
          frame.motherCardCascade.lower.top,
          closeTo(expectedLower.top, 1e-8),
        );
        expect(
          frame.motherCardCascade.lower.opacity,
          closeTo(expectedLower.opacity, 1e-8),
        );
        expect(
          frame.motherCardCascade.lower.scale,
          closeTo(expectedLower.scale, 1e-8),
        );

        if (separation > 0 && separation < 1) {
          expect(retimed.progress, greaterThan(raw.progress));
          expect(retimed.opacity, greaterThan(raw.opacity));
          expect(retimed.top, greaterThan(raw.top));
        }
      }
    },
  );
}
