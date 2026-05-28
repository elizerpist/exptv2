import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/transaction_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('header leaves the same gap above and below type pills', (
    tester,
  ) async {
    final store = TransactionStore(HeaderLayoutRepository());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: TransactionHomePage(store: store),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final headerBottom = tester
        .getRect(find.byKey(const ValueKey('header-expand-button')))
        .bottom;
    final typePill = find
        .byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == '_TransactionTypePill',
        )
        .first;
    final typePillRect = tester.getRect(typePill);
    final summaryTop = tester
        .getRect(find.byKey(const ValueKey('summary-pill')))
        .top;

    final topGap = typePillRect.top - headerBottom;
    final bottomGap = summaryTop - typePillRect.bottom;

    expect(topGap, moreOrLessEquals(bottomGap, epsilon: 0.1));
    expect(topGap, moreOrLessEquals(12, epsilon: 0.1));
  });

  testWidgets('calendar overlay starts on the summary pill top edge', (
    tester,
  ) async {
    final store = TransactionStore(HeaderLayoutRepository());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: TransactionHomePage(store: store),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final summaryTop = tester
        .getRect(find.byKey(const ValueKey('summary-pill')))
        .top;
    await tester.tap(find.byKey(const ValueKey('header-calendar-button')));
    await tester.pumpAndSettle();

    final overlayTop = tester
        .getRect(find.byKey(const ValueKey('calendar-menu-overlay')))
        .top;
    expect(overlayTop, moreOrLessEquals(summaryTop, epsilon: 0.1));
  });

  testWidgets(
    'category picker and add editor cards start on the summary pill top edge',
    (tester) async {
      final store = TransactionStore(HeaderLayoutRepository());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 780,
              child: TransactionHomePage(store: store),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final summaryTop = tester
          .getRect(find.byKey(const ValueKey('summary-pill')))
          .top;
      await tester.tap(find.byKey(const ValueKey('header-category-button')));
      await tester.pumpAndSettle();

      final pickerTop = tester
          .getRect(find.byKey(const ValueKey('category-menu-overlay')))
          .top;
      expect(pickerTop, moreOrLessEquals(summaryTop, epsilon: 0.1));

      expect(
        find.byKey(const ValueKey('category-menu-close-button')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('category-add-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('category-editor-slide-card')),
        findsOneWidget,
      );
      expect(find.byType(BottomSheet), findsNothing);
      final editorRect = tester.getRect(
        find.byKey(const ValueKey('category-editor-slide-card')),
      );
      expect(editorRect.top, moreOrLessEquals(summaryTop, epsilon: 0.1));
      expect(
        editorRect.bottom,
        moreOrLessEquals(_screenHeight(tester), epsilon: 0.1),
      );
    },
  );

  testWidgets(
    'header category button toggles the full height category picker',
    (tester) async {
      final store = TransactionStore(HeaderLayoutRepository());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 780,
              child: TransactionHomePage(store: store),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('header-category-button')));
      await tester.pumpAndSettle();

      final pickerRect = tester.getRect(
        find.byKey(const ValueKey('category-menu-overlay')),
      );
      expect(
        pickerRect.bottom,
        moreOrLessEquals(_screenHeight(tester), epsilon: 0.1),
      );

      await tester.tap(find.byKey(const ValueKey('header-category-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('category-menu-overlay')), findsNothing);
    },
  );

  testWidgets(
    'category modify editor card starts on the summary pill top edge',
    (tester) async {
      final store = TransactionStore(HeaderLayoutRepository());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 780,
              child: TransactionHomePage(store: store),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final summaryTop = tester
          .getRect(find.byKey(const ValueKey('summary-pill')))
          .top;
      await tester.tap(find.byKey(const ValueKey('header-category-button')));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const ValueKey('category-icon-6')));
      await tester.pumpAndSettle();

      expect(find.text('Kategória módosítása'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('category-editor-slide-card')),
        findsOneWidget,
      );
      final editorTop = tester
          .getRect(find.byKey(const ValueKey('category-editor-slide-card')))
          .top;
      expect(editorTop, moreOrLessEquals(summaryTop, epsilon: 0.1));
    },
  );

  testWidgets('header expand button stays fixed when header card slides up', (
    tester,
  ) async {
    final store = TransactionStore(HeaderLayoutRepository());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: TransactionHomePage(store: store),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final buttonTop = tester
        .getRect(find.byKey(const ValueKey('header-expand-button')))
        .top;
    await tester.tap(find.byKey(const ValueKey('header-expand-button')));
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byKey(const ValueKey('header-expand-button'))).top,
      moreOrLessEquals(buttonTop, epsilon: 0.1),
    );
  });

  testWidgets('header pull reveals FastInfo during drag and springs closed', (
    tester,
  ) async {
    final store = TransactionStore(HeaderLayoutRepository());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: TransactionHomePage(store: store),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(const Offset(180, 80));
    await gesture.moveBy(const Offset(0, 160));
    await tester.pump();

    expect(find.byKey(const ValueKey('fast-info-panel')), findsOneWidget);
    expect(find.text('Megtakarítás'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    expect(find.byKey(const ValueKey('fast-info-panel')), findsNothing);
  });

  testWidgets('expand button still toggles after header drag', (tester) async {
    final store = TransactionStore(HeaderLayoutRepository());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: TransactionHomePage(store: store),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final header = find.byKey(const ValueKey('transaction-header-card'));
    await tester.drag(header, const Offset(0, 80));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    await tester.tap(
      find.byKey(const ValueKey('header-expand-button-hit-area')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('category-budget-stage')), findsOneWidget);
  });
}

double _screenHeight(WidgetTester tester) =>
    tester.view.physicalSize.height / tester.view.devicePixelRatio;

class HeaderLayoutRepository implements TransactionRepositoryContract {
  @override
  Future<TransactionBootstrap> loadBootstrap() async => TransactionBootstrap(
    categories: [
      TransactionCategory.fromMap({
        'transactionCategoryID': 6,
        'name': 'Food',
        'type': 'kiadás',
        'colorSlot': 7,
        'iconSlot': 2,
        'backgroundColor': '#0ea5e9',
        'hasLimit': false,
        'limitAmount': 0,
        'alertActive': false,
        'isCustomIcon': true,
      }),
    ],
    transactions: [
      TransactionRecord.fromMap({
        'id': 1,
        'date': '2026.05.04',
        'time': '12:00',
        'merchant': 'Shop',
        'amount': -100,
        'userAssignedName': null,
        'transactionCategoryID': 6,
      }),
    ],
    limits: const [],
  );

  @override
  Future<TransactionRecord> addTransaction(Map<String, Object?> payload) async {
    throw UnimplementedError();
  }

  @override
  Future<TransactionRecord> updateTransaction(
    int id,
    Map<String, Object?> payload,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteTransaction(int id) async {
    throw UnimplementedError();
  }

  @override
  Future<TransactionCategory> addCategory(Map<String, Object?> payload) async {
    throw UnimplementedError();
  }

  @override
  Future<TransactionCategory> updateCategory(
    int id,
    Map<String, Object?> payload,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteCategory(int id) async {
    throw UnimplementedError();
  }

  @override
  Future<int> renameTransactionsByMerchant(
    String originalMerchant,
    String userAssignedName,
  ) async => throw UnimplementedError();

  @override
  Future<int> resetTransactionNamesByMerchant(String originalMerchant) async =>
      throw UnimplementedError();

  @override
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  }) async => const [];

  @override
  Future<Map<int, int>> categoryCounts() async => const {6: 1};

  @override
  Future<List<CategoryLimit>> listCategoryLimits({
    String? transactionType,
    String? window,
    String? periodKey,
  }) async {
    return const [];
  }

  @override
  Future<CategoryLimit> upsertCategoryLimit(
    Map<String, Object?> payload,
  ) async {
    throw UnimplementedError();
  }
}
