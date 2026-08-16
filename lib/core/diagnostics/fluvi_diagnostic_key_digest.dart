/// A bounded, deterministic representation for large internal cache keys.
///
/// Cache keys retain their full exact identity in memory. Diagnostic paths use
/// this digest so logging a rejected month/day candidate cannot allocate or
/// serialize a user-visible copy of its entire identity on an input turn.
abstract final class FluviDiagnosticKeyDigest {
  static String of(String value) {
    var hash = 0x811c9dc5;
    for (var index = 0; index < value.length; index += 1) {
      hash = (hash ^ value.codeUnitAt(index)) * 0x01000193 & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
