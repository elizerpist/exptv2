import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/manual_transactions/domain/manual_transaction_models.dart';
import 'package:fluvi/features/manual_transactions/domain/manual_transaction_repository.dart';
import 'package:fluvi/features/manual_transactions/presentation/manual_transaction_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final categories = <FluviCategory>[
    _category('uncategorized', 'Kategorizálatlan', uncategorized: true),
    _category('food', 'Élelmiszer'),
    _category('shopping', 'Vásárlás'),
  ];

  testWidgets(
    'create editor inherits selected partner category and saves an entry override',
    (tester) async {
      final repository = _FakeManualRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: ManualTransactionEditor.create(
            repository: repository,
            categories: categories,
            direction: LedgerDirection.expense,
          ),
        ),
      );

      expect(find.text('Új kiadás'), findsOneWidget);
      expect(find.text('Bevétel'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('manual-amount-field')),
        '12 450',
      );
      await tester.tap(find.byKey(const ValueKey('manual-partner-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tesco'));
      await tester.pumpAndSettle();

      expect(find.text('Partner alapértelmezése'), findsOneWidget);
      expect(find.text('Élelmiszer'), findsWidgets);
      await tester.tap(
        find.byKey(const ValueKey('manual-category-dropdown-anchor')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vásárlás').last);
      await tester.pumpAndSettle();
      expect(find.text('Egyedi kategória'), findsOneWidget);

      await tester.tap(find.text('Tranzakció hozzáadása'));
      await tester.pumpAndSettle();

      expect(repository.createCalls, 1);
      expect(
        repository.lastCategorySelection?.mode,
        ManualCategoryAssignmentMode.entryOverride,
      );
      expect(repository.lastCategorySelection?.categoryId, 'shopping');
      expect(repository.lastAmount, 1245000);
      expect(repository.lastDirection, LedgerDirection.expense);
    },
  );

  testWidgets('edit editor loads the existing entry and updates it in place', (
    tester,
  ) async {
    final repository = _FakeManualRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ManualTransactionEditor.edit(
          repository: repository,
          categories: categories,
          entryId: 'entry-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kiadás szerkesztése'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('manual-amount-field')))
          .controller
          ?.text,
      '1 000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('manual-amount-field')),
      '2 000',
    );
    await tester.tap(find.text('Módosítások mentése'));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, 1);
    expect(repository.createCalls, 0);
    expect(repository.lastUpdatedEntryId, 'entry-1');
    expect(repository.lastAmount, 200000);
  });
}

FluviCategory _category(String id, String name, {bool uncategorized = false}) =>
    FluviCategory(
      id: id,
      name: name,
      colorId: 'color_02',
      iconId: 'icon_02',
      isSystemUncategorized: uncategorized,
      createdAtUtcMs: 0,
      updatedAtUtcMs: 0,
    );

final class _FakeManualRepository implements ManualTransactionRepository {
  final PartnerDirectoryEntry partner = const PartnerDirectoryEntry(
    partnerId: 'partner-1',
    displayName: 'Tesco',
    originalName: 'TESCO',
    defaultCategoryId: 'food',
    defaultCategoryName: 'Élelmiszer',
    categoryColorId: 'color_02',
    categoryIconId: 'icon_02',
    isUncategorized: false,
    searchNames: ['Tesco', 'TESCO'],
  );

  int createCalls = 0;
  int updateCalls = 0;
  int? lastAmount;
  LedgerDirection? lastDirection;
  ManualCategorySelection? lastCategorySelection;
  String? lastUpdatedEntryId;

  @override
  Future<LedgerEntryDetail> createManualTransaction({
    required ManualPartnerSelection partner,
    required ManualCategorySelection categorySelection,
    required LedgerDirection direction,
    required int amountScaled100,
    required int bookedLocalEpochDay,
    required int bookedLocalTimeMinutes,
    required int occurredAtUtcMs,
    String? note,
  }) async {
    createCalls += 1;
    lastAmount = amountScaled100;
    lastDirection = direction;
    lastCategorySelection = categorySelection;
    return _entry(amountScaled100: amountScaled100);
  }

  @override
  Future<LedgerEntryDetail> getLedgerEntryById(String entryId) async =>
      _entry();

  @override
  Future<PartnerDirectoryEntry?> getPartnerById(String partnerId) async =>
      partnerId == partner.partnerId ? partner : null;

  @override
  Future<PartnerDirectoryEntry?> resolvePartner(String partnerId) =>
      getPartnerById(partnerId);

  @override
  Future<List<PartnerDirectoryEntry>> listPartners() async => [partner];

  @override
  Future<LedgerEntryDetail> updateTransaction({
    required String entryId,
    required int expectedRevision,
    required ManualPartnerSelection partner,
    required ManualCategorySelection categorySelection,
    required int amountScaled100,
    required int bookedLocalEpochDay,
    required int bookedLocalTimeMinutes,
    required int occurredAtUtcMs,
    String? note,
  }) async {
    updateCalls += 1;
    lastUpdatedEntryId = entryId;
    lastAmount = amountScaled100;
    lastCategorySelection = categorySelection;
    return _entry(amountScaled100: amountScaled100);
  }

  @override
  Future<PartnerDirectoryEntry> updatePartner({
    required String partnerId,
    required String? displayNameOverride,
    required String defaultCategoryId,
  }) async => partner;

  LedgerEntryDetail _entry({int amountScaled100 = 100000}) => LedgerEntryDetail(
    entryId: 'entry-1',
    partnerId: partner.partnerId,
    categoryId: partner.defaultCategoryId,
    categoryAssignmentMode: ManualCategoryAssignmentMode.partnerDefault,
    direction: LedgerDirection.expense,
    amountScaled100: amountScaled100,
    bookedLocalEpochDay: 20000,
    bookedLocalTimeMinutes: 600,
    occurredAtUtcMs: 1700000000000,
    note: 'Existing note',
    originKind: 'manual',
    notificationInboxId: null,
    revision: 1,
  );
}
