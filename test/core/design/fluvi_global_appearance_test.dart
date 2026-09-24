import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/catalog/category_color_catalog.dart';
import 'package:fluvi/core/categories/presentation/category_avatar_palette_catalog.dart';
import 'package:fluvi/core/design/fluvi_global_appearance.dart';

void main() {
  group('direction colour profiles', () {
    test('contain the four exact active direction treatments', () {
      expect(FluviDirectionColorProfile.values, hasLength(4));
      expect(
        _colors(FluviDirectionColorProfile.original, income: true),
        const <int>[0xFF715EFB, 0xFFB484F3, 0xFFE478C3],
      );
      expect(
        _colors(FluviDirectionColorProfile.original, income: false),
        const <int>[0xFFFF8A3D, 0xFFF542A7],
      );
      expect(
        _colors(FluviDirectionColorProfile.pastel, income: true),
        const <int>[0xFFAF99FF, 0xFFCAADFF, 0xFFFFC2E2],
      );
      expect(
        _colors(FluviDirectionColorProfile.pastel, income: false),
        const <int>[0xFFFFC2E2, 0xFFFFADC7, 0xFFFF99B6],
      );
      expect(
        _colors(FluviDirectionColorProfile.saturated, income: true),
        const <int>[0xFF9678FF, 0xFFB388FF, 0xFFFF9ED6],
      );
      expect(
        _colors(FluviDirectionColorProfile.saturated, income: false),
        const <int>[0xFFFF9ED6, 0xFFFF7FAE, 0xFFFF6A95],
      );
      expect(
        _colors(FluviDirectionColorProfile.vivid, income: true),
        const <int>[0xFF7A52FF, 0xFF9F66FF, 0xFFFF78CB],
      );
      expect(
        _colors(FluviDirectionColorProfile.vivid, income: false),
        const <int>[0xFFFF78CB, 0xFFFF4F96, 0xFFFF3380],
      );
    });
  });

  group('category avatar colour profiles', () {
    test(
      'preserve 21 canonical IDs, angles and three stops in every profile',
      () {
        expect(CategoryAvatarColorProfile.values, hasLength(4));
        expect(CategoryColorCatalog.values, hasLength(21));
        for (final entry in CategoryColorCatalog.values.entries) {
          final handle = CategoryColorCatalog.handleOf(entry.key);
          for (final profile in CategoryAvatarColorProfile.values) {
            final gradient = CategoryAvatarPaletteCatalog.gradientFor(
              profile,
              handle,
            );
            expect(gradient.stops, const <double>[0, .52, 1]);
            expect(gradient.colors, hasLength(3));
          }
          final original = CategoryAvatarPaletteCatalog.tokenFor(
            CategoryAvatarColorProfile.original,
            handle,
          );
          expect(original.id, entry.key);
          expect(original.angleDegrees, entry.value.angleDegrees);
          expect(original.colors, entry.value.colors);
        }
      },
    );

    test(
      'contains every exact authored pastel, saturated and vivid anchor',
      () {
        for (final entry in _expected.entries) {
          final handle = CategoryColorCatalog.handleOf(entry.key);
          for (final profileEntry in entry.value.entries) {
            final token = CategoryAvatarPaletteCatalog.tokenFor(
              profileEntry.key,
              handle,
            );
            expect(
              token.colors.map((color) => color.toARGB32()).toList(),
              profileEntry.value,
              reason: '${profileEntry.key.name} ${entry.key}',
            );
          }
        }
      },
    );

    test('retains the neutral fallback exactly', () {
      final fallback = CategoryAvatarPaletteCatalog.tokenFor(
        CategoryAvatarColorProfile.vivid,
        0,
      );
      expect(
        fallback.colors.map((color) => color.toARGB32()).toList(),
        const <int>[0xFF64748B, 0xFF7C8CA3, 0xFF94A3B8],
      );
    });
  });

  group('global appearance defaults', () {
    test(
      'keep visual choices independent and backwards-compatible by default',
      () {
        const settings = FluviGlobalAppearance.defaults();
        expect(
          settings.directionColorProfile,
          FluviDirectionColorProfile.original,
        );
        expect(
          settings.avatarColorProfile,
          CategoryAvatarColorProfile.original,
        );
        expect(settings.showsDirectionArtwork, isTrue);
        expect(settings.typography, FluviTypographyProfile.app);
        expect(
          settings
              .copyWith(directionColorProfile: FluviDirectionColorProfile.vivid)
              .avatarColorProfile,
          CategoryAvatarColorProfile.original,
        );
        expect(
          settings
              .copyWith(avatarColorProfile: CategoryAvatarColorProfile.pastel)
              .showsDirectionArtwork,
          isTrue,
        );
      },
    );

    test('Color Lab applies the bundled family to the app text theme', () {
      final themed = FluviTypographyProfile.colorLab.applyToTheme(ThemeData());
      expect(themed.textTheme.bodyMedium!.fontFamily, 'FluviColorLabInter');
      expect(
        themed.primaryTextTheme.titleMedium!.fontFamily,
        'FluviColorLabInter',
      );
      expect(
        FluviTypographyProfile.app
            .applyToTheme(ThemeData())
            .textTheme
            .bodyMedium!
            .fontFamily,
        isNot('FluviColorLabInter'),
      );
    });
  });
}

List<int> _colors(FluviDirectionColorProfile profile, {required bool income}) {
  final gradient = income
      ? FluviDirectionColorPaletteCatalog.income(profile)
      : FluviDirectionColorPaletteCatalog.expense(profile);
  return gradient.colors.map((Color color) => color.toARGB32()).toList();
}

const Map<String, Map<CategoryAvatarColorProfile, List<int>>>
_expected = <String, Map<CategoryAvatarColorProfile, List<int>>>{
  'color_01': {
    CategoryAvatarColorProfile.pastel: [0xFFEA979A, 0xFFF8A8AA, 0xFFFFBDBF],
    CategoryAvatarColorProfile.saturated: [0xFFEA6973, 0xFFFB8088, 0xFFFF9FA2],
    CategoryAvatarColorProfile.vivid: [0xFFE5274D, 0xFFFB4C64, 0xFFFF7C85],
  },
  'color_02': {
    CategoryAvatarColorProfile.pastel: [0xFFE89B83, 0xFFF7AC95, 0xFFFFC0AD],
    CategoryAvatarColorProfile.saturated: [0xFFE96F4A, 0xFFF98662, 0xFFFFA286],
    CategoryAvatarColorProfile.vivid: [0xFFDC4400, 0xFFFA5619, 0xFFFF815B],
  },
  'color_03': {
    CategoryAvatarColorProfile.pastel: [0xFFDDA46B, 0xFFEBB57E, 0xFFF8C696],
    CategoryAvatarColorProfile.saturated: [0xFFD68200, 0xFFEA952D, 0xFFFAAA51],
    CategoryAvatarColorProfile.vivid: [0xFFB56D00, 0xFFD27F00, 0xFFEF9200],
  },
  'color_04': {
    CategoryAvatarColorProfile.pastel: [0xFFD0AC64, 0xFFDFBC78, 0xFFECCD90],
    CategoryAvatarColorProfile.saturated: [0xFFC18F00, 0xFFD8A10D, 0xFFE9B543],
    CategoryAvatarColorProfile.vivid: [0xFFA37800, 0xFFBD8C00, 0xFFD8A000],
  },
  'color_05': {
    CategoryAvatarColorProfile.pastel: [0xFFBBB567, 0xFFCAC57B, 0xFFD9D593],
    CategoryAvatarColorProfile.saturated: [0xFFA79C00, 0xFFBAAF1E, 0xFFCCC24A],
    CategoryAvatarColorProfile.vivid: [0xFF8C8300, 0xFFA39900, 0xFFBBAF00],
  },
  'color_06': {
    CategoryAvatarColorProfile.pastel: [0xFFA3BC75, 0xFFB3CC87, 0xFFC5DB9E],
    CategoryAvatarColorProfile.saturated: [0xFF83A81F, 0xFF96BA45, 0xFFAACD62],
    CategoryAvatarColorProfile.vivid: [0xFF6D8E00, 0xFF7FA500, 0xFF92BD00],
  },
  'color_07': {
    CategoryAvatarColorProfile.pastel: [0xFF88C28A, 0xFF9AD29B, 0xFFAEE0AF],
    CategoryAvatarColorProfile.saturated: [0xFF4DB155, 0xFF68C36D, 0xFF80D584],
    CategoryAvatarColorProfile.vivid: [0xFF009B29, 0xFF02B432, 0xFF4BC957],
  },
  'color_08': {
    CategoryAvatarColorProfile.pastel: [0xFF74C59C, 0xFF88D4AD, 0xFF9FE3BF],
    CategoryAvatarColorProfile.saturated: [0xFF00B479, 0xFF35C78B, 0xFF5CD9A0],
    CategoryAvatarColorProfile.vivid: [0xFF009865, 0xFF00B176, 0xFF00CA88],
  },
  'color_09': {
    CategoryAvatarColorProfile.pastel: [0xFF72C59E, 0xFF86D4AE, 0xFF9EE3C0],
    CategoryAvatarColorProfile.saturated: [0xFF00B47B, 0xFF30C78D, 0xFF59D9A2],
    CategoryAvatarColorProfile.vivid: [0xFF009867, 0xFF00B079, 0xFF00C98B],
  },
  'color_10': {
    CategoryAvatarColorProfile.pastel: [0xFF5FC6B4, 0xFF76D5C4, 0xFF90E4D3],
    CategoryAvatarColorProfile.saturated: [0xFF00B09C, 0xFF00C6AF, 0xFF22DBC2],
    CategoryAvatarColorProfile.vivid: [0xFF009583, 0xFF00AD99, 0xFF00C6AF],
  },
  'color_11': {
    CategoryAvatarColorProfile.pastel: [0xFF5AC2D8, 0xFF71D1E6, 0xFF8DE0F3],
    CategoryAvatarColorProfile.saturated: [0xFF00ABC5, 0xFF00BFDC, 0xFF05D4F4],
    CategoryAvatarColorProfile.vivid: [0xFF0090A6, 0xFF00A7C1, 0xFF00BFDC],
  },
  'color_12': {
    CategoryAvatarColorProfile.pastel: [0xFF63BFE1, 0xFF78CEEF, 0xFF92DDFB],
    CategoryAvatarColorProfile.saturated: [0xFF00A8D3, 0xFF00BCEC, 0xFF3CCFFF],
    CategoryAvatarColorProfile.vivid: [0xFF008EB3, 0xFF00A5CF, 0xFF00BCEC],
  },
  'color_13': {
    CategoryAvatarColorProfile.pastel: [0xFF7FB6EE, 0xFF91C6FC, 0xFFADD6FF],
    CategoryAvatarColorProfile.saturated: [0xFF399DF6, 0xFF5EB0FF, 0xFF88C3FF],
    CategoryAvatarColorProfile.vivid: [0xFF0083DF, 0xFF1199FF, 0xFF5EB0FF],
  },
  'color_14': {
    CategoryAvatarColorProfile.pastel: [0xFF96AFF1, 0xFFA6BFFF, 0xFFBDD0FF],
    CategoryAvatarColorProfile.saturated: [0xFF6E91FA, 0xFF86A7FF, 0xFFA2BCFF],
    CategoryAvatarColorProfile.vivid: [0xFF4A70FF, 0xFF678DFF, 0xFF86A7FF],
  },
  'color_15': {
    CategoryAvatarColorProfile.pastel: [0xFFA3ABF0, 0xFFB3BBFE, 0xFFC6CDFF],
    CategoryAvatarColorProfile.saturated: [0xFF848BF8, 0xFF98A1FF, 0xFFAFB7FF],
    CategoryAvatarColorProfile.vivid: [0xFF6A66FE, 0xFF8085FF, 0xFF98A1FF],
  },
  'color_16': {
    CategoryAvatarColorProfile.pastel: [0xFFB2A6EC, 0xFFC2B6FA, 0xFFD1C9FF],
    CategoryAvatarColorProfile.saturated: [0xFF9B83F2, 0xFFAD98FF, 0xFFBFB1FF],
    CategoryAvatarColorProfile.vivid: [0xFF885BF5, 0xFF9A79FF, 0xFFAD98FF],
  },
  'color_17': {
    CategoryAvatarColorProfile.pastel: [0xFFB8A4E9, 0xFFC7B4F7, 0xFFD6C7FF],
    CategoryAvatarColorProfile.saturated: [0xFFA480EE, 0xFFB694FD, 0xFFC6AEFF],
    CategoryAvatarColorProfile.vivid: [0xFF9256F0, 0xFFA573FF, 0xFFB694FF],
  },
  'color_18': {
    CategoryAvatarColorProfile.pastel: [0xFFC3A0E2, 0xFFD3B0F0, 0xFFE1C2FC],
    CategoryAvatarColorProfile.saturated: [0xFFB57AE3, 0xFFC68FF2, 0xFFD6A5FF],
    CategoryAvatarColorProfile.vivid: [0xFFA64DE1, 0xFFBA68F5, 0xFFCB88FF],
  },
  'color_19': {
    CategoryAvatarColorProfile.pastel: [0xFFCA9EDD, 0xFFD9AEEB, 0xFFE7C1F7],
    CategoryAvatarColorProfile.saturated: [0xFFBD76DB, 0xFFCF8BEB, 0xFFE0A1FB],
    CategoryAvatarColorProfile.vivid: [0xFFB048D7, 0xFFC563EB, 0xFFD880FB],
  },
  'color_20': {
    CategoryAvatarColorProfile.pastel: [0xFFD799CD, 0xFFE6AADC, 0xFFF3BDEA],
    CategoryAvatarColorProfile.saturated: [0xFFD06FC3, 0xFFE185D4, 0xFFF29BE5],
    CategoryAvatarColorProfile.vivid: [0xFFC63BB8, 0xFFDC58CC, 0xFFEE77DE],
  },
  'color_21': {
    CategoryAvatarColorProfile.pastel: [0xFFDF97C0, 0xFFEEA8CF, 0xFFFABBDE],
    CategoryAvatarColorProfile.saturated: [0xFFDB6BAF, 0xFFEC81C0, 0xFFFD97D2],
    CategoryAvatarColorProfile.vivid: [0xFFD3329E, 0xFFE952B2, 0xFFFB72C6],
  },
};
