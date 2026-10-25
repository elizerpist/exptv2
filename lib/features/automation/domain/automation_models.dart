import '../../dashboard/query/domain/ledger_direction.dart';

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
