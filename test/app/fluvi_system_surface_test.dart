import 'package:fluvi/app/fluvi_system_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('paints white behind dynamic insets with dark system icons', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(top: 24, bottom: 16),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FluviSystemSurface(
            child: Container(key: const ValueKey('surface-child')),
          ),
        ),
      ),
    );

    final surface = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('fluvi-system-surface')),
    );
    final overlay = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
    );

    expect(surface.color, Colors.white);
    expect(overlay.value.statusBarIconBrightness, Brightness.dark);
    expect(overlay.value.systemNavigationBarIconBrightness, Brightness.dark);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('surface-child'))).dy,
      24,
    );
    expect(
      tester.getBottomRight(find.byKey(const ValueKey('surface-child'))).dy,
      584,
    );
  });
}
