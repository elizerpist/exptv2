import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/automation/domain/automation_models.dart';
import 'package:fluvi/features/manual_transactions/domain/manual_transaction_models.dart';

void main() {
  test(
    'occurrence bridge keeps category assignment and pending ghost identity',
    () {
      final occurrence = RecurrenceOccurrence.fromMap({
        'occurrenceId': 'occurrence-1',
        'ruleId': 'rule-1',
        'occurrenceKey': '2026-11',
        'expectedLocalEpochDay': 20761,
        'expectedLocalTimeMinutes': 480,
        'expectedAtUtcMs': 1794495600000,
        'partnerId': 'partner-1',
        'categoryId': 'category-1',
        'categoryAssignmentMode': 'entryOverride',
        'direction': 'expense',
        'expectedAmountScaled100': 449000,
        'note': 'Előfizetés',
        'triggerKind': 'push',
        'status': 'pending',
        'realizationKind': null,
      });

      expect(occurrence.occurrenceId, 'occurrence-1');
      expect(
        occurrence.categoryAssignmentMode,
        ManualCategoryAssignmentMode.entryOverride,
      );
      expect(occurrence.status, RecurrenceOccurrenceStatus.pending);
    },
  );
}
