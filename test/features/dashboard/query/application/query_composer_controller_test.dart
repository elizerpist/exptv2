import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/application/query_composer_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_temporal_filter.dart';
import 'package:fluvi/features/dashboard/query/domain/query_menu_data.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  CurrentLedgerQueryScope scope({Set<String> categories = const <String>{}}) =>
      CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: categories,
      );

  test('editing a composer draft does not mutate the applied query', () {
    final applied = CurrentQueryController(initialScope: scope());
    final composer = QueryComposerController(appliedQuery: applied);
    addTearDown(composer.dispose);
    addTearDown(applied.dispose);

    composer.open();
    composer.updateDraft(scope: scope(categories: const <String>{'food'}));

    expect(composer.draft.categoryIds, <String>{'food'});
    expect(applied.scope.categoryIds, isEmpty);

    composer.closeWithoutApply();
    expect(applied.scope.categoryIds, isEmpty);
    expect(composer.isOpen, isFalse);
  });

  test(
    'each edit session and draft mutation has a new cancellation identity',
    () {
      final applied = CurrentQueryController(initialScope: scope());
      final composer = QueryComposerController(appliedQuery: applied);
      addTearDown(composer.dispose);
      addTearDown(applied.dispose);

      composer.open();
      final first = composer.applyIdentity;
      composer.updateDraft(scope: scope(categories: const <String>{'food'}));
      final changedDraft = composer.applyIdentity;
      composer.closeWithoutApply();
      composer.open();
      final reopened = composer.applyIdentity;

      expect(first.sessionId, isNot(changedDraft.sessionId));
      expect(first.draftKey, scope().key.value);
      expect(changedDraft.draftKey, contains('categories:food'));
      expect(reopened.sessionId, isNot(changedDraft.sessionId));
      expect(reopened.draftKey, scope().key.value);
    },
  );

  test('the composer only closes after the core has committed its draft', () {
    final applied = CurrentQueryController(initialScope: scope());
    final composer = QueryComposerController(appliedQuery: applied);
    addTearDown(composer.dispose);
    addTearDown(applied.dispose);
    var notifications = 0;
    applied.addListener(() => notifications += 1);

    composer.open();
    composer.updateDraft(
      scope: scope().copyWith(
        temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>{
          QueryPeriodSelection.month(2026, 2),
        }),
      ),
    );
    // The composition root is the only owner allowed to replace the applied
    // dashboard scope. The composer merely accepts the already-published
    // scope and clears its transient draft.
    applied.apply(composer.draft);
    composer.completeApplied();

    expect(composer.isOpen, isFalse);
    expect(notifications, 1);
    expect(applied.scope.temporalFilter.isRestrictive, isTrue);
    expect(composer.isOpen, isFalse);
  });

  test(
    'an accepted Apply survives visual dismissal but not a newer edit session',
    () {
      final applied = CurrentQueryController(initialScope: scope());
      final composer = QueryComposerController(appliedQuery: applied);
      addTearDown(composer.dispose);
      addTearDown(applied.dispose);

      composer.open();
      composer.updateDraft(scope: scope(categories: const <String>{'food'}));
      final accepted = composer.applyIdentity;

      expect(composer.acceptApply(accepted), isTrue);
      expect(composer.isOpen, isFalse);
      expect(composer.isCurrentApplyIdentity(accepted), isTrue);

      composer.open();
      expect(composer.isCurrentApplyIdentity(accepted), isFalse);
    },
  );

  test(
    'the applied owner retains bounded facet presentation with its scope',
    () {
      final applied = CurrentQueryController(initialScope: scope());
      addTearDown(applied.dispose);
      final next = scope(categories: const <String>{'food'});
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 12, amountScaled100: 1000),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 1000,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[
          QueryMenuCategoryFacet(
            id: 'food',
            displayName: 'Étel',
            colorId: 'color_15',
            iconId: 'icon_02',
            entryCount: 12,
          ),
        ],
        partners: <QueryMenuPartnerFacet>[],
      );

      applied.apply(next, facetPresentation: facets);

      expect(applied.scope, next);
      expect(applied.facetPresentation?.categories.single.displayName, 'Étel');
    },
  );
}
