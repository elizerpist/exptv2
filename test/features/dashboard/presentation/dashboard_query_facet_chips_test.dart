import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_ephemeral_focus_controller.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_query_facet_chips.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_logbox_search_pill_visibility.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_menu_data.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  testWidgets(
    'renders applied category and partner chips and removes one facet',
    (tester) async {
      final query = CurrentQueryController(
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: const AllTimeScope(),
        ),
      );
      addTearDown(query.dispose);
      query.apply(
        CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: const AllTimeScope(),
          categoryIds: const <String>{'food'},
          partnerIds: const <String>{'tesco'},
        ),
        facetPresentation: const QueryMenuData(
          result: QueryMenuResultSummary(entryCount: 1, amountScaled100: 100),
          amountDomain: QueryMenuAmountDomain(
            minimumAmountScaled100: 0,
            maximumAmountScaled100: 100,
          ),
          availableMonths: <QueryMenuAvailableMonth>[],
          categories: <QueryMenuCategoryFacet>[
            QueryMenuCategoryFacet(
              id: 'food',
              displayName: 'Étel',
              colorId: 'color_15',
              iconId: 'icon_02',
              entryCount: 1,
            ),
          ],
          partners: <QueryMenuPartnerFacet>[
            QueryMenuPartnerFacet(
              id: 'tesco',
              displayName: 'Tesco',
              categoryId: 'food',
              categoryColorId: 'color_15',
              categoryIconId: 'icon_02',
              entryCount: 1,
            ),
          ],
        ),
      );
      String? removed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardQueryFacetChips(
              currentQuery: query,
              direction: LedgerDirection.expense,
              onRemoveCategory: (id) => removed = id,
              onRemovePartner: (_) {},
              onClear: () {},
            ),
          ),
        ),
      );

      expect(find.text('Étel'), findsOneWidget);
      expect(find.text('Tesco'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('dashboard-query-category-food')),
      );
      expect(removed, 'food');
    },
  );

  testWidgets(
    'RED: projects focus chips without mutating or removing base-query facets',
    (tester) async {
      final baseScope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food', 'utilities'},
        partnerIds: const <String>{'tesco', 'mvm'},
      );
      final query = CurrentQueryController(initialScope: baseScope);
      final focus = DashboardEphemeralFocusController();
      addTearDown(query.dispose);
      addTearDown(focus.dispose);
      query.apply(
        baseScope,
        facetPresentation: const QueryMenuData(
          result: QueryMenuResultSummary(entryCount: 4, amountScaled100: 400),
          amountDomain: QueryMenuAmountDomain(
            minimumAmountScaled100: 0,
            maximumAmountScaled100: 400,
          ),
          availableMonths: <QueryMenuAvailableMonth>[],
          categories: <QueryMenuCategoryFacet>[
            QueryMenuCategoryFacet(
              id: 'food',
              displayName: 'Étel',
              colorId: 'color_15',
              iconId: 'icon_02',
              entryCount: 2,
            ),
            QueryMenuCategoryFacet(
              id: 'utilities',
              displayName: 'Rezsi',
              colorId: 'color_12',
              iconId: 'icon_03',
              entryCount: 2,
            ),
          ],
          partners: <QueryMenuPartnerFacet>[
            QueryMenuPartnerFacet(
              id: 'tesco',
              displayName: 'Tesco',
              categoryId: 'food',
              categoryColorId: 'color_15',
              categoryIconId: 'icon_02',
              entryCount: 2,
            ),
            QueryMenuPartnerFacet(
              id: 'mvm',
              displayName: 'MVM',
              categoryId: 'utilities',
              categoryColorId: 'color_12',
              categoryIconId: 'icon_03',
              entryCount: 2,
            ),
          ],
        ),
      );
      focus.replace(
        baseScope: baseScope,
        coreRevision: 17,
        category: const DashboardFocusFacet(
          id: 'utilities',
          displayName: 'Rezsi',
          colorId: 'color_12',
          iconId: 'icon_03',
        ),
        partner: const DashboardFocusFacet(
          id: 'mvm',
          displayName: 'MVM',
          colorId: 'color_12',
          iconId: 'icon_03',
        ),
      );
      var clearedCategory = 0;
      var clearedPartner = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardQueryFacetChips(
              currentQuery: query,
              focus: focus,
              direction: LedgerDirection.expense,
              onRemoveCategory: (_) => fail('must not mutate base category'),
              onRemovePartner: (_) => fail('must not mutate base partner'),
              onClear: () => fail('must not clear the base query'),
              onClearFocusCategory: () => clearedCategory += 1,
              onClearFocusPartner: () => clearedPartner += 1,
            ),
          ),
        ),
      );

      expect(find.text('Étel'), findsNothing);
      expect(find.text('Tesco'), findsNothing);
      expect(find.text('Rezsi'), findsOneWidget);
      expect(find.text('MVM'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('dashboard-focus-category-utilities')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dashboard-focus-partner-mvm')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('dashboard-focus-category-utilities')),
      );
      await tester.tap(
        find.byKey(const ValueKey('dashboard-focus-partner-mvm')),
      );
      expect(clearedCategory, 1);
      expect(clearedPartner, 1);
      expect(query.scopeFor(LedgerDirection.expense), same(baseScope));
    },
  );

  testWidgets(
    'solid facet style uses the canonical avatar color at full opacity',
    (tester) async {
      final query = CurrentQueryController(
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: const AllTimeScope(),
        ),
      );
      final focus = DashboardEphemeralFocusController();
      addTearDown(query.dispose);
      addTearDown(focus.dispose);
      final scope = query.scopeFor(LedgerDirection.expense);
      focus.replace(
        baseScope: scope,
        coreRevision: 1,
        category: const DashboardFocusFacet(
          id: 'food',
          displayName: 'Étel',
          colorId: 'color_15',
          iconId: 'icon_02',
        ),
        partner: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardQueryFacetChips(
              currentQuery: query,
              focus: focus,
              direction: LedgerDirection.expense,
              style: DashboardQueryFacetPillStyle.solidAvatarColor,
              onRemoveCategory: (_) {},
              onRemovePartner: (_) {},
              onClear: () {},
              onClearFocusCategory: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<TextButton>(
        find.byKey(const ValueKey('dashboard-focus-category-food')),
      );
      expect(button.style?.backgroundColor?.resolve(<WidgetState>{})?.a, 1);
      expect(
        button.style?.foregroundColor?.resolve(<WidgetState>{}),
        Colors.white,
      );
    },
  );

  testWidgets(
    'a hidden SearchPill fallback exposes and individually clears live search',
    (tester) async {
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
      );
      final query = CurrentQueryController(initialScope: scope);
      final focus = DashboardEphemeralFocusController();
      addTearDown(query.dispose);
      addTearDown(focus.dispose);
      focus.replace(
        baseScope: scope,
        coreRevision: 1,
        category: null,
        partner: null,
        normalizedSearch: 'tej',
      );
      var clears = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardQueryFacetChips(
              currentQuery: query,
              focus: focus,
              direction: LedgerDirection.expense,
              onRemoveCategory: (_) {},
              onRemovePartner: (_) {},
              onClear: () {},
              onClearFocusSearch: () => clears += 1,
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('dashboard-focus-search')), findsOne);
      expect(find.text('Keresés: tej'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dashboard-focus-search')));
      expect(clears, 1);
    },
  );
}
