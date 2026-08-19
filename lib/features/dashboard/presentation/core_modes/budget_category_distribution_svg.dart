import 'package:flutter/material.dart';

import 'budget_clay_donut_scene.dart';

/// One raw source slice. The source generator excludes non-positive values so
/// SVG paths, hit testing and the legend always share the same prepared order.
@immutable
final class BudgetCategoryDistributionSvgSlice {
  const BudgetCategoryDistributionSvgSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;

  /// Exact prepared monetary amount. Geometry is the only later adapter that
  /// turns ratios into doubles; semantic money never leaves scaled integers.
  final int value;
  final Color color;
}

enum BudgetCategoryDistributionDonutTapTarget { outside, center, slice }

@immutable
final class BudgetCategoryDistributionDonutTap {
  const BudgetCategoryDistributionDonutTap._(this.target, [this.index]);

  const BudgetCategoryDistributionDonutTap.outside()
    : this._(BudgetCategoryDistributionDonutTapTarget.outside);
  const BudgetCategoryDistributionDonutTap.center()
    : this._(BudgetCategoryDistributionDonutTapTarget.center);
  const BudgetCategoryDistributionDonutTap.slice(int index)
    : this._(BudgetCategoryDistributionDonutTapTarget.slice, index);

  final BudgetCategoryDistributionDonutTapTarget target;
  final int? index;

  @override
  bool operator ==(Object other) =>
      other is BudgetCategoryDistributionDonutTap &&
      other.target == target &&
      other.index == index;

  @override
  int get hashCode => Object.hash(target, index);
}

/// Flutter gestures resolve against the same ring geometry as the dynamic SVG;
/// SVG paths themselves deliberately remain presentation-only.
abstract final class BudgetCategoryDistributionDonutHitTest {
  static BudgetCategoryDistributionDonutTap resolve({
    required Offset localPosition,
    required Size size,
    required List<int> values,
  }) {
    final hit = BudgetClayDonutGeometry.resolveHit(
      localPosition: localPosition,
      size: size,
      values: values,
    );
    return switch (hit.target) {
      BudgetClayDonutTapTarget.center =>
        const BudgetCategoryDistributionDonutTap.center(),
      BudgetClayDonutTapTarget.slice =>
        BudgetCategoryDistributionDonutTap.slice(hit.index!),
      BudgetClayDonutTapTarget.outside =>
        const BudgetCategoryDistributionDonutTap.outside(),
    };
  }
}

/// Fluvi-owned production implementation of the approved Budget V2 clay-donut
/// vector contract. It deliberately contains only SVG geometry, text and
/// Flutter-SVG sanitation — no transaction/store/controller architecture.
abstract final class BudgetCategoryDistributionSvg {
  static const viewBox = BudgetClayDonutGeometry.viewBox;
  static const sourceCenter = BudgetClayDonutGeometry.sourceCenter;
  static const innerRadius = BudgetClayDonutGeometry.innerRadius;
  static const normalOuterRadius = BudgetClayDonutGeometry.normalOuterRadius;
  static const selectedOuterRadius =
      BudgetClayDonutGeometry.selectedOuterRadius;
  static const centerPlateRadius = BudgetClayDonutGeometry.centerPlateRadius;
  static const selectedOffset = BudgetClayDonutGeometry.selectedOffset;

  static String flutterRenderable(String source) => source
      .replaceAll(RegExp(r'<filter\b[^>]*>.*?</filter>', dotAll: true), '')
      .replaceAll(RegExp(r'\sfilter="url\(#[^)]+\)"'), '')
      .replaceAll('font-weight="750"', 'font-weight="700"');

  static double gapDegreesForSliceCount(int count) =>
      BudgetClayDonutGeometry.gapDegreesForSliceCount(count);

  static double sweepDegrees(num value, num total) =>
      BudgetClayDonutGeometry.sweepDegrees(value, total);

  static (double, double) point(
    double cx,
    double cy,
    double radius,
    double degrees, {
    double yOffset = 0,
  }) {
    final value = BudgetClayDonutGeometry.point(
      cx,
      cy,
      radius,
      degrees,
      yOffset: yOffset,
    );
    return (value.dx, value.dy);
  }

  static (double, double) selectedOffsetFor({
    required double start,
    required double end,
  }) {
    final value = BudgetClayDonutGeometry.selectedOffsetFor(
      start: start,
      end: end,
    );
    return (value.dx, value.dy);
  }

  static String clayDonut({
    required List<BudgetCategoryDistributionSvgSlice> slices,
    required int? selectedIndex,
  }) {
    final items = slices
        .where((slice) => slice.value.isFinite && slice.value > 0)
        .toList(growable: false);
    final selected = selectedIndex == null || items.isEmpty
        ? -1
        : selectedIndex.clamp(0, items.length - 1).toInt();
    final total = items.fold<double>(0, (sum, item) => sum + item.value);
    final sidePaths = <String>[];
    final topPaths = <String>[];
    var angle = 0.0;
    final gap = gapDegreesForSliceCount(items.length);
    for (var index = 0; index < items.length; index += 1) {
      final item = items[index];
      final sweep = sweepDegrees(item.value, total);
      final start = angle + gap / 2;
      final end = angle + sweep - gap / 2;
      angle += sweep;
      if (end <= start) continue;
      final isSelected = index == selected;
      final radius = isSelected ? selectedOuterRadius : normalOuterRadius;
      final offset = isSelected
          ? selectedOffsetFor(start: start, end: end)
          : (0.0, 0.0);
      final transform = isSelected
          ? ' transform="translate(${_number(offset.$1.roundToDouble())} ${_number(offset.$2.roundToDouble())})"'
          : '';
      final selectedAttribute = isSelected
          ? ' data-fluvi-donut-selected="true"'
          : '';
      sidePaths.add(
        '<path d="${_donutOuterSidePath(radius, start, end)}" fill="${_hex(item.color)}" opacity=".84" aria-hidden="true"$transform$selectedAttribute/>',
      );
      final topPath = _donutRingSlicePath(radius, start, end);
      topPaths.add(
        '<path d="$topPath" fill="${_hex(item.color)}" stroke="#ffffff" stroke-opacity=".58" stroke-width="3" data-fluvi-donut-slice="$index" data-label="${_xmlEscape(item.label)}" data-value="${_number(item.value)}"$transform$selectedAttribute/>',
      );
      final glossTransform = isSelected
          ? 'translate(${_number(offset.$1.roundToDouble() - 4)} ${_number(offset.$2.roundToDouble() - 5)})'
          : 'translate(-4 -5)';
      topPaths.add(
        '<path d="$topPath" fill="#ffffff" opacity=".08" transform="$glossTransform" aria-hidden="true"/>',
      );
    }
    final centerValue = items.isEmpty
        ? '0%'
        : selected < 0
        ? '100%'
        : '${(items[selected].value / total * 100).round()}%';
    final centerLabel = items.isEmpty
        ? 'nincs adat'
        : selected < 0
        ? 'összesen'
        : items[selected].label;
    return '''<svg class="budget-category-distribution-clay-donut" viewBox="$viewBox" preserveAspectRatio="xMidYMid meet" role="img" data-budget-category-distribution-donut="true" data-budget-category-distribution-count="${items.length}"><defs><radialGradient id="budgetDistributionDonutCenterPlate" cx="34%" cy="28%" r="80%"><stop offset="0" stop-color="#ffffff"/><stop offset=".48" stop-color="#fbf9ff"/><stop offset="1" stop-color="#e9e3f4"/></radialGradient><linearGradient id="budgetDistributionDonutCenterRim" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ffffff" stop-opacity=".95"/><stop offset=".52" stop-color="#f1ecfa" stop-opacity=".72"/><stop offset="1" stop-color="#cfc5df" stop-opacity=".82"/></linearGradient><filter id="budgetDistributionDonutSoftShadow" x="-70%" y="-70%" width="240%" height="240%"><feGaussianBlur in="SourceAlpha" stdDeviation="13" result="b"/><feOffset in="b" dx="0" dy="16" result="o"/><feFlood flood-color="#75569c" flood-opacity=".22" result="c"/><feComposite in="c" in2="o" operator="in" result="s"/><feMerge><feMergeNode in="s"/><feMergeNode in="SourceGraphic"/></feMerge></filter><filter id="budgetDistributionDonutBlur8" x="-40%" y="-40%" width="180%" height="180%"><feGaussianBlur stdDeviation="8"/></filter><clipPath id="budgetDistributionDonutFrontSideClip"><rect x="44" y="256" width="424" height="212"/></clipPath></defs><ellipse cx="256" cy="426" rx="188" ry="38" fill="#8a6ab5" opacity=".11" filter="url(#budgetDistributionDonutBlur8)"/><g id="donut-chart" filter="url(#budgetDistributionDonutSoftShadow)"><g id="segment-sides" data-fluvi-donut-segment-sides="true" clip-path="url(#budgetDistributionDonutFrontSideClip)">${sidePaths.join()}</g><g id="segment-tops" data-fluvi-donut-segment-tops="true">${topPaths.join()}</g><circle cx="256" cy="256" r="106" fill="url(#budgetDistributionDonutCenterPlate)" stroke="url(#budgetDistributionDonutCenterRim)" stroke-width="6"/><path d="M188 212 C224 170 291 164 329 202" fill="none" stroke="#ffffff" stroke-opacity=".50" stroke-width="13" stroke-linecap="round" filter="url(#budgetDistributionDonutBlur8)"/><text id="center-value" x="256" y="252" text-anchor="middle" font-family="Inter, Arial, sans-serif" font-size="48" font-weight="750" fill="#303358">$centerValue</text><text id="center-label" x="256" y="285" text-anchor="middle" font-family="Inter, Arial, sans-serif" font-size="18" font-weight="600" fill="#7a7e9a">${_xmlEscape(centerLabel)}</text></g></svg>''';
  }

  static String _donutRingSlicePath(double radius, double start, double end) {
    final outerStart = point(sourceCenter, sourceCenter, radius, start);
    final outerEnd = point(sourceCenter, sourceCenter, radius, end);
    final innerEnd = point(sourceCenter, sourceCenter, innerRadius, end);
    final innerStart = point(sourceCenter, sourceCenter, innerRadius, start);
    final large = end - start > 180 ? 1 : 0;
    return 'M ${_number(outerStart.$1)} ${_number(outerStart.$2)} A ${_number(radius)} ${_number(radius)} 0 $large 1 ${_number(outerEnd.$1)} ${_number(outerEnd.$2)} L ${_number(innerEnd.$1)} ${_number(innerEnd.$2)} A 92 92 0 $large 0 ${_number(innerStart.$1)} ${_number(innerStart.$2)} Z';
  }

  static String _donutOuterSidePath(double radius, double start, double end) {
    final topStart = point(sourceCenter, sourceCenter, radius, start);
    final topEnd = point(sourceCenter, sourceCenter, radius, end);
    final bottomEnd = point(
      sourceCenter,
      sourceCenter,
      radius,
      end,
      yOffset: 14,
    );
    final bottomStart = point(
      sourceCenter,
      sourceCenter,
      radius,
      start,
      yOffset: 14,
    );
    final large = end - start > 180 ? 1 : 0;
    return 'M ${_number(topStart.$1)} ${_number(topStart.$2)} A ${_number(radius)} ${_number(radius)} 0 $large 1 ${_number(topEnd.$1)} ${_number(topEnd.$2)} L ${_number(bottomEnd.$1)} ${_number(bottomEnd.$2)} A ${_number(radius)} ${_number(radius)} 0 $large 0 ${_number(bottomStart.$1)} ${_number(bottomStart.$2)} Z';
  }

  static String _number(num value) {
    final asDouble = value.toDouble();
    final rounded = asDouble.roundToDouble();
    if ((asDouble - rounded).abs() < .000001) {
      return rounded.toInt().toString();
    }
    return asDouble
        .toStringAsFixed(6)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static String _xmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  static String _hex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
}
