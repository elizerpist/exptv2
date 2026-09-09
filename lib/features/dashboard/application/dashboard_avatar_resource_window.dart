import '../logbox/application/dashboard_log_viewport_state.dart';
import '../logbox/application/dashboard_logbox_scene_window.dart';
import '../query/domain/current_ledger_query_scope.dart';

/// Bounded reasons why a prearmed Avatar bank cannot cover a current target.
/// This classification carries no resource ownership or retry state.
enum AvatarResourceWindowRejection {
  pendingHotsetPlans,
  requiredHotsetKeysEmpty,
  missingHotsetEntry,
  aggregateFrameUnavailable,
  resourcePayloadScopeMismatch,
  resourcePayloadBaseMismatch,
  resourceIdentityMismatch,
  staleForegroundProducer,
}

enum AvatarPreviewTerminal {
  acceptedExactNonEmptyPainted,
  acceptedExactEmptyPainted,
  coalescedBeforeResourceReady,
  cancelledByNewPointer,
  staleRejected,
  disposed,
  explicitInvariantFailure,
}

final class AvatarResourceWindowResolution {
  const AvatarResourceWindowResolution.ready(this.window)
    : rejection = null,
      expectedPayloadQuery = null,
      actualPayloadQuery = null;
  const AvatarResourceWindowResolution.rejected(
    this.rejection, {
    this.expectedPayloadQuery,
    this.actualPayloadQuery,
  }) : window = null;

  final DashboardLogBoxSceneWindow? window;
  final AvatarResourceWindowRejection? rejection;
  final LedgerQueryKey? expectedPayloadQuery;
  final LedgerQueryKey? actualPayloadQuery;
}

/// Resolves bounded prearmed coverage from real immutable payload identities.
/// The current target's exact preparation does not depend on this warmup.
AvatarResourceWindowResolution resolveAvatarResourceWindow({
  required String resourceKey,
  required String expectedResourceKey,
  required int expectedRevision,
  required LedgerQueryKey aggregateQuery,
  required DashboardLogViewportState Function() aggregatePayload,
  required List<String> requiredKeys,
  required Map<String, DashboardLogViewportState> cachedPayloads,
  required Map<String, LedgerQueryKey> expectedPayloadQueries,
  int pendingPlanCount = 0,
  bool foregroundCurrent = true,
}) {
  AvatarResourceWindowResolution reject(
    AvatarResourceWindowRejection reason, {
    LedgerQueryKey? expected,
    LedgerQueryKey? actual,
  }) => AvatarResourceWindowResolution.rejected(
    reason,
    expectedPayloadQuery: expected,
    actualPayloadQuery: actual,
  );
  if (!foregroundCurrent) {
    return reject(AvatarResourceWindowRejection.staleForegroundProducer);
  }
  if (resourceKey != expectedResourceKey) {
    return reject(AvatarResourceWindowRejection.resourceIdentityMismatch);
  }
  if (pendingPlanCount > 0) {
    return reject(AvatarResourceWindowRejection.pendingHotsetPlans);
  }
  if (requiredKeys.isEmpty) {
    return reject(AvatarResourceWindowRejection.requiredHotsetKeysEmpty);
  }
  final DashboardLogViewportState aggregate;
  try {
    aggregate = aggregatePayload();
  } on StateError {
    return reject(AvatarResourceWindowRejection.aggregateFrameUnavailable);
  }
  if (aggregate.revision != expectedRevision) {
    return reject(AvatarResourceWindowRejection.resourcePayloadBaseMismatch);
  }
  if (aggregate.queryKey != aggregateQuery) {
    return reject(
      AvatarResourceWindowRejection.resourcePayloadScopeMismatch,
      expected: aggregateQuery,
      actual: aggregate.queryKey,
    );
  }
  final payloads = <String, DashboardLogViewportState>{
    aggregate.queryKey.value: aggregate,
  };
  for (final key in requiredKeys) {
    final payload = cachedPayloads[key];
    if (payload == null) {
      return reject(AvatarResourceWindowRejection.missingHotsetEntry);
    }
    if (payload.revision != expectedRevision) {
      return reject(AvatarResourceWindowRejection.resourcePayloadBaseMismatch);
    }
    if (payload.queryKey != expectedPayloadQueries[key]) {
      return reject(
        AvatarResourceWindowRejection.resourcePayloadScopeMismatch,
        expected: expectedPayloadQueries[key],
        actual: payload.queryKey,
      );
    }
    payloads[payload.queryKey.value] = payload;
  }
  return AvatarResourceWindowResolution.ready(
    DashboardLogBoxSceneWindow(
      identity: resourceKey,
      payloads: payloads.values.toList(growable: false),
    ),
  );
}
