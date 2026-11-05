import 'dart:math' as math;
import 'dart:typed_data';

/// Finite launcher packages need an observed return, not merely a duration
/// derived from one shader control.  This verifier compares the actual last
/// displayed frame with the first frame and calibrates that change against the
/// package's ordinary frame-to-frame motion.
final class DashboardOrbLoopVerifier {
  const DashboardOrbLoopVerifier();

  DashboardOrbLoopValidation validate({
    required List<Uint8List> frames,
    required Iterable<int> candidateFrameCounts,
  }) {
    var considered = 0;
    var valid = 0;
    _Candidate? bestAccepted;
    _Candidate? bestRejected;
    var sawZeroSamples = false;

    for (final count in candidateFrameCounts) {
      if (count < 3 || count > frames.length) continue;
      considered += 1;
      final candidate = _evaluate(frames, count);
      if (candidate == null) {
        sawZeroSamples = true;
        continue;
      }
      valid += 1;
      if (candidate.accepted) {
        if (bestAccepted == null || candidate.score < bestAccepted.score) {
          bestAccepted = candidate;
        }
      } else if (bestRejected == null || candidate.score < bestRejected.score) {
        bestRejected = candidate;
      }
    }

    final accepted = bestAccepted;
    if (accepted != null) {
      return DashboardOrbLoopValidation.accepted(
        frameCount: accepted.frameCount,
        candidateCount: considered,
        validCandidateCount: valid,
        seamMeanRgbDelta: accepted.seam.value,
        seamLimit: accepted.seamLimit,
        motionChangeMeanRgbDelta: accepted.motion.value,
        motionChangeLimit: accepted.motionLimit,
      );
    }
    final closest = bestRejected;
    return DashboardOrbLoopValidation.rejected(
      candidateCount: considered,
      validCandidateCount: valid,
      status: valid == 0 && sawZeroSamples
          ? DashboardOrbLoopStatus.noValidSamples
          : DashboardOrbLoopStatus.rejected,
      seamMeanRgbDelta: closest?.seam.value,
      seamLimit: closest?.seamLimit,
      motionChangeMeanRgbDelta: closest?.motion.value,
      motionChangeLimit: closest?.motionLimit,
    );
  }

  _Candidate? _evaluate(List<Uint8List> frames, int count) {
    final steps = <_RgbMetric>[];
    for (var index = 0; index < count - 1; index += 1) {
      final step = _meanRgbDelta(frames[index], frames[index + 1]);
      if (step == null) return null;
      steps.add(step);
    }
    final seam = _meanRgbDelta(frames[count - 1], frames.first);
    if (seam == null) return null;

    final internalMotion = <_RgbMetric>[];
    for (var index = 1; index < count - 1; index += 1) {
      final change = _meanRgbVelocityChange(
        frames[index - 1],
        frames[index],
        frames[index + 1],
      );
      if (change == null) return null;
      internalMotion.add(change);
    }
    final seamMotion = _meanRgbVelocityChange(
      frames[count - 1],
      frames.first,
      frames[1],
    );
    if (seamMotion == null || internalMotion.isEmpty) return null;

    final ordinaryStep = _median(steps.map((step) => step.value));
    final neighbouringStep = math.max(steps.first.value, steps.last.value);
    final seamLimit = math.max(
      1.25,
      math.max(ordinaryStep, neighbouringStep) * 1.35,
    );
    final ordinaryMotion = _median(
      internalMotion.map((change) => change.value),
    );
    final motionLimit = math.max(1.5, ordinaryMotion * 1.5);
    final accepted = seam.value <= seamLimit && seamMotion.value <= motionLimit;
    return _Candidate(
      frameCount: count,
      seam: seam,
      seamLimit: seamLimit,
      motion: seamMotion,
      motionLimit: motionLimit,
      accepted: accepted,
    );
  }

  static _RgbMetric? _meanRgbDelta(Uint8List first, Uint8List second) {
    if (first.length != second.length || first.length % 4 != 0) return null;
    var total = 0;
    var samples = 0;
    for (var index = 0; index < first.length; index += 4) {
      if (first[index + 3] == 0 || second[index + 3] == 0) continue;
      total += (first[index] - second[index]).abs();
      total += (first[index + 1] - second[index + 1]).abs();
      total += (first[index + 2] - second[index + 2]).abs();
      samples += 3;
    }
    return samples == 0 ? null : _RgbMetric(total / samples, samples);
  }

  static _RgbMetric? _meanRgbVelocityChange(
    Uint8List previous,
    Uint8List current,
    Uint8List next,
  ) {
    if (previous.length != current.length ||
        current.length != next.length ||
        previous.length % 4 != 0) {
      return null;
    }
    var total = 0;
    var samples = 0;
    for (var index = 0; index < previous.length; index += 4) {
      if (previous[index + 3] == 0 ||
          current[index + 3] == 0 ||
          next[index + 3] == 0) {
        continue;
      }
      for (var channel = 0; channel < 3; channel += 1) {
        final before = current[index + channel] - previous[index + channel];
        final after = next[index + channel] - current[index + channel];
        total += (after - before).abs();
        samples += 1;
      }
    }
    return samples == 0 ? null : _RgbMetric(total / samples, samples);
  }

  static double _median(Iterable<double> values) {
    final sorted = values.toList()..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }
}

enum DashboardOrbLoopStatus { accepted, rejected, noValidSamples }

final class DashboardOrbLoopValidation {
  const DashboardOrbLoopValidation._({
    required this.status,
    required this.frameCount,
    required this.candidateCount,
    required this.validCandidateCount,
    required this.seamMeanRgbDelta,
    required this.seamLimit,
    required this.motionChangeMeanRgbDelta,
    required this.motionChangeLimit,
  });

  factory DashboardOrbLoopValidation.accepted({
    required int frameCount,
    required int candidateCount,
    required int validCandidateCount,
    required double seamMeanRgbDelta,
    required double seamLimit,
    required double motionChangeMeanRgbDelta,
    required double motionChangeLimit,
  }) => DashboardOrbLoopValidation._(
    status: DashboardOrbLoopStatus.accepted,
    frameCount: frameCount,
    candidateCount: candidateCount,
    validCandidateCount: validCandidateCount,
    seamMeanRgbDelta: seamMeanRgbDelta,
    seamLimit: seamLimit,
    motionChangeMeanRgbDelta: motionChangeMeanRgbDelta,
    motionChangeLimit: motionChangeLimit,
  );

  factory DashboardOrbLoopValidation.rejected({
    required int candidateCount,
    required int validCandidateCount,
    required DashboardOrbLoopStatus status,
    double? seamMeanRgbDelta,
    double? seamLimit,
    double? motionChangeMeanRgbDelta,
    double? motionChangeLimit,
  }) => DashboardOrbLoopValidation._(
    status: status,
    frameCount: null,
    candidateCount: candidateCount,
    validCandidateCount: validCandidateCount,
    seamMeanRgbDelta: seamMeanRgbDelta,
    seamLimit: seamLimit,
    motionChangeMeanRgbDelta: motionChangeMeanRgbDelta,
    motionChangeLimit: motionChangeLimit,
  );

  final DashboardOrbLoopStatus status;
  final int? frameCount;
  final int candidateCount;
  final int validCandidateCount;
  final double? seamMeanRgbDelta;
  final double? seamLimit;
  final double? motionChangeMeanRgbDelta;
  final double? motionChangeLimit;

  bool get accepted => status == DashboardOrbLoopStatus.accepted;
}

final class _Candidate {
  const _Candidate({
    required this.frameCount,
    required this.seam,
    required this.seamLimit,
    required this.motion,
    required this.motionLimit,
    required this.accepted,
  });

  final int frameCount;
  final _RgbMetric seam;
  final double seamLimit;
  final _RgbMetric motion;
  final double motionLimit;
  final bool accepted;

  double get score => seam.value / seamLimit + motion.value / motionLimit;
}

final class _RgbMetric {
  const _RgbMetric(this.value, this.samples);

  final double value;
  final int samples;
}
