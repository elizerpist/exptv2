import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_distribution_visual_bank.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_partner_distribution_snapshot.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test('publishes one exact coherent scope scene identity', () async {
    final controller = _controller();
    addTearDown(controller.dispose);

    final month = await controller.prepareForScope(
      MonthScope(YearMonth(year: 2026, month: 1)),
    );
    controller.publish(month, source: 'railPreview');

    expect(
      controller.value!.semanticBundle.analysisScope.canonicalKey,
      'month:2026-01',
    );
    expect(
      controller.value!.partnerSemanticBundle!.analysisScope.canonicalKey,
      'month:2026-01',
    );
    expect(
      identical(month.semanticBundle, month.visualBank.semanticBundle),
      isTrue,
    );
    expect(month.hasPartnerDrawable, isTrue);
  });

  test('target and partner selection are retained scene lookups', () async {
    final controller = _controller();
    addTearDown(controller.dispose);
    final frame = await controller.prepareForScope(
      MonthScope(YearMonth(year: 2026, month: 1)),
    );
    final builds = controller.sceneBuildCount;
    final source = controller.sourceGenerationCount;
    final decode = controller.pictureDecodeCount;

    for (final handle in <int>[0, 1, 2, 1, 0]) {
      frame.visualBank
          .frameFor(LedgerDirection.expense)
          .sliceIndexForTargetHandle(handle);
      frame.partnerVisualBank!
          .frameFor(LedgerDirection.expense, targetHandle: handle)
          .selectedSliceIndexForPartnerId('expense-a');
    }

    expect(controller.sceneBuildCount, builds);
    expect(controller.sourceGenerationCount, source);
    expect(controller.pictureDecodeCount, decode);
    expect(controller.rendererPrewarmCount, 0);
    expect(controller.retainedPictureCount, 0);
  });

  test('bounded scene cache evicts nonvisible exact scope', () async {
    final controller = _controller(maximumFrames: 2);
    addTearDown(controller.dispose);
    final month = await controller.prepareForScope(
      MonthScope(YearMonth(year: 2026, month: 1)),
    );
    controller.publish(month);
    await controller.prepareForScope(const YearScope(2026));
    await controller.prepareForScope(const AllTimeScope());

    expect(controller.retainedFrameCount, 2);
    expect(controller.evictionCount, 1);
    expect(
      controller.value!.semanticBundle.analysisScope.canonicalKey,
      'month:2026-01',
    );
    expect(controller.estimatedRetainedBytes, greaterThan(0));
  });

  test('the visible temporal preview hotset publishes a sibling month while '
      'foreground fling motion is active', () async {
    var foregroundMotion = false;
    final controller = _controller(
      isForegroundInputActive: () => foregroundMotion,
    );
    addTearDown(controller.dispose);
    const year = YearScope(2026);
    const january = MonthScope(YearMonth(year: 2026, month: 1));
    const february = MonthScope(YearMonth(year: 2026, month: 2));

    await controller.warmHotsetForPreviewScope(
      parentScope: year,
      siblingScopes: const <LedgerTimeScope>[january, february],
    );
    foregroundMotion = true;

    expect(
      controller.publishIfReadyForTimeScope(february),
      isTrue,
      reason:
          'A cache-hot visible preview must bind Card2 synchronously; '
          'foreground motion may suppress only a cache miss.',
    );
    expect(
      controller.value!.semanticBundle.analysisScope.canonicalKey,
      february.canonicalKey,
    );
  });
}

DashboardBudgetDistributionDrawableController _controller({
  int maximumFrames = 40,
  bool Function()? isForegroundInputActive,
}) {
  final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
    _category('food'),
    _category('unused'),
  ]);
  return DashboardBudgetDistributionDrawableController(
    categories: categories,
    snapshot: _snapshot(),
    partnerSnapshotForCurrentFrame: _partnerSnapshot,
    maximumFrames: maximumFrames,
    isForegroundInputActive: isForegroundInputActive,
  );
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
  PreparedBudgetPartnerDistributionDirectionBank bank(String id) =>
      PreparedBudgetPartnerDistributionDirectionBank(
        orderedPartnerIds: <String>[id],
        orderedPartnerTitles: <String>[id],
        cells: <PreparedBudgetPartnerDistributionCell>[
          for (var index = 0; index < 14; index += 1)
            PreparedBudgetPartnerDistributionCell(
              actualScaled100: 100,
              dominantCategoryId: 'food',
            ),
        ],
        orderedCategoryIds: const <String>['food', 'unused'],
        categoryContributionOffsets: <int>[
          for (var index = 0; index < 29; index += 1) (index + 1) ~/ 2,
        ],
        categoryContributions: <PreparedBudgetPartnerCategoryContribution>[
          for (var index = 0; index < 14; index += 1)
            PreparedBudgetPartnerCategoryContribution(
              partnerHandle: 0,
              actualScaled100: 100,
            ),
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
