import 'dart:async';

import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/balance_frame.dart';
import 'package:exptv2/features/transactions/widgets/category_slot_icon.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_transaction_log.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_visual_spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/balance_production_host.dart';

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
    'L1-L8 renders the complete LogBox in a no-recovery collapsed production dashboard',
    (tester) async {
      await pumpBalanceProductionHost(tester, expanded: false, settle: false);
      await tester.pump();

      final viewport = find.byKey(
        const ValueKey('spendee-balance-transaction-viewport'),
      );
      final dayMaterial = find.byKey(
        const ValueKey('spendee-balance-transaction-day-decoration-2026-07-17'),
      );
      final row = find.byKey(
        const ValueKey('spendee-balance-transaction-row-record-1'),
      );
      final edit = find.byKey(
        const ValueKey('spendee-balance-transaction-edit-record-1'),
      );

      expect(tester.getSize(viewport), const Size(378, 422));
      expect(SpendeeBalanceTransactionLog.visibleRowBound(422), 8);
      expect(SpendeeBalanceTransactionLog.mountedRowBound(422), 21);
      final list = tester.widget<CustomScrollView>(
        find.descendant(of: viewport, matching: find.byType(CustomScrollView)),
      );
      expect(list.physics, isA<ClampingScrollPhysics>());
      // Flutter 3.41 still exposes only this legacy name.
      // ignore: deprecated_member_use
      expect(list.cacheExtent, 360);

      final dayDecoration =
          tester.widget<DecoratedSliver>(dayMaterial).decoration
              as BoxDecoration;
      expect(dayDecoration.color, isNull);
      expect(dayDecoration.border, isNull);
      expect(dayDecoration.boxShadow, isNull);

      expect(tester.getSize(row), const Size(372, 55));
      final movingDecoration =
          tester
                  .widget<DecoratedBox>(
                    find.byKey(
                      const ValueKey(
                        'spendee-balance-transaction-surface-record-2',
                      ),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(movingDecoration.color, const Color(0xF5FFFFFF));
      final movingBorder = movingDecoration.border! as Border;
      expect(movingBorder.top.color, const Color(0x1A666FAB));
      expect(movingBorder.left.color, const Color(0x1A666FAB));
      expect(movingBorder.right.color, const Color(0x1A666FAB));
      expect(movingDecoration.boxShadow, hasLength(2));
      expect(movingDecoration.boxShadow!.first.color, const Color(0x14524B93));
      expect(movingDecoration.boxShadow!.first.offset, const Offset(0, 9));
      expect(movingDecoration.boxShadow!.first.blurRadius, 19);
      expect(movingDecoration.boxShadow!.last.color, const Color(0xF5FFFFFF));
      expect(movingDecoration.boxShadow!.last.offset, const Offset(0, 1));
      expect(movingDecoration.boxShadow!.last.blurStyle, BlurStyle.inner);
      expect(edit, findsOneWidget);
      expect(tester.getSize(edit), const Size.square(24));
      expect(
        tester.getSize(
          find.byKey(
            const ValueKey('spendee-balance-transaction-edit-glyph-record-1'),
          ),
        ),
        const Size.square(13),
      );
      final editDecoration = decorationOf(tester, edit);
      expect(editDecoration.color, const Color(0x1A7D8798));
      expect(editDecoration.borderRadius, BorderRadius.circular(8));
      expect(
        tester.getRect(edit).right,
        tester.getRect(row).right -
            SpendeeBalanceVisualSpec.transactionRowPadding.right,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('spendee-balance-transaction-merchant-record-1'),
          ),
          matching: find.byType(SvgPicture),
        ),
        findsNothing,
      );
      expect(
        find
            .descendant(
              of: find.byKey(
                const ValueKey('spendee-balance-transaction-avatar-record-1'),
              ),
              matching: find.byType(SvgPicture),
            )
            .evaluate()
            .where((element) {
              final picture = element.widget as SvgPicture;
              return picture.bytesLoader.toString().contains('pencil.svg');
            }),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('L7 uses the literal compact empty-log state', (tester) async {
    await tester.pumpWidget(
      host(
        SpendeeBalanceTransactionLog(
          groups: const [],
          categoriesById: const {},
          viewportHeight: 100,
          onFastFilter: (_, _) {},
          onRecordTap: (_) {},
          onDeleteRequested: (_) => false,
          onCategoryFilter: (_) {},
          onEditTransaction: (_) {},
        ),
      ),
    );

    final message = find.text('Nincs megjeleníthető tranzakció');
    expect(message, findsOneWidget);
    final text = tester.widget<Text>(message);
    expect(text.style!.color, const Color(0xFF7D88A4));
    expect(text.style!.fontSize, 9);
    expect(text.style!.height, 1);
    expect(text.style!.fontWeight, FontWeight.w700);
    expect(
      find.ancestor(
        of: message,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Padding &&
              widget.padding == const EdgeInsets.only(top: 20),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'L6 production swipe leaves no opaque day material at the origin',
    (tester) async {
      await pumpBalanceProductionHost(tester);

      final day = find.byKey(
        const ValueKey('spendee-balance-transaction-day-decoration-2026-07-17'),
      );
      final surface = find.byKey(
        const ValueKey('spendee-balance-transaction-surface-record-1'),
      );
      final avatar = find.byKey(
        const ValueKey('spendee-balance-transaction-avatar-record-1'),
      );
      final edit = find.byKey(
        const ValueKey('spendee-balance-transaction-edit-record-1'),
      );
      final transform = find.byKey(
        const ValueKey('spendee-balance-transaction-transform-record-1'),
      );

      final dayDecoration =
          tester.widget<DecoratedSliver>(day).decoration as BoxDecoration;
      expect(dayDecoration.color, isNull);
      expect(dayDecoration.border, isNull);
      expect(dayDecoration.boxShadow, isNull);
      for (final descendant in <Finder>[surface, avatar, edit]) {
        expect(
          find.ancestor(of: descendant, matching: transform),
          findsOneWidget,
        );
      }
      expect(
        coloredAncestorsOf(
          tester,
          surface,
        ).where((color) => color != balanceProductionPageColor),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('L8 production host renders multiple all-time day groups', (
    tester,
  ) async {
    await pumpBalanceProductionHost(
      tester,
      transactions: productionLogFixture(3),
      allTime: true,
      expanded: false,
      settle: false,
    );
    await tester.pump();

    for (final dateKey in <String>['2026-07-17', '2026-07-16', '2026-07-15']) {
      expect(
        find.byKey(ValueKey('spendee-balance-transaction-day-title-$dateKey')),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('L8 production host publishes the ordered load-more trace', (
    tester,
  ) async {
    await pumpBalanceProductionHost(
      tester,
      transactions: productionLogFixture(97, multipleDays: false),
      expanded: false,
      settle: false,
    );
    await tester.pump();

    final viewport = find.byKey(
      const ValueKey('spendee-balance-transaction-viewport'),
    );
    DebugConsole.clear();
    await tester.drag(viewport, const Offset(0, -10000));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(
      balanceLogTracePhases(),
      containsAllInOrder(<String>[
        'scroll_start',
        'first_mounted_row_change',
        'near_end',
        'window_request',
        'load_more_publish',
        'first_frame_after_publish',
        'scroll_end',
      ]),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'L8 production query change cancels a queued stale load-more callback',
    (tester) async {
      final store = await pumpBalanceProductionHost(
        tester,
        transactions: productionLogFixture(97, multipleDays: false),
        expanded: false,
        settle: false,
      );
      await tester.pump();
      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byKey(
            const ValueKey('spendee-balance-transaction-viewport'),
          ),
          matching: find.byType(Scrollable),
        ),
      );
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pump();
      DebugConsole.clear();

      ScrollStartNotification(
        metrics: scrollable.position,
        context: scrollable.context,
      ).dispatch(scrollable.context);
      ScrollEndNotification(
        metrics: scrollable.position,
        context: scrollable.context,
      ).dispatch(scrollable.context);
      store.setMerchantFilter('Merchant 1');
      await tester.pump();
      await tester.pump();

      expect(balanceLogTracePhases(), isNot(contains('load_more_publish')));
      expect(tester.takeException(), isNull);
    },
  );

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
        findsOneWidget,
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
      expect(decoration.borderRadius, isNull);
      expect(decoration.color, isNull);
      expect(decoration.border, isNull);
      expect(decoration.boxShadow, isNull);

      final rowSurface = tester.widget<DecoratedBox>(
        find.byKey(
          const ValueKey('spendee-balance-transaction-surface-record-1'),
        ),
      );
      final rowDecoration = rowSurface.decoration as BoxDecoration;
      expect(rowDecoration.color, const Color(0xF5FFFFFF));
      expect(
        rowDecoration.borderRadius,
        const BorderRadius.vertical(top: Radius.circular(17)),
      );
      final rowBorder = rowDecoration.border! as Border;
      expect(rowBorder.top.color, const Color(0x1A666FAB));
      expect(rowBorder.left.color, const Color(0x1A666FAB));
      expect(rowBorder.right.color, const Color(0x1A666FAB));
      expect(rowDecoration.boxShadow, hasLength(2));
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
      findsOneWidget,
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
      var editCalls = 0;
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
            onEditTransaction: (_) => editCalls += 1,
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
        2,
        reason: 'the category avatar and right edit are nested actions',
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

      final edit = find.byKey(
        const ValueKey('spendee-balance-transaction-edit-record-1'),
      );
      expect(edit, findsOneWidget);
      expect(tester.getSemantics(edit).label, 'Tranzakció szerkesztése');
      await tester.tap(edit);
      await tester.pump();
      expect((editCalls, rowCalls), (1, 0));
      Focus.of(tester.element(edit)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect((editCalls, rowCalls), (2, 0));

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

  testWidgets('log rows expose one right-edge edit target', (tester) async {
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
      findsOneWidget,
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
    expect(transformDx(tester, 1), closeTo(-3, .001));
    expect(fastFilterCalls, 0);

    await gesture.moveBy(const Offset(-51, 0));
    await tester.pump();
    expect(transformDx(tester, 1), -3);
    expect(fastFilterCalls, 1);
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();
    expect(fastFilterCalls, 1);
    await gesture.up();
    await tester.pump();
    expect(transformDx(tester, 1), 0);
  });

  testWidgets('left swipe remains inside the authored Balance gutter', (
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

    final row = find.byKey(
      const ValueKey('spendee-balance-transaction-row-record-1'),
    );
    final surface = find.byKey(
      const ValueKey('spendee-balance-transaction-surface-record-1'),
    );
    final gesture = await tester.startGesture(tester.getCenter(row));
    await gesture.moveBy(const Offset(-120, 0));
    await tester.pump();

    expect(tester.getRect(surface).left, greaterThanOrEqualTo(17));
    await gesture.up();
  });

  testWidgets(
    'horizontal swipe translates the painted LogBox surface with its contents',
    (tester) async {
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

      final row = find.byKey(
        const ValueKey('spendee-balance-transaction-row-record-1'),
      );
      final surface = find.byKey(
        const ValueKey('spendee-balance-transaction-surface-record-1'),
      );
      final avatar = find.byKey(
        const ValueKey('spendee-balance-transaction-avatar-record-1'),
      );
      final transform = find.byKey(
        const ValueKey('spendee-balance-transaction-transform-record-1'),
      );
      expect(surface, findsOneWidget);
      expect(find.descendant(of: transform, matching: surface), findsOneWidget);
      expect(find.descendant(of: transform, matching: avatar), findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(row));
      await gesture.moveBy(const Offset(-20, 0));
      // The first movement only resolves Flutter's horizontal drag arena.
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();

      expect(transformDx(tester, 1), closeTo(-3, .01));
      final decoration =
          tester.widget<DecoratedBox>(surface).decoration as BoxDecoration;
      expect(decoration.color, const Color(0xF5FFFFFF));
      await gesture.up();
    },
  );

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

List<TransactionRecord> productionLogFixture(
  int count, {
  bool multipleDays = true,
}) => [
  for (var index = 0; index < count; index += 1)
    balanceProductionRecord(
      index + 1,
      categoryId: index.isEven ? 1 : 2,
      amount: -1000.0 - index,
      merchant: 'Merchant ${index + 1}',
      date: multipleDays
          ? switch (count <= 3 ? index : index ~/ 40) {
              0 => '2026.07.17',
              1 => '2026.07.16',
              _ => '2026.07.15',
            }
          : '2026.07.17',
      time: '10:${(index % 60).toString().padLeft(2, '0')}',
    ),
];

List<String> balanceLogTracePhases() {
  final phase = RegExp(r'phase=([a-z_]+)');
  return DebugConsole.entries
      .where((entry) => entry.contains('operation=balance-log-scroll'))
      .map((entry) => phase.firstMatch(entry)?.group(1))
      .whereType<String>()
      .toList();
}

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
