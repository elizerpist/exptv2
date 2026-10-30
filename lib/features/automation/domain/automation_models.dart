import '../../dashboard/query/domain/ledger_direction.dart';
import '../../manual_transactions/domain/manual_transaction_models.dart';

enum PushProfileState {
  waitingForPermission,
  waitingForTraining,
  testing,
  active,
  reviewRequired,
  paused,
}

enum PushTransactionDirection { automatic, expenseOnly, incomeOnly }

enum PushRuleState { draft, testing, active, paused, failed }

enum PushSampleKind { transaction, nonTransaction, failedTransaction, ignored }

enum PushFieldRole { amount, merchant, balance, account, currency, ignore }

enum PushReviewStatus { none, pending, approved, ignored, rejected }

final class InstalledApplication {
  const InstalledApplication({
    required this.packageName,
    required this.label,
    this.iconPngBase64,
  });

  factory InstalledApplication.fromMap(Map<Object?, Object?> map) =>
      InstalledApplication(
        packageName: map['packageName']! as String,
        label: map['label']! as String,
        iconPngBase64: map['iconPngBase64'] as String?,
      );

  final String packageName;
  final String label;
  final String? iconPngBase64;
}

final class AutomationPermissionStatus {
  const AutomationPermissionStatus({
    required this.notificationListenerGranted,
    required this.postNotificationsGranted,
    required this.notificationListenerAvailable,
    required this.appNotificationSettingsAvailable,
  });

  factory AutomationPermissionStatus.fromMap(Map<Object?, Object?> map) =>
      AutomationPermissionStatus(
        notificationListenerGranted:
            map['notificationListenerGranted'] as bool? ?? false,
        postNotificationsGranted:
            map['postNotificationsGranted'] as bool? ?? false,
        notificationListenerAvailable:
            map['notificationListenerAvailable'] as bool? ?? false,
        appNotificationSettingsAvailable:
            map['appNotificationSettingsAvailable'] as bool? ?? false,
      );

  final bool notificationListenerGranted;
  final bool postNotificationsGranted;
  final bool notificationListenerAvailable;
  final bool appNotificationSettingsAvailable;
}

final class PushProfile {
  const PushProfile({
    required this.profileId,
    required this.packageName,
    required this.appLabel,
    required this.displayName,
    required this.defaultDirection,
    required this.state,
    required this.ruleCount,
    required this.inboxCount,
    required this.revision,
  });

  factory PushProfile.fromMap(Map<Object?, Object?> map) => PushProfile(
    profileId: map['profileId']! as String,
    packageName: map['packageName']! as String,
    appLabel: map['appLabel']! as String,
    displayName: map['displayName']! as String,
    defaultDirection: PushTransactionDirection.values.byName(
      map['defaultDirection']! as String,
    ),
    state: PushProfileState.values.byName(map['state']! as String),
    ruleCount: (map['ruleCount'] as num?)?.toInt() ?? 0,
    inboxCount: (map['inboxCount'] as num?)?.toInt() ?? 0,
    revision: (map['revision'] as num?)?.toInt() ?? 0,
  );

  final String profileId;
  final String packageName;
  final String appLabel;
  final String displayName;
  final PushTransactionDirection defaultDirection;
  final PushProfileState state;
  final int ruleCount;
  final int inboxCount;
  final int revision;
}

final class PushRule {
  const PushRule({
    required this.ruleId,
    required this.profileId,
    required this.name,
    required this.direction,
    required this.state,
    required this.version,
    required this.priority,
    required this.autoAcceptThreshold,
  });

  factory PushRule.fromMap(Map<Object?, Object?> map) => PushRule(
    ruleId: map['ruleId']! as String,
    profileId: map['profileId']! as String,
    name: map['name']! as String,
    direction: LedgerDirection.values.byName(map['direction']! as String),
    state: PushRuleState.values.byName(map['state']! as String),
    version: (map['version'] as num?)?.toInt() ?? 1,
    priority: (map['priority'] as num?)?.toInt() ?? 100,
    autoAcceptThreshold: (map['autoAcceptThreshold'] as num?)?.toDouble() ?? .9,
  );

  final String ruleId;
  final String profileId;
  final String name;
  final LedgerDirection direction;
  final PushRuleState state;
  final int version;
  final int priority;
  final double autoAcceptThreshold;
}

final class NotificationInboxItem {
  const NotificationInboxItem({
    required this.notificationId,
    required this.profileId,
    required this.sourcePackageName,
    required this.sourceAppLabel,
    required this.title,
    required this.rawText,
    required this.receivedAtUtcMs,
    required this.parseStatus,
    required this.processingStatus,
    required this.trainingStatus,
    required this.reviewStatus,
    required this.confidence,
    required this.suggestedPayloadJson,
    required this.diagnosticsJson,
    required this.ledgerEntryId,
  });

  factory NotificationInboxItem.fromMap(Map<Object?, Object?> map) =>
      NotificationInboxItem(
        notificationId: map['notificationId']! as String,
        profileId: map['profileId'] as String?,
        sourcePackageName: map['sourcePackageName'] as String?,
        sourceAppLabel: map['sourceAppLabel'] as String?,
        title: map['title'] as String?,
        rawText: map['rawText']! as String,
        receivedAtUtcMs: (map['receivedAtUtcMs'] as num).toInt(),
        parseStatus: map['parseStatus']! as String,
        processingStatus: map['processingStatus']! as String,
        trainingStatus: map['trainingStatus']! as String,
        reviewStatus: PushReviewStatus.values.byName(
          map['reviewStatus']! as String,
        ),
        confidence: (map['confidence'] as num?)?.toDouble(),
        suggestedPayloadJson: map['suggestedPayloadJson'] as String?,
        diagnosticsJson: map['diagnosticsJson'] as String?,
        ledgerEntryId: map['ledgerEntryId'] as String?,
      );

  final String notificationId;
  final String? profileId;
  final String? sourcePackageName;
  final String? sourceAppLabel;
  final String? title;
  final String rawText;
  final int receivedAtUtcMs;
  final String parseStatus;
  final String processingStatus;
  final String trainingStatus;
  final PushReviewStatus reviewStatus;
  final double? confidence;
  final String? suggestedPayloadJson;
  final String? diagnosticsJson;
  final String? ledgerEntryId;
}

final class AutomationDashboardSnapshot {
  const AutomationDashboardSnapshot({
    required this.profiles,
    required this.pendingReviewCount,
    required this.capturedLast30Days,
    required this.recentInbox,
  });

  factory AutomationDashboardSnapshot.fromMap(Map<Object?, Object?> map) =>
      AutomationDashboardSnapshot(
        profiles: _list(map['profiles']).map(PushProfile.fromMap).toList(),
        pendingReviewCount: (map['pendingReviewCount'] as num?)?.toInt() ?? 0,
        capturedLast30Days: (map['capturedLast30Days'] as num?)?.toInt() ?? 0,
        recentInbox: _list(
          map['recentInbox'],
        ).map(NotificationInboxItem.fromMap).toList(),
      );

  final List<PushProfile> profiles;
  final int pendingReviewCount;
  final int capturedLast30Days;
  final List<NotificationInboxItem> recentInbox;
}

final class PushFieldSpan {
  const PushFieldSpan({
    required this.start,
    required this.endExclusive,
    required this.role,
  });

  final int start;
  final int endExclusive;
  final PushFieldRole role;

  Map<String, Object> toMap() => {
    'start': start,
    'endExclusive': endExclusive,
    'role': role.name,
  };
}

final class PushRuleTestReport {
  const PushRuleTestReport({
    required this.ruleId,
    required this.matchedCount,
    required this.reviewCount,
    required this.rejectedCount,
    required this.conflictedCount,
    required this.activationReady,
  });

  factory PushRuleTestReport.fromMap(Map<Object?, Object?> map) =>
      PushRuleTestReport(
        ruleId: map['ruleId']! as String,
        matchedCount: (map['matchedCount'] as num?)?.toInt() ?? 0,
        reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
        rejectedCount: (map['rejectedCount'] as num?)?.toInt() ?? 0,
        conflictedCount: (map['conflictedCount'] as num?)?.toInt() ?? 0,
        activationReady: map['activationReady'] as bool? ?? false,
      );

  final String ruleId;
  final int matchedCount;
  final int reviewCount;
  final int rejectedCount;
  final int conflictedCount;
  final bool activationReady;
}

List<Map<Object?, Object?>> _list(Object? value) =>
    (value as List<Object?>? ?? const [])
        .map(
          (item) => item is Map<Object?, Object?>
              ? item
              : Map<Object?, Object?>.from(item as Map),
        )
        .toList(growable: false);

enum RecurrenceTriggerKind { time, push }

enum RecurrenceAmountPolicy { fixed, estimated, unknown }

enum RecurrenceOccurrenceStatus {
  pending,
  review,
  realized,
  skipped,
  cancelled,
  voided,
}

final class RecurrenceRule {
  const RecurrenceRule({
    required this.ruleId,
    required this.name,
    required this.partnerId,
    required this.categoryId,
    required this.categoryAssignmentMode,
    required this.direction,
    required this.note,
    required this.triggerKind,
    required this.amountPolicy,
    required this.amountScaled100,
    required this.dayOfMonth,
    required this.localTimeMinutes,
    required this.startLocalEpochDay,
    required this.endLocalEpochDay,
    required this.timezoneId,
    required this.isActive,
    required this.ruleVersion,
    this.pushProfileId,
    this.pushRuleId,
    this.amountToleranceScaled100 = 0,
    this.dayWindow = 0,
  });
  factory RecurrenceRule.fromMap(Map<Object?, Object?> value) => RecurrenceRule(
    ruleId: value['ruleId']! as String,
    name: value['name']! as String,
    partnerId: value['partnerId']! as String,
    categoryId: value['categoryId']! as String,
    categoryAssignmentMode: value['categoryAssignmentMode']! as String,
    direction: LedgerDirection.values.byName(value['direction']! as String),
    note: value['note'] as String?,
    triggerKind: RecurrenceTriggerKind.values.byName(
      value['triggerKind']! as String,
    ),
    amountPolicy: RecurrenceAmountPolicy.values.byName(
      value['amountPolicy']! as String,
    ),
    amountScaled100: (value['amountScaled100'] as num?)?.toInt(),
    dayOfMonth: (value['dayOfMonth'] as num).toInt(),
    localTimeMinutes: (value['localTimeMinutes'] as num).toInt(),
    startLocalEpochDay: (value['startLocalEpochDay'] as num).toInt(),
    endLocalEpochDay: (value['endLocalEpochDay'] as num?)?.toInt(),
    timezoneId: value['timezoneId']! as String,
    isActive: value['isActive'] == true,
    ruleVersion: (value['ruleVersion'] as num?)?.toInt() ?? 1,
    pushProfileId: value['pushProfileId'] as String?,
    pushRuleId: value['pushRuleId'] as String?,
    amountToleranceScaled100:
        (value['amountToleranceScaled100'] as num?)?.toInt() ?? 0,
    dayWindow: (value['dayWindow'] as num?)?.toInt() ?? 0,
  );
  final String ruleId,
      name,
      partnerId,
      categoryId,
      categoryAssignmentMode,
      timezoneId;
  final LedgerDirection direction;
  final String? note;
  final RecurrenceTriggerKind triggerKind;
  final RecurrenceAmountPolicy amountPolicy;
  final int? amountScaled100, endLocalEpochDay;
  final int dayOfMonth, localTimeMinutes, startLocalEpochDay, ruleVersion;
  final bool isActive;
  final String? pushProfileId, pushRuleId;
  final int amountToleranceScaled100, dayWindow;
}

final class RecurrenceOccurrence {
  const RecurrenceOccurrence({
    required this.occurrenceId,
    required this.ruleId,
    required this.occurrenceKey,
    required this.expectedLocalEpochDay,
    required this.expectedLocalTimeMinutes,
    required this.expectedAtUtcMs,
    required this.partnerId,
    required this.categoryId,
    required this.categoryAssignmentMode,
    required this.direction,
    required this.expectedAmountScaled100,
    required this.note,
    required this.triggerKind,
    required this.status,
    required this.realizationKind,
    this.amountPolicy = RecurrenceAmountPolicy.unknown,
    this.timezoneId = 'Europe/Budapest',
    this.resolvedAtUtcMs,
  });
  factory RecurrenceOccurrence.fromMap(Map<Object?, Object?> value) =>
      RecurrenceOccurrence(
        occurrenceId: value['occurrenceId']! as String,
        ruleId: value['ruleId']! as String,
        occurrenceKey: value['occurrenceKey']! as String,
        expectedLocalEpochDay: (value['expectedLocalEpochDay'] as num).toInt(),
        expectedLocalTimeMinutes: (value['expectedLocalTimeMinutes'] as num)
            .toInt(),
        expectedAtUtcMs: (value['expectedAtUtcMs'] as num).toInt(),
        partnerId: value['partnerId']! as String,
        categoryId: value['categoryId']! as String,
        categoryAssignmentMode: switch (value['categoryAssignmentMode']!
            as String) {
          'partnerDefault' => ManualCategoryAssignmentMode.partnerDefault,
          'entryOverride' => ManualCategoryAssignmentMode.entryOverride,
          final mode => throw FormatException(
            'Unknown recurrence category mode $mode.',
          ),
        },
        direction: LedgerDirection.values.byName(value['direction']! as String),
        expectedAmountScaled100: (value['expectedAmountScaled100'] as num?)
            ?.toInt(),
        note: value['note'] as String?,
        triggerKind: RecurrenceTriggerKind.values.byName(
          value['triggerKind']! as String,
        ),
        status: RecurrenceOccurrenceStatus.values.byName(
          value['status']! as String,
        ),
        realizationKind: value['realizationKind'] as String?,
        amountPolicy: switch (value['amountPolicy']) {
          final String policy => RecurrenceAmountPolicy.values.byName(policy),
          _ => RecurrenceAmountPolicy.unknown,
        },
        timezoneId: value['timezoneId'] as String? ?? 'Europe/Budapest',
        resolvedAtUtcMs: (value['resolvedAtUtcMs'] as num?)?.toInt(),
      );
  final String occurrenceId, ruleId, occurrenceKey, partnerId, categoryId;
  final ManualCategoryAssignmentMode categoryAssignmentMode;
  final int expectedLocalEpochDay, expectedLocalTimeMinutes, expectedAtUtcMs;
  final LedgerDirection direction;
  final int? expectedAmountScaled100;
  final String? note, realizationKind;
  final RecurrenceTriggerKind triggerKind;
  final RecurrenceOccurrenceStatus status;
  final RecurrenceAmountPolicy amountPolicy;
  final String timezoneId;
  final int? resolvedAtUtcMs;
}

/// A read-only occurrence projection returned by the Core's scheduling
/// algorithm. Previewing must never insert a rule or an occurrence.
final class RecurrencePreview {
  const RecurrencePreview({
    required this.expectedLocalEpochDay,
    required this.expectedLocalTimeMinutes,
    required this.expectedAtUtcMs,
  });

  factory RecurrencePreview.fromMap(Map<Object?, Object?> value) =>
      RecurrencePreview(
        expectedLocalEpochDay: (value['expectedLocalEpochDay'] as num).toInt(),
        expectedLocalTimeMinutes: (value['expectedLocalTimeMinutes'] as num)
            .toInt(),
        expectedAtUtcMs: (value['expectedAtUtcMs'] as num).toInt(),
      );

  final int expectedLocalEpochDay;
  final int expectedLocalTimeMinutes;
  final int expectedAtUtcMs;
}

final class RecurrenceDashboardSnapshot {
  const RecurrenceDashboardSnapshot({
    required this.rules,
    required this.pendingCount,
    required this.dueCount,
    required this.realizedCount,
    required this.showPendingGhostsInLedger,
  });
  factory RecurrenceDashboardSnapshot.fromMap(Map<Object?, Object?> value) =>
      RecurrenceDashboardSnapshot(
        rules: _list(
          value['rules'],
        ).map(RecurrenceRule.fromMap).toList(growable: false),
        pendingCount: (value['pendingCount'] as num?)?.toInt() ?? 0,
        dueCount: (value['dueCount'] as num?)?.toInt() ?? 0,
        realizedCount: (value['realizedCount'] as num?)?.toInt() ?? 0,
        showPendingGhostsInLedger: value['showPendingGhostsInLedger'] != false,
      );
  final List<RecurrenceRule> rules;
  final int pendingCount, dueCount, realizedCount;
  final bool showPendingGhostsInLedger;
}
