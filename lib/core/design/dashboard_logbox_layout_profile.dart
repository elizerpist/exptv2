import 'package:flutter/foundation.dart';

import 'dashboard_mode_palette.dart';

/// Stepped normalized LogBox row-height preference. Quantization bounds live
/// slider updates to eleven complete geometry generations.
@immutable
final class DashboardLogBoxHeight {
  const DashboardLogBoxHeight._(this.position);

  factory DashboardLogBoxHeight(double position) =>
      DashboardLogBoxHeight._(_quantize(position));

  static const zero = DashboardLogBoxHeight._(0);
  static const one = DashboardLogBoxHeight._(1);
  static const divisions = 10;

  final double position;

  static double _quantize(double raw) {
    final clamped = raw.clamp(0.0, 1.0).toDouble();
    return (clamped * divisions).round() / divisions;
  }

  @override
  bool operator ==(Object other) =>
      other is DashboardLogBoxHeight && other.position == position;

  @override
  int get hashCode => position.hashCode;
}

/// Central geometry profile for every LogBox row/extent consumer.
@immutable
final class DashboardLogBoxLayoutProfile {
  const DashboardLogBoxLayoutProfile(this.height);

  static const baseline = DashboardLogBoxLayoutProfile(
    DashboardLogBoxHeight.zero,
  );

  final DashboardLogBoxHeight height;

  double get rowHeight =>
      DashboardLogBoxTokens.rowHeight * (1 + .5 * height.position);

  @override
  bool operator ==(Object other) =>
      other is DashboardLogBoxLayoutProfile && other.height == height;

  @override
  int get hashCode => height.hashCode;
}
