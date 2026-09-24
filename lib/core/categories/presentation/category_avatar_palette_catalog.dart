import 'dart:collection';

import 'package:flutter/material.dart';

import '../../design/fluvi_global_appearance.dart';
import '../catalog/category_color_catalog.dart';

/// Presentation-only palettes for the immutable semantic category handles.
///
/// The original values remain in [CategoryColorCatalog]. The three alternate
/// lists are authored source data: no profile derives colours at runtime.
abstract final class CategoryAvatarPaletteCatalog {
  static final Map<CategoryAvatarColorProfile, List<CategoryGradientToken>>
  _tokens =
      UnmodifiableMapView<
        CategoryAvatarColorProfile,
        List<CategoryGradientToken>
      >(<CategoryAvatarColorProfile, List<CategoryGradientToken>>{
        CategoryAvatarColorProfile.original:
            CategoryColorCatalog.allWithFallback,
        CategoryAvatarColorProfile.pastel: _tokensFor(_pastel),
        CategoryAvatarColorProfile.saturated: _tokensFor(_saturated),
        CategoryAvatarColorProfile.vivid: _tokensFor(_vivid),
      });

  static CategoryGradientToken tokenFor(
    CategoryAvatarColorProfile profile,
    int handle,
  ) {
    final values = _tokens[profile]!;
    if (handle < 0 || handle >= values.length) {
      throw RangeError.range(handle, 0, values.length - 1, 'handle');
    }
    return values[handle];
  }

  static LinearGradient gradientFor(
    CategoryAvatarColorProfile profile,
    int handle,
  ) => tokenFor(profile, handle).gradient;

  static List<CategoryGradientToken> allWithFallback(
    CategoryAvatarColorProfile profile,
  ) => _tokens[profile]!;

  static List<CategoryGradientToken> _tokensFor(List<List<int>> anchors) {
    assert(anchors.length == CategoryColorCatalog.values.length);
    final canonical = CategoryColorCatalog.allWithFallback;
    return List<CategoryGradientToken>.unmodifiable(<CategoryGradientToken>[
      CategoryColorCatalog.fallback,
      for (var index = 0; index < anchors.length; index += 1)
        CategoryGradientToken(
          id: canonical[index + 1].id,
          colorA: Color(anchors[index][0]),
          middleColor: Color(anchors[index][1]),
          colorB: Color(anchors[index][2]),
          angleDegrees: canonical[index + 1].angleDegrees,
        ),
    ]);
  }

  static const List<List<int>> _pastel = <List<int>>[
    <int>[0xFFEA979A, 0xFFF8A8AA, 0xFFFFBDBF],
    <int>[0xFFE89B83, 0xFFF7AC95, 0xFFFFC0AD],
    <int>[0xFFDDA46B, 0xFFEBB57E, 0xFFF8C696],
    <int>[0xFFD0AC64, 0xFFDFBC78, 0xFFECCD90],
    <int>[0xFFBBB567, 0xFFCAC57B, 0xFFD9D593],
    <int>[0xFFA3BC75, 0xFFB3CC87, 0xFFC5DB9E],
    <int>[0xFF88C28A, 0xFF9AD29B, 0xFFAEE0AF],
    <int>[0xFF74C59C, 0xFF88D4AD, 0xFF9FE3BF],
    <int>[0xFF72C59E, 0xFF86D4AE, 0xFF9EE3C0],
    <int>[0xFF5FC6B4, 0xFF76D5C4, 0xFF90E4D3],
    <int>[0xFF5AC2D8, 0xFF71D1E6, 0xFF8DE0F3],
    <int>[0xFF63BFE1, 0xFF78CEEF, 0xFF92DDFB],
    <int>[0xFF7FB6EE, 0xFF91C6FC, 0xFFADD6FF],
    <int>[0xFF96AFF1, 0xFFA6BFFF, 0xFFBDD0FF],
    <int>[0xFFA3ABF0, 0xFFB3BBFE, 0xFFC6CDFF],
    <int>[0xFFB2A6EC, 0xFFC2B6FA, 0xFFD1C9FF],
    <int>[0xFFB8A4E9, 0xFFC7B4F7, 0xFFD6C7FF],
    <int>[0xFFC3A0E2, 0xFFD3B0F0, 0xFFE1C2FC],
    <int>[0xFFCA9EDD, 0xFFD9AEEB, 0xFFE7C1F7],
    <int>[0xFFD799CD, 0xFFE6AADC, 0xFFF3BDEA],
    <int>[0xFFDF97C0, 0xFFEEA8CF, 0xFFFABBDE],
  ];

  static const List<List<int>> _saturated = <List<int>>[
    <int>[0xFFEA6973, 0xFFFB8088, 0xFFFF9FA2],
    <int>[0xFFE96F4A, 0xFFF98662, 0xFFFFA286],
    <int>[0xFFD68200, 0xFFEA952D, 0xFFFAAA51],
    <int>[0xFFC18F00, 0xFFD8A10D, 0xFFE9B543],
    <int>[0xFFA79C00, 0xFFBAAF1E, 0xFFCCC24A],
    <int>[0xFF83A81F, 0xFF96BA45, 0xFFAACD62],
    <int>[0xFF4DB155, 0xFF68C36D, 0xFF80D584],
    <int>[0xFF00B479, 0xFF35C78B, 0xFF5CD9A0],
    <int>[0xFF00B47B, 0xFF30C78D, 0xFF59D9A2],
    <int>[0xFF00B09C, 0xFF00C6AF, 0xFF22DBC2],
    <int>[0xFF00ABC5, 0xFF00BFDC, 0xFF05D4F4],
    <int>[0xFF00A8D3, 0xFF00BCEC, 0xFF3CCFFF],
    <int>[0xFF399DF6, 0xFF5EB0FF, 0xFF88C3FF],
    <int>[0xFF6E91FA, 0xFF86A7FF, 0xFFA2BCFF],
    <int>[0xFF848BF8, 0xFF98A1FF, 0xFFAFB7FF],
    <int>[0xFF9B83F2, 0xFFAD98FF, 0xFFBFB1FF],
    <int>[0xFFA480EE, 0xFFB694FD, 0xFFC6AEFF],
    <int>[0xFFB57AE3, 0xFFC68FF2, 0xFFD6A5FF],
    <int>[0xFFBD76DB, 0xFFCF8BEB, 0xFFE0A1FB],
    <int>[0xFFD06FC3, 0xFFE185D4, 0xFFF29BE5],
    <int>[0xFFDB6BAF, 0xFFEC81C0, 0xFFFD97D2],
  ];

  static const List<List<int>> _vivid = <List<int>>[
    <int>[0xFFE5274D, 0xFFFB4C64, 0xFFFF7C85],
    <int>[0xFFDC4400, 0xFFFA5619, 0xFFFF815B],
    <int>[0xFFB56D00, 0xFFD27F00, 0xFFEF9200],
    <int>[0xFFA37800, 0xFFBD8C00, 0xFFD8A000],
    <int>[0xFF8C8300, 0xFFA39900, 0xFFBBAF00],
    <int>[0xFF6D8E00, 0xFF7FA500, 0xFF92BD00],
    <int>[0xFF009B29, 0xFF02B432, 0xFF4BC957],
    <int>[0xFF009865, 0xFF00B176, 0xFF00CA88],
    <int>[0xFF009867, 0xFF00B079, 0xFF00C98B],
    <int>[0xFF009583, 0xFF00AD99, 0xFF00C6AF],
    <int>[0xFF0090A6, 0xFF00A7C1, 0xFF00BFDC],
    <int>[0xFF008EB3, 0xFF00A5CF, 0xFF00BCEC],
    <int>[0xFF0083DF, 0xFF1199FF, 0xFF5EB0FF],
    <int>[0xFF4A70FF, 0xFF678DFF, 0xFF86A7FF],
    <int>[0xFF6A66FE, 0xFF8085FF, 0xFF98A1FF],
    <int>[0xFF885BF5, 0xFF9A79FF, 0xFFAD98FF],
    <int>[0xFF9256F0, 0xFFA573FF, 0xFFB694FF],
    <int>[0xFFA64DE1, 0xFFBA68F5, 0xFFCB88FF],
    <int>[0xFFB048D7, 0xFFC563EB, 0xFFD880FB],
    <int>[0xFFC63BB8, 0xFFDC58CC, 0xFFEE77DE],
    <int>[0xFFD3329E, 0xFFE952B2, 0xFFFB72C6],
  ];
}
