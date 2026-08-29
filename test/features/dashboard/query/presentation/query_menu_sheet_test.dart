import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/application/query_composer_controller.dart';
import 'package:fluvi/features/dashboard/query/application/query_menu_data_controller.dart';
import 'package:fluvi/features/dashboard/query/application/saved_query_controller.dart';
import 'package:fluvi/features/dashboard/query/data/query_menu_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_menu_data.dart';
import 'package:fluvi/features/dashboard/query/presentation/query_menu_sheet.dart';
import 'package:fluvi/features/dashboard/query/presentation/query_amount_range_control.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  testWidgets(
    'opens the HTML query hierarchy and its category picker in one sheet',
    (tester) async {
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
      );
      final repository = _Repository();
      final applied = CurrentQueryController(initialScope: scope);
      final composer = QueryComposerController(appliedQuery: applied)..open();
      final data = QueryMenuDataController(repository: repository);
      final saved = SavedQueryController(repository: repository);
      addTearDown(applied.dispose);
      addTearDown(composer.dispose);
      addTearDown(data.dispose);
      addTearDown(saved.dispose);
      await data.refresh(scope);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryMenuSheet(
              composer: composer,
              dataController: data,
              savedQueries: saved,
              onDraftChanged: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.text('Keresés és szűrők'), findsOneWidget);
      expect(find.text('Mikor?'), findsOneWidget);
      expect(find.text('Mire költöttél?'), findsOneWidget);
      expect(find.text('Kinél?'), findsOneWidget);
      expect(find.text('További szűrők'), findsOneWidget);
      expect(find.text('Kategória hozzáadása'), findsOneWidget);

      await tester.tap(find.text('Kategória hozzáadása'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Kategóriák'), findsOneWidget);
      expect(find.text('Étel'), findsOneWidget);

      final categoryRow = find.byKey(const ValueKey('category-picker-food'));
      await tester.tapAt(tester.getTopLeft(categoryRow) + const Offset(28, 28));
      await tester.pump();
      expect(composer.draft.categoryIds, <String>{'food'});

      await tester.tap(find.byKey(const ValueKey('facet-picker-done')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 240));
      expect(find.byKey(const ValueKey('facet-picker-list')), findsNothing);
      expect(find.text('Étel'), findsOneWidget);

      await tester.tap(find.text('Partner hozzáadása'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Partnerek'), findsOneWidget);
      final partnerRow = find.byKey(const ValueKey('partner-picker-mol'));
      await tester.tapAt(tester.getTopLeft(partnerRow) + const Offset(28, 28));
      await tester.pump();
      expect(composer.draft.partnerIds, <String>{'mol'});

      await tester.tap(find.byKey(const ValueKey('facet-picker-done')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 240));
      expect(find.byKey(const ValueKey('facet-picker-list')), findsNothing);
    },
  );

  testWidgets('keeps the query sheet inside standard mobile widths', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in <double>[360, 390, 412, 430]) {
      await tester.binding.setSurfaceSize(Size(width, 800));
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
      );
      final applied = CurrentQueryController(initialScope: scope);
      final composer = QueryComposerController(appliedQuery: applied)..open();
      final data = QueryMenuDataController(repository: _Repository());
      final saved = SavedQueryController(repository: _Repository());
      addTearDown(applied.dispose);
      addTearDown(composer.dispose);
      addTearDown(data.dispose);
      addTearDown(saved.dispose);
      await data.refresh(scope);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryMenuSheet(
              composer: composer,
              dataController: data,
              savedQueries: saved,
              onDraftChanged: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull, reason: '${width.toInt()} px');
    }
  });

  testWidgets('keeps amount-slider movement local until the range ends', (
    tester,
  ) async {
    final scope = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const AllTimeScope(),
    );
    final applied = CurrentQueryController(initialScope: scope);
    final composer = QueryComposerController(appliedQuery: applied)..open();
    final data = QueryMenuDataController(repository: _Repository());
    final saved = SavedQueryController(repository: _Repository());
    addTearDown(applied.dispose);
    addTearDown(composer.dispose);
    addTearDown(data.dispose);
    addTearDown(saved.dispose);
    await data.refresh(scope);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QueryMenuSheet(
            composer: composer,
            dataController: data,
            savedQueries: saved,
            onDraftChanged: (_) {},
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('További szűrők'));
    await tester.pump();

    final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
    expect(
      find.byType(QueryAmountRangeControl),
      findsOneWidget,
      reason: 'G3: Query menu renders the shared two-ended component.',
    );
    slider.onChanged!(const RangeValues(100000, 200000));
    await tester.pump();
    expect(composer.draft.refinements, isEmpty);

    slider.onChangeEnd!(const RangeValues(100000, 200000));
    await tester.pump();
    expect(composer.draft.refinements['minimumAmountScaled100'], 100000);
    expect(composer.draft.refinements['maximumAmountScaled100'], 200000);
  });

  testWidgets(
    'keeps the last confirmed CTA count visible while the latest draft loads',
    (tester) async {
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
      );
      final repository = _DeferredRepository();
      final applied = CurrentQueryController(initialScope: scope);
      final composer = QueryComposerController(appliedQuery: applied)..open();
      final data = QueryMenuDataController(repository: repository);
      addTearDown(applied.dispose);
      addTearDown(composer.dispose);
      addTearDown(data.dispose);

      final initialRefresh = data.refresh(scope);
      repository.complete(0, _data(2458));
      await initialRefresh;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryMenuStickyFooter(
              composer: composer,
              dataController: data,
              onApply: (_) async {},
              onClear: () {},
            ),
          ),
        ),
      );
      expect(find.text('2458 tranzakció mutatása'), findsOneWidget);

      final changed = scope.copyWith(categoryIds: const <String>{'food'});
      composer.updateDraft(scope: changed);
      unawaited(data.refresh(changed));
      await tester.pump();

      expect(find.text('2458 tranzakció mutatása'), findsOneWidget);
      expect(find.text('Eredmény frissül…'), findsNothing);
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('query-menu-apply')))
            .onPressed,
        isNotNull,
        reason:
            'Apply must use the canonical current draft, not wait for UI data.',
      );
    },
  );
}

QueryMenuData _data(int count) => QueryMenuData(
  result: QueryMenuResultSummary(entryCount: count, amountScaled100: count),
  amountDomain: const QueryMenuAmountDomain(
    minimumAmountScaled100: 0,
    maximumAmountScaled100: 100,
  ),
  availableMonths: const <QueryMenuAvailableMonth>[],
  categories: const <QueryMenuCategoryFacet>[],
  partners: const <QueryMenuPartnerFacet>[],
);

final class _DeferredRepository implements QueryMenuRepository {
  final List<Completer<QueryMenuData>> _pending = <Completer<QueryMenuData>>[];

  @override
  Future<QueryMenuData> readFacets(CurrentLedgerQueryScope draft) {
    final pending = Completer<QueryMenuData>();
    _pending.add(pending);
    return pending.future;
  }

  void complete(int index, QueryMenuData value) =>
      _pending[index].complete(value);

  @override
  Future<SavedLedgerQuery> createSaved({
    required String name,
    required CurrentLedgerQueryScope scope,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteSaved({required String id}) => throw UnimplementedError();

  @override
  Future<SavedLedgerQuery> loadSaved({
    required String id,
    required LedgerDirection activeDirection,
  }) => throw UnimplementedError();

  @override
  Future<List<SavedLedgerQuery>> listSaved(LedgerDirection direction) =>
      throw UnimplementedError();

  @override
  Future<SavedLedgerQuery> renameSaved({
    required String id,
    required String name,
  }) => throw UnimplementedError();

  @override
  Future<SavedLedgerQuery> updateSaved({
    required String id,
    required String name,
    required CurrentLedgerQueryScope scope,
  }) => throw UnimplementedError();
}

final class _Repository implements QueryMenuRepository {
  @override
  Future<QueryMenuData> readFacets(CurrentLedgerQueryScope draft) async =>
      const QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 26, amountScaled100: 123000),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 250000,
        ),
        availableMonths: <QueryMenuAvailableMonth>[
          QueryMenuAvailableMonth(year: 2026, month: 2),
        ],
        categories: <QueryMenuCategoryFacet>[
          QueryMenuCategoryFacet(
            id: 'food',
            displayName: 'Étel',
            colorId: 'color_15',
            iconId: 'icon_02',
            entryCount: 26,
          ),
        ],
        partners: <QueryMenuPartnerFacet>[
          QueryMenuPartnerFacet(
            id: 'mol',
            displayName: 'MOL',
            categoryId: 'food',
            categoryColorId: 'color_07',
            categoryIconId: 'icon_08',
            entryCount: 4,
          ),
        ],
      );

  @override
  Future<SavedLedgerQuery> createSaved({
    required String name,
    required CurrentLedgerQueryScope scope,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteSaved({required String id}) => throw UnimplementedError();

  @override
  Future<SavedLedgerQuery> loadSaved({
    required String id,
    required LedgerDirection activeDirection,
  }) => throw UnimplementedError();

  @override
  Future<List<SavedLedgerQuery>> listSaved(LedgerDirection direction) async =>
      const <SavedLedgerQuery>[];

  @override
  Future<SavedLedgerQuery> renameSaved({
    required String id,
    required String name,
  }) => throw UnimplementedError();

  @override
  Future<SavedLedgerQuery> updateSaved({
    required String id,
    required String name,
    required CurrentLedgerQueryScope scope,
  }) => throw UnimplementedError();
}
