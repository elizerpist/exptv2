import '../../dashboard/query/domain/ledger_direction.dart';
import '../../manual_transactions/domain/manual_transaction_models.dart';
import '../domain/automation_models.dart';
import '../domain/automation_repository.dart';

final class UnavailableAutomationRepository implements AutomationRepository {
  const UnavailableAutomationRepository();
  Never _unavailable() =>
      throw UnsupportedError('Az automatizáció csak Androidon érhető el.');
  @override
  Future<AutomationDashboardSnapshot> dashboard() async => _unavailable();
  @override
  Future<AutomationDashboardSnapshot> homeDashboard() async => _unavailable();
  @override
  Future<List<PushProfile>> listProfiles() async => _unavailable();
  @override
  Future<PushProfile> profile(String profileId) async => _unavailable();
  @override
  Future<List<PushRule>> rules(String profileId) async => _unavailable();
  @override
  Future<List<NotificationInboxItem>> inbox({
    String? profileId,
    PushReviewStatus? reviewStatus,
    int limit = 50,
    int offset = 0,
  }) async => _unavailable();
  @override
  Future<PushProfile> createProfile({
    required String packageName,
    required String appLabel,
    required String displayName,
    required PushTransactionDirection defaultDirection,
    required bool monitoringRequested,
    required bool notificationAccessGranted,
  }) async => _unavailable();
  @override
  Future<PushProfile> updateProfile({
    required String profileId,
    required String displayName,
    required PushTransactionDirection defaultDirection,
    required PushProfileState state,
  }) async => _unavailable();
  @override
  Future<void> deleteProfile(String profileId) async => _unavailable();
  @override
  Future<void> addTrainingSample({
    required String profileId,
    required String notificationId,
    required PushSampleKind kind,
    required String spansJson,
  }) async => _unavailable();
  @override
  Future<PushRule> createRule({
    required String profileId,
    required String notificationId,
    required String name,
    required LedgerDirection direction,
    required List<PushFieldSpan> spans,
  }) async => _unavailable();
  @override
  Future<PushRuleTestReport> backtest(String ruleId) async => _unavailable();
  @override
  Future<PushRule> activateRule(String ruleId) async => _unavailable();
  @override
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
  }) async => _unavailable();
  @override
  Future<void> ignoreReview(String notificationId) async => _unavailable();
  @override
  Future<RecurrenceDashboardSnapshot> recurrenceDashboard() async =>
      _unavailable();
  @override
  Future<List<RecurrenceOccurrence>> upcomingRecurrenceOccurrences({
    required int fromUtcMs,
    required int toUtcMs,
    int limit = 3,
  }) async => _unavailable();
  @override
  Future<List<RecurrenceRule>> recurringRules() async => _unavailable();
  @override
  Future<RecurrenceRule> recurringRule(String ruleId) async => _unavailable();
  @override
  Future<List<RecurrenceOccurrence>> recurrenceOccurrences({
    RecurrenceOccurrenceStatus? status,
    String? ruleId,
    int? fromUtcMs,
    int? toUtcMs,
    int limit = 100,
    int offset = 0,
  }) async => _unavailable();
  @override
  Future<RecurrenceOccurrence> recurrenceOccurrence(
    String occurrenceId,
  ) async => _unavailable();
  @override
  Future<String?> realizedRecurrenceLedgerEntryId(String occurrenceId) async =>
      _unavailable();
  @override
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
  }) async => _unavailable();
  @override
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
  }) async => _unavailable();
  @override
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
  }) async => _unavailable();
  @override
  Future<List<RecurrencePreview>> previewRecurringOccurrences({
    required int dayOfMonth,
    required int localTimeMinutes,
    required int startLocalEpochDay,
    int? endLocalEpochDay,
    required String timezoneId,
    int count = 3,
  }) async => _unavailable();
  @override
  Future<void> setRecurringRuleActive(String ruleId, bool isActive) async =>
      _unavailable();
  @override
  Future<void> archiveRecurringRule(String ruleId) async => _unavailable();
  @override
  Future<void> setShowPendingGhosts(bool show) async => _unavailable();
  @override
  Future<void> skipRecurrenceOccurrence(String occurrenceId) async =>
      _unavailable();
  @override
  Future<RecurrenceOccurrence> updateRecurrenceOccurrence({
    required String occurrenceId,
    int? expectedAmountScaled100,
    int? expectedLocalEpochDay,
    int? expectedLocalTimeMinutes,
    String? partnerId,
    ManualCategorySelection? categorySelection,
    bool noteChanged = false,
    String? note,
  }) async => _unavailable();
}

final class UnavailableAutomationPermissionRepository
    implements AutomationPermissionRepository {
  const UnavailableAutomationPermissionRepository();
  @override
  Future<AutomationPermissionStatus> getPermissionStatus() async =>
      const AutomationPermissionStatus(
        notificationListenerGranted: false,
        postNotificationsGranted: false,
        notificationListenerAvailable: false,
        appNotificationSettingsAvailable: false,
      );
  @override
  Future<bool> openNotificationAccessSettings() async => false;
  @override
  Future<bool> openAppNotificationSettings() async => false;
  @override
  Future<bool> openAppInfoSettings() async => false;
  @override
  Future<bool> requestPostNotifications() async => false;
  @override
  Future<bool> sendTestNotification() async => false;
  @override
  Future<List<InstalledApplication>> listInstalledApps() async => const [];
}
