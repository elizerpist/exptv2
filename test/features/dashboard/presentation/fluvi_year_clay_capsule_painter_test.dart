import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/core/design/fluvi_year_clay_capsule_painter.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_clay_semicircle_gauge.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_year_focused_layout.dart';

void main() {
  testWidgets('shared annual capsule is pixel-identical to original Budget', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final strip in [false, true]) {
        for (final width in [4.0, 8.0, 14.0]) {
          for (final base in [
            FluviVisualTokens.budgetProgressHealthy,
            FluviVisualTokens.budgetProgressDanger,
          ]) {
            final m = BudgetClayActiveMaterial.forSemanticBase(base);
            final rect = Rect.fromLTWH(20, 15, width, 70);
            Future<ui.Image> render(int renderer) async {
              final recorder = ui.PictureRecorder();
              final canvas = Canvas(recorder);
              canvas.drawColor(Colors.white, BlendMode.src);
              if (renderer == 0) {
                _original(
                  canvas,
                  rect: rect,
                  clayMaterial: m,
                  showDecorativeStrip: strip,
                );
              } else if (renderer == 2) {
                BalanceYearFocusedChartPainter.paintCapsule(
                  canvas,
                  rect,
                  m,
                  strip: strip,
                );
              } else {
                FluviYearClayCapsulePainter.paint(
                  canvas,
                  rect: rect,
                  colors: m.colors,
                  depthColors: m.depthColors,
                  stops: m.stops,
                  showDecorativeStrip: strip,
                );
              }
              final picture = recorder.endRecording();
              final image = await picture.toImage(60, 100);
              picture.dispose();
              return image;
            }

            final original = await render(0);
            final shared = await render(1);
            final expected = await original.toByteData();
            final actual = await shared.toByteData();
            expect(
              actual!.buffer.asUint8List(),
              orderedEquals(expected!.buffer.asUint8List()),
              reason: 'width=$width strip=$strip base=$base',
            );
            final balance = await render(2);
            final balancePixels = await balance.toByteData();
            expect(
              balancePixels!.buffer.asUint8List(),
              orderedEquals(expected.buffer.asUint8List()),
              reason:
                  'Balance uses exact Budget material, width=$width strip=$strip base=$base',
            );
            balance.dispose();
            original.dispose();
            shared.dispose();
          }
        }
      }
    });
  });
}

// Frozen original Budget draw commands, independent of production primitive.
void _original(
  Canvas canvas, {
  required Rect rect,
  required BudgetClayActiveMaterial clayMaterial,
  required bool showDecorativeStrip,
}) {
  final radius = Radius.circular(rect.width / 2);
  final capsule = RRect.fromRectAndRadius(rect, radius);
  final depthOffset = Offset(rect.width * .10, math.max(.8, rect.width * .17));
  canvas.drawRRect(
    capsule.shift(depthOffset),
    Paint()
      ..color = clayMaterial.depthColors.last.withValues(alpha: .34)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, rect.width * .14),
  );
  canvas.drawRRect(
    capsule.shift(Offset(0, rect.width * .10)),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: clayMaterial.depthColors,
        stops: clayMaterial.stops,
      ).createShader(rect),
  );
  canvas.drawRRect(
    capsule,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: clayMaterial.colors,
        stops: clayMaterial.stops,
      ).createShader(rect),
  );
  if (!showDecorativeStrip) return;
  final capInset = math.min(rect.width * .22, rect.height * .22);
  final stripRect = Rect.fromLTWH(
    rect.left + rect.width * .18,
    rect.top + capInset,
    rect.width * .24,
    math.max(0, rect.height - capInset * 2),
  );
  if (stripRect.height <= 0) return;
  canvas.drawRRect(
    RRect.fromRectAndRadius(stripRect, Radius.circular(stripRect.width / 2)),
    Paint()..color = const Color(0x45FFFFFF),
  );
}
