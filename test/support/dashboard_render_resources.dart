import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';

/// Prepares the same DPR-specific render-critical resources that production
/// gates behind DashboardInteractionReadiness.
Future<void> prepareDashboardTestRenderResources() async {
  final atlas = PreparedVectorAssetAtlas.instance;
  await atlas.prepare();
  await atlas.prepareLogBoxRasters(devicePixelRatio: 3);
}
