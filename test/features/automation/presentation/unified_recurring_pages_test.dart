import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/automation/domain/automation_models.dart';
import 'package:fluvi/features/automation/domain/automation_repository.dart';
import 'package:fluvi/features/automation/presentation/recurring_navigation.dart';
import 'package:fluvi/features/automation/presentation/recurring_transaction_wizard_page.dart';
import 'package:fluvi/features/automation/presentation/unified_recurring_pages.dart';
import 'package:fluvi/features/dashboard/application/dashboard_presentation_preferences.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/manual_transactions/domain/manual_transaction_repository.dart';
import 'package:fluvi/features/manual_transactions/presentation/manual_transaction_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'unified editor keeps one scrollable draft and exposes both modes',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UnifiedRecurringTransactionEditorPage.create(
            repository: _AutomationFake(),
            manualRepository: _ManualFake(),
            categories: const <FluviCategory>[],
            initialDirection: LedgerDirection.expense,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Új ismétlődés'), findsOneWidget);
      expect(find.text('Időzítve'), findsOneWidget);
      expect(find.text('Banki értesítésből'), findsOneWidget);

      await tester.tap(find.text('Banki értesítésből'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Banki összekapcsolás'),
        240,
        scrollable: _editorScrollable,
      );
      expect(find.text('Banki összekapcsolás'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Következő alkalmak'),
        240,
        scrollable: _editorScrollable,
      );
      expect(find.text('Következő alkalmak'), findsOneWidget);
    },
  );

  testWidgets('unknown amount never renders a false zero in the hero', (
    tester,
  ) async {
    final repository = _AutomationFake();
    await tester.pumpWidget(
      MaterialApp(
        home: UnifiedRecurringTransactionEditorPage.create(
          repository: repository,
          manualRepository: _ManualFake(),
          categories: const <FluviCategory>[],
          initialDirection: LedgerDirection.income,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Banki értesítésből'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Fix összeg'),
      220,
      scrollable: _editorScrollable,
    );
    await tester.tap(find.text('Fix összeg'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Értesítésből'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alkalmaz'));
    await tester.pumpAndSettle();

    expect(find.text('Értesítésből'), findsWidgets);
    expect(find.text('0 Ft'), findsNothing);
  });

  testWidgets(
    'create editor uses the shared direction capsule without hiding metadata surfaces',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UnifiedRecurringTransactionEditorPage.create(
            repository: _AutomationFake(),
            manualRepository: _ManualFake(),
            categories: const <FluviCategory>[],
            initialDirection: LedgerDirection.expense,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('creation-direction-toggle')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('creation-direction-expense')),
        findsOneWidget,
      );
      expect(find.byTooltip('Ikonhátterek elrejtése'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('creation-direction-income')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('creation-direction-income')),
        findsOneWidget,
      );
    },
  );

  testWidgets('legacy and unified creation routes stay genuinely separate', (
    tester,
  ) async {
    Future<void> pumpFor(RecurringUiDesign design) => tester.pumpWidget(
      MaterialApp(home: _RecurringCreateLauncher(design: design)),
    );

    await pumpFor(RecurringUiDesign.legacy);
    await tester.tap(find.text('Megnyitás'));
    await tester.pumpAndSettle();
    expect(find.byType(RecurringTransactionWizardPage), findsOneWidget);

    Navigator.of(
      tester.element(find.byType(RecurringTransactionWizardPage)),
    ).pop();
    await tester.pumpAndSettle();
    await pumpFor(RecurringUiDesign.unified);
    await tester.tap(find.text('Megnyitás'));
    await tester.pumpAndSettle();
    expect(find.byType(UnifiedRecurringTransactionEditorPage), findsOneWidget);
  });

  testWidgets('unified timed editor visual reference', (tester) async {
    // Keep the raster hero artwork on the same cold-cache path as the
    // standalone golden run. Earlier interaction cases deliberately load a
    // different direction image, and their retained image frame otherwise
    // makes this visual reference dependent on test order.
    PaintingBinding.instance.imageCache.clear();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('unified-recurring-editor-visual-boundary'),
        child: MaterialApp(
          home: UnifiedRecurringTransactionEditorPage.create(
            repository: _AutomationFake(),
            manualRepository: _ManualFake(),
            categories: const <FluviCategory>[],
            initialDirection: LedgerDirection.expense,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey('unified-recurring-editor-visual-boundary')),
      matchesGoldenFile('../../../goldens/unified_recurring_editor_timed.png'),
    );
  });

  testWidgets(
    'recurring CTA actions keep one compact right-aligned footer row',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: UnifiedRecurringTransactionEditorPage.create(
            repository: _AutomationFake(),
            manualRepository: _ManualFake(),
            categories: const <FluviCategory>[],
            initialDirection: LedgerDirection.expense,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cancel = tester.getRect(
        find.byKey(const ValueKey('unified-recurring-cta-secondary')),
      );
      final create = tester.getRect(
        find.byKey(const ValueKey('unified-recurring-cta-primary')),
      );
      expect(cancel.top, closeTo(create.top, 0.1));
      expect(cancel.right, lessThan(create.left));
      expect(create.right, closeTo(260, 0.5));
    },
  );

  testWidgets('recurring editor hero has the manual editor hero geometry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: ManualTransactionEditor.create(
          repository: _ManualFake(),
          categories: const <FluviCategory>[],
          direction: LedgerDirection.expense,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final manualSize = tester.getSize(
      find.byKey(const ValueKey('manual-editor-hero')),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: UnifiedRecurringTransactionEditorPage.create(
          repository: _AutomationFake(),
          manualRepository: _ManualFake(),
          categories: const <FluviCategory>[],
          initialDirection: LedgerDirection.expense,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final recurringSize = tester.getSize(
      find.byKey(const ValueKey('unified-recurring-editor-hero')),
    );
    expect(recurringSize.height, closeTo(manualSize.height, 0.1));
  });
}

final Finder _editorScrollable = find
    .descendant(
      of: find.byKey(const ValueKey('unified-recurring-editor-scroll')),
      matching: find.byType(Scrollable),
    )
    .first;

final class _RecurringCreateLauncher extends StatelessWidget {
  const _RecurringCreateLauncher({required this.design});
  final RecurringUiDesign design;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: FilledButton(
        onPressed: () => RecurringNavigation.openCreate(
          context,
          design: design,
          repository: _AutomationFake(),
          manualRepository: _ManualFake(),
          categories: const <FluviCategory>[],
          direction: LedgerDirection.expense,
        ),
        child: const Text('Megnyitás'),
      ),
    ),
  );
}

final class _AutomationFake implements AutomationRepository {
  @override
  Future<List<PushProfile>> listProfiles() async => const [];

  @override
  Future<List<RecurrencePreview>> previewRecurringOccurrences({
    required int dayOfMonth,
    required int localTimeMinutes,
    required int startLocalEpochDay,
    int? endLocalEpochDay,
    required String timezoneId,
    int count = 3,
  }) async => List<RecurrencePreview>.generate(
    count,
    (index) => RecurrencePreview(
      expectedLocalEpochDay: startLocalEpochDay + 30 * index,
      expectedLocalTimeMinutes: localTimeMinutes,
      expectedAtUtcMs: 0,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ManualFake implements ManualTransactionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
