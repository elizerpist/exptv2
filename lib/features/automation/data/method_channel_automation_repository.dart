import 'package:flutter/services.dart';

import '../../dashboard/query/domain/ledger_direction.dart';
import '../domain/automation_models.dart';
import '../domain/automation_repository.dart';

final class MethodChannelAutomationRepository implements AutomationRepository {
  MethodChannelAutomationRepository({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.fluvi/automation');
  final MethodChannel _channel;
  @override
  Future<AutomationDashboardSnapshot> dashboard() async =>
      AutomationDashboardSnapshot.fromMap(
        _map(await _channel.invokeMethod<Object?>('getDashboard')),
      );
  @override
  Future<List<PushProfile>> listProfiles() async => _maps(
    await _channel.invokeMethod<List<Object?>>('listProfiles'),
  ).map(PushProfile.fromMap).toList(growable: false);
  @override
  Future<PushProfile> profile(String id) async => PushProfile.fromMap(
    _map(await _channel.invokeMethod<Object?>('getProfile', {'profileId': id})),
  );
  @override
  Future<List<PushRule>> rules(String id) async => _maps(
    await _channel.invokeMethod<List<Object?>>('listRules', {'profileId': id}),
  ).map(PushRule.fromMap).toList(growable: false);
  @override
  Future<List<NotificationInboxItem>> inbox({
    String? profileId,
    int limit = 50,
    int offset = 0,
  }) async => _maps(
    await _channel.invokeMethod<List<Object?>>('listInbox', {
      'profileId': profileId,
      'limit': limit,
      'offset': offset,
    }),
  ).map(NotificationInboxItem.fromMap).toList(growable: false);
  @override
  Future<PushProfile> createProfile({
    required String packageName,
    required String appLabel,
    required String displayName,
    required PushTransactionDirection defaultDirection,
    required bool monitoringRequested,
    required bool notificationAccessGranted,
  }) async => PushProfile.fromMap(
    _map(
      await _channel.invokeMethod<Object?>('createProfile', {
        'packageName': packageName,
        'appLabel': appLabel,
        'displayName': displayName,
        'defaultDirection': defaultDirection.name,
        'monitoringRequested': monitoringRequested,
        'notificationAccessGranted': notificationAccessGranted,
      }),
    ),
  );
  @override
  Future<PushProfile> updateProfile({
    required String profileId,
    required String displayName,
    required PushTransactionDirection defaultDirection,
    required PushProfileState state,
  }) async => PushProfile.fromMap(
    _map(
      await _channel.invokeMethod<Object?>('updateProfile', {
        'profileId': profileId,
        'displayName': displayName,
        'defaultDirection': defaultDirection.name,
        'state': state.name,
      }),
    ),
  );
  @override
  Future<void> deleteProfile(String id) =>
      _channel.invokeMethod<void>('deleteProfile', {'profileId': id});
  @override
  Future<void> addTrainingSample({
    required String profileId,
    required String notificationId,
    required PushSampleKind kind,
    required String spansJson,
  }) => _channel.invokeMethod<void>('addTrainingSample', {
    'profileId': profileId,
    'notificationId': notificationId,
    'sampleKind': kind.name,
    'spansJson': spansJson,
  });
  @override
  Future<PushRule> createRule({
    required String profileId,
    required String notificationId,
    required String name,
    required LedgerDirection direction,
    required List<PushFieldSpan> spans,
  }) async => PushRule.fromMap(
    _map(
      await _channel.invokeMethod<Object?>('createRule', {
        'profileId': profileId,
        'notificationId': notificationId,
        'name': name,
        'direction': direction.name,
        'spans': spans.map((span) => span.toMap()).toList(),
      }),
    ),
  );
  @override
  Future<PushRuleTestReport> backtest(String id) async =>
      PushRuleTestReport.fromMap(
        _map(
          await _channel.invokeMethod<Object?>('backtestRule', {'ruleId': id}),
        ),
      );
  @override
  Future<PushRule> activateRule(String id) async => PushRule.fromMap(
    _map(await _channel.invokeMethod<Object?>('activateRule', {'ruleId': id})),
  );
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
  }) async =>
      (_map(
            await _channel.invokeMethod<Object?>('approveReview', {
              'notificationId': notificationId,
              'merchantName': merchantName,
              'direction': direction.name,
              'amountScaled100': amountScaled100,
              'bookedLocalEpochDay': bookedLocalEpochDay,
              'bookedLocalTimeMinutes': bookedLocalTimeMinutes,
              'occurredAtUtcMs': occurredAtUtcMs,
              'note': note,
              'trainingCorrectionJson': trainingCorrectionJson,
            }),
          )['ledgerEntryId']!
          as String);
  @override
  Future<void> ignoreReview(String id) =>
      _channel.invokeMethod<void>('ignoreReview', {'notificationId': id});
}

final class MethodChannelAutomationPermissionRepository
    implements AutomationPermissionRepository {
  MethodChannelAutomationPermissionRepository({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('com.fluvi/automation_permissions');
  final MethodChannel _channel;
  @override
  Future<AutomationPermissionStatus> getPermissionStatus() async =>
      AutomationPermissionStatus.fromMap(
        _map(await _channel.invokeMethod<Object?>('getPermissionStatus')),
      );
  @override
  Future<bool> openNotificationAccessSettings() async =>
      await _channel.invokeMethod<bool>('openNotificationAccessSettings') ??
      false;
  @override
  Future<bool> openAppNotificationSettings() async =>
      await _channel.invokeMethod<bool>('openAppNotificationSettings') ?? false;
  @override
  Future<bool> openAppInfoSettings() async =>
      await _channel.invokeMethod<bool>('openAppInfoSettings') ?? false;
  @override
  Future<bool> requestPostNotifications() async =>
      await _channel.invokeMethod<bool>('requestPostNotifications') ?? false;
  @override
  Future<bool> sendTestNotification() async =>
      await _channel.invokeMethod<bool>('sendTestNotification') ?? false;
  @override
  Future<List<InstalledApplication>> listInstalledApps() async => _maps(
    await _channel.invokeMethod<List<Object?>>('listInstalledApps'),
  ).map(InstalledApplication.fromMap).toList(growable: false);
}

Map<Object?, Object?> _map(Object? value) => value is Map<Object?, Object?>
    ? value
    : Map<Object?, Object?>.from(value as Map);
List<Map<Object?, Object?>> _maps(List<Object?>? items) =>
    (items ?? const []).map(_map).toList(growable: false);
