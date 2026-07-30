import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../../../core/debug/debug_console.dart';

/// Sanitized, interaction-scoped Budget V2 diagnostic data.
///
/// This contains only counts, indexes, a revision fingerprint, and duration.
/// It intentionally has no record, amount, category, merchant, or avatar data.
@immutable
class BudgetV2InteractionDiagnostic {
  const BudgetV2InteractionDiagnostic({
    required this.sourceRevision,
    required this.recordCount,
    required this.barCount,
    required this.physicalFrameCount,
    required this.settledIndex,
    required this.commitCount,
    required this.finalCommitDuration,
    required this.outcome,
    this.directSnapshotResolveCount = 0,
    this.directSnapshotPreparationCount = 0,
  });

  final int sourceRevision;
  final int recordCount;
  final int barCount;
  final int physicalFrameCount;
  final int settledIndex;
  final int commitCount;
  final Duration finalCommitDuration;
  final BudgetV2InteractionOutcome outcome;
  final int directSnapshotResolveCount;
  final int directSnapshotPreparationCount;

  @override
  bool operator ==(Object other) =>
      other is BudgetV2InteractionDiagnostic &&
      sourceRevision == other.sourceRevision &&
      recordCount == other.recordCount &&
      barCount == other.barCount &&
      physicalFrameCount == other.physicalFrameCount &&
      settledIndex == other.settledIndex &&
      commitCount == other.commitCount &&
      finalCommitDuration == other.finalCommitDuration &&
      outcome == other.outcome &&
      directSnapshotResolveCount == other.directSnapshotResolveCount &&
      directSnapshotPreparationCount == other.directSnapshotPreparationCount;

  @override
  int get hashCode => Object.hash(
    sourceRevision,
    recordCount,
    barCount,
    physicalFrameCount,
    settledIndex,
    commitCount,
    finalCommitDuration,
    outcome,
    directSnapshotResolveCount,
    directSnapshotPreparationCount,
  );

  String get trace =>
      '[BudgetV2Interaction] '
      'outcome=${outcome.name} '
      'source_revision=$sourceRevision '
      'record_count=$recordCount '
      'bar_count=$barCount '
      'physical_frames=$physicalFrameCount '
      'settled_index=$settledIndex '
      'commit_count=$commitCount '
      'final_commit_us=${finalCommitDuration.inMicroseconds} '
      'direct_snapshot_resolves=$directSnapshotResolveCount '
      'direct_snapshot_preparations=$directSnapshotPreparationCount';
}

enum BudgetV2InteractionOutcome { committed, cancelled }

/// Owns a bounded history of final interaction summaries.
class BudgetV2InteractionDiagnostics {
  BudgetV2InteractionDiagnostics({this.maximumRecords = 16})
    : assert(maximumRecords > 0);

  final int maximumRecords;
  final Queue<BudgetV2InteractionDiagnostic> _records =
      Queue<BudgetV2InteractionDiagnostic>();

  List<BudgetV2InteractionDiagnostic> get records =>
      List<BudgetV2InteractionDiagnostic>.unmodifiable(_records);

  BudgetV2InteractionSession begin({
    required int sourceRevision,
    required int recordCount,
    required int barCount,
  }) => BudgetV2InteractionSession._(
    owner: this,
    sourceRevision: sourceRevision < 0 ? 0 : sourceRevision,
    recordCount: recordCount < 0 ? 0 : recordCount,
    barCount: barCount < 0 ? 0 : barCount,
  );

  void _append(BudgetV2InteractionDiagnostic diagnostic) {
    _records.add(diagnostic);
    while (_records.length > maximumRecords) {
      _records.removeFirst();
    }
    DebugConsole.log(diagnostic.trace);
  }
}

/// A local rail/dashboard interaction that publishes exactly one final record.
class BudgetV2InteractionSession {
  BudgetV2InteractionSession._({
    required BudgetV2InteractionDiagnostics owner,
    required int sourceRevision,
    required int recordCount,
    required int barCount,
  }) : _owner = owner,
       _sourceRevision = sourceRevision,
       _recordCount = recordCount,
       _barCount = barCount;

  final BudgetV2InteractionDiagnostics _owner;
  final int _sourceRevision;
  final int _recordCount;
  final int _barCount;
  var _physicalFrameCount = 0;
  var _directSnapshotResolveCount = 0;
  var _directSnapshotPreparationCount = 0;
  var _complete = false;

  void recordPhysicalFrame() {
    if (!_complete) _physicalFrameCount += 1;
  }

  void recordPhysicalFrames(int count) {
    if (!_complete && count > 0) _physicalFrameCount += count;
  }

  void recordDirectSnapshotWork({
    required int resolveCount,
    required int preparationCount,
  }) {
    if (_complete) return;
    _directSnapshotResolveCount = resolveCount < 0 ? 0 : resolveCount;
    _directSnapshotPreparationCount = preparationCount < 0
        ? 0
        : preparationCount;
  }

  void complete({
    required int settledIndex,
    required int commitCount,
    required Duration finalCommitDuration,
  }) => _finish(
    settledIndex: settledIndex,
    commitCount: commitCount,
    finalCommitDuration: finalCommitDuration,
    outcome: BudgetV2InteractionOutcome.committed,
  );

  void cancel({required int settledIndex}) => _finish(
    settledIndex: settledIndex,
    commitCount: 0,
    finalCommitDuration: Duration.zero,
    outcome: BudgetV2InteractionOutcome.cancelled,
  );

  void _finish({
    required int settledIndex,
    required int commitCount,
    required Duration finalCommitDuration,
    required BudgetV2InteractionOutcome outcome,
  }) {
    if (_complete) return;
    _complete = true;
    _owner._append(
      BudgetV2InteractionDiagnostic(
        sourceRevision: _sourceRevision,
        recordCount: _recordCount,
        barCount: _barCount,
        physicalFrameCount: _physicalFrameCount,
        settledIndex: settledIndex < 0 ? 0 : settledIndex,
        commitCount: commitCount < 0 ? 0 : commitCount,
        finalCommitDuration: finalCommitDuration.isNegative
            ? Duration.zero
            : finalCommitDuration,
        outcome: outcome,
        directSnapshotResolveCount: _directSnapshotResolveCount,
        directSnapshotPreparationCount: _directSnapshotPreparationCount,
      ),
    );
  }
}
