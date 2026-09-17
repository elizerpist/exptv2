import 'package:flutter/foundation.dart';

/// Expense-only mathematical alternatives for Mind's canonical daily score
/// series. Income deliberately does not use this setting.
enum MindExpenseScoreAlgorithm {
  htmlCentered,
  htmlTrailing,
  causalTrailing;

  String get tunerLabel => switch (this) {
    MindExpenseScoreAlgorithm.htmlCentered => 'HTML · centered',
    MindExpenseScoreAlgorithm.htmlTrailing => 'HTML · trailing',
    MindExpenseScoreAlgorithm.causalTrailing => 'Kauzális · trailing',
  };
}

/// The warm-up boundary for the causal Expense algorithm only.
enum MindCausalHistoryOrigin {
  selectedScopeStart,
  fullFilteredHistory;

  String get tunerLabel => switch (this) {
    MindCausalHistoryOrigin.selectedScopeStart => 'Scope elejétől',
    MindCausalHistoryOrigin.fullFilteredHistory => 'Teljes korábbi történet',
  };
}

/// Immutable semantic settings published independently of visual Header
/// tuning and of canonical Query state. [revision] makes the accepted setting
/// generation explicit in score-publication provenance.
@immutable
final class MindBehavioralScoreSettings {
  const MindBehavioralScoreSettings({
    required this.expenseAlgorithm,
    required this.causalHistoryOrigin,
    required this.revision,
  });

  const MindBehavioralScoreSettings.defaults()
    : expenseAlgorithm = MindExpenseScoreAlgorithm.causalTrailing,
      causalHistoryOrigin = MindCausalHistoryOrigin.fullFilteredHistory,
      revision = 0;

  final MindExpenseScoreAlgorithm expenseAlgorithm;
  final MindCausalHistoryOrigin causalHistoryOrigin;
  final int revision;

  bool get usesCausalHistory =>
      expenseAlgorithm == MindExpenseScoreAlgorithm.causalTrailing;

  MindBehavioralScoreSettings copyWith({
    MindExpenseScoreAlgorithm? expenseAlgorithm,
    MindCausalHistoryOrigin? causalHistoryOrigin,
    int? revision,
  }) => MindBehavioralScoreSettings(
    expenseAlgorithm: expenseAlgorithm ?? this.expenseAlgorithm,
    causalHistoryOrigin: causalHistoryOrigin ?? this.causalHistoryOrigin,
    revision: revision ?? this.revision,
  );

  @override
  bool operator ==(Object other) =>
      other is MindBehavioralScoreSettings &&
      other.expenseAlgorithm == expenseAlgorithm &&
      other.causalHistoryOrigin == causalHistoryOrigin &&
      other.revision == revision;

  @override
  int get hashCode =>
      Object.hash(expenseAlgorithm, causalHistoryOrigin, revision);
}

/// The single state owner for Expense-score presentation semantics. Widgets
/// collect intent only; Core owns the listener that rebuilds/publishes its
/// resident score projection.
final class MindBehavioralScoreSettingsController
    extends ValueNotifier<MindBehavioralScoreSettings> {
  MindBehavioralScoreSettingsController({MindBehavioralScoreSettings? initial})
    : super(initial ?? const MindBehavioralScoreSettings.defaults());

  void setExpenseAlgorithm(MindExpenseScoreAlgorithm algorithm) {
    final current = value;
    if (current.expenseAlgorithm == algorithm) return;
    value = current.copyWith(
      expenseAlgorithm: algorithm,
      revision: current.revision + 1,
    );
  }

  void setCausalHistoryOrigin(MindCausalHistoryOrigin origin) {
    final current = value;
    if (current.causalHistoryOrigin == origin) return;
    value = current.copyWith(
      causalHistoryOrigin: origin,
      revision: current.revision + 1,
    );
  }
}
