import '../../dashboard/query/domain/ledger_direction.dart';
import '../domain/automation_models.dart';
import '../domain/automation_repository.dart';

final class UnavailableAutomationRepository implements AutomationRepository {
  const UnavailableAutomationRepository();
  Never _unavailable() =>
      throw UnsupportedError('Az automatizáció csak Androidon érhető el.');
  @override
  Future<AutomationDashboardSnapshot> dashboard() async => _unavailable();
  @override
  Future<List<PushProfile>> listProfiles() async => _unavailable();
  @override
  Future<PushProfile> profile(String profileId) async => _unavailable();
  @override
  Future<List<PushRule>> rules(String profileId) async => _unavailable();
  @override
  Future<List<NotificationInboxItem>> inbox({
    String? profileId,
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
