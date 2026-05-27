import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/models/transaction_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TransactionCategory normalizes Hungarian type values', () {
    final income = TransactionCategory.fromMap({
      'transactionCategoryID': 5,
      'name': 'Rr',
      'type': 'bevétel',
      'colorSlot': 2,
      'iconSlot': 0,
      'backgroundColor': '#3b82f6',
      'icon': './assets/broccoli.png',
      'notification': null,
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': true,
      'originalIcon': null,
    });

    final expense = TransactionCategory.fromMap({
      'transactionCategoryID': 6,
      'name': 'Q',
      'type': 'kiadás',
      'colorSlot': 7,
      'iconSlot': 2,
      'backgroundColor': '#dc2626',
      'icon': './assets/example.png',
      'notification': null,
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': true,
      'originalIcon': null,
    });

    expect(income.normalizedType, TransactionType.income);
    expect(expense.normalizedType, TransactionType.expense);
    expect(income.slotColorHex, '#eab308');
  });

  test(
    'TransactionRecord parses native payload and formats display fields',
    () {
      final record = TransactionRecord.fromMap({
        'id': 250905,
        'date': '2025.09.24',
        'time': '21:56',
        'latitude': null,
        'longitude': null,
        'address': 'Unknown location',
        'merchant': 'Rrteeaawwq',
        'amount': 5555,
        'userAssignedName': 'Gguu',
        'transactionCategoryID': 5,
      });

      expect(record.type, TransactionType.income);
      expect(record.displayMerchant, 'Gguu');
      expect(record.displayAmount, '+5 555 Ft');
      expect(record.displayTime, '21:56');
      expect(record.yearMonthKey, '2025-09');
    },
  );

  test('TransactionSummary calculates income expense and active total', () {
    final records = [
      TransactionRecord.fromMap({
        'id': 250901,
        'date': '2025.09.24',
        'time': '20:31',
        'merchant': 'Tt',
        'amount': -66,
        'userAssignedName': null,
        'transactionCategoryID': 9,
      }),
      TransactionRecord.fromMap({
        'id': 250905,
        'date': '2025.09.24',
        'time': '21:56',
        'merchant': 'Rrteeaawwq',
        'amount': 5555,
        'userAssignedName': 'Gguu',
        'transactionCategoryID': 5,
      }),
    ];

    final summary = TransactionSummary.fromRecords(records);

    expect(summary.income, 5555);
    expect(summary.expense, 66);
    expect(summary.formattedFor(TransactionType.income), '+5 555 Ft');
    expect(summary.formattedFor(TransactionType.expense), '-66 Ft');
  });
}
