import '../../dashboard/query/domain/ledger_direction.dart';
import '../../manual_transactions/domain/manual_transaction_models.dart';
import 'automation_models.dart';

abstract interface class AutomationRepository {
  Future<AutomationDashboardSnapshot> dashboard();

  /// A bounded, read-only summary for the daily Automation home. Unlike the
  /// legacy dashboard, it never scans a large inbox merely to calculate a
  /// 30-day statistic.
  Future<AutomationDashboardSnapshot> homeDashboard();
  Future<List<PushProfile>> listProfiles();
  Future<PushProfile> profile(String profileId);
  Future<List<PushRule>> rules(String profileId);
  Future<List<NotificationInboxItem>> inbox({
    String? profileId,
    PushReviewStatus? reviewStatus,
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

  /// Bounded active, non-archived pending occurrences for the Automation
  /// overview. This deliberately does not depend on Ledger ghost visibility.
  Future<List<RecurrenceOccurrence>> upcomingRecurrenceOccurrences({
    required int fromUtcMs,
    required int toUtcMs,
    int limit = 3,
  });
  Future<List<RecurrenceRule>> recurringRules();
  Future<RecurrenceRule> recurringRule(String ruleId);
  Future<List<RecurrenceOccurrence>> recurrenceOccurrences({
    RecurrenceOccurrenceStatus? status,
    String? ruleId,
    int? fromUtcMs,
    int? toUtcMs,
    int limit = 100,
    int offset = 0,
  });
  Future<RecurrenceOccurrence> recurrenceOccurrence(String occurrenceId);
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

  /// Same Core transaction as creation, but accepts the manual editor's
  /// existing/new-partner draft without requiring a premature partner write.
  Future<RecurrenceRule> createRecurringRuleWithPartner({
    required String name,
    required ManualPartnerSelection partner,
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
  Future<RecurrenceRule> updateRecurringRule({
    required String ruleId,
    required int expectedRuleVersion,
    required String name,
    required String partnerId,
    required ManualCategorySelection categorySelection,
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
  Future<List<RecurrencePreview>> previewRecurringOccurrences({
    required int dayOfMonth,
    required int localTimeMinutes,
    required int startLocalEpochDay,
    int? endLocalEpochDay,
    required String timezoneId,
    int count = 3,
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
