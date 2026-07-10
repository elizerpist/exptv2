import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_log_entry.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/slots/category_icon_manager.dart';
import 'package:exptv2/features/transactions/widgets/category_slot_icon.dart';
import 'package:exptv2/features/transactions/widgets/transaction_log_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  testWidgets('logbox icons render from warm cache on first list frame', (
    tester,
  ) async {
    DebugConsole.clear();
    CategoryIconManager.resetForTests();
    resetCategorySlotIconCacheForTests();

    await tester.runAsync(() async {
      await warmUpCategorySlotIconCache(slots: const [0, 2], strokeWidth: 1.35);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 260,
          child: TransactionLogList(
            entries: [
              TransactionLogEntry.header('2025.09.25'),
              TransactionLogEntry.record(sampleRecord()),
              TransactionLogEntry.ghost(sampleGhostRecord()),
            ],
            categoriesById: {
              sampleCategory().transactionCategoryID: sampleCategory(),
              sampleExpenseCategory().transactionCategoryID:
                  sampleExpenseCategory(),
            },
            onFastFilter: (_, _) {},
            onRecordTap: (_) {},
            onDeleteRequested: (_) => true,
            onCategoryFilter: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(SvgPicture), findsNWidgets(2));
    expect(DebugConsole.allText, contains('[IconLoad] asset warmup start'));
    expect(DebugConsole.allText, contains('[IconLoad] asset warmup end'));
    expect(DebugConsole.allText, contains('[LogBoxIcon] first list build'));
    expect(DebugConsole.allText, contains('visibleRows=2'));
    expect(
      DebugConsole.allText,
      contains('[LogBoxIcon] first render source=transaction-logbox'),
    );
    expect(
      DebugConsole.allText,
      contains('[LogBoxIcon] first render source=recurring-ghost-logbox'),
    );
    expect(DebugConsole.allText, contains('cacheHit=true'));
  });
}

TransactionRecord sampleRecord() => TransactionRecord.fromMap({
  'id': 250905,
  'date': '2025.09.24',
  'time': '21:56',
  'merchant': 'Rrteeaawwq',
  'amount': 5555,
  'userAssignedName': 'Gguu',
  'transactionCategoryID': 5,
});

TransactionCategory sampleCategory() => TransactionCategory.fromMap({
  'transactionCategoryID': 5,
  'name': 'Rr',
  'type': 'bevétel',
  'colorSlot': 2,
  'iconSlot': 0,
  'backgroundColor': '#3b82f6',
  'hasLimit': false,
  'limitAmount': 0,
  'alertActive': false,
  'isCustomIcon': true,
});

RecurringGhostRecord sampleGhostRecord() => RecurringGhostRecord.fromMap({
  'id': 250910,
  'recurringTransactionId': 91,
  'periodKey': '2025-09',
  'name': 'Expected Shop',
  'amount': 1200,
  'triggerTypeSnapshot': 'date',
  'transactionType': 'expense',
  'date': '2025.09.25',
  'time': '08:00',
  'categoryId': 6,
  'categoryName': 'Q',
  'categoryColor': '#dc2626',
  'categoryIconSlot': 2,
  'triggerMillis': 0,
  'isActivated': false,
  'activatedTransactionId': null,
  'createdAt': 0,
  'updatedAt': 0,
});

TransactionCategory sampleExpenseCategory() => TransactionCategory.fromMap({
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
