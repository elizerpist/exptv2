#!/usr/bin/env python3
"""Generate the immutable Kotlin/Dart catalog views from the JSON manifest."""

from __future__ import annotations

import json
import argparse
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "assets/category_catalog/category_catalog.json"
DART_IDS = ROOT / "lib/core/categories/catalog/category_catalog_ids.dart"
DART_COLORS = ROOT / "lib/core/categories/catalog/category_color_catalog.dart"
DART_ICONS = ROOT / "lib/core/categories/catalog/category_icon_catalog.dart"
KOTLIN_CATALOG = (
    ROOT
    / "android/fluvi-core/src/main/kotlin/com/fluvi/core/catalog/FluviCategoryCatalog.kt"
)
LOGBOX_GLYPH_DIRECTORY = ROOT / "assets/logbox_category_icons"


def dart_color(value: str) -> str:
    return f"Color(0xFF{value.removeprefix('#').upper()})"


def quoted(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def logbox_source_asset_path(asset_path: str) -> str:
    return str(LOGBOX_GLYPH_DIRECTORY.relative_to(ROOT) / Path(asset_path).name)


def read_manifest() -> dict:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    colors = manifest["colors"]
    icons = manifest["icons"]
    if manifest["version"] != 1:
        raise ValueError("Only catalog manifest version 1 is supported.")
    if len(colors) != 21 or len(icons) != 50:
        raise ValueError("The catalog must contain exactly 21 colors and 50 icons.")
    if len({entry["id"] for entry in colors}) != len(colors):
        raise ValueError("Color IDs must be unique.")
    if len({entry["id"] for entry in icons}) != len(icons):
        raise ValueError("Icon IDs must be unique.")
    return manifest


def write_logbox_white_sources(manifest: dict) -> None:
    """Derive bounded monochrome LogBox SVGs from canonical category sources.

    The LogBox uses a self-contained white vector asset rather than applying a
    destination-dependent tint to a reusable display list. The manifest stays
    the only category asset registry; these files are deterministic build
    products of its source SVGs.
    """
    for entry in manifest["icons"]:
        source_path = ROOT / entry["asset"]
        if not source_path.is_file():
            raise FileNotFoundError(entry["asset"])
        source = source_path.read_text(encoding="utf-8")
        if "currentColor" not in source:
            raise ValueError(
                f"Category icon does not expose a canonical currentColor: "
                f"{entry['asset']}"
            )
        derived = source.replace("currentColor", "#FFFFFF")
        target_path = ROOT / logbox_source_asset_path(entry["asset"])
        target_path.parent.mkdir(parents=True, exist_ok=True)
        if not target_path.is_file() or target_path.read_text(encoding="utf-8") != derived:
            target_path.write_text(derived, encoding="utf-8")


def validate_runtime_assets(manifest: dict) -> None:
    for entry in manifest["icons"]:
        source_asset = entry["asset"]
        for asset in (source_asset, logbox_source_asset_path(source_asset)):
            if not (ROOT / asset).is_file():
                raise FileNotFoundError(asset)
            compiled_asset = f"{asset}.vec"
            if not (ROOT / compiled_asset).is_file():
                raise FileNotFoundError(compiled_asset)


def render_dart_ids(manifest: dict) -> str:
    color_ids = [entry["id"] for entry in manifest["colors"]]
    icon_ids = [entry["id"] for entry in manifest["icons"]]
    colors = ",\n".join(f"    {quoted(value)}" for value in color_ids)
    icons = ",\n".join(f"    {quoted(value)}" for value in icon_ids)
    return f'''// GENERATED FILE. Edit assets/category_catalog/category_catalog.json instead.
/// Stable category catalog identifiers.
abstract final class CategoryCatalogIds {{
  static const int version = {manifest["version"]};
  static const String uncategorizedColorId = {quoted(manifest["uncategorized"]["colorId"])};
  static const String uncategorizedIconId = {quoted(manifest["uncategorized"]["iconId"])};

  static const List<String> colorIds = <String>[
{colors},
  ];

  static const List<String> iconIds = <String>[
{icons},
  ];
}}
'''


def render_dart_colors(manifest: dict) -> str:
    entries = []
    for entry in manifest["colors"]:
        entries.append(
            f'''    {quoted(entry["id"])}: CategoryGradientToken(
      id: {quoted(entry["id"])},
      colorA: {dart_color(entry["a"])},
      middleColor: {dart_color(entry["middle"])},
      colorB: {dart_color(entry["b"])},
      angleDegrees: {entry["angleDegrees"]},
    ),'''
        )
    return f'''// GENERATED FILE. Edit assets/category_catalog/category_catalog.json instead.
import 'dart:math' as math;

import 'package:flutter/material.dart';

class CategoryGradientToken {{
  const CategoryGradientToken({{
    required this.id,
    required this.colorA,
    required this.middleColor,
    required this.colorB,
    required this.angleDegrees,
  }});

  final String id;
  final Color colorA;
  final Color middleColor;
  final Color colorB;
  final double angleDegrees;

  List<Color> get colors => <Color>[colorA, middleColor, colorB];

  LinearGradient get gradient => LinearGradient(
        colors: colors,
        stops: const <double>[0, 0.52, 1],
        transform: GradientRotation(
          (90 - angleDegrees) * math.pi / 180,
        ),
      );
}}

abstract final class CategoryColorCatalog {{
  static const CategoryGradientToken fallback = CategoryGradientToken(
    id: 'fallback',
    colorA: Color(0xFF64748B),
    middleColor: Color(0xFF7C8CA3),
    colorB: Color(0xFF94A3B8),
    angleDegrees: 135,
  );

  static const Map<String, CategoryGradientToken> values =
      <String, CategoryGradientToken>{{
{chr(10).join(entries)}
  }};

  static CategoryGradientToken resolve(String colorId) =>
      values[colorId] ?? fallback;

  static final Map<String, int> _handles = <String, int>{{
    for (final (index, id) in values.keys.indexed) id: index + 1,
  }};

  static int handleOf(String colorId) => _handles[colorId] ?? 0;

  static final List<CategoryGradientToken> _byHandle =
      List<CategoryGradientToken>.unmodifiable(<CategoryGradientToken>[
    fallback,
    ...values.values,
  ]);

  static CategoryGradientToken tokenForHandle(int handle) => _byHandle[handle];

  static List<CategoryGradientToken> get allWithFallback => _byHandle;

  static bool contains(String colorId) => values.containsKey(colorId);

  static List<CategoryGradientToken> get all =>
      List<CategoryGradientToken>.unmodifiable(values.values);
}}
'''


def render_dart_icons(manifest: dict) -> str:
    entries = []
    for entry in manifest["icons"]:
        entries.append(
            f'''    {quoted(entry["id"])}: CategoryIconToken(
      id: {quoted(entry["id"])},
      sourceAssetPath: {quoted(entry["asset"])},
      compiledAssetPath: {quoted(f'{entry["asset"]}.vec')},
      bytesLoader: AssetBytesLoader({quoted(f'{entry["asset"]}.vec')}),
      logBoxSourceAssetPath: {quoted(logbox_source_asset_path(entry["asset"]))},
      logBoxCompiledAssetPath: {quoted(f'{logbox_source_asset_path(entry["asset"])}.vec')},
      logBoxBytesLoader: AssetBytesLoader({quoted(f'{logbox_source_asset_path(entry["asset"])}.vec')}),
      semanticName: {quoted(entry["semanticName"])},
    ),'''
        )
    return f'''// GENERATED FILE. Edit assets/category_catalog/category_catalog.json instead.
import 'package:vector_graphics/vector_graphics.dart';

class CategoryIconToken {{
  const CategoryIconToken({{
    required this.id,
    required this.sourceAssetPath,
    required this.compiledAssetPath,
    required this.bytesLoader,
    required this.logBoxSourceAssetPath,
    required this.logBoxCompiledAssetPath,
    required this.logBoxBytesLoader,
    required this.semanticName,
  }});

  final String id;
  final String sourceAssetPath;
  final String compiledAssetPath;
  final AssetBytesLoader bytesLoader;
  final String logBoxSourceAssetPath;
  final String logBoxCompiledAssetPath;
  final AssetBytesLoader logBoxBytesLoader;
  final String semanticName;
}}

abstract final class CategoryIconCatalog {{
  static const CategoryIconToken fallback = CategoryIconToken(
    id: 'fallback',
    sourceAssetPath: 'assets/category_icons/shirt.svg',
    compiledAssetPath: 'assets/category_icons/shirt.svg.vec',
    bytesLoader: AssetBytesLoader('assets/category_icons/shirt.svg.vec'),
    logBoxSourceAssetPath: 'assets/logbox_category_icons/shirt.svg',
    logBoxCompiledAssetPath: 'assets/logbox_category_icons/shirt.svg.vec',
    logBoxBytesLoader: AssetBytesLoader('assets/logbox_category_icons/shirt.svg.vec'),
    semanticName: 'category icon fallback',
  );

  static const Map<String, CategoryIconToken> values =
      <String, CategoryIconToken>{{
{chr(10).join(entries)}
  }};

  static CategoryIconToken resolve(String iconId) => values[iconId] ?? fallback;

  static final Map<String, int> _handles = <String, int>{{
    for (final (index, id) in values.keys.indexed) id: index + 1,
  }};

  static int handleOf(String iconId) => _handles[iconId] ?? 0;

  static final List<CategoryIconToken> _byHandle =
      List<CategoryIconToken>.unmodifiable(<CategoryIconToken>[
    fallback,
    ...values.values,
  ]);

  static CategoryIconToken tokenForHandle(int handle) => _byHandle[handle];

  static List<CategoryIconToken> get allWithFallback => _byHandle;

  static bool contains(String iconId) => values.containsKey(iconId);

  static List<CategoryIconToken> get all =>
      List<CategoryIconToken>.unmodifiable(values.values);
}}
'''


def render_kotlin(manifest: dict) -> str:
    color_ids = ",\n        ".join(quoted(entry["id"]) for entry in manifest["colors"])
    icon_ids = ",\n        ".join(quoted(entry["id"]) for entry in manifest["icons"])
    return f'''// GENERATED FILE. Edit assets/category_catalog/category_catalog.json instead.
package com.fluvi.core.catalog

object FluviCategoryCatalog {{
    const val VERSION = {manifest["version"]}

    val colorIds: Set<String> = linkedSetOf(
        {color_ids},
    )

    val iconIds: Set<String> = linkedSetOf(
        {icon_ids},
    )

    const val SYSTEM_UNCATEGORIZED_COLOR_ID = {quoted(manifest["uncategorized"]["colorId"])}
    const val SYSTEM_UNCATEGORIZED_ICON_ID = {quoted(manifest["uncategorized"]["iconId"])}
}}
'''


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--write-logbox-sources",
        action="store_true",
        help="write derived monochrome LogBox SVGs before vector compilation",
    )
    arguments = parser.parse_args()
    manifest = read_manifest()
    write_logbox_white_sources(manifest)
    if arguments.write_logbox_sources:
        print("Generated monochrome LogBox category SVGs from", MANIFEST)
        return
    validate_runtime_assets(manifest)
    DART_IDS.write_text(render_dart_ids(manifest), encoding="utf-8")
    DART_COLORS.write_text(render_dart_colors(manifest), encoding="utf-8")
    DART_ICONS.write_text(render_dart_icons(manifest), encoding="utf-8")
    KOTLIN_CATALOG.write_text(render_kotlin(manifest), encoding="utf-8")
    print("Generated category catalog views from", MANIFEST)


if __name__ == "__main__":
    main()
