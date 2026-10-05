import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart' show vg;
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:fluvi/core/design/fluvi_global_appearance.dart';
import 'package:fluvi/app/shell/bnb03_bottom_navigation.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
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
        find.byKey(const ValueKey('bnb03-fab-visible-footprint')),
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
      find.byKey(const ValueKey('bnb03-fab-visible-footprint')),
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
        find.byKey(const ValueKey('bnb03-fab-visible-footprint')),
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
      find.byKey(const ValueKey('bnb03-fab-visible-footprint')),
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
      find.byKey(const ValueKey('bnb03-fab-visible-footprint')),
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

  testWidgets('bottom navigation inherits the one selected global typeface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FluviTypographyProfile.colorLab.applyToTheme(ThemeData()),
        home: Bnb03BottomNavigation(
          selected: Bnb03Item.home,
          onChanged: (_) {},
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text('Home')).style!.fontFamily,
      'FluviColorLabInter',
    );
    expect(
      find.textContaining('SF Pro Text'),
      findsNothing,
      reason: 'The former hardcoded bottom-navigation family must not survive.',
    );
  });

  testWidgets(
    'BNB FAB defaults to the active income add-transaction artwork instead of the shop glyph',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Bnb03BottomNavigation(
            selected: Bnb03Item.home,
            onChanged: (_) {},
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('bnb03-fab-income-artwork')),
        findsOneWidget,
      );
      expect(find.byIcon(IconsaxPlusLinear.shop), findsNothing);
      expect(find.byIcon(IconsaxPlusBold.shop), findsNothing);
    },
  );

  test(
    'FAB visual resolves active direction artwork without retaining a hidden coloured ring',
    () {
      final income = Bnb03FabDirectionVisual.resolve(
        direction: TransactionDirection.income,
        profile: FluviDirectionColorProfile.vivid,
      );
      final expense = Bnb03FabDirectionVisual.resolve(
        direction: TransactionDirection.expense,
        profile: FluviDirectionColorProfile.vivid,
      );
      final expectedIncome = FluviDirectionColorPaletteCatalog.income(
        FluviDirectionColorProfile.vivid,
      );
      final expectedExpense = FluviDirectionColorPaletteCatalog.expense(
        FluviDirectionColorProfile.vivid,
      );

      expect(income.gradient.begin, Alignment.topLeft);
      expect(income.gradient.end, Alignment.bottomRight);
      expect(income.gradient.colors, expectedIncome.colors);
      expect(income.ringColor, isNull);
      expect(expense.gradient.colors, expectedExpense.colors);
      expect(expense.ringColor, isNull);
      expect(income.artworkAssetPath, 'assets/fluvi/actions/addnew_income.png');
      expect(
        expense.artworkAssetPath,
        'assets/fluvi/actions/addnew_expense.png',
      );
    },
  );

  testWidgets('FAB switches to expense artwork with the active direction', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Bnb03BottomNavigation(
          selected: Bnb03Item.home,
          transactionDirection: TransactionDirection.expense,
          directionColorProfile: FluviDirectionColorProfile.pastel,
          onChanged: (_) {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('bnb03-fab-expense-artwork')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('bnb03-fab-income-artwork')),
      findsNothing,
    );
  });

  testWidgets(
    'FAB artwork fills the former ring footprint without a ring or inner core while legacy retains the white shop glyph',
    (tester) async {
      final artwork = Bnb03FabDirectionVisual.resolve(
        direction: TransactionDirection.expense,
        profile: FluviDirectionColorProfile.vivid,
        iconPresentation: FluviFabIconPresentation.directionArtwork,
      );
      expect(artwork.coreColor, isNull);
      expect(artwork.ringColor, isNull);

      await tester.pumpWidget(
        MaterialApp(
          home: Bnb03BottomNavigation(
            width: 428,
            selected: Bnb03Item.home,
            transactionDirection: TransactionDirection.expense,
            directionColorProfile: FluviDirectionColorProfile.vivid,
            onChanged: (_) {},
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('bnb03-fab-outer-purple-ring')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('bnb03-fab-core')),
        findsNothing,
      );
      expect(
        tester.getSize(
          find.byKey(const ValueKey<String>('bnb03-fab-expense-artwork')),
        ),
        const Size(84, 84),
        reason:
            'Artwork owns the visible ring footprint instead of the former '
            'small inner-glyph area.',
      );
      final artworkScale = tester.widget<Transform>(
        find.byKey(const ValueKey<String>('bnb03-fab-artwork-optical-scale')),
      );
      final scale = artworkScale.transform.storage[0];
      expect(scale, greaterThan(1));
      expect(
        Bnb03FabArtworkGeometry.opaqueWidthFor(
          visibleFootprintDiameter: 84,
          scale: scale,
        ),
        closeTo(84, .01),
        reason:
            'The 820px opaque width inside the supplied 1024px PNG must '
            'visually reach the former 84px coloured-ring diameter.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Bnb03BottomNavigation(
            selected: Bnb03Item.home,
            transactionDirection: TransactionDirection.expense,
            directionColorProfile: FluviDirectionColorProfile.vivid,
            fabIconPresentation: FluviFabIconPresentation.legacyWhiteStore,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.byIcon(IconsaxPlusLinear.shop), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('bnb03-fab-expense-artwork')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('bnb03-fab-outer-purple-ring')),
        findsOneWidget,
      );
    },
  );

  test(
    'FAB legacy white-store mode derives its ring midpoint and diagonal core from the active direction pill',
    () {
      for (final direction in TransactionDirection.values) {
        for (final profile in FluviDirectionColorProfile.values) {
          final visual = Bnb03FabDirectionVisual.resolve(
            direction: direction,
            profile: profile,
            iconPresentation: FluviFabIconPresentation.legacyWhiteStore,
          );
          final expected = direction == TransactionDirection.income
              ? FluviDirectionColorPaletteCatalog.income(profile)
              : FluviDirectionColorPaletteCatalog.expense(profile);

          expect(visual.showsArtwork, isFalse);
          expect(visual.gradient.begin, Alignment.topLeft);
          expect(visual.gradient.end, Alignment.bottomRight);
          expect(visual.gradient.colors, expected.colors);
          expect(visual.gradient.stops, expected.stops);
          expect(
            visual.ringColor,
            FluviDirectionColorPaletteCatalog.midpoint(expected),
          );
        }
      }
    },
  );

  testWidgets('FAB artwork has one ring-free full-footprint visual state', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>('bnb03-artwork-golden-boundary');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: RepaintBoundary(
              key: boundaryKey,
              child: Bnb03BottomNavigation(
                width: 428,
                selected: Bnb03Item.home,
                transactionDirection: TransactionDirection.expense,
                directionColorProfile: FluviDirectionColorProfile.vivid,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('../goldens/bnb03_fab_direction_artwork.png'),
    );
  });

  testWidgets(
    'compact vector FAB keeps the established direction-gradient button chrome and stays inside it',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Bnb03BottomNavigation(
                width: 428,
                selected: Bnb03Item.home,
                transactionDirection: TransactionDirection.expense,
                fabIconPresentation:
                    FluviFabIconPresentation.compactEditableVector,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      final footprint = find.byKey(
        const ValueKey<String>('bnb03-fab-visible-footprint'),
      );
      final vector = find.byKey(
        const ValueKey<String>('bnb03-fab-compact-vector'),
      );
      expect(vector, findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('bnb03-fab-button-shell')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('bnb03-fab-outer-purple-ring')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('bnb03-fab-core')),
        findsOneWidget,
      );
      expect(
        tester.getSize(vector).width,
        lessThan(tester.getSize(footprint).width),
      );
    },
  );

  testWidgets(
    'full baby-blue vector FAB owns the artwork footprint without a button shell, ring, or core',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Bnb03BottomNavigation(
                width: 428,
                selected: Bnb03Item.home,
                transactionDirection: TransactionDirection.income,
                fabIconPresentation:
                    FluviFabIconPresentation.fullBabyBlueVector,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      final footprint = find.byKey(
        const ValueKey<String>('bnb03-fab-visible-footprint'),
      );
      final vector = find.byKey(
        const ValueKey<String>('bnb03-fab-full-baby-blue-vector'),
      );
      expect(vector, findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('bnb03-fab-button-shell')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('bnb03-fab-outer-purple-ring')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('bnb03-fab-core')),
        findsNothing,
      );
      expect(tester.getSize(vector).width, tester.getSize(footprint).width);
      expect(
        find.byKey(const ValueKey<String>('bnb03-fab-hit-target')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'vector FAB treatments retain their distinct material hierarchy',
    (tester) async {
      Future<void> expectVectorGolden({
        required String boundaryId,
        required FluviFabIconPresentation presentation,
        required String golden,
      }) async {
        final boundaryKey = ValueKey<String>(boundaryId);
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: RepaintBoundary(
                key: boundaryKey,
                child: Bnb03BottomNavigation(
                  width: 428,
                  selected: Bnb03Item.home,
                  transactionDirection: TransactionDirection.expense,
                  directionColorProfile: FluviDirectionColorProfile.original,
                  fabIconPresentation: presentation,
                  fabVectorPrimaryArgb: 0xFF6948DB,
                  fabVectorHighlightArgb: 0xFFE5DEFF,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(vg.waitForPendingDecodes);
        await tester.pump();
        await expectLater(find.byKey(boundaryKey), matchesGoldenFile(golden));
      }

      await expectVectorGolden(
        boundaryId: 'bnb03-compact-vector-golden-boundary',
        presentation: FluviFabIconPresentation.compactEditableVector,
        golden: '../goldens/bnb03_fab_compact_vector.png',
      );
      await expectVectorGolden(
        boundaryId: 'bnb03-full-baby-blue-vector-golden-boundary',
        presentation: FluviFabIconPresentation.fullBabyBlueVector,
        golden: '../goldens/bnb03_fab_full_baby_blue_vector.png',
      );
    },
  );
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
