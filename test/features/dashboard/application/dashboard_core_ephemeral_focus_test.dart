import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_ephemeral_focus_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_vertical_geometry_manifest.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/data/empty_dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/dashboard_focus_membership_seed.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';

void main() {
  test(
    'focus publication narrows a derived index and clearing restores the retained base without a repository read',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final baseIndex = core.preparedIndex!;
      final baseQuery = core.currentQuery.scopeFor(LedgerDirection.income);

      final focused = await core.requestCategoryFocus(
        const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
      );

      expect(focused, isTrue);
      expect(repository.prepareCalls, 1, reason: 'the tap must not read Room');
      expect(core.currentQuery.scopeFor(LedgerDirection.income), baseQuery);
      expect(core.focus.state?.category?.id, 'utilities');
      expect(core.preparedIndex, isNot(same(baseIndex)));
      expect(
        core.preparedIndex!
            .frameFor(core.navigation.state.parentQueryScope)
            .entryCount,
        1,
      );

      final restored = await core.clearAllEphemeralFocus();

      expect(restored, isTrue);
      expect(repository.prepareCalls, 1);
      expect(core.focus.state, isNull);
      expect(core.preparedIndex, same(baseIndex));
      expect(core.currentQuery.scopeFor(LedgerDirection.income), baseQuery);
    },
  );

  test(
    'partner focus composes with category focus and clears each dimension without rebuilding its base',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final baseIndex = core.preparedIndex!;
      final baseQuery = core.currentQuery.scopeFor(LedgerDirection.income);

      expect(
        await core.requestCategoryFocus(
          const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        ),
        isTrue,
      );
      expect(
        await core.requestPartnerFocus(
          const DashboardFocusFacet(
            id: 'partner-utility',
            displayName: 'Utility partner',
          ),
        ),
        isTrue,
      );
      expect(core.focus.state?.category?.id, 'utilities');
      expect(core.focus.state?.partner?.id, 'partner-utility');
      expect(repository.prepareCalls, 1);

      expect(await core.clearPartnerFocus(), isTrue);
      expect(core.focus.state?.category?.id, 'utilities');
      expect(core.focus.state?.partner, isNull);
      expect(repository.prepareCalls, 1);

      expect(await core.clearCategoryFocus(), isTrue);
      expect(core.focus.state, isNull);
      expect(core.preparedIndex, same(baseIndex));
      expect(core.currentQuery.scopeFor(LedgerDirection.income), baseQuery);
      expect(repository.prepareCalls, 1);
    },
  );

  test(
    'a newer committed base Query invalidates focus and cannot restore its old base',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final oldBase = core.currentQuery.scopeFor(LedgerDirection.income);

      expect(
        await core.requestCategoryFocus(
          const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        ),
        isTrue,
      );

      final newerBase = oldBase.copyWith(categoryIds: const <String>{'food'});
      expect(await core.applyQuery(newerBase), isTrue);

      expect(core.focus.state, isNull);
      expect(core.currentQuery.scopeFor(LedgerDirection.income), newerBase);
      expect(
        await core.clearAllEphemeralFocus(),
        isFalse,
        reason:
            'Clearing stale focus may never reinstall the retained old base '
            'after a newer Query has become authoritative.',
      );
      expect(core.currentQuery.scopeFor(LedgerDirection.income), newerBase);
    },
  );
}

final class _FocusSeedRepository implements DashboardDataRuntimeRepository {
  final EmptyDashboardDataRuntimeRepository _empty =
      const EmptyDashboardDataRuntimeRepository();
  var prepareCalls = 0;

  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(1);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) async {
    prepareCalls += 1;
    final base = await _empty.prepareIndex(request, token);
    final rows = <DashboardLedgerEntry>[
      const DashboardLedgerEntry(
        id: 'utility-row',
        partnerId: 'partner-utility',
        categoryId: 'utilities',
        direction: 'income',
        amountMinor: 500,
        bookedLocalEpochDay: 20636,
        bookedLocalTimeMinutes: 600,
        partnerDisplayName: 'Utility partner',
        categoryDisplayName: 'Utilities',
        categoryColorId: 'fallback',
        categoryIconId: 'fallback',
      ),
      const DashboardLedgerEntry(
        id: 'food-row',
        partnerId: 'partner-food',
        categoryId: 'food',
        direction: 'income',
        amountMinor: 700,
        bookedLocalEpochDay: 20635,
        bookedLocalTimeMinutes: 600,
        partnerDisplayName: 'Food partner',
        categoryDisplayName: 'Food',
        categoryColorId: 'fallback',
        categoryIconId: 'fallback',
      ),
    ];
    return PreparedDashboardIndex.complete(
      key: base.key,
      frames: base.frames,
      catalogs: base.catalogs,
      scopes: <LedgerQueryKey, CurrentLedgerQueryScope>{
        for (final zero in base.compactZeroFrames.values)
          zero.queryKey: zero.scope,
        for (final frame in base.frames.values) frame.queryKey: frame.scope,
      },
      origins: base.origins,
      geometrySeedsByDirection:
          <LedgerDirection, List<CommittedVerticalGeometryDayBucket>>{
            for (final direction in LedgerDirection.values)
              direction: base.partitionFor(direction).verticalGeometrySeed,
          },
      focusMembershipSeedsByDirection:
          <LedgerDirection, DashboardFocusMembershipSeed>{
            LedgerDirection.income: DashboardFocusMembershipSeed(rows),
          },
      generation: base.generation,
      contentDigest: base.contentDigest,
      preparedAt: base.preparedAt,
      buildMetrics: base.buildMetrics,
    );
  }

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) => _empty.readCommittedPage(request);

  @override
  Map<String, Object?> performanceReport() => _empty.performanceReport();
}
