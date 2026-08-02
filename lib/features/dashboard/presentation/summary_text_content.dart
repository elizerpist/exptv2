import 'package:flutter/foundation.dart';

/// Immutable presentation snapshot for the SummaryPill navigation text.
///
/// This model deliberately lives outside widget files because both the local
/// shell state machine and the presentation intent controller retain it.
@immutable
class SummaryTextContent {
  const SummaryTextContent({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  bool operator ==(Object other) {
    return other is SummaryTextContent &&
        other.title == title &&
        other.subtitle == subtitle;
  }

  @override
  int get hashCode => Object.hash(title, subtitle);
}
