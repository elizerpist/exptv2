import 'package:fluvi/app/fluvi_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots into the fixed Fluvi dashboard shell', (tester) async {
    await tester.pumpWidget(const FluviApp());
    expect(find.byKey(const ValueKey('fluvi-app-shell')), findsOneWidget);
    expect(find.byKey(const ValueKey('core-dashboard')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-nav-item')), findsOneWidget);
  });
}
