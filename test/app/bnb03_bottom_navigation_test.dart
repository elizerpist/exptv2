import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/app/shell/bnb03_bottom_navigation.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_shell_presentation.dart';

void main() {
  const size = Size(428, 75);

  Bnb03BottomNavigationContour contour(DashboardBottomNavEdgeShape shape) =>
      Bnb03BottomNavigationContour(
        edgeShape: shape,
        fabCenterX: 214,
        fabCenterY: 24,
        fabRadius: 48,
        cornerRadius: 32,
      );

  test('straight outer contour reaches both screen-edge top corners', () {
    final rounded = contour(
      DashboardBottomNavEdgeShape.rounded,
    ).physicalPath(size);
    final straight = contour(
      DashboardBottomNavEdgeShape.straight,
    ).physicalPath(size);

    expect(straight.contains(const Offset(0, .25)), isTrue);
    expect(straight.contains(const Offset(427.75, .25)), isTrue);
    expect(rounded.contains(const Offset(0, .25)), isFalse);
    expect(rounded.contains(const Offset(427.75, .25)), isFalse);
  });

  test('outer shape changes preserve the center FAB contour geometry', () {
    final rounded = contour(
      DashboardBottomNavEdgeShape.rounded,
    ).topContour(size);
    final straight = contour(
      DashboardBottomNavEdgeShape.straight,
    ).topContour(size);

    // Both paths use the same FAB-derived arc. Shape selection must only
    // alter the two outer terminations, never the original 24px protrusion.
    expect(rounded.getBounds().top, -24);
    expect(straight.getBounds().top, -24);
    expect(rounded.getBounds().center.dx, straight.getBounds().center.dx);
  });

  test('central contour is mirrored by construction', () {
    final physical = contour(DashboardBottomNavEdgeShape.rounded);
    for (final dx in const <double>[0, 4, 12, 24, 36, 41]) {
      final leftX = physical.fabCenterX - dx;
      final rightX = physical.fabCenterX + dx;
      expect(physical.topEdgeYAt(leftX), physical.topEdgeYAt(rightX));
      expect(
        physical.mirroredTopPoint(Offset(leftX, physical.topEdgeYAt(leftX))),
        Offset(rightX, physical.topEdgeYAt(rightX)),
      );
    }
    // The actual purple ring is 84px across inside the 96px shell. The
    // physical contour owns the outer 48px radius, yielding a 6px symmetric
    // clearance at every matching radial angle.
    expect(physical.fabRadius - 42, 6);
  });

  test('contained-flat contour keeps the centre top edge horizontal', () {
    const contained = Bnb03BottomNavigationContour(
      edgeShape: DashboardBottomNavEdgeShape.rounded,
      fabCenterX: 214,
      fabCenterY: 37.5,
      fabRadius: 30,
      cornerRadius: 32,
      hasCentralProtrusion: false,
    );

    expect(contained.topEdgeYAt(214), 0);
    expect(contained.topEdgeYAt(190), 0);
    expect(contained.topEdgeYAt(238), 0);
    expect(contained.topContour(size).getBounds().top, 0);
  });

  testWidgets('shape and border controls preserve the authored FAB rect', (
    tester,
  ) async {
    Future<Rect> pump(
      DashboardBottomNavEdgeShape shape,
      DashboardBottomNavTopBorder border,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Bnb03BottomNavigation(
                selected: Bnb03Item.home,
                edgeShape: shape,
                topBorder: border,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('bnb03-physical-bar-surface')),
        findsOneWidget,
      );
      return tester.getRect(
        find.byKey(const ValueKey('bnb03-fab-outer-purple-ring')),
      );
    }

    final roundedOff = await pump(
      DashboardBottomNavEdgeShape.rounded,
      DashboardBottomNavTopBorder.off,
    );
    final straightOn = await pump(
      DashboardBottomNavEdgeShape.straight,
      DashboardBottomNavTopBorder.thinGrey,
    );
    expect(straightOn, roundedOff);
  });

  testWidgets('FAB and physical BottomNav share the exact centre line', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: Bnb03BottomNavigation(
              width: 428,
              selected: Bnb03Item.home,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final bar = tester.getRect(
      find.byKey(const ValueKey('bnb03-physical-bar-surface')),
    );
    final fab = tester.getRect(
      find.byKey(const ValueKey('bnb03-fab-outer-purple-ring')),
    );
    expect(fab.center.dx, bar.center.dx);
  });

  testWidgets(
    'contained-flat style has a wholly-contained smaller visible FAB and a 48px hit target',
    (tester) async {
      Bnb03Item? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Bnb03BottomNavigation(
                width: 428,
                selected: Bnb03Item.home,
                layoutStyle: DashboardBottomNavLayoutStyle.containedFlat,
                topBorder: DashboardBottomNavTopBorder.thinGrey,
                onChanged: (item) => selected = item,
              ),
            ),
          ),
        ),
      );

      final bar = tester.getRect(
        find.byKey(const ValueKey('bnb03-physical-bar-surface')),
      );
      final visibleFab = tester.getRect(
        find.byKey(const ValueKey('bnb03-fab-outer-purple-ring')),
      );
      final hitTarget = tester.getRect(
        find.byKey(const ValueKey('bnb03-fab-hit-target')),
      );
      expect(bar.height, 75);
      expect(visibleFab.width, lessThan(84));
      expect(visibleFab.top, greaterThanOrEqualTo(bar.top));
      expect(visibleFab.bottom, lessThanOrEqualTo(bar.bottom));
      expect(visibleFab.center.dx, bar.center.dx);
      expect(hitTarget.width, greaterThanOrEqualTo(48));
      expect(hitTarget.height, greaterThanOrEqualTo(48));
      expect(
        find.byKey(const ValueKey('bnb03-top-contour-overlay')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('bnb03-fab-hit-target')));
      expect(selected, Bnb03Item.shop);
      await tester.tap(find.text('Home'));
      expect(selected, Bnb03Item.home);
    },
  );

  testWidgets('raised style remains the default 24px-overflow geometry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: Bnb03BottomNavigation(
              width: 428,
              selected: Bnb03Item.home,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final navigation = tester.getRect(
      find.byKey(const ValueKey('bnb03-navigation-envelope')),
    );
    final bar = tester.getRect(
      find.byKey(const ValueKey('bnb03-physical-bar-surface')),
    );
    final visibleFab = tester.getRect(
      find.byKey(const ValueKey('bnb03-fab-outer-purple-ring')),
    );
    expect(navigation.height, 99);
    expect(bar.top - navigation.top, 24);
    expect(visibleFab.width, 84);
  });

  testWidgets('contained-flat raster keeps the border horizontal at centre', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>('bnb03-contained-raster-boundary');
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: Bnb03BottomNavigation(
              width: 428,
              selected: Bnb03Item.home,
              layoutStyle: DashboardBottomNavLayoutStyle.containedFlat,
              topBorder: DashboardBottomNavTopBorder.thinGrey,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );
    final image = (await tester.runAsync(
      () => boundary.toImage(pixelRatio: 1),
    ))!;
    try {
      final bytes = await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      );
      expect(bytes, isNotNull);
      for (final point in const <Offset>[
        Offset(190, 0),
        Offset(214, 0),
        Offset(238, 0),
      ]) {
        expect(
          _hasBorderPixelNear(
            bytes!,
            width: image.width,
            height: image.height,
            center: point,
          ),
          isTrue,
          reason: 'Expected a horizontal contained border near $point.',
        );
      }
    } finally {
      image.dispose();
    }
  });

  testWidgets('contained-flat keeps edge, border, and SafeArea behavior', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(bottom: 24);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: SafeArea(
            top: false,
            child: Bnb03BottomNavigation(
              width: 428,
              selected: Bnb03Item.home,
              edgeShape: DashboardBottomNavEdgeShape.straight,
              layoutStyle: DashboardBottomNavLayoutStyle.containedFlat,
              topBorder: DashboardBottomNavTopBorder.off,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final bar = tester.getRect(
      find.byKey(const ValueKey('bnb03-physical-bar-surface')),
    );
    final ring = tester.getRect(
      find.byKey(const ValueKey('bnb03-fab-outer-purple-ring')),
    );
    expect(
      find.byKey(const ValueKey('bnb03-top-contour-overlay')),
      findsNothing,
    );
    expect(ring.top, greaterThanOrEqualTo(bar.top));
    expect(ring.bottom, lessThanOrEqualTo(bar.bottom));

    const straightFlat = Bnb03BottomNavigationContour(
      edgeShape: DashboardBottomNavEdgeShape.straight,
      fabCenterX: 214,
      fabCenterY: 37.5,
      fabRadius: 30,
      cornerRadius: 32,
      hasCentralProtrusion: false,
    );
    expect(
      straightFlat.physicalPath(size).contains(const Offset(0, .25)),
      isTrue,
    );
  });

  testWidgets(
    'thin border uses one final non-interactive contour overlay above the FAB',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Bnb03BottomNavigation(
                selected: Bnb03Item.home,
                topBorder: DashboardBottomNavTopBorder.thinGrey,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      final contourOverlay = find.byKey(
        const ValueKey('bnb03-top-contour-overlay'),
      );
      expect(contourOverlay, findsOneWidget);
      expect(tester.widget<IgnorePointer>(contourOverlay).ignoring, isTrue);
      expect(
        find.byKey(const ValueKey('bnb03-top-contour-overlay-paint')),
        findsOneWidget,
      );
    },
  );

  testWidgets('composited contour remains visible across both FAB sides', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Bnb03BottomNavigation(
              width: 428,
              selected: Bnb03Item.home,
              topBorder: DashboardBottomNavTopBorder.thinGrey,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final stack = tester.widget<Stack>(
      find.ancestor(
        of: find.byKey(const ValueKey('bnb03-top-contour-overlay')),
        matching: find.byType(Stack),
      ),
    );
    final fabIndex = stack.children.indexWhere(
      (child) => child.key == const ValueKey('bnb03-fab-layer'),
    );
    final overlayIndex = stack.children.indexWhere(
      (child) => child.key == const ValueKey('bnb03-top-contour-layer'),
    );

    // This verifies the actual Stack composition, not only the mathematical
    // Path: the one canonical contour is painted after the FAB backing layer.
    expect(fabIndex, greaterThanOrEqualTo(0));
    expect(overlayIndex, greaterThan(fabIndex));
  });

  testWidgets('the final raster contains the contour across both FAB sides', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>('bnb03-raster-boundary');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: Bnb03BottomNavigation(
                width: 428,
                selected: Bnb03Item.home,
                topBorder: DashboardBottomNavTopBorder.thinGrey,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );
    final image = (await tester.runAsync(
      () => boundary.toImage(pixelRatio: 1),
    ))!;
    try {
      final bytes = await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      );
      expect(bytes, isNotNull);

      // The BNB's 75px bar begins at y=24 inside its 99px boundary. These
      // points sample the actual left rise, crest, right fall and horizontal
      // continuations. Before the foreground overlay, the FAB white backing
      // hid the right-fall sample even though the mathematical Path had it.
      for (final point in const <Offset>[
        Offset(150, 24),
        Offset(190, 6),
        Offset(214, 0),
        Offset(238, 6),
        Offset(280, 24),
      ]) {
        expect(
          _hasBorderPixelNear(
            bytes!,
            width: image.width,
            height: image.height,
            center: point,
          ),
          isTrue,
          reason: 'Expected the one final contour near $point.',
        );
      }
    } finally {
      image.dispose();
    }
  });
}

bool _hasBorderPixelNear(
  ByteData bytes, {
  required int width,
  required int height,
  required Offset center,
}) {
  for (var y = center.dy.round() - 3; y <= center.dy.round() + 3; y += 1) {
    for (var x = center.dx.round() - 3; x <= center.dx.round() + 3; x += 1) {
      if (x < 0 || y < 0 || x >= width || y >= height) continue;
      final offset = (y * width + x) * 4;
      final red = bytes.getUint8(offset);
      final green = bytes.getUint8(offset + 1);
      final blue = bytes.getUint8(offset + 2);
      if ((red - 0xE2).abs() <= 18 &&
          (green - 0xE8).abs() <= 18 &&
          (blue - 0xF0).abs() <= 18) {
        return true;
      }
    }
  }
  return false;
}
