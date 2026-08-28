import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_ephemeral_focus_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_live_interaction_coordinator.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';

void main() {
  test('latest accepted live interaction supersedes an older generation', () {
    final navigation = DashboardNavigationController(
      initialDate: DateTime.utc(2026, 8, 28),
    );
    final coordinator = DashboardLiveInteractionCoordinator();
    addTearDown(navigation.dispose);
    addTearDown(coordinator.dispose);

    final category = coordinator.accept(
      source: DashboardLiveInteractionSource.logBoxCategory,
      coreRevision: 7,
      direction: LedgerDirection.expense,
      temporalCandidate: navigation.state,
      category: const DashboardFocusFacet(id: 'food', displayName: 'Étel'),
      partner: null,
      normalizedSearch: null,
    );
    final partner = coordinator.accept(
      source: DashboardLiveInteractionSource.partnerSwipe,
      coreRevision: 7,
      direction: LedgerDirection.expense,
      temporalCandidate: navigation.state,
      category: const DashboardFocusFacet(id: 'food', displayName: 'Étel'),
      partner: const DashboardFocusFacet(id: 'spar', displayName: 'SPAR'),
      normalizedSearch: null,
    );

    expect(category.generation, 1);
    expect(partner.generation, 2);
    expect(coordinator.isCurrent(category), isFalse);
    expect(coordinator.isCurrent(partner), isTrue);
    expect(partner.projectionKey, contains('category:food'));
    expect(partner.projectionKey, contains('partner:spar'));
  });
}
