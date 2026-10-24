import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_unified_mother_card_motion.dart';

void main() {
  testWidgets(
    'physical viewport fades trailing ink and reverses without remount',
    (tester) async {
      const capture = ValueKey('clip-capture');
      const ink = ValueKey('persistent-content');
      Future<void> render(double fade, {bool enabled = true}) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: RepaintBoundary(
                  key: capture,
                  child: Stack(
                    children: [
                      DashboardMotherCardContentClip(
                        bounds: const Rect.fromLTRB(10, 10, 90, 80),
                        radius: BorderRadius.zero,
                        trailingFadeExtent: fade,
                        enabled: enabled,
                        child: const Positioned.fill(
                          child: ColoredBox(key: ink, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      Future<int> alpha(int y) async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(capture),
        );
        return (await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final value = bytes.getUint8((y * 100 + 50) * 4 + 3);
          image.dispose();
          return value;
        }))!;
      }

      await render(0);
      final element = tester.element(find.byKey(ink));
      expect(await alpha(79), 255);
      expect(await alpha(81), 0);
      await render(20);
      expect(tester.element(find.byKey(ink)), same(element));
      expect(await alpha(59), 255);
      expect(await alpha(70), inExclusiveRange(70, 180));
      expect(await alpha(79), lessThan(25));
      expect(await alpha(81), 0);
      await render(0);
      expect(tester.element(find.byKey(ink)), same(element));
      expect(await alpha(79), 255);
      await render(20, enabled: false);
      expect(tester.element(find.byKey(ink)), same(element));
      expect(await alpha(90), 255);
      expect(tester.takeException(), isNull);
    },
  );
}
