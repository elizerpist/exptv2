import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_ephemeral_focus_controller.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_partner_visual_intent.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  const identity = BudgetPartnerVisualIdentity(
    coreRevision: 7,
    direction: LedgerDirection.expense,
    targetHandle: 1,
    analysisScope: MonthScope(YearMonth(year: 2026, month: 7)),
  );
  const partnerA = DashboardFocusFacet(
    id: 'partner-a',
    displayName: 'Partner A',
    colorId: 'color_01',
  );
  const partnerB = DashboardFocusFacet(
    id: 'partner-b',
    displayName: 'Partner B',
    colorId: 'color_02',
  );
  const partnerC = DashboardFocusFacet(
    id: 'partner-c',
    displayName: 'Partner C',
    colorId: 'color_03',
  );
  const available = <String>{'partner-a', 'partner-b', 'partner-c'};

  test('pending Partner visual intent paints before authoritative focus', () {
    final intents = BudgetPartnerVisualIntentController();
    final pending = intents.begin(partner: partnerA, identity: identity);

    expect(
      intents.effectivePartner(
        identity: identity,
        availablePartnerIds: available,
        authoritativePartner: null,
      ),
      same(partnerA),
    );
    expect(
      intents.acknowledge(identity: identity, authoritativePartner: partnerA),
      isTrue,
    );
    expect(intents.pending, isNull);
    expect(
      intents.effectivePartner(
        identity: identity,
        availablePartnerIds: available,
        authoritativePartner: partnerA,
      ),
      same(partnerA),
      reason: 'Acknowledgement must not create an unselected visual frame.',
    );
    expect(pending.generation, 1);
  });

  test('failed Partner focus returns only the matching visual intent', () {
    final intents = BudgetPartnerVisualIntentController();
    final pending = intents.begin(partner: partnerA, identity: identity);

    expect(
      intents.complete(generation: pending.generation, accepted: false),
      isTrue,
    );
    expect(intents.pending, isNull);
    expect(
      intents.effectivePartner(
        identity: identity,
        availablePartnerIds: available,
        authoritativePartner: partnerB,
      ),
      same(partnerB),
    );
  });

  test('rapid Partner intents ignore stale completion and acknowledgement', () {
    final intents = BudgetPartnerVisualIntentController();
    final first = intents.begin(partner: partnerA, identity: identity);
    final second = intents.begin(partner: partnerB, identity: identity);
    final latest = intents.begin(partner: partnerC, identity: identity);

    expect(
      intents.complete(generation: first.generation, accepted: false),
      isFalse,
    );
    expect(
      intents.acknowledge(identity: identity, authoritativePartner: partnerA),
      isFalse,
    );
    expect(
      intents.complete(generation: second.generation, accepted: true),
      isFalse,
    );
    expect(
      intents.effectivePartner(
        identity: identity,
        availablePartnerIds: available,
        authoritativePartner: partnerA,
      ),
      same(partnerC),
    );
    expect(
      intents.acknowledge(identity: identity, authoritativePartner: partnerC),
      isTrue,
    );
    expect(
      intents.effectivePartner(
        identity: identity,
        availablePartnerIds: available,
        authoritativePartner: partnerC,
      ),
      same(partnerC),
    );
    expect(latest.generation, 3);
  });

  test(
    'target or scope replacement invalidates an incompatible pending Partner',
    () {
      final intents = BudgetPartnerVisualIntentController()
        ..begin(partner: partnerA, identity: identity);
      const nextIdentity = BudgetPartnerVisualIdentity(
        coreRevision: 7,
        direction: LedgerDirection.expense,
        targetHandle: 2,
        analysisScope: MonthScope(YearMonth(year: 2026, month: 7)),
      );

      expect(
        intents.invalidateIfIncompatible(
          identity: nextIdentity,
          availablePartnerIds: available,
        ),
        isTrue,
      );
      expect(intents.pending, isNull);
    },
  );
}
