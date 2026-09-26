import 'dart:math' as math;

/// The small authored family keeps Balance carousel decoration broad and soft
/// while the stable card identity prevents a wave from changing when its card
/// moves between side and center positions.
enum BalanceCarouselWaveFamily { leftRise, centerCrest, lateRise }

/// Immutable identity-derived variation for one Balance carousel card.
final class BalanceCarouselWaveProfile {
  const BalanceCarouselWaveProfile._({
    required this.cardId,
    required this.family,
    required this.phaseOffset,
    required this.cadencePhase,
    required this.cadenceAmplitude,
    required this.shapeBias,
    required this.amplitudeScale,
  });

  final String cardId;
  final BalanceCarouselWaveFamily family;

  /// A stable circular phase offset makes visible cards move asynchronously.
  final double phaseOffset;

  /// A periodic local timing warp provides gentle cadence variation without
  /// breaking the phase-zero/one loop seam.
  final double cadencePhase;
  final double cadenceAmplitude;

  /// Small bounded identity variation inside an authored family.
  final double shapeBias;
  final double amplitudeScale;

  @override
  bool operator ==(Object other) =>
      other is BalanceCarouselWaveProfile &&
      other.cardId == cardId &&
      other.family == family &&
      other.phaseOffset == phaseOffset &&
      other.cadencePhase == cadencePhase &&
      other.cadenceAmplitude == cadenceAmplitude &&
      other.shapeBias == shapeBias &&
      other.amplitudeScale == amplitudeScale;

  @override
  int get hashCode => Object.hash(
    cardId,
    family,
    phaseOffset,
    cadencePhase,
    cadenceAmplitude,
    shapeBias,
    amplitudeScale,
  );
}

/// Normalized cubic points for the lower filled wave. The order is start,
/// first cubic's two controls/end, then second cubic's two controls/end.
final class BalanceCarouselWaveGeometry {
  BalanceCarouselWaveGeometry(List<double> normalizedControlPoints)
    : normalizedControlPoints = List<double>.unmodifiable(
        normalizedControlPoints,
      );

  final List<double> normalizedControlPoints;
}

/// Pure identity-to-wave resolver. It has no ticker, Flutter widgets, carousel
/// index or selection input, so it is deterministic across rebuilds.
abstract final class BalanceCarouselWaveMotion {
  static const _twoPi = math.pi * 2;

  static BalanceCarouselWaveProfile profileForCardId(String cardId) {
    final hash = _stableHash(cardId);
    final family = BalanceCarouselWaveFamily
        .values[hash % BalanceCarouselWaveFamily.values.length];
    final phaseOffset = _unit(_mix(hash ^ 0x6D2B79F5));
    final cadencePhase = _unit(_mix(hash ^ 0x1B873593)) * _twoPi;
    return BalanceCarouselWaveProfile._(
      cardId: cardId,
      family: family,
      phaseOffset: phaseOffset,
      cadencePhase: cadencePhase,
      cadenceAmplitude: .018 + _unit(_mix(hash ^ 0x85EBCA6B)) * .016,
      shapeBias: (_unit(_mix(hash ^ 0xC2B2AE35)) - .5) * .018,
      amplitudeScale: .86 + _unit(_mix(hash ^ 0x27D4EB2F)) * .22,
    );
  }

  /// All terms are periodic over a unit clock. At phase 0 and phase 1 both
  /// the geometry and its first derivative are equal, so a forward repeating
  /// controller has no rendered reset seam.
  static BalanceCarouselWaveGeometry geometryFor({
    required BalanceCarouselWaveProfile profile,
    required double clockPhase,
  }) {
    final clock = _wrap(clockPhase);
    final warpedClock = _wrap(
      clock +
          profile.phaseOffset +
          profile.cadenceAmplitude *
              math.sin(_twoPi * clock + profile.cadencePhase),
    );
    final angle = _twoPi * warpedClock;
    final primary = math.sin(angle);
    final secondary = math.sin(angle * 2 + profile.cadencePhase);
    final late = math.cos(angle - profile.cadencePhase * .5);
    final family = _familyGeometry(profile.family);
    final amplitude = .026 * profile.amplitudeScale;
    final bias = profile.shapeBias;

    return BalanceCarouselWaveGeometry(<double>[
      0,
      family.startY + primary * amplitude + bias * .35,
      family.firstControlX + secondary * .008 + bias,
      family.firstControlY + primary * amplitude * .62 - late * .008,
      family.secondControlX - late * .007 - bias * .5,
      family.secondControlY - primary * amplitude * .76 + secondary * .009,
      family.firstEndX + primary * .006,
      family.firstEndY + late * amplitude * .7 - bias * .25,
      family.trailingFirstControlX - secondary * .008 + bias * .4,
      family.trailingFirstControlY + primary * amplitude * .54,
      family.trailingSecondControlX + late * .006 - bias,
      family.trailingSecondControlY - primary * amplitude * .68,
      1,
      family.endY + secondary * amplitude * .58 + bias * .4,
    ]);
  }

  static _WaveFamilyGeometry _familyGeometry(
    BalanceCarouselWaveFamily family,
  ) => switch (family) {
    BalanceCarouselWaveFamily.leftRise => const _WaveFamilyGeometry(
      startY: .78,
      firstControlX: .22,
      firstControlY: .64,
      secondControlX: .47,
      secondControlY: .97,
      firstEndX: .68,
      firstEndY: .72,
      trailingFirstControlX: .82,
      trailingFirstControlY: .58,
      trailingSecondControlX: .93,
      trailingSecondControlY: .78,
      endY: .66,
    ),
    BalanceCarouselWaveFamily.centerCrest => const _WaveFamilyGeometry(
      startY: .84,
      firstControlX: .19,
      firstControlY: .75,
      secondControlX: .46,
      secondControlY: .54,
      firstEndX: .66,
      firstEndY: .68,
      trailingFirstControlX: .79,
      trailingFirstControlY: .80,
      trailingSecondControlX: .93,
      trailingSecondControlY: .72,
      endY: .78,
    ),
    BalanceCarouselWaveFamily.lateRise => const _WaveFamilyGeometry(
      startY: .73,
      firstControlX: .23,
      firstControlY: .61,
      secondControlX: .47,
      secondControlY: .955,
      firstEndX: .65,
      firstEndY: .82,
      trailingFirstControlX: .80,
      trailingFirstControlY: .72,
      trailingSecondControlX: .94,
      trailingSecondControlY: .50,
      endY: .61,
    ),
  };

  static int _stableHash(String value) {
    var hash = 0x811C9DC5;
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193).toUnsigned(32);
    }
    return hash;
  }

  static int _mix(int value) {
    var next = value.toUnsigned(32);
    next = ((next ^ (next >> 16)) * 0x7FEB352D).toUnsigned(32);
    next = ((next ^ (next >> 15)) * 0x846CA68B).toUnsigned(32);
    return (next ^ (next >> 16)).toUnsigned(32);
  }

  static double _unit(int value) => value.toUnsigned(32) / 0x100000000;

  static double _wrap(double value) {
    if (!value.isFinite) return 0;
    return value - value.floorToDouble();
  }
}

final class _WaveFamilyGeometry {
  const _WaveFamilyGeometry({
    required this.startY,
    required this.firstControlX,
    required this.firstControlY,
    required this.secondControlX,
    required this.secondControlY,
    required this.firstEndX,
    required this.firstEndY,
    required this.trailingFirstControlX,
    required this.trailingFirstControlY,
    required this.trailingSecondControlX,
    required this.trailingSecondControlY,
    required this.endY,
  });

  final double startY;
  final double firstControlX;
  final double firstControlY;
  final double secondControlX;
  final double secondControlY;
  final double firstEndX;
  final double firstEndY;
  final double trailingFirstControlX;
  final double trailingFirstControlY;
  final double trailingSecondControlX;
  final double trailingSecondControlY;
  final double endY;
}
