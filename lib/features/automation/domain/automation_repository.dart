import '../../dashboard/query/domain/ledger_direction.dart';
import '../../manual_transactions/domain/manual_transaction_models.dart';
import 'automation_models.dart';

abstract interface class AutomationRepository {
  Future<AutomationDashboardSnapshot> dashboard();
  Future<List<PushProfile>> listProfiles();
  Future<PushProfile> profile(String profileId);
  Future<List<PushRule>> rules(String profileId);
  Future<List<NotificationInboxItem>> inbox({
    String? profileId,
    int limit = 50,
    int offset = 0,
  });
  Future<PushProfile> createProfile({
    required String packageName,
    required String appLabel,
    required String displayName,
    required PushTransactionDirection defaultDirection,
    required bool monitoringRequested,
    required bool notificationAccessGranted,
  });
  Future<PushProfile> updateProfile({
    required String profileId,
    required String displayName,
    required PushTransactionDirection defaultDirection,
    required PushProfileState state,
  });
  Future<void> deleteProfile(String profileId);
  Future<void> addTrainingSample({
    required String profileId,
    required String notificationId,
    required PushSampleKind kind,
    required String spansJson,
  });
  Future<PushRule> createRule({
    required String profileId,
    required String notificationId,
    required String name,
    required LedgerDirection direction,
    required List<PushFieldSpan> spans,
  });
  Future<PushRuleTestReport> backtest(String ruleId);
  Future<PushRule> activateRule(String ruleId);
  Future<String> approveReview({
    required String notificationId,
    required String merchantName,
    required LedgerDirection direction,
    required int amountScaled100,
    required int bookedLocalEpochDay,
    required int bookedLocalTimeMinutes,
    required int occurredAtUtcMs,
    String? note,
    String? trainingCorrectionJson,
  });
  Future<void> ignoreReview(String notificationId);
  Future<RecurrenceDashboardSnapshot> recurrenceDashboard();
  Future<List<RecurrenceRule>> recurringRules();
  Future<List<RecurrenceOccurrence>> recurrenceOccurrences({
    RecurrenceOccurrenceStatus? status,
    int limit = 100,
    int offset = 0,
  });
  Future<String?> realizedRecurrenceLedgerEntryId(String occurrenceId);
  Future<RecurrenceRule> createRecurringRule({
    required String name,
    required String partnerId,
    required ManualCategorySelection categorySelection,
    required LedgerDirection direction,
    String? note,
    required RecurrenceTriggerKind triggerKind,
    required RecurrenceAmountPolicy amountPolicy,
    int? amountScaled100,
    required int dayOfMonth,
    required int localTimeMinutes,
    required int startLocalEpochDay,
    int? endLocalEpochDay,
    required String timezoneId,
    String? pushProfileId,
    String? pushRuleId,
    int amountToleranceScaled100 = 0,
    int dayWindow = 2,
  });
  Future<void> setRecurringRuleActive(String ruleId, bool isActive);
  Future<void> archiveRecurringRule(String ruleId);
  Future<void> setShowPendingGhosts(bool show);
  Future<void> skipRecurrenceOccurrence(String occurrenceId);
  Future<RecurrenceOccurrence> updateRecurrenceOccurrence({
    required String occurrenceId,
    int? expectedAmountScaled100,
    int? expectedLocalEpochDay,
    int? expectedLocalTimeMinutes,
    String? partnerId,
    ManualCategorySelection? categorySelection,
    bool noteChanged = false,
    String? note,
  });
}

abstract interface class AutomationPermissionRepository {
  Future<AutomationPermissionStatus> getPermissionStatus();
  Future<bool> openNotificationAccessSettings();
  Future<bool> openAppNotificationSettings();
  Future<bool> openAppInfoSettings();
  Future<bool> requestPostNotifications();
  Future<bool> sendTestNotification();
  Future<List<InstalledApplication>> listInstalledApps();
}
