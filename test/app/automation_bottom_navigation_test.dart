import 'package:fluvi/app/shell/bnb03_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('automation, pulse and settings occupy their fixed positions', (
    tester,
  ) async {
    Bnb03Item? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: Bnb03BottomNavigation(
              width: 428,
              selected: Bnb03Item.home,
              onChanged: (item) => selected = item,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Automat.'), findsOneWidget);
    expect(find.text('Pulse'), findsOneWidget);
    expect(find.text('Beáll.'), findsOneWidget);
    await tester.tap(find.text('Automat.'));
    expect(selected, Bnb03Item.search);
    await tester.tap(find.text('Pulse'));
    expect(selected, Bnb03Item.cart);
    await tester.tap(find.text('Beáll.'));
    expect(selected, Bnb03Item.profile);
  });
}
