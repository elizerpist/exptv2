import 'dart:async';

/// Minimal local wall-clock boundary for features whose semantics genuinely
/// follow the device calendar instead of a dashboard navigation selection.
abstract interface class FluviClock {
  const FluviClock();

  DateTime now();
}

/// Production clock. [DateTime.now] is intentionally local because callers
/// that use this boundary own local calendar semantics.
final class SystemFluviClock implements FluviClock {
  const SystemFluviClock();

  @override
  DateTime now() => DateTime.now();
}

/// The core-owned, cancellable scheduling seam for a local-calendar rollover.
///
/// Dashboard projection code receives this as a dependency: timing itself does
/// not decide whether a presentation state is correct. Keeping the concrete
/// timer here also lets a caller test a date-boundary transition without wall
/// time.
typedef FluviRolloverScheduler =
    FluviCancellable Function(Duration delay, void Function() callback);

typedef FluviCancellable = void Function();

final class SystemFluviRolloverScheduler {
  const SystemFluviRolloverScheduler();

  FluviCancellable schedule(Duration delay, void Function() callback) {
    final timer = Timer(delay, callback);
    return timer.cancel;
  }
}
