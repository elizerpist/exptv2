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
    expect(
      controller.tuning.value.globalAppearance.mindExpandedSurfaceStyle,
      MindExpandedSurfaceStyle.seamlessCard,
      reason: 'Fresh expanded Mind now joins Header and content by default.',
    );
    expect(
      controller.tuning.value.globalAppearance.fabIconPresentation,
      FluviFabIconPresentation.directionArtwork,
    );
    expect(
      controller.tuning.value.globalAppearance.fabVectorPrimaryArgb,
      0xFF715EFB,
    );
    expect(
      controller.tuning.value.globalAppearance.fabVectorHighlightArgb,
      0xFFE2D7FF,
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
    controller.setFabIconPresentation(
      FluviFabIconPresentation.legacyWhiteStore,
    );
    controller.setFabVectorPrimaryArgb(0xFF5533CC);
    controller.setFabVectorHighlightArgb(0xFFD8CCFF);
    controller.setGlobalTypography(FluviTypographyProfile.colorLab);
    controller.setDirectionControlStyle(FluviDirectionControlStyle.slidingRail);
    controller.setCollapseHandleStyle(
      FluviCollapseHandleStyle.headerTranslucentPill,
    );
    controller.setActiveDirectionLabelTone(FluviActiveDirectionLabelTone.black);
    controller.setInactiveDirectionLabelTone(
      FluviInactiveDirectionLabelTone.black,
    );
    controller.setShowsHeaderModeLabelAboveValue(true);
    controller.setMindExpandedSurfaceStyle(
      MindExpandedSurfaceStyle.separateCards,
    );
    controller.setMindExpandedSurfaceStyle(
      MindExpandedSurfaceStyle.seamlessCard,
    );
    controller.setBudgetAvatarContentStyle(
      BudgetAvatarContentStyle.overlappingGlow,
    );
    expect(
      controller.tuning.value.globalAppearance,
      const FluviGlobalAppearance(
        directionColorProfile: FluviDirectionColorProfile.vivid,
        avatarColorProfile: CategoryAvatarColorProfile.pastel,
        showsDirectionArtwork: false,
        fabIconPresentation: FluviFabIconPresentation.legacyWhiteStore,
        fabVectorPrimaryArgb: 0xFF5533CC,
        fabVectorHighlightArgb: 0xFFD8CCFF,
        typography: FluviTypographyProfile.colorLab,
        directionControlStyle: FluviDirectionControlStyle.slidingRail,
        collapseHandleStyle: FluviCollapseHandleStyle.headerTranslucentPill,
        activeDirectionLabelTone: FluviActiveDirectionLabelTone.black,
        inactiveDirectionLabelTone: FluviInactiveDirectionLabelTone.black,
        showsHeaderModeLabelAboveValue: true,
        mindExpandedSurfaceStyle: MindExpandedSurfaceStyle.seamlessCard,
        budgetAvatarContentStyle: BudgetAvatarContentStyle.overlappingGlow,
      ),
    );
    expect(controller.tuning.value.generation, initialGeneration + 15);
    expect(controller.tickerIdentity, same(ticker));
  });
}
