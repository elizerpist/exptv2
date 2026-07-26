import 'dart:async';

import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/balance_frame.dart';
import 'package:exptv2/features/transactions/widgets/category_slot_icon.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_transaction_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child, {double width = 378, double height = 892}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(412, height)),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );
  }

  testWidgets(
    '0726 ports the exact title-free grouped HTML transaction geometry',
    (tester) async {
      final groups = [
        BalanceLogGroup(
          date: '2026.07.25.',
          rows: [
            BalanceLogRow.record(record(1, merchant: 'Lidl', amount: -4250)),
            BalanceLogRow.record(record(2, merchant: 'MOL', amount: -18000)),
          ],
        ),
        BalanceLogGroup(
          date: '2026.07.24.',
          rows: [BalanceLogRow.record(record(3, merchant: 'Cinema City'))],
        ),
      ];

      await tester.pumpWidget(
        host(
          SpendeeBalanceTransactionLog(
            groups: groups,
            categoriesById: {7: category()},
            viewportHeight: 220,
            onFastFilter: (_, _) {},
            onRecordTap: (_) {},
            onDeleteRequested: (_) => false,
            onCategoryFilter: (_) {},
            onEditTransaction: (_) {},
          ),
        ),
      );

      final section = find.byKey(
        const ValueKey('spendee-balance-transaction-section'),
      );
      final viewport = find.byKey(
        const ValueKey('spendee-balance-transaction-viewport'),
      );
      final firstTitle = find.byKey(
        const ValueKey('spendee-balance-transaction-day-title-2026-07-25'),
      );
      final secondTitle = find.byKey(
        const ValueKey('spendee-balance-transaction-day-title-2026-07-24'),
      );
      final firstCard = find.byKey(
        const ValueKey('spendee-balance-transaction-day-card-2026-07-25'),
      );
      final firstRow = find.byKey(
        const ValueKey('spendee-balance-transaction-row-record-1'),
      );
      final secondRow = find.byKey(
        const ValueKey('spendee-balance-transaction-row-record-2'),
      );

      expect(tester.getSize(section), const Size(378, 220));
      expect(
        find.byKey(const ValueKey('spendee-balance-transaction-heading')),
        findsNothing,
      );
      expect(tester.getSize(viewport), const Size(378, 220));
      expect(tester.getTopLeft(viewport).dy - tester.getTopLeft(section).dy, 0);
      expect(tester.getSize(firstTitle), const Size(374, 15));
      final cardSliver = tester.renderObject<RenderSliver>(firstCard);
      expect(cardSliver.constraints.crossAxisExtent, 374);
      expect(cardSliver.geometry?.scrollExtent, 112);
      expect(
        tester.getTopLeft(firstRow).dy - tester.getTopLeft(firstTitle).dy,
        21,
      );
      expect(
        tester.getTopLeft(secondTitle).dy - tester.getTopLeft(firstTitle).dy,
        142,
      );
      expect(tester.getSize(firstRow), const Size(372, 55));
      expect(tester.getSize(secondRow), const Size(372, 55));
      expect(
        tester.getSize(
          find.byKey(
            const ValueKey('spendee-balance-transaction-avatar-record-1'),
          ),
        ),
        const Size.square(34),
      );
      expect(
        find.byKey(const ValueKey('spendee-balance-transaction-edit-record-1')),
        findsNothing,
      );
      expect(
        tester.getSize(
          find.byKey(
            const ValueKey('spendee-balance-transaction-separator-record-2'),
          ),
        ),
        const Size(372, 1),
      );
      expect(find.text('TRANZAKCIÓK'), findsNothing);
      expect(find.text('2026.07.25.'), findsOneWidget);
      expect(find.text('Lidl'), findsOneWidget);
      expect(find.text('Élelmiszer'), findsNWidgets(3));
      expect(find.text('-4250 Ft'), findsNWidgets(2));
      expect(find.text('11:42'), findsWidgets);

      final decoration =
          tester
                  .widget<DecoratedSliver>(
                    find.byKey(
                      const ValueKey(
                        'spendee-balance-transaction-day-decoration-2026-07-25',
                      ),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(18));
      expect(decoration.color, const Color(0xF5FFFFFF));
      expect(decoration.border, Border.all(color: const Color(0x1A666FAB)));
      expect(decoration.boxShadow, hasLength(2));
      expect(decoration.boxShadow!.first.offset, const Offset(0, 9));
      expect(decoration.boxShadow!.first.blurRadius, 19);
    },
  );

  testWidgets(
    'real and ghost income rows use the exact signed four-digit formatter',
    (tester) async {
      await tester.pumpWidget(
        host(
          SpendeeBalanceTransactionLog(
            groups: [
              BalanceLogGroup(
                date: '2026.07.25.',
                rows: [
                  BalanceLogRow.record(record(1, amount: 6500)),
                  BalanceLogRow.ghost(incomeGhost()),
                ],
              ),
            ],
            categoriesById: {7: category()},
            viewportHeight: 120,
            onFastFilter: (_, _) {},
            onRecordTap: (_) {},
            onDeleteRequested: (_) => false,
            onCategoryFilter: (_) {},
            onEditTransaction: (_) {},
          ),
        ),
      );

      expect(find.text('+6500 Ft'), findsNWidgets(2));
      expect(find.text('+6 500 Ft'), findsNothing);
      expect(
        tester
            .getSemantics(
              find.byKey(
                const ValueKey(
                  'spendee-balance-transaction-semantics-record-1',
                ),
              ),
            )
            .label,
        contains('+6500 Ft'),
      );
      expect(
        tester
            .getSemantics(
              find.byKey(
                const ValueKey(
                  'spendee-balance-transaction-semantics-ghost-101',
                ),
              ),
            )
            .label,
        contains('+6500 Ft'),
      );
    },
  );

  testWidgets('avatar and row targets dispatch once in isolation', (
    tester,
  ) async {
    var avatarCalls = 0;
    var rowCalls = 0;
    await tester.pumpWidget(
      host(
        SpendeeBalanceTransactionLog(
          groups: oneGroup(),
          categoriesById: {7: category()},
          viewportHeight: 100,
          onFastFilter: (_, _) {},
          onRecordTap: (_) => rowCalls += 1,
          onDeleteRequested: (_) => false,
          onCategoryFilter: (_) => avatarCalls += 1,
          onEditTransaction: (_) {},
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('spendee-balance-transaction-avatar-record-1')),
    );
    await tester.pump();
    expect((avatarCalls, rowCalls), (1, 0));
    expect(
      find.byKey(const ValueKey('spendee-balance-transaction-edit-record-1')),
      findsNothing,
    );

    final row = find.byKey(
      const ValueKey('spendee-balance-transaction-row-record-1'),
    );
    await tester.tapAt(tester.getCenter(row) + const Offset(40, 0));
    await tester.pump();
    expect((avatarCalls, rowCalls), (1, 1));
  });

  testWidgets(
    'mounted log avatars track the live central category colour and icon',
    (tester) async {
      var currentCategory = category();
      late StateSetter setHostState;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return SpendeeBalanceTransactionLog(
                groups: oneGroup(),
                categoriesById: {7: currentCategory},
                viewportHeight: 100,
                onFastFilter: (_, _) {},
                onRecordTap: (_) {},
                onDeleteRequested: (_) => false,
                onCategoryFilter: (_) {},
                onEditTransaction: (_) {},
              );
            },
          ),
        ),
      );

      final avatar = find.byKey(
        const ValueKey('spendee-balance-transaction-avatar-record-1'),
      );
      BoxDecoration avatarDecoration() =>
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: avatar,
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      CategorySlotIcon slotIcon() => tester.widget<CategorySlotIcon>(
        find.descendant(of: avatar, matching: find.byType(CategorySlotIcon)),
      );

      expect(
        (avatarDecoration().gradient! as LinearGradient).colors[1],
        currentCategory.slotColor,
      );
      expect(slotIcon().slot, 1);

      setHostState(() {
        currentCategory = TransactionCategory.fromMap({
          ...currentCategory.toMap(),
          'colorSlot': 8,
          'iconSlot': 2,
        });
      });
      await tester.pump();

      expect(
        (avatarDecoration().gradient! as LinearGradient).colors[1],
        currentCategory.slotColor,
      );
      expect(slotIcon().slot, 2);
    },
  );

  testWidgets(
    'row swipe actions have semantic alternatives and nested buttons activate '
    'from the keyboard exactly once',
    (tester) async {
      var fastFilterCalls = 0;
      var deleteCalls = 0;
      var avatarCalls = 0;
      var rowCalls = 0;
      await tester.pumpWidget(
        host(
          SpendeeBalanceTransactionLog(
            groups: oneGroup(),
            categoriesById: {7: category()},
            viewportHeight: 100,
            onFastFilter: (_, _) => fastFilterCalls += 1,
            onRecordTap: (_) => rowCalls += 1,
            onDeleteRequested: (_) {
              deleteCalls += 1;
              return false;
            },
            onCategoryFilter: (_) => avatarCalls += 1,
            onEditTransaction: (_) {},
          ),
        ),
      );

      final rowSemantics = find.byKey(
        const ValueKey('spendee-balance-transaction-semantics-record-1'),
      );
      final node = tester.getSemantics(rowSemantics);
      expect(node.label, 'Lidl, Élelmiszer, -4250 Ft, 11:42');
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(
        node.childrenCount,
        1,
        reason: 'the category avatar is the only nested action',
      );
      final actionIds =
          node.getSemanticsData().customSemanticsActionIds ?? const <int>[];
      final labels = actionIds
          .map(CustomSemanticsAction.getAction)
          .whereType<CustomSemanticsAction>()
          .map((action) => action.label)
          .toSet();
      expect(labels, {'Kereskedő gyorsszűrése', 'Tranzakció törlése'});

      void perform(String label) {
        final actionId = CustomSemanticsAction.getIdentifier(
          CustomSemanticsAction(label: label),
        );
        node.owner!.performAction(
          node.id,
          SemanticsAction.customAction,
          actionId,
        );
      }

      perform('Kereskedő gyorsszűrése');
      await tester.pump();
      expect(fastFilterCalls, 1);
      perform('Tranzakció törlése');
      await tester.pump();
      expect(deleteCalls, 1);

      final avatar = find.byKey(
        const ValueKey('spendee-balance-transaction-avatar-record-1'),
      );
      Focus.of(tester.element(avatar)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect((avatarCalls, rowCalls), (1, 0));

      expect(
        find.byKey(const ValueKey('spendee-balance-transaction-edit-record-1')),
        findsNothing,
      );

      final row = find.byKey(
        const ValueKey('spendee-balance-transaction-row-record-1'),
      );
      Focus.of(tester.element(row)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(rowCalls, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(rowCalls, 2);
    },
  );

  testWidgets(
    'record keyboard alternatives dispatch without modifier collisions',
    (tester) async {
      final deleteResult = Completer<bool>();
      var fastFilterCalls = 0;
      var deleteCalls = 0;
      var renameCalls = 0;
      var resetCalls = 0;
      var rowCalls = 0;
      await tester.pumpWidget(
        host(
          SpendeeBalanceTransactionLog(
            groups: [
              BalanceLogGroup(
                date: '2026.07.25.',
                rows: [
                  BalanceLogRow.record(
                    record(1, userAssignedName: 'Heti bevásárlás'),
                  ),
                ],
              ),
            ],
            categoriesById: {7: category()},
            viewportHeight: 100,
            onFastFilter: (_, _) => fastFilterCalls += 1,
            onRecordTap: (_) => rowCalls += 1,
            onDeleteRequested: (_) {
              deleteCalls += 1;
              return deleteResult.future;
            },
            onCategoryFilter: (_) {},
            onEditTransaction: (_) {},
            onRenameMerchantRequested: (_) => renameCalls += 1,
            onResetMerchantName: (_) => resetCalls += 1,
          ),
        ),
      );

      final row = find.byKey(
        const ValueKey('spendee-balance-transaction-row-record-1'),
      );
      Focus.of(tester.element(row)).requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pump();
      expect((fastFilterCalls, rowCalls), (1, 0));

      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.pump();
      expect((renameCalls, resetCalls, rowCalls), (1, 0, 0));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(
        (renameCalls, resetCalls, rowCalls),
        (1, 1, 0),
        reason: 'Shift+R must not also dispatch the unmodified R binding',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect((deleteCalls, rowCalls), (1, 0));
      expect(transformDx(tester, 1), 44);

      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(
        deleteCalls,
        1,
        reason: 'the confirmed-delete route guards a pending request',
      );

      deleteResult.complete(false);
      await tester.pumpAndSettle();
      expect(transformDx(tester, 1), 0);
    },
  );

  testWidgets(
    'unavailable rename and reset shortcuts remain available to ancestors',
    (tester) async {
      var ancestorRenameCalls = 0;
      var ancestorResetCalls = 0;
      var resetCalls = 0;
      await tester.pumpWidget(
        host(
          CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.keyR): () =>
                  ancestorRenameCalls += 1,
              const SingleActivator(LogicalKeyboardKey.keyR, shift: true): () =>
                  ancestorResetCalls += 1,
            },
            child: SpendeeBalanceTransactionLog(
              groups: oneGroup(),
              categoriesById: {7: category()},
              viewportHeight: 100,
              onFastFilter: (_, _) {},
              onRecordTap: (_) {},
              onDeleteRequested: (_) => false,
              onCategoryFilter: (_) {},
              onEditTransaction: (_) {},
              onResetMerchantName: (_) => resetCalls += 1,
            ),
          ),
        ),
      );

      final row = find.byKey(
        const ValueKey('spendee-balance-transaction-row-record-1'),
      );
      Focus.of(tester.element(row)).requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      expect((ancestorRenameCalls, ancestorResetCalls), (1, 1));
      expect(
        resetCalls,
        0,
        reason: 'Shift+R is disabled until the record has a custom name',
      );
    },
  );

  testWidgets('log rows expose no redundant right-edge edit target', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SpendeeBalanceTransactionLog(
          groups: oneGroup(),
          categoriesById: {7: category()},
          viewportHeight: 100,
          onFastFilter: (_, _) {},
          onRecordTap: (_) {},
          onDeleteRequested: (_) => false,
          onCategoryFilter: (_) {},
          onEditTransaction: (_) {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('spendee-balance-transaction-edit-record-1')),
      findsNothing,
    );
  });

  testWidgets(
    'visible merchant rename and revert targets preserve the HTML row bounds '
    'and dispatch once in isolation',
    (tester) async {
      var hasCustomName = false;
      var renameCalls = 0;
      var resetCalls = 0;
      var avatarCalls = 0;
      var rowCalls = 0;
      late StateSetter setHostState;

      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return SpendeeBalanceTransactionLog(
                groups: [
                  BalanceLogGroup(
                    date: '2026.07.25.',
                    rows: [
                      BalanceLogRow.record(
                        record(
                          1,
                          userAssignedName: hasCustomName
                              ? 'Heti bevásárlás'
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
                categoriesById: {7: category()},
                viewportHeight: 100,
                onFastFilter: (_, _) {},
                onRecordTap: (_) => rowCalls += 1,
                onDeleteRequested: (_) => false,
                onCategoryFilter: (_) => avatarCalls += 1,
                onEditTransaction: (_) {},
                onRenameMerchantRequested: (_) => renameCalls += 1,
                onResetMerchantName: (_) => resetCalls += 1,
              );
            },
          ),
        ),
      );

      final row = find.byKey(
        const ValueKey('spendee-balance-transaction-row-record-1'),
      );
      final avatar = find.byKey(
        const ValueKey('spendee-balance-transaction-avatar-record-1'),
      );
      final rename = find.byKey(
        const ValueKey('spendee-balance-transaction-rename-record-1'),
      );
      final reset = find.byKey(
        const ValueKey('spendee-balance-transaction-reset-record-1'),
      );

      final originalRowRect = tester.getRect(row);
      final originalAvatarRect = tester.getRect(avatar);
      expect(originalRowRect.size, const Size(372, 55));
      expect(rename, findsOneWidget);
      expect(reset, findsNothing);

      setHostState(() => hasCustomName = true);
      await tester.pump();

      expect(tester.getRect(row), originalRowRect);
      expect(tester.getRect(avatar), originalAvatarRect);
      expect(tester.getSize(reset), const Size.square(14));
      expect(
        find.descendant(of: reset, matching: find.byType(SvgPicture)),
        findsOneWidget,
        reason:
            'The explicit revert affordance must use the authored Lucide SVG',
      );
      final renameRect = tester.getRect(rename);
      final resetRect = tester.getRect(reset);
      expect(renameRect.height, 13);
      expect(renameRect.overlaps(originalAvatarRect), isFalse);
      expect(renameRect.overlaps(resetRect), isFalse);
      expect(resetRect.overlaps(originalAvatarRect), isFalse);
      expect(originalRowRect.contains(renameRect.topLeft), isTrue);
      expect(
        originalRowRect.contains(
          renameRect.bottomRight - const Offset(.01, .01),
        ),
        isTrue,
      );
      expect(originalRowRect.contains(resetRect.topLeft), isTrue);
      expect(
        originalRowRect.contains(
          resetRect.bottomRight - const Offset(.01, .01),
        ),
        isTrue,
      );

      await tester.tap(rename);
      await tester.pump();
      expect((renameCalls, resetCalls, avatarCalls, rowCalls), (1, 0, 0, 0));
      expect(transformDx(tester, 1), 0);

      await tester.tap(reset);
      await tester.pump();
      expect((renameCalls, resetCalls, avatarCalls, rowCalls), (1, 1, 0, 0));
      expect(transformDx(tester, 1), 0);

      final renameNode = tester.getSemantics(rename);
      expect(renameNode.label, 'Heti bevásárlás kereskedő átnevezése');
      expect(
        renameNode.getSemanticsData().hasAction(SemanticsAction.tap),
        true,
      );
      final resetNode = tester.getSemantics(reset);
      expect(resetNode.label, 'Heti bevásárlás eredeti nevének visszaállítása');
      expect(resetNode.getSemanticsData().hasAction(SemanticsAction.tap), true);
      resetNode.owner!.performAction(resetNode.id, SemanticsAction.tap);
      await tester.pump();
      expect(resetCalls, 2);

      Focus.of(tester.element(rename)).requestFocus();
      await tester.pump();
      expect(Focus.of(tester.element(rename)).hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(renameCalls, 2);
      expect(rowCalls, 0);
    },
  );

  testWidgets(
    'revert target exists only for a real custom name with a reset callback',
    (tester) async {
      await tester.pumpWidget(
        host(
          SpendeeBalanceTransactionLog(
            groups: [
              BalanceLogGroup(
                date: '2026.07.25.',
                rows: [
                  BalanceLogRow.record(record(1)),
                  BalanceLogRow.ghost(incomeGhost()),
                ],
              ),
            ],
            categoriesById: {7: category()},
            viewportHeight: 120,
            onFastFilter: (_, _) {},
            onRecordTap: (_) {},
            onDeleteRequested: (_) => false,
            onCategoryFilter: (_) {},
            onEditTransaction: (_) {},
            onRenameMerchantRequested: (_) {},
            onResetMerchantName: (_) {},
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey('spendee-balance-transaction-rename-record-1'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('spendee-balance-transaction-rename-ghost-101'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('spendee-balance-transaction-reset-record-1'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('spendee-balance-transaction-reset-ghost-101'),
        ),
        findsNothing,
      );

      await tester.pumpWidget(
        host(
          SpendeeBalanceTransactionLog(
            groups: [
              BalanceLogGroup(
                date: '2026.07.25.',
                rows: [
                  BalanceLogRow.record(
                    record(1, userAssignedName: 'Heti bevásárlás'),
                  ),
                ],
              ),
            ],
            categoriesById: {7: category()},
            viewportHeight: 100,
            onFastFilter: (_, _) {},
            onRecordTap: (_) {},
            onDeleteRequested: (_) => false,
            onCategoryFilter: (_) {},
            onEditTransaction: (_) {},
            onRenameMerchantRequested: (_) {},
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey('spendee-balance-transaction-reset-record-1'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'merchant copy exposes rename and custom-name revert entrypoints',
    (tester) async {
      var renameCalls = 0;
      var resetCalls = 0;
      await tester.pumpWidget(
        host(
          SpendeeBalanceTransactionLog(
            groups: [
              BalanceLogGroup(
                date: '2026.07.25.',
                rows: [
                  BalanceLogRow.record(
                    record(1, userAssignedName: 'Heti bevásárlás'),
                  ),
                ],
              ),
            ],
            categoriesById: {7: category()},
            viewportHeight: 100,
            onFastFilter: (_, _) {},
            onRecordTap: (_) {},
            onDeleteRequested: (_) => false,
            onCategoryFilter: (_) {},
            onEditTransaction: (_) {},
            onRenameMerchantRequested: (_) => renameCalls += 1,
            onResetMerchantName: (_) => resetCalls += 1,
          ),
        ),
      );

      await tester.longPress(
        find.byKey(
          const ValueKey('spendee-balance-transaction-merchant-record-1'),
        ),
      );
      await tester.pump();
      expect((renameCalls, resetCalls), (1, 0));

      await tester.longPress(
        find.byKey(
          const ValueKey('spendee-balance-transaction-category-record-1'),
        ),
      );
      await tester.pump();
      expect((renameCalls, resetCalls), (1, 1));
    },
  );

  testWidgets('left swipe follows the row then fast-filters once at -80px', (
    tester,
  ) async {
    var fastFilterCalls = 0;
    await tester.pumpWidget(
      host(
        SpendeeBalanceTransactionLog(
          groups: oneGroup(),
          categoriesById: {7: category()},
          viewportHeight: 100,
          onFastFilter: (_, selectedCategory) {
            expect(selectedCategory?.transactionCategoryID, 7);
            fastFilterCalls += 1;
          },
          onRecordTap: (_) {},
          onDeleteRequested: (_) => false,
          onCategoryFilter: (_) {},
          onEditTransaction: (_) {},
        ),
      ),
    );

    final row = find.byKey(
      const ValueKey('spendee-balance-transaction-row-record-1'),
    );
    final gesture = await tester.startGesture(tester.getCenter(row));
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    expect(transformDx(tester, 1), closeTo(-30, .001));
    expect(fastFilterCalls, 0);

    await gesture.moveBy(const Offset(-51, 0));
    await tester.pump();
    expect(transformDx(tester, 1), -44);
    expect(fastFilterCalls, 1);
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();
    expect(fastFilterCalls, 1);
    await gesture.up();
    await tester.pump();
    expect(transformDx(tester, 1), 0);
  });

  testWidgets('right swipe freezes at 44px until delete is cancelled', (
    tester,
  ) async {
    final result = Completer<bool>();
    var deleteCalls = 0;
    await tester.pumpWidget(
      host(
        SpendeeBalanceTransactionLog(
          groups: oneGroup(),
          categoriesById: {7: category()},
          viewportHeight: 100,
          onFastFilter: (_, _) {},
          onRecordTap: (_) {},
          onDeleteRequested: (_) {
            deleteCalls += 1;
            return result.future;
          },
          onCategoryFilter: (_) {},
          onEditTransaction: (_) {},
        ),
      ),
    );

    final row = find.byKey(
      const ValueKey('spendee-balance-transaction-row-record-1'),
    );
    final gesture = await tester.startGesture(tester.getCenter(row));
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(71, 0));
    await tester.pump();
    expect(deleteCalls, 1);
    expect(transformDx(tester, 1), 44);
    await gesture.up();
    await tester.pump();
    expect(transformDx(tester, 1), 44);

    result.complete(false);
    await tester.pumpAndSettle();
    expect(transformDx(tester, 1), 0);
    expect(deleteCalls, 1);
  });

  testWidgets('flings dispatch each direction once without a stray row tap', (
    tester,
  ) async {
    var fastFilterCalls = 0;
    var deleteCalls = 0;
    var rowTapCalls = 0;
    await tester.pumpWidget(
      host(
        SpendeeBalanceTransactionLog(
          groups: oneGroup(),
          categoriesById: {7: category()},
          viewportHeight: 100,
          onFastFilter: (_, _) => fastFilterCalls += 1,
          onRecordTap: (_) => rowTapCalls += 1,
          onDeleteRequested: (_) {
            deleteCalls += 1;
            return true;
          },
          onCategoryFilter: (_) {},
          onEditTransaction: (_) {},
        ),
      ),
    );

    final row = find.byKey(
      const ValueKey('spendee-balance-transaction-row-record-1'),
    );
    await tester.fling(row, const Offset(-120, 0), 1800);
    await tester.pumpAndSettle();
    expect((fastFilterCalls, deleteCalls, rowTapCalls), (1, 0, 0));
    expect(transformDx(tester, 1), 0);

    await tester.fling(row, const Offset(120, 0), 1800);
    await tester.pumpAndSettle();
    expect((fastFilterCalls, deleteCalls, rowTapCalls), (1, 1, 0));
    expect(transformDx(tester, 1), 44);

    await tester.fling(row, const Offset(120, 0), 1800);
    await tester.pumpAndSettle();
    expect(deleteCalls, 1);
  });

  testWidgets(
    'short high-velocity fling dispatches without distance threshold',
    (tester) async {
      var fastFilterCalls = 0;
      var deleteCalls = 0;
      await tester.pumpWidget(
        host(
          SpendeeBalanceTransactionLog(
            groups: oneGroup(),
            categoriesById: {7: category()},
            viewportHeight: 100,
            onFastFilter: (_, _) => fastFilterCalls += 1,
            onRecordTap: (_) {},
            onDeleteRequested: (_) {
              deleteCalls += 1;
              return false;
            },
            onCategoryFilter: (_) {},
            onEditTransaction: (_) {},
          ),
        ),
      );

      final row = find.byKey(
        const ValueKey('spendee-balance-transaction-row-record-1'),
      );
      Future<void> shortFling(double dx) async {
        final start = tester.getCenter(row);
        final gesture = await tester.createGesture();
        await gesture.down(start);
        for (var index = 0; index < 3; index += 1) {
          await gesture.moveBy(
            Offset(dx / 3, 0),
            timeStamp: Duration(milliseconds: (index + 1) * 2),
          );
        }
        await gesture.up(timeStamp: const Duration(milliseconds: 8));
      }

      await shortFling(-30);
      await tester.pumpAndSettle();
      expect((fastFilterCalls, deleteCalls), (1, 0));

      await shortFling(30);
      await tester.pumpAndSettle();
      expect((fastFilterCalls, deleteCalls), (1, 1));
    },
  );

  testWidgets('sub-threshold swipe cancels without dispatch', (tester) async {
    var fastFilterCalls = 0;
    var deleteCalls = 0;
    await tester.pumpWidget(
      host(
        SpendeeBalanceTransactionLog(
          groups: oneGroup(),
          categoriesById: {7: category()},
          viewportHeight: 100,
          onFastFilter: (_, _) => fastFilterCalls += 1,
          onRecordTap: (_) {},
          onDeleteRequested: (_) {
            deleteCalls += 1;
            return false;
          },
          onCategoryFilter: (_) {},
          onEditTransaction: (_) {},
        ),
      ),
    );

    final row = find.byKey(
      const ValueKey('spendee-balance-transaction-row-record-1'),
    );
    final gesture = await tester.startGesture(tester.getCenter(row));
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.moveBy(const Offset(-40, 0));
    await gesture.up();
    await tester.pump();

    expect((fastFilterCalls, deleteCalls), (0, 0));
    expect(transformDx(tester, 1), 0);
  });

  testWidgets('lazily builds groups with 360px cache and one 320px load-more', (
    tester,
  ) async {
    var loadMoreCalls = 0;
    final groups = [
      BalanceLogGroup(
        date: '2026.07.25.',
        rows: [
          for (var index = 0; index < 500; index += 1)
            BalanceLogRow.record(record(index + 1)),
        ],
      ),
    ];
    await tester.pumpWidget(
      host(
        SpendeeBalanceTransactionLog(
          groups: groups,
          categoriesById: {7: category()},
          viewportHeight: 180,
          hasMore: true,
          onLoadMore: () => loadMoreCalls += 1,
          onFastFilter: (_, _) {},
          onRecordTap: (_) {},
          onDeleteRequested: (_) => false,
          onCategoryFilter: (_) {},
          onEditTransaction: (_) {},
        ),
      ),
    );

    final list = tester.widget<CustomScrollView>(
      find.descendant(
        of: find.byKey(const ValueKey('spendee-balance-transaction-viewport')),
        matching: find.byType(CustomScrollView),
      ),
    );
    // Flutter 3.41 still exposes only this legacy name.
    // ignore: deprecated_member_use
    expect(list.cacheExtent, 360);
    expect(
      find.byKey(const ValueKey('spendee-balance-transaction-row-record-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-balance-transaction-row-record-500')),
      findsNothing,
    );
    expect(
      find
          .byWidgetPredicate(
            (widget) =>
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'spendee-balance-transaction-row-record-',
                ),
          )
          .evaluate()
          .length,
      lessThanOrEqualTo(12),
    );

    await tester.drag(
      find.byKey(const ValueKey('spendee-balance-transaction-viewport')),
      const Offset(0, -30000),
    );
    await tester.pumpAndSettle();
    expect(loadMoreCalls, 1);
    await tester.pumpAndSettle();
    expect(loadMoreCalls, 1);
  });

  testWidgets('query key change resets the grouped viewport to the top', (
    tester,
  ) async {
    var queryKey = 'all';
    late StateSetter setHostState;
    final groups = [
      for (var index = 0; index < 40; index += 1)
        BalanceLogGroup(
          date: '2026.06.${(index + 1).toString().padLeft(2, '0')}.',
          rows: [BalanceLogRow.record(record(index + 1))],
        ),
    ];
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return SpendeeBalanceTransactionLog(
              groups: groups,
              categoriesById: {7: category()},
              viewportHeight: 180,
              queryKey: queryKey,
              onFastFilter: (_, _) {},
              onRecordTap: (_) {},
              onDeleteRequested: (_) => false,
              onCategoryFilter: (_) {},
              onEditTransaction: (_) {},
            );
          },
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('spendee-balance-transaction-viewport')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey('spendee-balance-transaction-viewport')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.pixels, greaterThan(0));

    setHostState(() => queryKey = 'merchant:lidl');
    await tester.pump();
    await tester.pump();
    expect(scrollable.position.pixels, 0);
  });

  testWidgets(
    'queued load-more cannot cross into a same-row-count query generation',
    (tester) async {
      var queryKey = 'first';
      var loadMoreCalls = 0;
      late StateSetter setHostState;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return SpendeeBalanceTransactionLog(
                groups: oneGroup(),
                categoriesById: {7: category()},
                viewportHeight: 100,
                queryKey: queryKey,
                hasMore: true,
                onLoadMore: () => loadMoreCalls += 1,
                onFastFilter: (_, _) {},
                onRecordTap: (_) {},
                onDeleteRequested: (_) => false,
                onCategoryFilter: (_) {},
                onEditTransaction: (_) {},
              );
            },
          ),
        ),
      );

      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byKey(
            const ValueKey('spendee-balance-transaction-viewport'),
          ),
          matching: find.byType(Scrollable),
        ),
      );
      ScrollEndNotification(
        metrics: scrollable.position,
        context: scrollable.context,
      ).dispatch(scrollable.context);
      setHostState(() => queryKey = 'second');
      await tester.pump();
      expect(loadMoreCalls, 0);
    },
  );
}

List<BalanceLogGroup> oneGroup() => [
  BalanceLogGroup(date: '2026.07.25.', rows: [BalanceLogRow.record(record(1))]),
];

TransactionRecord record(
  int id, {
  String merchant = 'Lidl',
  double amount = -4250,
  String? userAssignedName,
}) {
  return TransactionRecord(
    id: id,
    date: '2026.07.25.',
    time: '11:42',
    latitude: null,
    longitude: null,
    address: null,
    merchant: merchant,
    amount: amount,
    userAssignedName: userAssignedName,
    transactionCategoryID: 7,
  );
}

TransactionCategory category() => TransactionCategory.fromMap({
  'transactionCategoryID': 7,
  'name': 'Élelmiszer',
  'type': 'kiadás',
  'colorSlot': 3,
  'iconSlot': 1,
  'backgroundColor': '#ff4b78',
  'hasLimit': false,
  'limitAmount': 0,
  'alertActive': false,
  'isCustomIcon': false,
});

RecurringGhostRecord incomeGhost() => const RecurringGhostRecord(
  id: 101,
  recurringTransactionId: 11,
  periodKey: '2026-07',
  name: 'Fizetés',
  amount: 6500,
  transactionType: 'income',
  date: '2026.07.25.',
  time: '09:00',
  categoryId: 7,
  categoryName: 'Élelmiszer',
  categoryColor: '#ff4b78',
  categoryIconSlot: 1,
  triggerMillis: 0,
  isActivated: false,
  activatedTransactionId: null,
  createdAt: 0,
  updatedAt: 0,
);

double transformDx(WidgetTester tester, int recordId) {
  final transform = tester.widget<Transform>(
    find.byKey(
      ValueKey('spendee-balance-transaction-transform-record-$recordId'),
    ),
  );
  return transform.transform.getTranslation().x;
}
