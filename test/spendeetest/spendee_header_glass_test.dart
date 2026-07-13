import 'dart:io';
import 'dart:ui' as ui;

import 'package:exptv2/features/transactions/widgets/experimental/spendee_header_glass.dart';
import 'package:exptv2/features/transactions/widgets/experimental/spendee_header_visual_spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final spec = SpendeeHeaderVisualSpec.budgetDefault();

  testWidgets(
    'glass paint order keeps graphics behind semantic content and border last',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 372,
              height: 104,
              child: SpendeeHeaderGlassSurface(
                spec: spec,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
          ),
        ),
      );

      final surface = find.byType(SpendeeHeaderGlassSurface);
      final stackFinder = find.descendant(
        of: surface,
        matching: find.byType(Stack),
      );
      final stack = tester.widget<Stack>(stackFinder);

      expect(stack.children, hasLength(3));
      expect(
        stack.children[0].key,
        const ValueKey('spendee-test-header-graphic-opacity'),
      );
      expect(
        stack.children[1].key,
        const ValueKey('spendee-test-header-semantic-content'),
      );
      expect(
        find.byKey(const ValueKey('spendee-test-header-glass-layer')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-header-foreground-border')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Opacity>(
              find.byKey(const ValueKey('spendee-test-header-graphic-opacity')),
            )
            .opacity,
        closeTo(.57, 1e-12),
      );
    },
  );

  test('foreground border is pure white on the straight top edge', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(372, 104);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    SpendeeHeaderBorderPainter(spec).paint(canvas, size);
    final image = await recorder.endRecording().toImage(372, 104);
    addTearDown(image.dispose);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(bytes, isNotNull);
    const x = 186;
    const y = 0;
    final offset = (y * image.width + x) * 4;

    expect(bytes!.getUint8(offset), 255);
    expect(bytes.getUint8(offset + 1), 255);
    expect(bytes.getUint8(offset + 2), 255);
    expect(bytes.getUint8(offset + 3), 255);
  });

  testWidgets('menu surface and bars use the exact HTML geometry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SpendeeHeaderMenuButton(spec: spec, onPressed: () {}),
        ),
      ),
    );

    final menu = find.byKey(const ValueKey('spendee-test-header-menu-button'));
    expect(tester.getSize(menu), const Size.square(33.6));
    final customPaint = tester.widget<CustomPaint>(
      find.descendant(of: menu, matching: find.byType(CustomPaint)),
    );
    expect(customPaint.painter, isA<SpendeeHeaderMenuSurfacePainter>());

    for (var index = 0; index < 3; index += 1) {
      final bar = find.byKey(ValueKey('spendee-test-header-menu-bar-$index'));
      expect(bar, findsOneWidget);
      expect(tester.getSize(bar), const Size(16, 3));
      final decoration = tester.widget<Container>(bar).decoration;
      expect(decoration, isA<BoxDecoration>());
      final box = decoration! as BoxDecoration;
      expect(box.borderRadius, BorderRadius.circular(1.5));
      final gradient = box.gradient! as LinearGradient;
      expect(gradient.colors, spec.menu.barGradientColors);
      expect(gradient.stops, spec.menu.barGradientStops);
    }
  });

  test('menu painter exposes distinct fill border and inset pixels', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size.square(34);
    SpendeeHeaderMenuSurfacePainter(spec.menu).paint(canvas, size);
    final image = await recorder.endRecording().toImage(34, 34);
    addTearDown(image.dispose);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(bytes, isNotNull);

    List<int> pixelAt(int x, int y) {
      final offset = (y * image.width + x) * 4;
      return List<int>.generate(4, (index) => bytes!.getUint8(offset + index));
    }

    final fill = pixelAt(17, 17);
    final border = pixelAt(17, 0);
    final topInset = pixelAt(17, 1);
    final bottomInset = pixelAt(17, 32);

    expect(fill[3], closeTo(82, 1));
    expect(border[3], greaterThan(fill[3]));
    expect(topInset[3], greaterThan(fill[3]));
    expect(bottomInset[2], greaterThan(bottomInset[0]));
  });

  test('production brand asset is an exact packaged copy of the reference', () {
    final reference = File(
      'docs/prototypes/spendee_final_spendeevector.svg',
    ).readAsBytesSync();
    final packaged = File(
      'assets/brand/final_spendeevector.svg',
    ).readAsBytesSync();

    expect(packaged, reference);
  });
}
