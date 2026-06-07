import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  test('primary raised surface keeps the HTML gradient and outer shadows', () {
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
    expect(decoration.boxShadow![0].color, const Color(0x570891B2));
    expect(decoration.boxShadow![0].offset, const Offset(8, 8));
    expect(decoration.boxShadow![0].blurRadius, 17);
    expect(decoration.boxShadow![1].color, const Color(0xD9FFFFFF));
    expect(decoration.boxShadow![1].offset, const Offset(-7, -7));
    expect(decoration.boxShadow![1].blurRadius, 16);
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
}
