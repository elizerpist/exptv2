import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_avatar_resource_window.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import '../../../support/avatar_target_liveness_fixture.dart';

void main() {
  final repository = AvatarTargetLivenessRepository();
  final aggregate = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const AllTimeScope(),
  );
  final target = aggregate.copyWith(categoryIds: {'avatar-category-8'});
  AvatarResourceWindowResolution resolve({
    int pending = 0,
    bool noKeys = false,
    bool missing = false,
    bool noAggregate = false,
    DashboardLogViewportState? targetPayload,
    String key = 'exact-window',
    bool foreground = true,
  }) => resolveAvatarResourceWindow(
    resourceKey: key,
    expectedResourceKey: 'exact-window',
    expectedRevision: 1,
    aggregateQuery: aggregate.key,
    aggregatePayload: () => noAggregate
        ? throw StateError('retired frame')
        : repository.payload(aggregate, 1),
    requiredKeys: noKeys ? [] : ['category8'],
    cachedPayloads: {
      if (!missing) 'category8': targetPayload ?? repository.payload(target, 1),
    },
    expectedPayloadQueries: {'category8': target.key},
    pendingPlanCount: pending,
    foregroundCurrent: foreground,
  );
  test(
    'complete exact roots preserve nonempty aggregate and category8 payloads',
    () {
      final result = resolve();
      expect(result.rejection, isNull);
      expect(
        result.window!.payloads.map((payload) => payload.previewRowCount),
        [8, 1],
      );
      expect(result.window!.payloads.last.queryKey, target.key);
    },
  );
  test(
    'pending plan cannot be described as a ready window',
    () => expect(
      resolve(pending: 2).rejection,
      AvatarResourceWindowRejection.pendingHotsetPlans,
    ),
  );
  test('empty required keys is distinguished from a missing entry', () {
    expect(
      resolve(noKeys: true).rejection,
      AvatarResourceWindowRejection.requiredHotsetKeysEmpty,
    );
    expect(
      resolve(missing: true).rejection,
      AvatarResourceWindowRejection.missingHotsetEntry,
    );
  });
  test(
    'retired aggregate frame is classified without swallowing other errors',
    () => expect(
      resolve(noAggregate: true).rejection,
      AvatarResourceWindowRejection.aggregateFrameUnavailable,
    ),
  );
  test(
    'nonempty payload from another scope is rejected',
    () => expect(
      resolve(
        targetPayload: repository.payload(
          aggregate.copyWith(categoryIds: {'avatar-category-7'}),
          1,
        ),
      ).rejection,
      AvatarResourceWindowRejection.resourcePayloadScopeMismatch,
    ),
  );
  test(
    'same query from an older revision is rejected',
    () => expect(
      resolve(targetPayload: repository.payload(target, 0)).rejection,
      AvatarResourceWindowRejection.resourcePayloadBaseMismatch,
    ),
  );
  test('retired bank identity and foreground ownership are distinct', () {
    expect(
      resolve(key: 'old-window').rejection,
      AvatarResourceWindowRejection.resourceIdentityMismatch,
    );
    expect(
      resolve(foreground: false, pending: 2).rejection,
      AvatarResourceWindowRejection.staleForegroundProducer,
    );
  });
  test('scope rejection preserves the actual wrong payload identity', () {
    final wrong = aggregate.copyWith(categoryIds: {'avatar-category-7'});
    final result = resolve(targetPayload: repository.payload(wrong, 1));
    expect(result.expectedPayloadQuery, target.key);
    expect(result.actualPayloadQuery, wrong.key);
  });
}
