import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
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
}

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
  Future<CategoryLimit> upsertCategoryLimit(Map<String, Object?> payload) async {
    throw UnimplementedError();
  }
}
