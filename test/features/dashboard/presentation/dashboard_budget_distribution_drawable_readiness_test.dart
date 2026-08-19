import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_category_distribution_controller.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_distribution_visual_bank.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_partner_distribution_snapshot.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

void main() {
  test(
    'publishes a target period only after its exact SVG bank is renderer ready',
    () async {
      final prewarmer = _ControlledPrewarmer();
      final controller = DashboardBudgetDistributionDrawableController(
        categories: ValueNotifier<List<FluviCategory>>(<FluviCategory>[
          _category('food'),
          _category('unused'),
        ]),
        snapshot: _snapshot(),
        prewarmer: prewarmer,
      );
      addTearDown(controller.dispose);

      final month = await controller.prepare(
        const BudgetLimitPeriod.month(2026, 1),
      );
      controller.publish(month);
      expect(
        controller.value!.semanticBundle.key.diagnosticLabel,
        'month:2026-01',
      );

      final coldYear = controller.prepare(const BudgetLimitPeriod.year(2026));
      await Future<void>.microtask(() {});

      expect(
        controller.value!.semanticBundle.key.diagnosticLabel,
        'month:2026-01',
        reason: 'the old coherent frame remains visible during prewarm',
      );
      expect(prewarmer.pending, hasLength(1));

      prewarmer.pending.single.complete();
      final year = await coldYear;
      controller.publish(year);

      expect(controller.value!.semanticBundle.key.diagnosticLabel, 'year:2026');
      expect(
        identical(
          controller.value!.semanticBundle,
          controller.value!.visualBank.semanticBundle,
        ),
        isTrue,
        reason: 'semantic values and renderer-ready SVG share one identity.',
      );
    },
  );

  test(
    'treats category and partner SVG banks as one drawable time identity',
    () async {
      final prewarmer = _CapturingPrewarmer();
      final controller = DashboardBudgetDistributionDrawableController(
        categories: ValueNotifier<List<FluviCategory>>(<FluviCategory>[
          _category('food'),
          _category('unused'),
        ]),
        snapshot: _snapshot(),
        partnerSnapshotForCurrentFrame: _partnerSnapshot,
        prewarmer: prewarmer,
      );
      addTearDown(controller.dispose);

      final preparation = controller.prepare(
        const BudgetLimitPeriod.month(2026, 1),
      );
      await Future<void>.microtask(() {});

      expect(controller.value, isNull);
      expect(prewarmer.pending, hasLength(1));
      expect(prewarmer.pending.single.sources, hasLength(6));

      prewarmer.pending.single.completer.complete();
      final frame = await preparation;
      expect(frame.hasPartnerDrawable, isTrue);
      expect(
        frame.partnerSemanticBundle!.key.diagnosticLabel,
        frame.semanticBundle.key.diagnosticLabel,
      );
      expect(frame.partnerVisualBank!.variantCount, 2);
    },
  );

  test(
    'a target prewarm failure retains the last coherent drawable frame',
    () async {
      final controller = DashboardBudgetDistributionDrawableController(
        categories: ValueNotifier<List<FluviCategory>>(<FluviCategory>[
          _category('food'),
          _category('unused'),
        ]),
        snapshot: _snapshot(),
        prewarmer: _FailingSecondPrewarmer(),
      );
      addTearDown(controller.dispose);

      final month = await controller.prepare(
        const BudgetLimitPeriod.month(2026, 1),
      );
      controller.publish(month);

      expect(
        await controller.prepareForTimeScope(const YearScope(2026)),
        isFalse,
      );
      expect(
        controller.value!.semanticBundle.key.diagnosticLabel,
        'month:2026-01',
        reason: 'an error may not expose an empty or mixed Card2 frame.',
      );
    },
  );

  test(
    'background period hotset never supersedes a foreground target prewarm',
    () async {
      final prewarmer = _ControlledPrewarmer();
      final controller = DashboardBudgetDistributionDrawableController(
        categories: ValueNotifier<List<FluviCategory>>(<FluviCategory>[
          _category('food'),
          _category('unused'),
        ]),
        snapshot: _snapshot(),
        prewarmer: prewarmer,
      );
      addTearDown(controller.dispose);
      final month = await controller.prepare(
        const BudgetLimitPeriod.month(2026, 1),
      );
      controller.publish(month);

      final target = controller.prepare(const BudgetLimitPeriod.year(2026));
      final targetExpectation = expectLater(target, completes);
      final navigation = DashboardNavigationController(
        initialDate: DateTime(2026, 1, 14),
        initialPlane: TimePlane.month,
        initialDirection: LedgerDirection.expense,
      );
      unawaited(controller.warmHotsetFor(navigation.state));
      await Future<void>.microtask(() {});

      expect(
        prewarmer.pending,
        hasLength(1),
        reason:
            'maintenance must yield while a real navigation target owns preparation.',
      );
      prewarmer.pending.single.complete();
      await targetExpectation;
    },
  );

  test(
    'the latest foreground period supersedes a queued stale target',
    () async {
      final prewarmer = _ControlledPrewarmer();
      final controller = DashboardBudgetDistributionDrawableController(
        categories: ValueNotifier<List<FluviCategory>>(<FluviCategory>[
          _category('food'),
          _category('unused'),
        ]),
        snapshot: _snapshot(),
        prewarmer: prewarmer,
      );
      addTearDown(controller.dispose);
      final month = await controller.prepare(
        const BudgetLimitPeriod.month(2026, 1),
      );
      controller.publish(month);

      final staleYear = controller.prepare(const BudgetLimitPeriod.year(2026));
      final latestSum = controller.prepare(const BudgetLimitPeriod.sum());
      await Future<void>.microtask(() {});

      expect(
        prewarmer.pending,
        hasLength(1),
        reason: 'only one renderer prewarm may own the resource at a time.',
      );
      prewarmer.pending.single.complete();
      await expectLater(staleYear, throwsA(isA<StateError>()));
      await Future<void>.microtask(() {});

      expect(prewarmer.pending, hasLength(2));
      prewarmer.pending.last.complete();
      final sum = await latestSum;
      expect(sum.semanticBundle.key.diagnosticLabel, 'sum');
    },
  );
}

final class _ControlledPrewarmer
    implements BudgetCategoryDistributionSvgPrewarmer {
  var calls = 0;
  final List<Completer<void>> pending = <Completer<void>>[];

  @override
  Future<void> prewarm(Iterable<String> sources) {
    calls += 1;
    if (calls == 1) return Future<void>.value();
    final completer = Completer<void>();
    pending.add(completer);
    return completer.future;
  }
}

final class _FailingSecondPrewarmer
    implements BudgetCategoryDistributionSvgPrewarmer {
  var calls = 0;

  @override
  Future<void> prewarm(Iterable<String> sources) {
    calls += 1;
    return calls == 1
        ? Future<void>.value()
        : Future<void>.error(StateError('Injected SVG prewarm failure.'));
  }
}

final class _CapturingPrewarmer
    implements BudgetCategoryDistributionSvgPrewarmer {
  final List<_PendingPrewarm> pending = <_PendingPrewarm>[];

  @override
  Future<void> prewarm(Iterable<String> sources) {
    final next = _PendingPrewarm(sources.toList(growable: false));
    pending.add(next);
    return next.completer.future;
  }
}

final class _PendingPrewarm {
  _PendingPrewarm(this.sources);

  final List<String> sources;
  final Completer<void> completer = Completer<void>();
}

FluviCategory _category(String id) => FluviCategory(
  id: id,
  name: id,
  colorId: 'color_01',
  iconId: 'icon_01',
  isSystemUncategorized: false,
  createdAtUtcMs: 1,
  updatedAtUtcMs: 1,
);

PreparedBudgetLimitSnapshot _snapshot() => PreparedBudgetLimitSnapshot(
  coreRevision: 7,
  yearWindowStart: 2026,
  yearWindowEndInclusive: 2026,
  incomeBank: _bank(const <int>[0, 0, 0]),
  expenseBank: _bank(const <int>[300, 200, 100]),
);

PreparedBudgetPartnerDistributionSnapshot _partnerSnapshot() {
  const zero = PreparedBudgetPartnerDistributionCell(
    actualScaled100: 0,
    dominantCategoryId: '',
  );
  const positive = PreparedBudgetPartnerDistributionCell(
    actualScaled100: 100,
    dominantCategoryId: 'food',
  );
  PreparedBudgetPartnerDistributionDirectionBank bank(String id) =>
      PreparedBudgetPartnerDistributionDirectionBank(
        orderedPartnerIds: <String>[id],
        orderedPartnerTitles: <String>[id],
        cells: <PreparedBudgetPartnerDistributionCell>[
          zero,
          zero,
          positive,
          for (var index = 0; index < 11; index += 1) zero,
        ],
      );
  return PreparedBudgetPartnerDistributionSnapshot(
    coreRevision: 7,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: bank('income-partner'),
    expenseBank: bank('expense-partner'),
  );
}

PreparedBudgetLimitDirectionBank _bank(List<int> values) {
  final cells = List<PreparedBudgetLimitCell>.filled(
    14 * values.length,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  for (final slice in <int>[0, 1, 2]) {
    for (var handle = 0; handle < values.length; handle += 1) {
      cells[slice * values.length + handle] = PreparedBudgetLimitCell(
        actualScaled100: values[handle],
        limitScaled100: null,
      );
    }
  }
  return PreparedBudgetLimitDirectionBank(
    orderedCategoryIds: const <String>['food', 'unused'],
    cells: cells,
  );
}
