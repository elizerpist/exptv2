import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/features/transactions/widgets/slide_up_menu_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('slide card logs open lifecycle and layout', (tester) async {
    DebugConsole.clear();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 600,
            child: SlideUpMenuCard(
              cardKey: const ValueKey('test-slide-card'),
              debugLabel: 'TestMenu',
              child: const SizedBox(height: 220),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(DebugConsole.allText, contains('[SlideUpMenu] TestMenu layout'));
    expect(
      DebugConsole.allText,
      contains('[SlideUpMenu] TestMenu open complete'),
    );
  });


  testWidgets('slide card renders a dark focus veil behind the popup', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 600,
            child: SlideUpMenuCard(
              cardKey: const ValueKey('test-slide-card'),
              debugLabel: 'TestMenu',
              child: const SizedBox(height: 220),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final veil = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('slide-up-menu-veil')),
    );

    expect(veil.color, Colors.black.withValues(alpha: 0.28));
  });

  testWidgets('slide card ignores drag gestures outside the handle zone', (
    tester,
  ) async {
    var dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 600,
            child: SlideUpMenuCard(
              cardKey: const ValueKey('test-slide-card'),
              debugLabel: 'TestMenu',
              onDismissed: () => dismissed = true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 120),
                  TextButton(
                    key: const ValueKey('slide-card-content-button'),
                    onPressed: () {},
                    child: const Text('Content action'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final before = tester
        .getTopLeft(find.byKey(const ValueKey('test-slide-card')))
        .dy;
    await tester.drag(
      find.byKey(const ValueKey('slide-card-content-button')),
      const Offset(0, 140),
    );
    await tester.pumpAndSettle();
    final after = tester
        .getTopLeft(find.byKey(const ValueKey('test-slide-card')))
        .dy;

    expect(after, moreOrLessEquals(before, epsilon: 0.1));
    expect(dismissed, isFalse);
  });

  testWidgets('slide card animates partial drag snap back instead of jumping', (
    tester,
  ) async {
    DebugConsole.clear();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 600,
            child: SlideUpMenuCard(
              cardKey: const ValueKey('test-slide-card'),
              debugLabel: 'TestMenu',
              panelHeight: 220,
              child: const SizedBox(height: 220),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final before = _slideCardTranslationY(tester);
    const panelTop = 600 - 220.0;
    final gesture = await tester.startGesture(
      const Offset(180, panelTop + 24),
    );
    await gesture.moveBy(const Offset(0, 70));
    await tester.pump();

    final dragged = _slideCardTranslationY(tester);
    expect(dragged, greaterThan(before + 60));

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 16));

    final duringSnap = _slideCardTranslationY(tester);
    expect(duringSnap, greaterThan(before));
    expect(duringSnap, lessThan(dragged));

    await tester.pumpAndSettle();

    final after = _slideCardTranslationY(tester);
    expect(after, moreOrLessEquals(before, epsilon: 0.1));
    expect(
      DebugConsole.allText,
      contains('[SlideUpMenu] TestMenu snap start'),
    );
    expect(
      DebugConsole.allText,
      contains('[SlideUpMenu] TestMenu snap complete'),
    );
  });
}

double _slideCardTranslationY(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.byKey(const ValueKey('slide-up-menu-transform')),
  );
  return transform.transform.getTranslation().y;
}
