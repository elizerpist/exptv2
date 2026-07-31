import 'package:fluvi/app/fluvi_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots into the active Dashboard placeholder', (tester) async {
    await tester.pumpWidget(const FluviApp());
    expect(find.byKey(const ValueKey('fluvi-app-shell')), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
