import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/catalog/category_catalog.dart';

void main() {
  late Map<String, Object?> manifest;

  setUpAll(() {
    final file = File('assets/category_catalog/category_catalog.json');
    manifest = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  });

  test('has exactly the stable 21-color and 50-icon contract', () {
    expect(CategoryCatalogIds.version, 1);
    expect(CategoryColorCatalog.values.length, 21);
    expect(CategoryIconCatalog.values.length, 50);
    expect(
      CategoryColorCatalog.values.keys.toList(),
      CategoryCatalogIds.colorIds,
    );
    expect(
      CategoryIconCatalog.values.keys.toList(),
      CategoryCatalogIds.iconIds,
    );
  });

  test('manifest and Dart color catalog contain the same source values', () {
    final colors = manifest['colors']! as List<Object?>;
    expect(colors, hasLength(21));

    for (final raw in colors) {
      final entry = Map<String, Object?>.from(raw! as Map);
      final token = CategoryColorCatalog.values[entry['id']];
      expect(token, isNotNull);
      expect(_hex(token!.colorA), entry['a']);
      expect(_hex(token.middleColor), entry['middle']);
      expect(_hex(token.colorB), entry['b']);
      expect(token.angleDegrees, entry['angleDegrees']);
    }
  });

  test(
    'every catalog icon keeps its SVG source and compiled runtime asset',
    () {
      final icons = manifest['icons']! as List<Object?>;
      expect(icons, hasLength(50));

      for (final raw in icons) {
        final entry = Map<String, Object?>.from(raw! as Map);
        final id = entry['id']! as String;
        final token = CategoryIconCatalog.values[id];
        expect(token, isNotNull);
        expect(token!.sourceAssetPath, entry['asset']);
        expect(token.compiledAssetPath, '${entry['asset']}.vec');

        final file = File(token.sourceAssetPath);
        expect(file.existsSync(), isTrue, reason: token.sourceAssetPath);
        final svg = file.readAsStringSync();
        expect(svg, contains('<svg'));
        expect(
          RegExp(r'viewBox="\s*0\s+0\s+[0-9.]+\s+[0-9.]+\s*"').hasMatch(svg),
          isTrue,
          reason: token.sourceAssetPath,
        );
        expect(svg, isNot(contains('<image')));

        final compiled = File(token.compiledAssetPath);
        expect(compiled.existsSync(), isTrue, reason: token.compiledAssetPath);
        expect(compiled.lengthSync(), greaterThan(0));
      }
    },
  );

  test('fallbacks are explicit and do not use a catalog ID', () {
    expect(CategoryColorCatalog.resolve('unknown').id, 'fallback');
    expect(CategoryIconCatalog.resolve('unknown').id, 'fallback');
    expect(CategoryCatalogIds.uncategorizedColorId, 'color_01');
    expect(CategoryCatalogIds.uncategorizedIconId, 'icon_01');
  });
}

String _hex(Color color) =>
    '#${(color.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}';
