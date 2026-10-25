import '../../dashboard/query/domain/ledger_direction.dart';
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
