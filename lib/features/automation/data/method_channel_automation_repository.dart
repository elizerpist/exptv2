import 'package:flutter/services.dart';

import '../../dashboard/query/domain/ledger_direction.dart';
import '../../manual_transactions/domain/manual_transaction_models.dart';
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
  Future<AutomationDashboardSnapshot> homeDashboard() async =>
      AutomationDashboardSnapshot.fromMap(
        _map(
          await _channel.invokeMethod<Object?>('getAutomationHomeDashboard'),
        ),
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
    PushReviewStatus? reviewStatus,
    int limit = 50,
    int offset = 0,
  }) async => _maps(
    await _channel.invokeMethod<List<Object?>>('listInbox', {
      'profileId': profileId,
      'reviewStatus': reviewStatus?.name,
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
  Future<PushRule> updateRule({
    required String ruleId,
    required int expectedVersion,
    required String notificationId,
    required String name,
    required LedgerDirection direction,
    required List<PushFieldSpan> spans,
  }) async => PushRule.fromMap(
    _map(
      await _channel.invokeMethod<Object?>('updateRule', {
        'ruleId': ruleId,
        'expectedVersion': expectedVersion,
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
  @override
  Future<RecurrenceDashboardSnapshot> recurrenceDashboard() async =>
      RecurrenceDashboardSnapshot.fromMap(
        _map(await _channel.invokeMethod<Object?>('getRecurrenceDashboard')),
      );
  @override
  Future<List<RecurrenceOccurrence>> upcomingRecurrenceOccurrences({
    required int fromUtcMs,
    required int toUtcMs,
    int limit = 3,
  }) async => _maps(
    await _channel.invokeMethod<List<Object?>>(
      'listUpcomingRecurrenceOccurrences',
      {'fromUtcMs': fromUtcMs, 'toUtcMs': toUtcMs, 'limit': limit},
    ),
  ).map(RecurrenceOccurrence.fromMap).toList(growable: false);
  @override
  Future<List<RecurrenceRule>> recurringRules() async => _maps(
    await _channel.invokeMethod<List<Object?>>('listRecurringRules'),
  ).map(RecurrenceRule.fromMap).toList(growable: false);
  @override
  Future<RecurrenceRule> recurringRule(String ruleId) async =>
      RecurrenceRule.fromMap(
        _map(
          await _channel.invokeMethod<Object?>('getRecurringRule', {
            'ruleId': ruleId,
          }),
        ),
      );
  @override
  Future<List<RecurrenceOccurrence>> recurrenceOccurrences({
    RecurrenceOccurrenceStatus? status,
    String? ruleId,
    int? fromUtcMs,
    int? toUtcMs,
    int limit = 100,
    int offset = 0,
  }) async => _maps(
    await _channel.invokeMethod<List<Object?>>('listRecurrenceOccurrences', {
      'status': status?.name,
      'ruleId': ruleId,
      'fromUtcMs': fromUtcMs,
      'toUtcMs': toUtcMs,
      'limit': limit,
      'offset': offset,
    }),
  ).map(RecurrenceOccurrence.fromMap).toList(growable: false);
  @override
  Future<RecurrenceOccurrence> recurrenceOccurrence(
    String occurrenceId,
  ) async => RecurrenceOccurrence.fromMap(
    _map(
      await _channel.invokeMethod<Object?>('getRecurrenceOccurrence', {
        'occurrenceId': occurrenceId,
      }),
    ),
  );
  @override
  Future<String?> realizedRecurrenceLedgerEntryId(String occurrenceId) async =>
      _map(
            await _channel.invokeMethod<Object?>(
              'getRealizedRecurrenceLedgerEntryId',
              {'occurrenceId': occurrenceId},
            ),
          )['ledgerEntryId']
          as String?;
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
  }) async => RecurrenceRule.fromMap(
    _map(
      await _channel.invokeMethod<Object?>('createRecurringRule', {
        'name': name,
        'partnerId': partnerId,
        'categorySelection': categorySelection.toMap(),
        'direction': direction.name,
        'note': note,
        'triggerKind': triggerKind.name,
        'amountPolicy': amountPolicy.name,
        'amountScaled100': amountScaled100,
        'dayOfMonth': dayOfMonth,
        'localTimeMinutes': localTimeMinutes,
        'startLocalEpochDay': startLocalEpochDay,
        'endLocalEpochDay': endLocalEpochDay,
        'timezoneId': timezoneId,
        'pushProfileId': pushProfileId,
        'pushRuleId': pushRuleId,
        'amountToleranceScaled100': amountToleranceScaled100,
        'dayWindow': dayWindow,
      }),
    ),
  );
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
  }) async => RecurrenceRule.fromMap(
    _map(
      await _channel.invokeMethod<Object?>('createRecurringRule', {
        'name': name,
        'partner': partner.toMap(),
        'categorySelection': categorySelection.toMap(),
        'direction': direction.name,
        'note': note,
        'triggerKind': triggerKind.name,
        'amountPolicy': amountPolicy.name,
        'amountScaled100': amountScaled100,
        'dayOfMonth': dayOfMonth,
        'localTimeMinutes': localTimeMinutes,
        'startLocalEpochDay': startLocalEpochDay,
        'endLocalEpochDay': endLocalEpochDay,
        'timezoneId': timezoneId,
        'pushProfileId': pushProfileId,
        'pushRuleId': pushRuleId,
        'amountToleranceScaled100': amountToleranceScaled100,
        'dayWindow': dayWindow,
      }),
    ),
  );
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
  }) async => RecurrenceRule.fromMap(
    _map(
      await _channel.invokeMethod<Object?>('updateRecurringRule', {
        'ruleId': ruleId,
        'expectedRuleVersion': expectedRuleVersion,
        'name': name,
        'partnerId': partnerId,
        'categorySelection': categorySelection.toMap(),
        'note': note,
        'triggerKind': triggerKind.name,
        'amountPolicy': amountPolicy.name,
        'amountScaled100': amountScaled100,
        'dayOfMonth': dayOfMonth,
        'localTimeMinutes': localTimeMinutes,
        'startLocalEpochDay': startLocalEpochDay,
        'endLocalEpochDay': endLocalEpochDay,
        'timezoneId': timezoneId,
        'pushProfileId': pushProfileId,
        'pushRuleId': pushRuleId,
        'amountToleranceScaled100': amountToleranceScaled100,
        'dayWindow': dayWindow,
      }),
    ),
  );
  @override
  Future<List<RecurrencePreview>> previewRecurringOccurrences({
    required int dayOfMonth,
    required int localTimeMinutes,
    required int startLocalEpochDay,
    int? endLocalEpochDay,
    required String timezoneId,
    int count = 3,
  }) async => _maps(
    await _channel.invokeMethod<List<Object?>>('previewRecurringOccurrences', {
      'dayOfMonth': dayOfMonth,
      'localTimeMinutes': localTimeMinutes,
      'startLocalEpochDay': startLocalEpochDay,
      'endLocalEpochDay': endLocalEpochDay,
      'timezoneId': timezoneId,
      'count': count,
    }),
  ).map(RecurrencePreview.fromMap).toList(growable: false);
  @override
  Future<void> setRecurringRuleActive(String ruleId, bool isActive) =>
      _channel.invokeMethod<void>('setRecurringRuleActive', {
        'ruleId': ruleId,
        'isActive': isActive,
      });
  @override
  Future<void> archiveRecurringRule(String ruleId) =>
      _channel.invokeMethod<void>('archiveRecurringRule', {'ruleId': ruleId});
  @override
  Future<void> setShowPendingGhosts(bool show) =>
      _channel.invokeMethod<void>('setShowPendingGhosts', {'show': show});
  @override
  Future<void> skipRecurrenceOccurrence(String occurrenceId) =>
      _channel.invokeMethod<void>('skipRecurrenceOccurrence', {
        'occurrenceId': occurrenceId,
      });
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
  }) async => RecurrenceOccurrence.fromMap(
    _map(
      await _channel.invokeMethod<Object?>('updateRecurrenceOccurrence', {
        'occurrenceId': occurrenceId,
        'expectedAmountScaled100': expectedAmountScaled100,
        'expectedLocalEpochDay': expectedLocalEpochDay,
        'expectedLocalTimeMinutes': expectedLocalTimeMinutes,
        'partnerId': partnerId,
        'categorySelection': categorySelection?.toMap(),
        'noteChanged': noteChanged,
        'note': note,
      }),
    ),
  );
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
  Future<bool> openTestNotificationChannelSettings() async =>
      await _channel.invokeMethod<bool>(
        'openTestNotificationChannelSettings',
      ) ??
      false;
  @override
  Future<bool> openAppInfoSettings() async =>
      await _channel.invokeMethod<bool>('openAppInfoSettings') ?? false;
  @override
  Future<bool> requestPostNotifications() async =>
      await _channel.invokeMethod<bool>('requestPostNotifications') ?? false;
  @override
  Future<PushTestNotificationDispatch> sendTestNotification() async =>
      PushTestNotificationDispatch.fromMap(
        _map(await _channel.invokeMethod<Object?>('sendTestNotification')),
      );
  @override
  Future<List<InstalledApplication>> listInstalledApps() async => _maps(
    await _channel.invokeMethod<List<Object?>>('listInstalledApps'),
  ).map(InstalledApplication.fromMap).toList(growable: false);
  @override
  Future<String?> installedApplicationIcon(String packageName) =>
      _channel.invokeMethod<String>('getInstalledAppIcon', {
        'packageName': packageName,
      });
  @override
  Future<PushDiagnosticsSnapshot> pushDiagnostics() async =>
      PushDiagnosticsSnapshot.fromMap(
        _map(await _channel.invokeMethod<Object?>('getPushDiagnostics')),
      );
  @override
  Future<void> clearPushDiagnostics() =>
      _channel.invokeMethod<void>('clearPushDiagnostics');
}

Map<Object?, Object?> _map(Object? value) => value is Map<Object?, Object?>
    ? value
    : Map<Object?, Object?>.from(value as Map);
List<Map<Object?, Object?>> _maps(List<Object?>? items) =>
    (items ?? const []).map(_map).toList(growable: false);
