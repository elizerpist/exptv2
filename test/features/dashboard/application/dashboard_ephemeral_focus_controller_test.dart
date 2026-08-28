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

  test('search is an orthogonal facet and survives temporal rebasing', () {
    final controller = DashboardEphemeralFocusController();
    addTearDown(controller.dispose);
    final january = base();
    final february = january.copyWith(timeScope: YearScope(2026));

    controller.setNormalizedSearch(
      baseScope: january,
      coreRevision: 7,
      normalizedSearch: 'tej',
    );

    expect(controller.effectiveScopeFor(february).normalizedSearch, 'tej');
    controller.clearSearch();
    expect(controller.effectiveScopeFor(february).normalizedSearch, isNull);
  });

  test('clearing the final Search facet becomes a real empty overlay', () {
    final controller = DashboardEphemeralFocusController();
    addTearDown(controller.dispose);
    final scope = base();

    controller.setNormalizedSearch(
      baseScope: scope,
      coreRevision: 7,
      normalizedSearch: 'tej',
    );
    controller.setNormalizedSearch(
      baseScope: scope,
      coreRevision: 7,
      normalizedSearch: null,
    );

    expect(controller.state, isNull);
    expect(controller.effectiveScopeFor(scope), same(scope));
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
    'RED: an interactive category facet rebases over a new temporal/base scope',
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
        isFalse,
      );
      expect(controller.state?.category?.id, 'utilities');
      expect(controller.effectiveScopeFor(newBase).categoryIds, <String>{
        'utilities',
      });
    },
  );
}
