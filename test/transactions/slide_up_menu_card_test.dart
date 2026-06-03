import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/widgets/category_menu/category_editor_sheet.dart';
import 'package:exptv2/features/transactions/widgets/slide_up_menu_card.dart';
import 'package:exptv2/features/transactions/widgets/slide_up_panel_metrics.dart';
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

  testWidgets(
    'veil tap hides keyboard instead of dismissing when keyboard is open',
    (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 600),
              viewInsets: EdgeInsets.only(bottom: 180),
            ),
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              body: SizedBox(
                width: 390,
                height: 600,
                child: SlideUpMenuCard(
                  cardKey: const ValueKey('test-slide-card'),
                  debugLabel: 'KeyboardDismissMenu',
                  panelHeight: 260,
                  onDismissed: () => dismissed = true,
                  child: const SizedBox(height: 260),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(24, 24));
      await tester.pumpAndSettle();

      expect(dismissed, isFalse);
      expect(find.byKey(const ValueKey('test-slide-card')), findsOneWidget);
      expect(
        DebugConsole.allText,
        contains('[SlideUpMenu] KeyboardDismissMenu veil tap unfocus keyboard'),
      );
    },
  );

  testWidgets('category editor sheet does not follow keyboard lift', (
    tester,
  ) async {
    DebugConsole.clear();

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 600),
            viewInsets: EdgeInsets.only(bottom: 180),
          ),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: SizedBox(
              width: 390,
              height: 600,
              child: CategoryEditorSheet(
                activeType: TransactionType.expense,
                panelHeight: 260,
                onSave: (_) {},
                onClose: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_slideCardTranslationY(tester), moreOrLessEquals(0, epsilon: 0.1));
    expect(
      DebugConsole.allText,
      isNot(contains('[SlideUpMenu] AddCategory keyboard lift inset=180.0')),
    );
  });

  testWidgets(
    'slide card translates by keyboard inset without resizing panel',
    (tester) async {
      DebugConsole.clear();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 600),
              viewInsets: EdgeInsets.only(bottom: 180),
            ),
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              body: SizedBox(
                width: 390,
                height: 600,
                child: SlideUpMenuCard(
                  cardKey: const ValueKey('test-slide-card'),
                  debugLabel: 'KeyboardMenu',
                  panelHeight: 260,
                  child: const SizedBox(height: 260),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_slideCardTranslationY(tester), moreOrLessEquals(-180));
      expect(
        DebugConsole.allText,
        contains('[SlideUpMenu] KeyboardMenu keyboard lift inset=180.0'),
      );
      expect(
        DebugConsole.allText,
        contains(
          '[SlideUpMenu] KeyboardMenu layout available=600.0 panel=260.0',
        ),
      );
    },
  );

  testWidgets('panel metrics ignore keyboard inset for stable card content', (
    tester,
  ) async {
    late double closedNoKeyboard;
    late double budgetNoKeyboard;
    late double closedWithKeyboard;
    late double budgetWithKeyboard;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            closedNoKeyboard = SlideUpPanelMetrics.transactionHeight(
              context,
              pickerOpen: false,
            );
            budgetNoKeyboard = SlideUpPanelMetrics.budgetHeight(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 600),
            viewInsets: EdgeInsets.only(bottom: 240),
          ),
          child: Builder(
            builder: (context) {
              closedWithKeyboard = SlideUpPanelMetrics.transactionHeight(
                context,
                pickerOpen: false,
              );
              budgetWithKeyboard = SlideUpPanelMetrics.budgetHeight(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(closedWithKeyboard, closedNoKeyboard);
    expect(budgetWithKeyboard, budgetNoKeyboard);
  });

  testWidgets('slide card can stage entry animation until after layout', (
    tester,
  ) async {
    DebugConsole.clear();
    var visible = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 600,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Stack(
                  children: [
                    TextButton(
                      key: const ValueKey('show-slide-card'),
                      onPressed: () => setState(() => visible = true),
                      child: const Text('Show'),
                    ),
                    SlideUpMenuCard(
                      cardKey: const ValueKey('test-slide-card'),
                      debugLabel: 'DeferredMenu',
                      panelHeight: 260,
                      visible: visible,
                      deferEntryAnimation: true,
                      child: const SizedBox(height: 260),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('show-slide-card')));
    await tester.pump();

    expect(
      DebugConsole.allText,
      contains('[SlideUpMenu] DeferredMenu open staged'),
    );
    expect(
      DebugConsole.allText,
      isNot(contains('[SlideUpMenu] DeferredMenu open animating')),
    );

    await tester.pump();

    expect(
      DebugConsole.allText,
      contains('[SlideUpMenu] DeferredMenu open animating'),
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

  testWidgets('slide card dismisses when the focus veil is tapped', (
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
              panelHeight: 260,
              onDismissed: () => dismissed = true,
              child: const SizedBox(height: 260),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(24, 24));
    await tester.pumpAndSettle();

    expect(dismissed, isTrue);
  });

  testWidgets('slide card fades the focus veil while dragged down', (
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
              panelHeight: 320,
              child: const SizedBox(height: 320),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_veilOpacity(tester), moreOrLessEquals(1));

    const panelTop = 600 - 320.0;
    final gesture = await tester.startGesture(
      const Offset(180, panelTop + 140),
    );
    await gesture.moveBy(const Offset(0, 160));
    await tester.pump();

    expect(_veilOpacity(tester), lessThan(0.65));
    expect(_veilOpacity(tester), greaterThan(0.35));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('slide card can be dragged from the content area', (
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

    final before = _slideCardTranslationY(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('slide-card-content-button'))),
    );
    await gesture.moveBy(const Offset(0, 120));
    await tester.pump();

    final dragged = _slideCardTranslationY(tester);
    expect(dragged, greaterThan(before + 100));

    await gesture.moveBy(const Offset(0, -180));
    await tester.pump();

    final clampedBack = _slideCardTranslationY(tester);
    expect(clampedBack, moreOrLessEquals(before, epsilon: 0.1));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(dismissed, isFalse);
  });

  testWidgets('slide card ignores vertical drift during horizontal gestures', (
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
              panelHeight: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 160),
                  TextButton(
                    key: const ValueKey('horizontal-drag-target'),
                    onPressed: () {},
                    child: const Text('Horizontal action'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final before = _slideCardTranslationY(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('horizontal-drag-target'))),
    );
    await gesture.moveBy(const Offset(140, 18));
    await tester.pump();

    expect(_slideCardTranslationY(tester), moreOrLessEquals(before));
    expect(
      DebugConsole.allText,
      contains('[SlideUpMenu] TestMenu drag horizontal lock'),
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('slide card ignores drags started in exclusion zones', (
    tester,
  ) async {
    final excludedKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 600,
            child: SlideUpMenuCard(
              cardKey: const ValueKey('test-slide-card'),
              debugLabel: 'TestMenu',
              panelHeight: 360,
              dragExclusionKeys: [excludedKey],
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Container(
                    key: excludedKey,
                    height: 150,
                    color: Colors.red,
                    child: const Center(child: Text('Nested scroller')),
                  ),
                  const SizedBox(height: 40),
                  TextButton(
                    key: const ValueKey('outside-drag-target'),
                    onPressed: () {},
                    child: const Text('Outside'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final before = _slideCardTranslationY(tester);
    final excludedGesture = await tester.startGesture(
      tester.getCenter(find.text('Nested scroller')),
    );
    await excludedGesture.moveBy(const Offset(0, 140));
    await tester.pump();
    expect(_slideCardTranslationY(tester), moreOrLessEquals(before));
    await excludedGesture.up();
    await tester.pumpAndSettle();

    final outsideGesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('outside-drag-target'))),
    );
    await outsideGesture.moveBy(const Offset(0, 120));
    await tester.pump();
    expect(_slideCardTranslationY(tester), greaterThan(before + 100));
    await outsideGesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('slide card can be manually dragged nearly off screen', (
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
              panelHeight: 360,
              child: const SizedBox(height: 360),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const panelTop = 600 - 360.0;
    final gesture = await tester.startGesture(
      const Offset(180, panelTop + 150),
    );
    await gesture.moveBy(const Offset(0, 320));
    await tester.pump();

    expect(_slideCardTranslationY(tester), greaterThan(300));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('slide card dismissal continues from the dragged offset', (
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
              panelHeight: 320,
              onDismissed: () => dismissed = true,
              child: const SizedBox(height: 320),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const panelTop = 600 - 320.0;
    final gesture = await tester.startGesture(
      const Offset(180, panelTop + 140),
    );
    await gesture.moveBy(const Offset(0, 170));
    await tester.pump();
    final dragged = _slideCardTranslationY(tester);

    await gesture.up();
    await tester.pump();

    final afterRelease = _slideCardTranslationY(tester);
    expect(afterRelease, greaterThanOrEqualTo(dragged - 1));

    await tester.pumpAndSettle();
    expect(dismissed, isTrue);
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
    final gesture = await tester.startGesture(const Offset(180, panelTop + 24));
    await gesture.moveBy(const Offset(0, 70));
    await tester.pump();

    final dragged = _slideCardTranslationY(tester);
    expect(dragged, greaterThan(before + 60));

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 64));

    final duringSnap = _slideCardTranslationY(tester);
    expect(duringSnap, greaterThan(before));

    await tester.pumpAndSettle();

    final after = _slideCardTranslationY(tester);
    expect(after, moreOrLessEquals(before, epsilon: 0.1));
    expect(DebugConsole.allText, contains('[SlideUpMenu] TestMenu snap start'));
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

double _veilOpacity(WidgetTester tester) {
  final opacity = tester.widget<Opacity>(
    find.byKey(const ValueKey('slide-up-menu-veil-opacity')),
  );
  return opacity.opacity;
}
