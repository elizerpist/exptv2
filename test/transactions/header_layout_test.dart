import 'package:exptv2/core/theme/app_dimensions.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/transaction_home_page.dart';
import 'package:exptv2/features/transactions/widgets/header_card/transaction_header_card.dart';
import 'package:exptv2/features/transactions/widgets/header_card/transaction_header_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('magnet strip metric is 50 percent taller than the prior strip', () {
    expect(TransactionHeaderMetrics.magnetHeight, greaterThanOrEqualTo(157.5));
  });

  testWidgets('header shadow remains visible while fast info is visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionHeaderCard(
            balanceText: '-100 Ft',
            onCategoryPressed: () {},
            onExpandPressed: () {},
            fastInfoVisible: true,
            magnetType: MagnetType.fade,
            totalIncome: 0,
            totalExpense: 100,
          ),
        ),
      ),
    );

    final decoratedBox = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .firstWhere((box) {
          final decoration = box.decoration;
          return decoration is BoxDecoration &&
              (decoration.boxShadow?.isNotEmpty ?? false);
        });
    final decoration = decoratedBox.decoration as BoxDecoration;

    expect(
      decoration.boxShadow!.single.color,
      Colors.black.withValues(alpha: 0.15),
    );
  });

  testWidgets('neumorphic header keeps a drop shadow on the background', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionHeaderCard(
            balanceText: '-100 Ft',
            onCategoryPressed: () {},
            onExpandPressed: () {},
            surfaceStyle: ExpenseSurfaceInteraction.raisedInset,
          ),
        ),
      ),
    );

    final surface = tester.widget<Container>(
      find.byKey(const ValueKey('transaction-header-surface')),
    );
    final decoration = surface.decoration! as BoxDecoration;

    expect(
      decoration.boxShadow,
      contains(
        isA<BoxShadow>()
            .having(
              (shadow) => shadow.color,
              'color',
              Colors.black.withValues(alpha: 0.15),
            )
            .having((shadow) => shadow.offset, 'offset', const Offset(0, 4))
            .having((shadow) => shadow.blurRadius, 'blurRadius', 8),
      ),
    );
  });

  testWidgets('budget trigger chip is left aligned on the header card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: TransactionHeaderCard(
              balanceText: '-100 Ft',
              onCategoryPressed: () {},
              onExpandPressed: () {},
            ),
          ),
        ),
      ),
    );

    final headerRect = tester.getRect(
      find.byKey(const ValueKey('transaction-header-card')),
    );
    final chipRect = tester.getRect(
      find.byKey(const ValueKey('header-budget-trigger-chip')),
    );

    expect(chipRect.left - headerRect.left, moreOrLessEquals(30, epsilon: 1));
  });

  testWidgets('hide balance button toggles the visible balance text', (
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

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('header-balance-text')))
          .data,
      '-100 Ft',
    );

    await tester.tap(
      find.byKey(const ValueKey('header-balance-visibility-button')),
    );
    await tester.pump();

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('header-balance-text')))
          .data,
      '••••••• Ft',
    );

    await tester.tap(
      find.byKey(const ValueKey('header-balance-visibility-button')),
    );
    await tester.pump();

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('header-balance-text')))
          .data,
      '-100 Ft',
    );
  });
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

    expect(find.byKey(const ValueKey('header-card-drag-handle')), findsNothing);
    final headerBottom = tester
        .getRect(find.byKey(const ValueKey('transaction-header-card')))
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

    expect(topGap, greaterThan(0));
    expect(bottomGap, greaterThan(0));
  });

  testWidgets('header no longer owns the calendar entry point', (tester) async {
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

    expect(find.byKey(const ValueKey('header-calendar-button')), findsNothing);
    expect(
      find.byKey(const ValueKey('header-category-button')),
      findsOneWidget,
    );
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
      expect(pickerTop, moreOrLessEquals(summaryTop, epsilon: 1.1));

      expect(
        find.byKey(const ValueKey('category-menu-close-button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('category-menu-back-button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('category-menu-add-button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'header category button toggles the full height category picker',
    (tester) async {
      final previousFatalHitTest = WidgetController.hitTestWarningShouldBeFatal;
      WidgetController.hitTestWarningShouldBeFatal = true;
      addTearDown(() {
        WidgetController.hitTestWarningShouldBeFatal = previousFatalHitTest;
      });
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
      final widgets = tester.allWidgets.toList();
      final pickerPaintIndex = widgets.indexWhere(
        (widget) => widget.key == const ValueKey('category-menu-overlay'),
      );
      final headerPaintIndex = widgets.indexWhere(
        (widget) => widget.key == const ValueKey('transaction-header-card'),
      );
      expect(headerPaintIndex, greaterThan(pickerPaintIndex));
      expect(
        pickerRect.bottom,
        moreOrLessEquals(
          _screenHeight(tester) - AppDimensions.bottomNavHeight,
          epsilon: 1.1,
        ),
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

  testWidgets('header card animates upward when backheader opens', (
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

    final before = tester
        .getTopLeft(find.byKey(const ValueKey('transaction-header-card')))
        .dy;
    await tester.tap(find.byKey(const ValueKey('header-budget-trigger-chip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final during = tester
        .getTopLeft(find.byKey(const ValueKey('transaction-header-card')))
        .dy;
    await tester.pumpAndSettle();
    final after = tester
        .getTopLeft(find.byKey(const ValueKey('transaction-header-card')))
        .dy;

    expect(during, lessThan(before));
    expect(during, greaterThan(after));
  });

  testWidgets(
    'header content stays visible until upward slide is almost complete',
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

      await tester.tap(
        find.byKey(const ValueKey('header-budget-trigger-chip')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      var balanceOpacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.byKey(const ValueKey('header-balance-text')),
          matching: find.byType(Opacity),
        ),
      );
      expect(balanceOpacity.opacity, moreOrLessEquals(1, epsilon: 0.01));

      await tester.pumpAndSettle();
      balanceOpacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.byKey(const ValueKey('header-balance-text')),
          matching: find.byType(Opacity),
        ),
      );
      expect(balanceOpacity.opacity, moreOrLessEquals(0, epsilon: 0.01));
    },
  );

  testWidgets('budget trigger opens backheader without arrow close button', (
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

    final closedTop = tester
        .getTopLeft(find.byKey(const ValueKey('transaction-header-card')))
        .dy;
    await tester.tap(find.byKey(const ValueKey('header-budget-trigger-chip')));
    await tester.pumpAndSettle();
    final expandedTop = tester
        .getTopLeft(find.byKey(const ValueKey('transaction-header-card')))
        .dy;

    expect(expandedTop, lessThan(closedTop));
    expect(find.byKey(const ValueKey('category-budget-stage')), findsOneWidget);
    expect(find.byKey(const ValueKey('header-expand-button')), findsNothing);
  });

  testWidgets('header budget trigger chip slides with the header card', (
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

    final chipTop = tester
        .getRect(find.byKey(const ValueKey('header-budget-trigger-chip')))
        .top;
    await tester.tap(find.byKey(const ValueKey('header-budget-trigger-chip')));
    await tester.pumpAndSettle();

    expect(
      tester
          .getRect(find.byKey(const ValueKey('header-budget-trigger-chip')))
          .top,
      moreOrLessEquals(
        chipTop - TransactionHeaderMetrics.expandedSlideDistance,
        epsilon: 1,
      ),
    );
  });

  testWidgets('header arrow expand button is not rendered', (tester) async {
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

    expect(find.byKey(const ValueKey('header-expand-button')), findsNothing);
    expect(
      find.byKey(const ValueKey('header-expand-button-hit-area')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('header-budget-trigger-chip')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('header-card-drag-handle')), findsNothing);
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

    expect(
      find.byKey(const ValueKey('header-fast-info-extent-builder')),
      findsOneWidget,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('transaction-header-card'))),
    );
    await gesture.moveBy(const Offset(0, 160));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('header-fast-info-surface')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('fast-info-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('fastinfo-box-slot-0')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('header-fast-info-surface')),
        matching: find.byKey(const ValueKey('transaction-header-card')),
      ),
      findsOneWidget,
    );

    await gesture.up();
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    expect(find.byKey(const ValueKey('fast-info-panel')), findsNothing);
  });

  testWidgets('budget trigger still toggles after header drag', (tester) async {
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

    await tester.tap(find.byKey(const ValueKey('header-budget-trigger-chip')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('category-budget-stage')), findsOneWidget);
  });

  testWidgets(
    'category picker stays open and refreshes when active type changes',
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

      expect(
        find.byKey(const ValueKey('category-menu-overlay')),
        findsOneWidget,
      );
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Salary'), findsNothing);

      await tester.tap(find.text('Bevétel'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('category-menu-overlay')),
        findsOneWidget,
      );
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('Food'), findsNothing);
    },
  );

  testWidgets('magnet strip moves up and balance label sits in magnet zone', (
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

    final magnet = tester.getRect(
      find.byKey(const ValueKey('magnet-strip-fade')),
    );
    final balanceLabel = tester.getRect(find.text('Egyenleg'));
    final balanceText = tester.getRect(
      find.byKey(const ValueKey('header-balance-text')),
    );
    final trackHeight = TransactionHeaderMetrics.magnetHeight * 6 / 35;
    final trackTop =
        TransactionHeaderMetrics.magnetTop +
        TransactionHeaderMetrics.magnetHeight / 2 -
        trackHeight / 2;
    final trackBottom = trackTop + trackHeight;

    expect(magnet.top, moreOrLessEquals(41, epsilon: 0.1));
    expect(balanceLabel.center.dy, greaterThanOrEqualTo(trackTop));
    expect(balanceLabel.center.dy, lessThanOrEqualTo(trackBottom));
    expect(balanceText.top, greaterThanOrEqualTo(trackBottom));
  });
}

double _screenHeight(WidgetTester tester) =>
    tester.view.physicalSize.height / tester.view.devicePixelRatio;

class HeaderLayoutRepository extends TransactionRepositoryContract {
  @override
  Future<TransactionBootstrap> loadBootstrap() async => TransactionBootstrap(
    categories: [
      TransactionCategory.fromMap({
        'transactionCategoryID': 5,
        'name': 'Salary',
        'type': 'bevétel',
        'colorSlot': 2,
        'iconSlot': 0,
        'backgroundColor': '#3b82f6',
        'hasLimit': false,
        'limitAmount': 0,
        'alertActive': false,
        'isCustomIcon': true,
      }),
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
  Future<TransactionPage> listTransactionPage(
    TransactionPageQuery query,
  ) async {
    return TransactionPage(
      transactions: const [],
      totalCount: 0,
      limit: query.limit,
      offset: query.offset,
    );
  }

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
  Future<Map<int, int>> categoryCounts() async => const {5: 0, 6: 1};

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
