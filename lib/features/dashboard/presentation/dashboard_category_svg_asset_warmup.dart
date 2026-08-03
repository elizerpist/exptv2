import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/categories/catalog/category_icon_catalog.dart';

/// Presentation-only cache warming for the few category icons that can become
/// visible immediately around the selected dashboard rail child.
abstract final class DashboardCategorySvgAssetWarmup {
  static Set<String> assetPathsFor(Iterable<String> iconIds) => <String>{
    for (final iconId in iconIds) CategoryIconCatalog.resolve(iconId).assetPath,
  };

  static Future<void> warm(BuildContext context, Iterable<String> iconIds) {
    return Future.wait(
      assetPathsFor(
        iconIds,
      ).map((assetPath) => SvgAssetLoader(assetPath).loadBytes(context)),
    );
  }
}
