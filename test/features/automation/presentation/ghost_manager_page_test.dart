import 'dart:async';

import 'package:fluvi/features/automation/domain/automation_models.dart';
import 'package:fluvi/features/automation/domain/automation_repository.dart';
import 'package:fluvi/features/automation/presentation/ghost_manager_page.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/manual_transactions/domain/manual_transaction_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'inline skip admits one mutation, disables its button, and refreshes the committed skipped occurrence',
    (tester) async {
      final repository = _GhostRepository()..skipGate = Completer<void>();
      await tester.pumpWidget(_manager(repository));
      await tester.pumpAndSettle();

      final skip = find.byKey(
        const ValueKey<String>('ghost-skip-occurrence-1'),
      );
      await tester.tap(skip);
      await tester.pump();
      expect(repository.skipCalls, 1);
      expect(tester.widget<IconButton>(skip).onPressed, isNull);

      repository.skipGate!.complete();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(repository.skipCalls, 1);
      expect(find.text('time · skipped'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'inline skip failure keeps Ghost Manager usable and a failed refresh does not repeat the mutation',
    (tester) async {
      final repository = _GhostRepository()..failRefreshAfterSkip = true;
      await tester.pumpWidget(_manager(repository));
      await tester.pumpAndSettle();

      final skip = find.byKey(
        const ValueKey<String>('ghost-skip-occurrence-1'),
      );
      await tester.tap(skip);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(repository.skipCalls, 1);
      expect(
        find.text('Az alkalom kimaradt, de a lista frissítése nem sikerült.'),
        findsOneWidget,
      );
      expect(find.byType(GhostManagerPage), findsOneWidget);
      expect(tester.widget<IconButton>(skip).onPressed, isNotNull);
    },
  );

  testWidgets(
    'detail skip is guarded, returns to the manager, and performs one mutation',
    (tester) async {
      final repository = _GhostRepository()..skipGate = Completer<void>();
      await tester.pumpWidget(_manager(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('occurrence-1 · 12.34 Ft'));
      await tester.pumpAndSettle();
      expect(find.byType(GhostOccurrenceDetailPage), findsOneWidget);

      final skip = find.widgetWithText(OutlinedButton, 'Alkalom kihagyása');
      await tester.tap(skip);
      await tester.pump();
      expect(repository.skipCalls, 1);
      expect(tester.widget<OutlinedButton>(skip).onPressed, isNull);

      repository.skipGate!.complete();
      await tester.pumpAndSettle();

      expect(repository.skipCalls, 1);
      expect(find.byType(GhostManagerPage), findsOneWidget);
      expect(find.byType(GhostOccurrenceDetailPage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a failed initial load presents a retry without discarding UI', (
    tester,
  ) async {
    final repository = _GhostRepository()..failLoad = true;
    await tester.pumpWidget(_manager(repository));
    await tester.pumpAndSettle();

    expect(
      find.text('A Ghost Manager betöltése nem sikerült.'),
      findsOneWidget,
    );
    repository.failLoad = false;
    await tester.tap(find.text('Újrapróbálás'));
    await tester.pumpAndSettle();

    expect(find.text('occurrence-1 · 12.34 Ft'), findsOneWidget);
  });
}

Widget _manager(AutomationRepository repository) =>
    MaterialApp(home: GhostManagerPage(repository: repository));

final class _GhostRepository implements AutomationRepository {
  RecurrenceOccurrenceStatus _status = RecurrenceOccurrenceStatus.pending;
  Completer<void>? skipGate;
  var skipCalls = 0;
  var failLoad = false;
  var failRefreshAfterSkip = false;

  @override
  Future<RecurrenceDashboardSnapshot> recurrenceDashboard() async {
    if (failLoad) throw StateError('dashboard unavailable');
    return RecurrenceDashboardSnapshot(
      rules: const <RecurrenceRule>[],
      pendingCount: _status == RecurrenceOccurrenceStatus.pending ? 1 : 0,
      dueCount: 0,
      realizedCount: 0,
      showPendingGhostsInLedger: true,
    );
  }

  @override
  Future<List<RecurrenceOccurrence>> recurrenceOccurrences({
    RecurrenceOccurrenceStatus? status,
    String? ruleId,
    int? fromUtcMs,
    int? toUtcMs,
    int limit = 100,
    int offset = 0,
  }) async {
    if (failLoad) throw StateError('occurrences unavailable');
    final occurrence = _occurrence(_status);
    if (status != null && status != occurrence.status) {
      return const <RecurrenceOccurrence>[];
    }
    return <RecurrenceOccurrence>[occurrence];
  }

  @override
  Future<void> skipRecurrenceOccurrence(String occurrenceId) async {
    skipCalls += 1;
    await skipGate?.future;
    if (occurrenceId != 'occurrence-1' ||
        _status != RecurrenceOccurrenceStatus.pending) {
      throw StateError('Occurrence is no longer pending.');
    }
    _status = RecurrenceOccurrenceStatus.skipped;
    if (failRefreshAfterSkip) failLoad = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

RecurrenceOccurrence _occurrence(RecurrenceOccurrenceStatus status) =>
    RecurrenceOccurrence(
      occurrenceId: 'occurrence-1',
      ruleId: 'rule-1',
      occurrenceKey: 'occurrence-1',
      expectedLocalEpochDay: 20000,
      expectedLocalTimeMinutes: 540,
      expectedAtUtcMs: 0,
      partnerId: 'partner-1',
      categoryId: 'category-1',
      categoryAssignmentMode: ManualCategoryAssignmentMode.partnerDefault,
      direction: LedgerDirection.expense,
      expectedAmountScaled100: 1234,
      note: null,
      triggerKind: RecurrenceTriggerKind.time,
      status: status,
      realizationKind: null,
    );
