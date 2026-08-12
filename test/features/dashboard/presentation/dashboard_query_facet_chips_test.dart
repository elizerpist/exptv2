import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_query_facet_chips.dart';
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
}
