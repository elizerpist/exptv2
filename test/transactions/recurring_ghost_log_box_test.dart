import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/widgets/ghost_logbox_visuals.dart';
import 'package:exptv2/features/transactions/widgets/recurring_ghost_log_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('default ghost logbox renders expected ghost visuals', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RecurringGhostLogBox(
            ghost: ghostFixture(),
            category: categoryFixture(),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('recurring-ghost-dashed-border-1')),
      findsOneWidget,
    );
    expect(find.byType(GhostBadge), findsOneWidget);
    expect(find.text('Várható · ismétlődő'), findsOneWidget);
    expect(find.text('Ghost'), findsNothing);
  });

  testWidgets('normal border and hidden labels omit ghost visuals', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RecurringGhostLogBox(
            ghost: ghostFixture(),
            category: categoryFixture(),
            settings: const GhostLogboxSettings(
              borderStyle: GhostLogboxBorderStyle.normal,
              backgroundOpacityEnabled: true,
              avatarOpacityEnabled: false,
              textOpacityEnabled: false,
              avatarBadgeEnabled: false,
              textTone: GhostLogboxTextTone.normal,
              expectedLabelEnabled: false,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('recurring-ghost-dashed-border-1')),
      findsNothing,
    );
    expect(find.byType(GhostBadge), findsNothing);
    expect(find.text('Várható · ismétlődő'), findsNothing);
  });
}

RecurringGhostRecord ghostFixture({
  int year = 2026,
  int month = 5,
  int day = 15,
  int id = 1,
  int recurringId = 9,
  String name = 'Rent',
  double amount = 500,
  String transactionType = 'expense',
  String categoryName = 'Q',
  String categoryColor = '#dc2626',
  int categoryIconSlot = 2,
  bool activated = false,
}) {
  final periodKey =
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
  final date =
      '${year.toString().padLeft(4, '0')}.${month.toString().padLeft(2, '0')}.${day.toString().padLeft(2, '0')}';
  return RecurringGhostRecord.fromMap({
    'id': id,
    'recurringTransactionId': recurringId,
    'periodKey': periodKey,
    'name': name,
    'amount': amount,
    'transactionType': transactionType,
    'date': date,
    'time': '00:00',
    'categoryId': 6,
    'categoryName': categoryName,
    'categoryColor': categoryColor,
    'categoryIconSlot': categoryIconSlot,
    'triggerMillis': 1778803200000,
    'isActivated': activated,
    'activatedTransactionId': activated ? 120 : null,
    'createdAt': 1778360000000,
    'updatedAt': 1778360000000,
  });
}

TransactionCategory categoryFixture() => TransactionCategory.fromMap({
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
