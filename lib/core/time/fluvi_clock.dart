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
