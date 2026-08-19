import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../application/dashboard_budget_category_distribution_controller.dart';
import '../../query/domain/ledger_direction.dart';
import 'budget_category_distribution_svg.dart';

abstract interface class BudgetCategoryDistributionSvgPrewarmer {
  Future<void> prewarm(Iterable<String> sources);
}

/// Uses flutter_svg 2.3's public [SvgStringLoader.loadBytes] API. That loader
/// stores the encoded vector source in the public global `svg.cache`, so a
/// later `SvgPicture.string` with the same source does not parse SVG anew.
final class FlutterSvgBudgetCategoryDistributionPrewarmer
    implements BudgetCategoryDistributionSvgPrewarmer {
  const FlutterSvgBudgetCategoryDistributionPrewarmer();

  @override
  Future<void> prewarm(Iterable<String> sources) async {
    for (final source in sources) {
      await SvgStringLoader(source).loadBytes(null);
    }
  }
}

abstract interface class BudgetCategoryDistributionSvgSourceGenerator {
  String generate({
    required List<BudgetCategoryDistributionSvgSlice> slices,
    required int? selectedIndex,
  });
}

final class FluviBudgetCategoryDistributionSvgSourceGenerator
    implements BudgetCategoryDistributionSvgSourceGenerator {
  const FluviBudgetCategoryDistributionSvgSourceGenerator();

  @override
  String generate({
    required List<BudgetCategoryDistributionSvgSlice> slices,
    required int? selectedIndex,
  }) => BudgetCategoryDistributionSvg.flutterRenderable(
    BudgetCategoryDistributionSvg.clayDonut(
      slices: slices,
      selectedIndex: selectedIndex,
    ),
  );
}

@immutable
final class DashboardBudgetCategoryDistributionVisualFrame {
  DashboardBudgetCategoryDistributionVisualFrame({
    required this.semanticFrame,
    required List<String> svgVariants,
    required List<int> variantIndexByTargetHandle,
  }) : svgVariants = List<String>.unmodifiable(svgVariants),
       variantIndexByTargetHandle = List<int>.unmodifiable(
         variantIndexByTargetHandle,
       );

  final DashboardBudgetCategoryDistributionDirectionFrame semanticFrame;
  final List<String> svgVariants;
  final List<int> variantIndexByTargetHandle;

  String svgForTargetHandle(int targetHandle) {
    final variant =
        targetHandle >= 0 && targetHandle < variantIndexByTargetHandle.length
        ? variantIndexByTargetHandle[targetHandle]
        : 0;
    return svgVariants[variant];
  }

  int variantIndexForTargetHandle(int targetHandle) =>
      targetHandle >= 0 && targetHandle < variantIndexByTargetHandle.length
      ? variantIndexByTargetHandle[targetHandle]
      : 0;
}

@immutable
final class DashboardBudgetCategoryDistributionVisualBank {
  DashboardBudgetCategoryDistributionVisualBank({
    required this.semanticBundle,
    required this.income,
    required this.expense,
    required this.sourceBytes,
  });

  final DashboardBudgetCategoryDistributionBundle semanticBundle;
  final DashboardBudgetCategoryDistributionVisualFrame income;
  final DashboardBudgetCategoryDistributionVisualFrame expense;
  final int sourceBytes;

  int get variantCount =>
      income.svgVariants.length + expense.svgVariants.length;
  int get estimatedRetainedBytes =>
      sourceBytes +
      (income.variantIndexByTargetHandle.length +
              expense.variantIndexByTargetHandle.length) *
          4;

  DashboardBudgetCategoryDistributionVisualFrame frameFor(
    LedgerDirection direction,
  ) => switch (direction) {
    LedgerDirection.income => income,
    LedgerDirection.expense => expense,
  };

  Iterable<String> get allSources sync* {
    yield* income.svgVariants;
    yield* expense.svgVariants;
  }

  factory DashboardBudgetCategoryDistributionVisualBank.prepare({
    required DashboardBudgetCategoryDistributionBundle semanticBundle,
    required BudgetCategoryDistributionSvgSourceGenerator sourceGenerator,
  }) {
    DashboardBudgetCategoryDistributionVisualFrame buildFrame(
      DashboardBudgetCategoryDistributionDirectionFrame frame,
    ) {
      final slices = List<BudgetCategoryDistributionSvgSlice>.unmodifiable([
        for (final entry in frame.entries)
          BudgetCategoryDistributionSvgSlice(
            label: entry.title,
            value: entry.actualScaled100,
            color: CategoryColorCatalog.resolve(entry.colorId).middleColor,
          ),
      ]);
      final variants = <String>[
        sourceGenerator.generate(slices: slices, selectedIndex: null),
        for (var index = 0; index < frame.entries.length; index += 1)
          sourceGenerator.generate(slices: slices, selectedIndex: index),
      ];
      final variantByHandle = List<int>.filled(frame.targetCount, 0);
      for (var slice = 0; slice < frame.entries.length; slice += 1) {
        variantByHandle[frame.entries[slice].targetHandle] = slice + 1;
      }
      return DashboardBudgetCategoryDistributionVisualFrame(
        semanticFrame: frame,
        svgVariants: variants,
        variantIndexByTargetHandle: variantByHandle,
      );
    }

    final income = buildFrame(semanticBundle.income);
    final expense = buildFrame(semanticBundle.expense);
    final bytes =
        income.svgVariants.fold<int>(
          0,
          (sum, source) => sum + utf8.encode(source).length,
        ) +
        expense.svgVariants.fold<int>(
          0,
          (sum, source) => sum + utf8.encode(source).length,
        );
    return DashboardBudgetCategoryDistributionVisualBank(
      semanticBundle: semanticBundle,
      income: income,
      expense: expense,
      sourceBytes: bytes,
    );
  }
}

/// Bounded renderer-resource owner. Selection is intentionally not an input:
/// all source variants are ready before this bank becomes visible.
final class DashboardBudgetCategoryDistributionVisualBankController
    extends ValueNotifier<DashboardBudgetCategoryDistributionVisualBank?> {
  DashboardBudgetCategoryDistributionVisualBankController({
    required ValueListenable<DashboardBudgetCategoryDistributionBundle?>
    bundles,
    BudgetCategoryDistributionSvgPrewarmer? prewarmer,
    BudgetCategoryDistributionSvgSourceGenerator? sourceGenerator,
    this.maximumBanks = 3,
  }) : _bundles = bundles,
       _prewarmer =
           prewarmer ?? const FlutterSvgBudgetCategoryDistributionPrewarmer(),
       _sourceGenerator =
           sourceGenerator ??
           const FluviBudgetCategoryDistributionSvgSourceGenerator(),
       assert(maximumBanks > 0),
       super(null) {
    _bundles.addListener(_prepareCurrentBundle);
    _prepareCurrentBundle();
  }

  final ValueListenable<DashboardBudgetCategoryDistributionBundle?> _bundles;
  final BudgetCategoryDistributionSvgPrewarmer _prewarmer;
  final BudgetCategoryDistributionSvgSourceGenerator _sourceGenerator;
  final int maximumBanks;
  final LinkedHashMap<
    DashboardBudgetCategoryDistributionKey,
    DashboardBudgetCategoryDistributionVisualBank
  >
  _banks =
      LinkedHashMap<
        DashboardBudgetCategoryDistributionKey,
        DashboardBudgetCategoryDistributionVisualBank
      >();
  int _prepareGeneration = 0;
  int sourceGenerationCount = 0;
  int rendererPrewarmCount = 0;
  int evictionCount = 0;

  int get retainedBankCount => _banks.length;

  Future<void> _prepareCurrentBundle() async {
    final bundle = _bundles.value;
    final generation = ++_prepareGeneration;
    if (bundle == null) {
      if (value != null) value = null;
      return;
    }
    final retained = _banks.remove(bundle.key);
    if (retained != null && identical(retained.semanticBundle, bundle)) {
      _banks[bundle.key] = retained;
      if (!identical(value, retained)) value = retained;
      return;
    }
    final watch = Stopwatch()..start();
    final bank = DashboardBudgetCategoryDistributionVisualBank.prepare(
      semanticBundle: bundle,
      sourceGenerator: _sourceGenerator,
    );
    sourceGenerationCount += bank.variantCount;
    final sourceGenerationMicros = watch.elapsedMicroseconds;
    await _prewarmer.prewarm(bank.allSources);
    if (generation != _prepareGeneration ||
        !identical(_bundles.value, bundle)) {
      return;
    }
    rendererPrewarmCount += bank.variantCount;
    _banks[bundle.key] = bank;
    while (_banks.length > maximumBanks) {
      _banks.remove(_banks.keys.first);
      evictionCount += 1;
    }
    watch.stop();
    // The semantic controller logs source-domain counts; renderer ownership
    // adds bounded visual-cache information once per prepared bundle.
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_DISTRIBUTION_READY',
        coreRevision: bank.semanticBundle.key.coreRevision,
        entryCount: bank.variantCount,
        durationMs: watch.elapsedMilliseconds,
        scope:
            '${bank.semanticBundle.key.diagnosticLabel} '
            'incomeCategoryCount=${bank.semanticBundle.income.targetCount - 1} '
            'expenseCategoryCount=${bank.semanticBundle.expense.targetCount - 1} '
            'incomePositiveSliceCount=${bank.semanticBundle.income.entries.length} '
            'expensePositiveSliceCount=${bank.semanticBundle.expense.entries.length} '
            'incomeTotalScaled100=${bank.semanticBundle.income.totalCategoryActualScaled100} '
            'expenseTotalScaled100=${bank.semanticBundle.expense.totalCategoryActualScaled100} '
            'projectionMicros=${bank.semanticBundle.projectionMicros} '
            'svgVariantCount=${bank.variantCount} '
            'svgSourceBytes=${bank.sourceBytes} '
            'svgGenerationMicros=$sourceGenerationMicros '
            'svgPrewarmMicros=${watch.elapsedMicroseconds} '
            'estimatedRetainedBytes=${bank.estimatedRetainedBytes}',
      ),
    );
    value = bank;
  }

  @override
  void dispose() {
    _prepareGeneration += 1;
    _bundles.removeListener(_prepareCurrentBundle);
    super.dispose();
  }
}
