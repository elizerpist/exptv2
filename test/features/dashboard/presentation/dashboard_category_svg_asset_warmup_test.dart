import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_category_svg_asset_warmup.dart';

void main() {
  test('deduplicates resolved category SVG asset paths', () {
    final paths = DashboardCategorySvgAssetWarmup.assetPathsFor(const [
      'icon_01',
      'icon_01',
      'missing-icon',
    ]);

    expect(paths, <String>{'assets/category_icons/shirt.svg'});
  });
}
