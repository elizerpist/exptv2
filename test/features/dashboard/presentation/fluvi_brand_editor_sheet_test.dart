import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/fluvi_surface_fill.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/fluvi_brand_editor_sheet.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/fluvi_brand_mark.dart';

void main() {
  testWidgets(
    'a palette choice is inert until its active target preview is tapped',
    (tester) async {
      final changes = <FluviBrandSurfaceAppearance>[];
      final persists = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showFluviBrandEditorSheet(
                context: context,
                appearance: FluviBrandSurfaceAppearance.defaults,
                onChanged: (appearance, {required persist}) {
                  changes.add(appearance);
                  persists.add(persist);
                },
              ),
              child: const Text('Megnyitás'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Megnyitás'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('fluvi-brand-palette-light-D1')),
      );
      await tester.pump();
      expect(changes, isEmpty);

      await tester.tap(
        find.byKey(const ValueKey('fluvi-brand-target-background')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('fluvi-brand-background-preview')),
      );
      await tester.pump();
      expect(changes, hasLength(1));
      expect(persists.single, isTrue);
      expect(changes.single.pageBackground.leftArgb, 0xFFFFFFFF);
    },
  );

  testWidgets('custom boundary commits only at the semantic change end', (
    tester,
  ) async {
    final persists = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showFluviBrandEditorSheet(
              context: context,
              appearance: FluviBrandSurfaceAppearance.defaults,
              onChanged: (_, {required persist}) => persists.add(persist),
            ),
            child: const Text('Megnyitás'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Megnyitás'));
    await tester.pumpAndSettle();
    final slider = find.byKey(
      const ValueKey('fluvi-brand-custom-boundary-slider-0'),
    );
    await tester.ensureVisible(slider);
    await tester.drag(slider, const Offset(70, 0));
    await tester.pump();
    expect(persists, contains(false));
    expect(persists.last, isTrue);
  });

  testWidgets('the two logo arcs accept independent chosen fills', (
    tester,
  ) async {
    final changes = <FluviBrandSurfaceAppearance>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showFluviBrandEditorSheet(
              context: context,
              appearance: FluviBrandSurfaceAppearance.defaults,
              onChanged: (appearance, {required persist}) {
                if (persist) changes.add(appearance);
              },
            ),
            child: const Text('Megnyitás'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Megnyitás'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('fluvi-brand-palette-light-D1')),
    );
    await tester.tap(find.byKey(const ValueKey('fluvi-brand-apply-logo-top')));
    await tester.pump();
    expect(changes.single.logoTop.leftArgb, 0xFFFFFFFF);
    expect(
      changes.single.logoBottom,
      FluviBrandSurfaceAppearance.defaults.logoBottom,
    );

    await tester.tap(
      find.byKey(const ValueKey('fluvi-brand-palette-app-expense')),
    );
    await tester.tap(
      find.byKey(const ValueKey('fluvi-brand-apply-logo-bottom')),
    );
    await tester.pump();
    expect(changes.last.logoTop.leftArgb, 0xFFFFFFFF);
    expect(changes.last.logoBottom.leftArgb, isNot(0xFFCE51FA));
  });

  testWidgets(
    'the bottom-navigation target applies only after its preview tap',
    (tester) async {
      final changes = <FluviBrandSurfaceAppearance>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showFluviBrandEditorSheet(
                context: context,
                appearance: FluviBrandSurfaceAppearance.defaults,
                onChanged: (appearance, {required persist}) {
                  if (persist) changes.add(appearance);
                },
              ),
              child: const Text('Megnyitás'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Megnyitás'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('fluvi-brand-palette-app-expense')),
      );
      await tester.tap(
        find.byKey(const ValueKey('fluvi-brand-target-bottomNavigation')),
      );
      await tester.pump();
      expect(changes, isEmpty);

      await tester.tap(
        find.byKey(const ValueKey('fluvi-brand-bottom-navigation-preview')),
      );
      await tester.pump();
      expect(changes, hasLength(1));
      expect(
        changes.single.bottomNavigation,
        isNot(FluviBrandSurfaceAppearance.defaults.bottomNavigation),
      );
      expect(
        changes.single.pageBackground,
        FluviBrandSurfaceAppearance.defaults.pageBackground,
      );
    },
  );

  testWidgets('a custom mark uses the boundary-aware four-path vector', (
    tester,
  ) async {
    final top = FluviBrandSurfaceAppearance.defaults.logoTop.copyWith(
      leftArgb: 0xFF102A43,
      rightArgb: 0xFF38B2AC,
      boundaryPercent: 72,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: FluviBrandMark(
            appearance: FluviBrandSurfaceAppearance.defaults.copyWith(
              logoTop: top,
            ),
            width: 160,
            height: 160,
            preferPreparedAsset: false,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
