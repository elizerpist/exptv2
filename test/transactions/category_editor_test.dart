import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/widgets/category_menu/category_editor_panel.dart';
import 'package:exptv2/features/transactions/widgets/category_menu/category_preview_pill.dart';
import 'package:exptv2/features/transactions/widgets/category_menu/category_slot_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'category editor creates category draft from name color and icon slots',
    (tester) async {
      CategoryDraft? saved;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryEditorPanel(
              activeType: TransactionType.expense,
              onSave: (draft) => saved = draft,
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.text('Új kiadási kategória'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('category-editor-back-button')),
        findsNothing,
      );
      await tester.enterText(
        find.byKey(const ValueKey('category-name-input')),
        'Travel',
      );
      await tester.tap(find.byKey(const ValueKey('color-slot-9')));
      await tester.tap(find.byKey(const ValueKey('category-slot-toggle-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('icon-slot-grid')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('category-slot-toggle-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('color-slot-grid')), findsOneWidget);
      await tester.drag(
        find.byKey(const ValueKey('category-slot-page-view')),
        const Offset(-320, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('icon-slot-4')));
      await tester.tap(find.byKey(const ValueKey('category-save-button')));

      expect(saved?.name, 'Travel');
      expect(saved?.type, TransactionType.expense);
      expect(saved?.colorSlot, 9);
      expect(saved?.iconSlot, 4);
    },
  );

  testWidgets('category slot swipe slides briefly and triggers haptic', (
    tester,
  ) async {
    final hapticCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            hapticCalls.add(call);
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryEditorPanel(
            activeType: TransactionType.expense,
            onSave: (_) {},
            onClose: () {},
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('category-slot-page-view'))),
    );
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-90, 0));
    await tester.pump();

    final feedback = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('category-slot-page-transform')),
    );
    expect(feedback.transform!.getTranslation().x, lessThan(0));

    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('icon-slot-grid')), findsOneWidget);
    expect(
      hapticCalls.map((call) => call.arguments),
      contains('HapticFeedbackType.selectionClick'),
    );
  });

  testWidgets('category editor modifies and deletes existing category', (
    tester,
  ) async {
    CategoryDraft? saved;
    TransactionCategory? deleted;
    final category = TransactionCategory.fromMap({
      'transactionCategoryID': 6,
      'name': 'Q',
      'type': 'kiadás',
      'colorSlot': 7,
      'iconSlot': 2,
      'backgroundColor': '#dc2626',
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': true,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryEditorPanel(
            activeType: TransactionType.expense,
            initialCategory: category,
            onSave: (draft) => saved = draft,
            onDelete: (category) => deleted = category,
            onClose: () {},
          ),
        ),
      ),
    );

    expect(find.text('Kategória módosítása'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('category-editor-back-button')),
      findsNothing,
    );
    await tester.enterText(
      find.byKey(const ValueKey('category-name-input')),
      'Q Edit',
    );
    await tester.tap(find.byKey(const ValueKey('category-save-button')));
    await tester.tap(
      find.byKey(const ValueKey('category-editor-delete-button')),
    );

    expect(saved?.id, 6);
    expect(saved?.name, 'Q Edit');
    expect(deleted?.transactionCategoryID, 6);
  });

  testWidgets('category slots keep selected item inset in neumorphism', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategorySlotGrid.colors(
            selectedSlot: 9,
            surfaceStyle: ExpenseSurfaceInteraction.raisedInset,
            selectedSurfaceStyle: ExpenseSurfaceInteraction.insetInset,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    final selected = tester.widget<Container>(
      find.byKey(const ValueKey('color-slot-surface-9')),
    );
    final unselected = tester.widget<Container>(
      find.byKey(const ValueKey('color-slot-surface-8')),
    );
    expect((selected.decoration! as BoxDecoration).boxShadow, isNull);
    expect((unselected.decoration! as BoxDecoration).boxShadow, isNotNull);
  });

  testWidgets('category preview uses inset log body and raised avatar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CategoryPreviewPill(
          name: 'Travel',
          colorSlot: 9,
          iconSlot: 4,
          surfaceColor: AppColors.gray200,
          bodySurfaceStyle: ExpenseSurfaceInteraction.insetInset,
          avatarSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('category-preview-pill-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('category-preview-avatar-surface')),
      findsOneWidget,
    );
  });
}
