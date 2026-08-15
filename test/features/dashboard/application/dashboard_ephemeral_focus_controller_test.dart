import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_ephemeral_focus_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  CurrentLedgerQueryScope base({
    Set<String> categories = const <String>{'food', 'utilities'},
    Set<String> partners = const <String>{'mvm', 'market'},
  }) => CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const AllTimeScope(),
    categoryIds: categories,
    partnerIds: partners,
  );

  test('category focus narrows without mutating its committed base query', () {
    final controller = DashboardEphemeralFocusController();
    addTearDown(controller.dispose);
    final baseScope = base();

    controller.focusCategory(
      baseScope: baseScope,
      coreRevision: 7,
      facet: const DashboardFocusFacet(id: 'utilities', displayName: 'Rezsi'),
    );

    expect(baseScope.categoryIds, <String>{'food', 'utilities'});
    expect(controller.state!.category?.id, 'utilities');
    expect(controller.effectiveScopeFor(baseScope).categoryIds, <String>{
      'utilities',
    });
    expect(controller.effectiveScopeFor(baseScope).partnerIds, <String>{
      'mvm',
      'market',
    });

    controller.clearCategory();

    expect(controller.state, isNull);
    expect(controller.effectiveScopeFor(baseScope), same(baseScope));
  });

  test('focus dimensions compose and clear independently', () {
    final controller = DashboardEphemeralFocusController();
    addTearDown(controller.dispose);
    final baseScope = base();

    controller.focusCategory(
      baseScope: baseScope,
      coreRevision: 7,
      facet: const DashboardFocusFacet(id: 'utilities', displayName: 'Rezsi'),
    );
    controller.focusPartner(
      baseScope: baseScope,
      coreRevision: 7,
      facet: const DashboardFocusFacet(id: 'mvm', displayName: 'MVM'),
    );

    expect(controller.effectiveScopeFor(baseScope).categoryIds, <String>{
      'utilities',
    });
    expect(controller.effectiveScopeFor(baseScope).partnerIds, <String>{'mvm'});

    controller.clearPartner();
    expect(controller.state!.category?.id, 'utilities');
    expect(controller.state!.partner, isNull);
    expect(controller.effectiveScopeFor(baseScope).partnerIds, <String>{
      'mvm',
      'market',
    });

    controller.clearCategory();
    expect(controller.state, isNull);
    expect(controller.effectiveScopeFor(baseScope), same(baseScope));
  });

  test(
    'category focus narrows an unrestricted base and clearing restores it',
    () {
      final controller = DashboardEphemeralFocusController();
      addTearDown(controller.dispose);
      final unrestricted = base(
        categories: const <String>{},
        partners: const <String>{},
      );

      controller.focusCategory(
        baseScope: unrestricted,
        coreRevision: 7,
        facet: const DashboardFocusFacet(id: 'food', displayName: 'Étel'),
      );

      expect(controller.effectiveScopeFor(unrestricted).categoryIds, <String>{
        'food',
      });
      controller.clearCategory();
      expect(controller.state, isNull);
      expect(controller.effectiveScopeFor(unrestricted), same(unrestricted));
    },
  );

  test(
    'a new base query invalidates a stale focus rather than rebasing it',
    () {
      final controller = DashboardEphemeralFocusController();
      addTearDown(controller.dispose);
      final oldBase = base();
      final newBase = base(categories: const <String>{'transport'});
      controller.focusCategory(
        baseScope: oldBase,
        coreRevision: 7,
        facet: const DashboardFocusFacet(id: 'utilities', displayName: 'Rezsi'),
      );

      expect(
        controller.invalidateIfBaseChanged(baseScope: newBase, coreRevision: 7),
        isTrue,
      );
      expect(controller.state, isNull);
      expect(controller.effectiveScopeFor(newBase), same(newBase));
    },
  );
}
