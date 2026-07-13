import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/models/transaction_summary.dart';
import 'package:exptv2/features/transactions/slots/category_color_manager.dart';
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
    expect(income.slotColorHex, CategoryColorManager.hex(2));
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

  test('TransactionRecord treats recurring rule links as generated', () {
    final record = TransactionRecord.fromMap({
      'id': 250905,
      'date': '2025.09.24',
      'time': '21:56',
      'merchant': 'Bank hitel',
      'amount': -100000,
      'userAssignedName': 'Hitel',
      'transactionCategoryID': 6,
      'recurringRuleId': 42,
      'recurringInstanceId': 4201,
    });

    expect(record.isRecurringGenerated, isTrue);
    expect(record.recurringRuleId, 42);
    expect(record.recurringInstanceId, 4201);
    expect(record.toMap(), containsPair('recurringRuleId', 42));
    expect(record.toMap(), containsPair('recurringInstanceId', 4201));
  });

  test('TransactionRecord parses uncategorized push source payload', () {
    final record = TransactionRecord.fromMap({
      'id': 26060701,
      'date': '2026.06.07',
      'time': '21:10',
      'merchant': 'Tesco',
      'amount': -12345,
      'userAssignedName': null,
      'transactionCategoryID': null,
      'sourceNotificationEventId': 77,
    });

    expect(record.transactionCategoryID, isNull);
    expect(record.sourceNotificationEventId, 77);
    expect(record.displayAmount, '-12 345 Ft');
    expect(record.toMap(), containsPair('transactionCategoryID', null));
    expect(record.toMap(), containsPair('sourceNotificationEventId', 77));
  });

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
