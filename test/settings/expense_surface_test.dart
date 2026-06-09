import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inset surfaces expose the exact HTML inset shadow tokens', () {
    final shadows = ExpenseSurface.insetShadowTokens(
      style: ExpenseSurfaceInteraction.insetInset,
      pressed: false,
      primary: false,
    );

    expect(shadows, hasLength(2));
    expect(shadows[0].color, AppColors.gray400.withValues(alpha: 0.35));
    expect(shadows[0].offset, const Offset(6, 6));
    expect(shadows[0].blurRadius, 13);
    expect(shadows[1].color, Colors.white.withValues(alpha: 0.92));
    expect(shadows[1].offset, const Offset(-6, -6));
    expect(shadows[1].blurRadius, 13);
  });

  test('header inset surfaces use the stronger HTML header tokens', () {
    final shadows = ExpenseSurface.insetShadowTokens(
      style: ExpenseSurfaceInteraction.insetInset,
      pressed: false,
      primary: false,
      profile: ExpenseSurfaceProfile.headerCard,
    );

    expect(shadows, hasLength(2));
    expect(shadows[0].color, AppColors.gray400.withValues(alpha: 0.36));
    expect(shadows[0].offset, const Offset(9, 9));
    expect(shadows[0].blurRadius, 19);
    expect(shadows[1].color, Colors.white.withValues(alpha: 0.92));
    expect(shadows[1].offset, const Offset(-9, -9));
    expect(shadows[1].blurRadius, 19);
  });

  test('primary inset buttons expose black-toned inset shadow tokens', () {
    final rest = ExpenseSurface.insetShadowTokens(
      style: ExpenseSurfaceInteraction.insetInset,
      pressed: false,
      primary: true,
    );
    final pressed = ExpenseSurface.insetShadowTokens(
      style: ExpenseSurfaceInteraction.insetInset,
      pressed: true,
      primary: true,
    );

    expect(rest, hasLength(2));
    final primaryShadowDark = Color.lerp(
      AppColors.primary,
      Colors.black,
      0.55,
    )!;

    expect(rest[0].color, primaryShadowDark.withValues(alpha: 0.56));
    expect(rest[0].offset, const Offset(5, 5));
    expect(rest[0].blurRadius, 10);
    expect(rest[1].color, AppColors.primaryLight.withValues(alpha: 0.36));
    expect(rest[1].offset, const Offset(-4, -4));
    expect(rest[1].blurRadius, 9);
    expect(pressed, hasLength(2));
    expect(pressed[0].color, primaryShadowDark.withValues(alpha: 0.64));
    expect(pressed[0].offset, const Offset(7, 7));
    expect(pressed[0].blurRadius, 13);
    expect(pressed[1].color, AppColors.primaryLight.withValues(alpha: 0.38));
    expect(pressed[1].offset, const Offset(-5, -5));
    expect(pressed[1].blurRadius, 11);
  });

  test('active nav inset surfaces use their own HTML tokens', () {
    final rest = ExpenseSurface.insetShadowTokens(
      style: ExpenseSurfaceInteraction.insetInset,
      pressed: false,
      primary: false,
      profile: ExpenseSurfaceProfile.activeNavItem,
    );
    final pressed = ExpenseSurface.insetShadowTokens(
      style: ExpenseSurfaceInteraction.insetInset,
      pressed: true,
      primary: false,
      profile: ExpenseSurfaceProfile.activeNavItem,
    );

    expect(rest, hasLength(2));
    expect(rest[0].color, AppColors.primary.withValues(alpha: 0.20));
    expect(rest[0].offset, const Offset(4, 4));
    expect(rest[0].blurRadius, 9);
    expect(rest[1].color, Colors.white.withValues(alpha: 0.88));
    expect(rest[1].offset, const Offset(-4, -4));
    expect(rest[1].blurRadius, 9);
    expect(pressed, hasLength(2));
    expect(pressed[0].color, AppColors.primary.withValues(alpha: 0.24));
    expect(pressed[0].offset, const Offset(6, 6));
    expect(pressed[0].blurRadius, 12);
    expect(pressed[1].color, Colors.white.withValues(alpha: 0.88));
    expect(pressed[1].offset, const Offset(-5, -5));
    expect(pressed[1].blurRadius, 10);
  });

  test('raised surface uses the HTML neumorphism shadow tokens', () {
    final decoration = ExpenseSurface.decoration(
      style: ExpenseSurfaceInteraction.raisedInset,
      color: AppColors.gray200,
      borderRadius: BorderRadius.circular(25),
    );

    final shadows = decoration.boxShadow!;
    expect(decoration.border, isA<Border>());
    expect(shadows, hasLength(2));
    expect(shadows[0].color, const Color(0x5794A3B8));
    expect(shadows[0].offset, const Offset(7, 7));
    expect(shadows[0].blurRadius, 15);
    expect(shadows[1].color, const Color(0xEBFFFFFF));
    expect(shadows[1].offset, const Offset(-7, -7));
    expect(shadows[1].blurRadius, 15);
  });

  test('primary raised surface keeps the gradient and black outer shadows', () {
    final decoration = ExpenseSurface.decoration(
      style: ExpenseSurfaceInteraction.raisedInset,
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(25),
      primary: true,
    );

    final gradient = decoration.gradient! as LinearGradient;
    expect(
      gradient.colors,
      [AppColors.primaryLight, AppColors.primary, AppColors.primaryDark],
    );
    expect(decoration.border, isNull);
    expect(decoration.boxShadow, hasLength(2));
    expect(decoration.boxShadow![0].color, const Color(0x33000000));
    expect(decoration.boxShadow![0].offset, const Offset(8, 8));
    expect(decoration.boxShadow![0].blurRadius, 17);
    expect(decoration.boxShadow![1].color, const Color(0xD9FFFFFF));
    expect(decoration.boxShadow![1].offset, const Offset(-7, -7));
    expect(decoration.boxShadow![1].blurRadius, 16);
  });

  test('neutral-press primary pressed state stays solid like the HTML', () {
    final decoration = ExpenseSurface.decoration(
      style: ExpenseSurfaceInteraction.neutralInset,
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(25),
      primary: true,
      pressed: true,
    );

    expect(decoration.color, AppColors.primary);
    expect(decoration.gradient, isNull);
    expect(decoration.border, isNull);
  });

  test('non-primary inset surfaces stay flat like CSS inset box-shadow', () {
    final baseInset = ExpenseSurface.decoration(
      style: ExpenseSurfaceInteraction.insetInset,
      color: AppColors.gray200,
      borderRadius: BorderRadius.circular(25),
    );
    final pressedInset = ExpenseSurface.decoration(
      style: ExpenseSurfaceInteraction.neutralInset,
      color: AppColors.gray200,
      borderRadius: BorderRadius.circular(25),
      pressed: true,
    );

    expect(baseInset.color, AppColors.gray200);
    expect(baseInset.gradient, isNull);
    expect(pressedInset.color, AppColors.gray200);
    expect(pressedInset.gradient, isNull);
  });

  test('press offsets match the HTML downward slide animation', () {
    expect(
      ExpenseSurface.pressOffset(
        style: ExpenseSurfaceInteraction.neutralNeutral,
        pressed: true,
      ),
      Offset.zero,
    );
    expect(
      ExpenseSurface.pressOffset(
        style: ExpenseSurfaceInteraction.neutralInset,
        pressed: true,
      ),
      const Offset(0, 2),
    );
    expect(
      ExpenseSurface.pressOffset(
        style: ExpenseSurfaceInteraction.raisedInset,
        pressed: true,
      ),
      const Offset(0, 2),
    );
    expect(
      ExpenseSurface.pressOffset(
        style: ExpenseSurfaceInteraction.insetInset,
        pressed: true,
      ),
      const Offset(0, 1),
    );
  });

  testWidgets('inset shadow layer stays behind child content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          key: const ValueKey('expense-surface-test-host'),
          child: ExpenseSurfaceContainer(
            style: ExpenseSurfaceInteraction.neutralInset,
            color: AppColors.gray200,
            borderRadius: BorderRadius.circular(25),
            pressed: true,
            child: const Text('content'),
          ),
        ),
      ),
    );

    final stack = tester.widget<Stack>(
      find.descendant(
        of: find.byKey(const ValueKey('expense-surface-test-host')),
        matching: find.byType(Stack),
      ),
    );
    expect(stack.children.first, isA<Positioned>());
    expect(stack.children.last, isA<Padding>());
  });

  testWidgets('keyed surfaces log the resolved HTML surface state', (
    tester,
  ) async {
    DebugConsole.clear();
    await tester.pumpWidget(
      MaterialApp(
        home: ExpenseSurfaceContainer(
          surfaceKey: const ValueKey('search-pill-container'),
          style: ExpenseSurfaceInteraction.insetInset,
          color: AppColors.gray200,
          borderRadius: BorderRadius.circular(25),
          child: const Text('content'),
        ),
      ),
    );

    final logs = DebugConsole.allText;
    expect(logs, contains('[ThemeSurface] surface key=search-pill-container'));
    expect(logs, contains('style=insetInset'));
    expect(logs, contains('profile=standard'));
    expect(logs, contains('innerShadows=2'));
  });

  test(
    'material feedback is disabled when neumorphic press feedback is active',
    () {
      expect(
        ExpenseSurface.materialFeedbackEnabled(
          ExpenseSurfaceInteraction.neutralNeutral,
        ),
        isTrue,
      );
      expect(
        ExpenseSurface.materialFeedbackEnabled(
          ExpenseSurfaceInteraction.insetInset,
        ),
        isFalse,
      );
      expect(
        ExpenseSurface.transparentOverlayColor.resolve({WidgetState.pressed}),
        Colors.transparent,
      );
    },
  );
}
