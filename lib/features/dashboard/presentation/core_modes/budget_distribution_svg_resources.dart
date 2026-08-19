import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/prepared_dynamic_vector_picture.dart';

import 'budget_category_distribution_svg.dart';

/// Renderer-cache owner shared by every Budget Card2 donut page. It uses only
/// flutter_svg's public loader/cache API, so first user exposure never needs
/// to parse a just-created source.
abstract interface class BudgetDistributionSvgPrewarmer {
  Future<void> prewarm(Iterable<String> sources);
}

final class FlutterBudgetDistributionSvgPrewarmer
    implements BudgetDistributionSvgPrewarmer {
  const FlutterBudgetDistributionSvgPrewarmer();

  @override
  Future<void> prewarm(Iterable<String> sources) async {
    for (final source in sources) {
      await SvgStringLoader(source).loadBytes(null);
    }
  }
}

/// Budget aliases preserve the feature's explicit frame ownership while the
/// renderer decode/painter mechanism has one core implementation.
typedef BudgetDistributionPreparedPicture = PreparedDynamicVectorPicture;
typedef BudgetDistributionPicturePreparer = DynamicVectorPicturePreparer;
typedef FlutterBudgetDistributionPicturePreparer =
    FlutterDynamicVectorPicturePreparer;
typedef BudgetDistributionPreparedPictureView =
    PreparedDynamicVectorPictureView;

/// Production SVG source authority shared by category and partner. The
/// selected index is null for the read-only Partner page.
abstract interface class BudgetDistributionSvgSourceGenerator {
  String generate({
    required List<BudgetCategoryDistributionSvgSlice> slices,
    required int? selectedIndex,
  });
}

final class FluviBudgetDistributionSvgSourceGenerator
    implements BudgetDistributionSvgSourceGenerator {
  const FluviBudgetDistributionSvgSourceGenerator();

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

/// Compatibility names retained for the existing category visual-bank public
/// API. Both aliases resolve to the single production implementation above.
typedef BudgetCategoryDistributionSvgPrewarmer = BudgetDistributionSvgPrewarmer;
typedef FlutterSvgBudgetCategoryDistributionPrewarmer =
    FlutterBudgetDistributionSvgPrewarmer;
typedef BudgetCategoryDistributionSvgSourceGenerator =
    BudgetDistributionSvgSourceGenerator;
typedef FluviBudgetCategoryDistributionSvgSourceGenerator =
    FluviBudgetDistributionSvgSourceGenerator;
