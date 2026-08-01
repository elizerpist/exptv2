import 'package:fluvi/app/fluvi_app.dart';
import 'package:fluvi/app/shell/bnb03_bottom_navigation.dart';
import 'package:fluvi/app/shell/fluvi_bottom_navigation.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots into the fixed Fluvi dashboard shell', (tester) async {
    await tester.pumpWidget(const FluviApp());
    expect(find.byKey(const ValueKey('fluvi-app-shell')), findsOneWidget);
    expect(find.byKey(const ValueKey('core-dashboard')), findsOneWidget);
    expect(find.byType(Bnb03BottomNavigation), findsOneWidget);
    expect(
      find.byKey(const ValueKey('fluvi-fullscreen-button')),
      findsOneWidget,
    );
  });

  testWidgets('keeps the raised center action inside the reserved nav area', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 412,
            height: FluviVisualTokens.navigationHeight,
            child: FluviBottomNavigation(onDashboardTap: () {}),
          ),
        ),
      ),
    );

    final navigation = tester.getRect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.painter is FluviConvexCenterBottomNavigationPainter,
      ),
    );
    final centerAction = tester.getRect(
      find.byKey(const ValueKey('fluvi-center-fab')),
    );

    expect(navigation.height, greaterThanOrEqualTo(110));
    expect(navigation.height, lessThanOrEqualTo(144));
    expect(centerAction.width, closeTo(64, 0.001));
    expect(centerAction.height, closeTo(64, 0.001));
    expect(centerAction.top - navigation.top, closeTo(10, 2));
    expect(centerAction.left, greaterThanOrEqualTo(navigation.left));
    expect(centerAction.right, lessThanOrEqualTo(navigation.right));
    expect(centerAction.top, greaterThanOrEqualTo(navigation.top));
    expect(centerAction.bottom, lessThanOrEqualTo(navigation.bottom));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.painter is FluviConvexCenterBottomNavigationPainter,
      ),
      findsOneWidget,
    );
  });
}
