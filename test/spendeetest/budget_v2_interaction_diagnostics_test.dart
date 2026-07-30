import 'package:exptv2/features/transactions/widgets/experimental/budget_v2/budget_v2_interaction_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('retains sanitized bounded final summaries only', () {
    final diagnostics = BudgetV2InteractionDiagnostics(maximumRecords: 2);

    final first = diagnostics.begin(
      sourceRevision: 11,
      recordCount: 4096,
      barCount: 5,
    );
    first.recordPhysicalFrame();
    first.recordPhysicalFrame();
    first.recordDirectQueryWork(
      resolveCount: 3,
      cacheMissCount: 2,
      projectionCount: 2,
    );
    first.complete(
      settledIndex: 2,
      commitCount: 1,
      finalCommitDuration: const Duration(milliseconds: 7),
    );
    final firstDiagnostic = diagnostics.records.single;
    expect(
      firstDiagnostic.trace,
      allOf(
        contains('direct_query_cache_resolves=3'),
        contains('direct_query_cache_misses=2'),
        contains('direct_log_projections=2'),
      ),
    );

    diagnostics
        .begin(sourceRevision: -1, recordCount: -4, barCount: -3)
        .complete(
          settledIndex: -2,
          commitCount: -1,
          finalCommitDuration: const Duration(microseconds: -1),
        );
    diagnostics
        .begin(sourceRevision: 12, recordCount: 4096, barCount: 5)
        .cancel(settledIndex: 1);

    expect(diagnostics.records, hasLength(2));
    expect(
      diagnostics.records.first,
      const BudgetV2InteractionDiagnostic(
        sourceRevision: 0,
        recordCount: 0,
        barCount: 0,
        physicalFrameCount: 0,
        settledIndex: 0,
        commitCount: 0,
        finalCommitDuration: Duration.zero,
        outcome: BudgetV2InteractionOutcome.committed,
      ),
    );
    expect(
      diagnostics.records.last,
      const BudgetV2InteractionDiagnostic(
        sourceRevision: 12,
        recordCount: 4096,
        barCount: 5,
        physicalFrameCount: 0,
        settledIndex: 1,
        commitCount: 0,
        finalCommitDuration: Duration.zero,
        outcome: BudgetV2InteractionOutcome.cancelled,
      ),
    );
  });
}
