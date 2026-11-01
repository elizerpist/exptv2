import 'dart:convert';

import 'package:flutter/material.dart';

/// A value-only paint material used by the Fluvi mark and the two editable
/// application surfaces.  The model intentionally describes a fill, not a
/// widget: the same instance can be persisted, previewed and painted into a
/// clipped navigation contour without introducing a second colour authority.
@immutable
final class FluviSurfaceFill {
  const FluviSurfaceFill({
    required this.leftArgb,
    required this.rightArgb,
    required this.boundaryPercent,
    this.middleArgb,
  }) : assert(boundaryPercent >= 0 && boundaryPercent <= 100);

  const FluviSurfaceFill.solid(int argb)
    : leftArgb = argb,
      rightArgb = argb,
      middleArgb = argb,
      boundaryPercent = 50;

  final int leftArgb;
  final int rightArgb;

  /// `null` means the fill owns a two-endpoint gradient.  Its middle is kept
  /// at the visual 50% mix while [boundaryPercent] moves the stop itself.  It
  /// deliberately does *not* interpolate at the boundary again: that made the
  /// former custom-gradient slider mathematically invisible.
  final int? middleArgb;
  final double boundaryPercent;

  Color get left => Color(leftArgb);
  Color get right => Color(rightArgb);
  Color get effectiveMiddle =>
      middleArgb == null ? Color.lerp(left, right, .5)! : Color(middleArgb!);

  bool get isSolid =>
      leftArgb == rightArgb && effectiveMiddle.toARGB32() == leftArgb;

  LinearGradient gradient({
    AlignmentGeometry begin = Alignment.centerLeft,
    AlignmentGeometry end = Alignment.centerRight,
  }) => LinearGradient(
    begin: begin,
    end: end,
    colors: <Color>[left, effectiveMiddle, right],
    // Duplicate end stops are valid and make 0% and 100% deterministic rather
    // than silently rewriting the value the user selected.
    stops: <double>[0, boundaryPercent / 100, 1],
  );

  FluviSurfaceFill copyWith({
    int? leftArgb,
    int? rightArgb,
    int? middleArgb,
    bool clearMiddle = false,
    double? boundaryPercent,
  }) => FluviSurfaceFill(
    leftArgb: leftArgb ?? this.leftArgb,
    rightArgb: rightArgb ?? this.rightArgb,
    middleArgb: clearMiddle ? null : (middleArgb ?? this.middleArgb),
    boundaryPercent: (boundaryPercent ?? this.boundaryPercent)
        .clamp(0, 100)
        .toDouble(),
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'leftArgb': leftArgb,
    'rightArgb': rightArgb,
    'middleArgb': middleArgb,
    'boundaryPercent': boundaryPercent,
  };

  static FluviSurfaceFill? tryParse(Object? source) {
    if (source is! Map) return null;
    final left = source['leftArgb'];
    final right = source['rightArgb'];
    final boundary = source['boundaryPercent'];
    if (left is! num || right is! num || boundary is! num) return null;
    final middle = source['middleArgb'];
    if (middle != null && middle is! num) return null;
    final normalizedBoundary = boundary.toDouble();
    if (!normalizedBoundary.isFinite ||
        normalizedBoundary < 0 ||
        normalizedBoundary > 100) {
      return null;
    }
    return FluviSurfaceFill(
      leftArgb: left.toInt(),
      rightArgb: right.toInt(),
      middleArgb: middle is num ? middle.toInt() : null,
      boundaryPercent: normalizedBoundary,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FluviSurfaceFill &&
      other.leftArgb == leftArgb &&
      other.rightArgb == rightArgb &&
      other.middleArgb == middleArgb &&
      other.boundaryPercent == boundaryPercent;

  @override
  int get hashCode =>
      Object.hash(leftArgb, rightArgb, middleArgb, boundaryPercent);
}

/// The persisted appearance values used by the editable Fluvi brand mark and
/// the editable page and bottom-navigation surfaces.
@immutable
final class FluviBrandSurfaceAppearance {
  const FluviBrandSurfaceAppearance({
    required this.logoTop,
    required this.logoBottom,
    required this.pageBackground,
    required this.bottomNavigation,
    required this.customSlots,
  });

  static const _slotCount = 5;

  static const defaults = FluviBrandSurfaceAppearance(
    // These reproduce the supplied four-path Fluvi vector exactly when no
    // custom fill has been applied.  Detail paths stay on their authored
    // source treatment in that default case.
    logoTop: FluviSurfaceFill(
      leftArgb: 0xFF00EDF5,
      rightArgb: 0xFF5385FF,
      boundaryPercent: 50,
    ),
    logoBottom: FluviSurfaceFill(
      leftArgb: 0xFFCE51FA,
      rightArgb: 0xFF2E6AFE,
      boundaryPercent: 50,
    ),
    pageBackground: FluviSurfaceFill.solid(0xFFF1F5F9),
    bottomNavigation: FluviSurfaceFill.solid(0xFFFFFFFF),
    customSlots: <FluviSurfaceFill>[
      FluviSurfaceFill(
        leftArgb: 0xFFFFFFFF,
        rightArgb: 0xFF0F172A,
        boundaryPercent: 50,
      ),
      FluviSurfaceFill(
        leftArgb: 0xFFF8FAFC,
        rightArgb: 0xFF06B6D4,
        boundaryPercent: 50,
      ),
      FluviSurfaceFill(
        leftArgb: 0xFF22C55E,
        rightArgb: 0xFF8B5CF6,
        boundaryPercent: 50,
      ),
      FluviSurfaceFill(
        leftArgb: 0xFFFBF8CC,
        rightArgb: 0xFFB9FBC0,
        boundaryPercent: 50,
      ),
      FluviSurfaceFill(
        leftArgb: 0xFFD9ED92,
        rightArgb: 0xFF184E77,
        boundaryPercent: 50,
      ),
    ],
  );

  final FluviSurfaceFill logoTop;
  final FluviSurfaceFill logoBottom;
  final FluviSurfaceFill pageBackground;
  final FluviSurfaceFill bottomNavigation;
  final List<FluviSurfaceFill> customSlots;

  bool get hasDefaultLogoFills =>
      logoTop == defaults.logoTop && logoBottom == defaults.logoBottom;

  FluviBrandSurfaceAppearance copyWith({
    FluviSurfaceFill? logoTop,
    FluviSurfaceFill? logoBottom,
    FluviSurfaceFill? pageBackground,
    FluviSurfaceFill? bottomNavigation,
    List<FluviSurfaceFill>? customSlots,
  }) => FluviBrandSurfaceAppearance(
    logoTop: logoTop ?? this.logoTop,
    logoBottom: logoBottom ?? this.logoBottom,
    pageBackground: pageBackground ?? this.pageBackground,
    bottomNavigation: bottomNavigation ?? this.bottomNavigation,
    customSlots: customSlots ?? this.customSlots,
  );

  FluviBrandSurfaceAppearance withCustomSlot(int index, FluviSurfaceFill fill) {
    if (index < 0 || index >= customSlots.length) return this;
    final next = List<FluviSurfaceFill>.of(customSlots)..[index] = fill;
    return copyWith(customSlots: List<FluviSurfaceFill>.unmodifiable(next));
  }

  String encode() => jsonEncode(<String, Object?>{
    'version': 1,
    'logoTop': logoTop.toJson(),
    'logoBottom': logoBottom.toJson(),
    'pageBackground': pageBackground.toJson(),
    'bottomNavigation': bottomNavigation.toJson(),
    'customSlots': <Object?>[for (final slot in customSlots) slot.toJson()],
  });

  static FluviBrandSurfaceAppearance decode(Object? raw) {
    if (raw is! String || raw.isEmpty) return defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['version'] != 1) return defaults;
      final top = FluviSurfaceFill.tryParse(decoded['logoTop']);
      final bottom = FluviSurfaceFill.tryParse(decoded['logoBottom']);
      final background = FluviSurfaceFill.tryParse(decoded['pageBackground']);
      final navigation = FluviSurfaceFill.tryParse(decoded['bottomNavigation']);
      final rawSlots = decoded['customSlots'];
      if (top == null ||
          bottom == null ||
          background == null ||
          navigation == null ||
          rawSlots is! List ||
          rawSlots.length != _slotCount) {
        return defaults;
      }
      final slots = <FluviSurfaceFill>[];
      for (final rawSlot in rawSlots) {
        final slot = FluviSurfaceFill.tryParse(rawSlot);
        if (slot == null) return defaults;
        slots.add(slot);
      }
      return FluviBrandSurfaceAppearance(
        logoTop: top,
        logoBottom: bottom,
        pageBackground: background,
        bottomNavigation: navigation,
        customSlots: List<FluviSurfaceFill>.unmodifiable(slots),
      );
    } on FormatException {
      return defaults;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is FluviBrandSurfaceAppearance &&
      other.logoTop == logoTop &&
      other.logoBottom == logoBottom &&
      other.pageBackground == pageBackground &&
      other.bottomNavigation == bottomNavigation &&
      _sameSlots(other.customSlots, customSlots);

  @override
  int get hashCode => Object.hash(
    logoTop,
    logoBottom,
    pageBackground,
    bottomNavigation,
    Object.hashAll(customSlots),
  );

  static bool _sameSlots(
    List<FluviSurfaceFill> left,
    List<FluviSurfaceFill> right,
  ) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
