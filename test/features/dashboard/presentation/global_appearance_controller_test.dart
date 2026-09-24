import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/fluvi_global_appearance.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('global appearance mutations are independent and retain one ticker', () {
    final controller = DashboardHeaderVisualController(
      vsync: const TestVSync(),
    );
    addTearDown(controller.dispose);

    final ticker = controller.tickerIdentity;
    final initialGeneration = controller.tuning.value.generation;
    expect(
      controller.tuning.value.globalAppearance,
      const FluviGlobalAppearance.defaults(),
    );

    controller.setDirectionColorProfile(FluviDirectionColorProfile.vivid);
    expect(
      controller.tuning.value.globalAppearance.directionColorProfile,
      FluviDirectionColorProfile.vivid,
    );
    expect(
      controller.tuning.value.globalAppearance.avatarColorProfile,
      CategoryAvatarColorProfile.original,
    );

    controller.setAvatarColorProfile(CategoryAvatarColorProfile.pastel);
    controller.setShowsDirectionArtwork(false);
    controller.setGlobalTypography(FluviTypographyProfile.colorLab);
    expect(
      controller.tuning.value.globalAppearance,
      const FluviGlobalAppearance(
        directionColorProfile: FluviDirectionColorProfile.vivid,
        avatarColorProfile: CategoryAvatarColorProfile.pastel,
        showsDirectionArtwork: false,
        typography: FluviTypographyProfile.colorLab,
      ),
    );
    expect(controller.tuning.value.generation, initialGeneration + 4);
    expect(controller.tickerIdentity, same(ticker));
  });
}
