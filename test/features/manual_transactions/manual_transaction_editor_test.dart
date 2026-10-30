import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/core/categories/domain/category_repository.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/manual_transactions/application/manual_transaction_editor_preferences.dart';
import 'package:fluvi/features/manual_transactions/domain/manual_transaction_impact_repository.dart';
import 'package:fluvi/features/manual_transactions/domain/manual_transaction_models.dart';
import 'package:fluvi/features/manual_transactions/domain/manual_transaction_repository.dart';
import 'package:fluvi/features/manual_transactions/presentation/manual_transaction_editor.dart';
import 'package:fluvi/features/manual_transactions/presentation/partner_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => PreparedVectorAssetAtlas.instance.prepare());

  final categories = <FluviCategory>[
    _category('uncategorized', 'Kategorizálatlan', uncategorized: true),
    _category('food', 'Élelmiszer'),
    _category('shopping', 'Vásárlás'),
  ];

  testWidgets(
    'create editor inherits selected partner category and saves an entry override',
    (tester) async {
      final repository = _FakeManualRepository();
      ManualTransactionSaveResult? savedResult;
      await tester.pumpWidget(
        MaterialApp(
          home: ManualTransactionEditor.create(
            repository: repository,
            categories: categories,
            direction: LedgerDirection.expense,
            onSaved: (result) async => savedResult = result,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Új kiadás'), findsOneWidget);
      expect(find.text('Bevétel'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('manual-amount-field')),
        '12 450',
      );
      await tester.tap(find.byKey(const ValueKey('manual-partner-field')));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is PartnerCategoryAvatar &&
              widget.partner.categoryIconId == 'icon_02' &&
              widget.partner.categoryColorId == 'color_02',
        ),
        findsOneWidget,
        reason: 'The normal picker resolves the real catalog avatar.',
      );
      await tester.tap(find.text('Tesco'));
      await tester.pumpAndSettle();

      expect(find.text('Partner alapértelmezése'), findsOneWidget);
      expect(find.text('Élelmiszer'), findsWidgets);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is PartnerCategoryAvatar &&
              widget.partner.categoryIconId == 'icon_02' &&
              widget.partner.categoryColorId == 'color_02',
        ),
        findsOneWidget,
        reason:
            'The selected field retains the partner-default catalog icon, '
            'not the old fixed storefront glyph.',
      );
      await tester.tap(
        find.byKey(const ValueKey('manual-category-dropdown-anchor')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vásárlás').last);
      await tester.pumpAndSettle();
      expect(find.text('Egyedi kategória'), findsOneWidget);

      await tester.tap(find.text('Mentés'));
      await tester.pumpAndSettle();

      expect(repository.createCalls, 1);
      expect(
        repository.lastCategorySelection?.mode,
        ManualCategoryAssignmentMode.entryOverride,
      );
      expect(repository.lastCategorySelection?.categoryId, 'shopping');
      expect(repository.lastAmount, 1245000);
      expect(repository.lastDirection, LedgerDirection.expense);
      expect(savedResult?.entry.entryId, 'entry-1');
      expect(savedResult?.globalCoreRevision, 42);
      expect(savedResult?.effectiveCategory?.id, 'shopping');
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
    await tester.tap(find.text('Mentés'));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, 1);
    expect(repository.createCalls, 0);
    expect(repository.lastUpdatedEntryId, 'entry-1');
    expect(repository.lastAmount, 200000);
  });

  testWidgets(
    'layout and partner-presentation switches retain the live draft',
    (tester) async {
      final preferences = _MemoryEditorPreferencesStore();
      await tester.pumpWidget(
        MaterialApp(
          home: ManualTransactionEditor.create(
            repository: _FakeManualRepository(),
            categories: categories,
            direction: LedgerDirection.expense,
            preferencesStore: preferences,
            impactRepository: const _FakeImpactRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('manual-amount-field')),
        '2 500',
      );
      await tester.enterText(
        find.byKey(const ValueKey('manual-note-field')),
        'Megőrzendő szöveg',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('manual-layout-toggle')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('manual-editor-islands')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('manual-amount-field')),
            )
            .controller
            ?.text,
        '2 500',
      );
      expect(find.text('Megőrzendő szöveg'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('manual-partner-presentation-toggle')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('manual-partner-dropdown-anchor')),
        findsOneWidget,
      );
      expect(
        preferences.value,
        const ManualTransactionEditorPreferences(
          layout: ManualTransactionEditorLayout.islands,
          partnerPickerPresentation: ManualPartnerPickerPresentation.dropdown,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('manual-quick-5000')));
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('manual-amount-field')),
            )
            .controller
            ?.text,
        '7 500',
      );
    },
  );

  testWidgets(
    'expense impact shows a real negative remainder without clamping',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ManualTransactionEditor.create(
            repository: _FakeManualRepository(),
            categories: categories,
            direction: LedgerDirection.expense,
            impactRepository: const _FakeImpactRepository(
              categoryActualScaled100: 900000,
              categoryLimitScaled100: 1000000,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('manual-quick-1000')));
      await tester.tap(find.byKey(const ValueKey('manual-quick-1000')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('A tranzakció hatása'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('manual-impact-value')))
            .data,
        '−1 000 Ft',
      );
    },
  );

  testWidgets('a real zero category limit stays an overrun, never NaN', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ManualTransactionEditor.create(
          repository: _FakeManualRepository(),
          categories: categories,
          direction: LedgerDirection.expense,
          impactRepository: const _FakeImpactRepository(
            categoryActualScaled100: 0,
            categoryLimitScaled100: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('manual-quick-1000')));
    await tester.scrollUntilVisible(
      find.text('A tranzakció hatása'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('manual-impact-value')))
          .data,
      '−1 000 Ft',
    );
  });

  testWidgets('edit impact request excludes the persisted entry', (
    tester,
  ) async {
    final impact = _RecordingImpactRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ManualTransactionEditor.edit(
          repository: _FakeManualRepository(),
          categories: categories,
          entryId: 'entry-1',
          impactRepository: impact,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(impact.excludedEntryId, 'entry-1');
  });

  testWidgets(
    'new category is persisted and selected as this transaction override',
    (tester) async {
      final categoryRepository = _FakeCategoryRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: ManualTransactionEditor.create(
            repository: _FakeManualRepository(),
            categories: categories,
            categoryRepository: categoryRepository,
            direction: LedgerDirection.expense,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('manual-category-dropdown-anchor')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('manual-category-create-action')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('category-editor-name-input')),
        'Közlekedés',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('category-editor-save')),
      );
      await tester.tap(find.byKey(const ValueKey('category-editor-save')));
      await tester.pumpAndSettle();

      expect(categoryRepository.created?.name, 'Közlekedés');
      expect(find.text('Közlekedés'), findsOneWidget);
      expect(find.text('Egyedi kategória'), findsOneWidget);
    },
  );

  testWidgets('hero income editor visual reference', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: ManualTransactionEditor.create(
          repository: _FakeManualRepository(),
          categories: categories,
          direction: LedgerDirection.income,
          preferencesStore: _MemoryEditorPreferencesStore(),
          impactRepository: const _FakeImpactRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('manual-quick-1000')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey('manual-editor-visual-boundary')),
      matchesGoldenFile(
        '../../goldens/manual_transaction_editor_hero_income.png',
      ),
    );
  });

  testWidgets('islands expense editor visual reference', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final preferences = _MemoryEditorPreferencesStore()
      ..value = const ManualTransactionEditorPreferences(
        layout: ManualTransactionEditorLayout.islands,
        partnerPickerPresentation: ManualPartnerPickerPresentation.dropdown,
      );
    await tester.pumpWidget(
      MaterialApp(
        home: ManualTransactionEditor.create(
          repository: _FakeManualRepository(),
          categories: categories,
          direction: LedgerDirection.expense,
          preferencesStore: preferences,
          impactRepository: const _FakeImpactRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('manual-quick-5000')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey('manual-editor-visual-boundary')),
      matchesGoldenFile(
        '../../goldens/manual_transaction_editor_islands_expense.png',
      ),
    );
  });
}

final class _MemoryEditorPreferencesStore
    implements ManualTransactionEditorPreferencesStore {
  ManualTransactionEditorPreferences value =
      ManualTransactionEditorPreferences.defaults;

  @override
  Future<ManualTransactionEditorPreferences> read() async => value;

  @override
  Future<void> write(ManualTransactionEditorPreferences preferences) async {
    value = preferences;
  }
}

final class _FakeImpactRepository implements ManualTransactionImpactRepository {
  const _FakeImpactRepository({
    this.categoryActualScaled100 = 0,
    this.categoryLimitScaled100 = 3000000,
  });

  final int categoryActualScaled100;
  final int? categoryLimitScaled100;

  @override
  Future<ManualTransactionMonthImpact> loadMonthImpact({
    required LedgerDirection direction,
    required String? categoryId,
    required int year,
    required int month,
    String? excludedEntryId,
  }) async => ManualTransactionMonthImpact(
    categoryActualScaled100: categoryActualScaled100,
    categoryLimitScaled100: categoryLimitScaled100,
    monthIncomeScaled100: 4000000,
    monthExpenseScaled100: 1200000,
  );
}

final class _FakeCategoryRepository implements CategoryRepository {
  FluviCategory? created;

  @override
  Future<FluviCategory> createCategory({
    required String name,
    required String colorId,
    required String iconId,
  }) async => created = FluviCategory(
    id: 'created-category',
    name: name,
    colorId: colorId,
    iconId: iconId,
    isSystemUncategorized: false,
    createdAtUtcMs: 1,
    updatedAtUtcMs: 1,
  );

  @override
  Future<void> deleteCategory(String id) async {}

  @override
  Future<List<FluviCategory>> getCategories() async =>
      created == null ? const [] : [created!];

  @override
  Future<FluviCategory?> getCategoryById(String id) async =>
      created?.id == id ? created : null;

  @override
  Future<FluviCategory> updateCategory({
    required String id,
    required String name,
    required String colorId,
    required String iconId,
  }) async => createCategory(name: name, colorId: colorId, iconId: iconId);

  @override
  Stream<List<FluviCategory>> watchCategories() =>
      Stream.value(created == null ? const [] : [created!]);
}

final class _RecordingImpactRepository
    implements ManualTransactionImpactRepository {
  String? excludedEntryId;

  @override
  Future<ManualTransactionMonthImpact> loadMonthImpact({
    required LedgerDirection direction,
    required String? categoryId,
    required int year,
    required int month,
    String? excludedEntryId,
  }) async {
    this.excludedEntryId = excludedEntryId;
    return const ManualTransactionMonthImpact(
      categoryActualScaled100: 100000,
      categoryLimitScaled100: 300000,
      monthIncomeScaled100: 0,
      monthExpenseScaled100: 100000,
    );
  }
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
    return _entry(
      amountScaled100: amountScaled100,
      categoryId:
          categorySelection.categoryId ?? this.partner.defaultCategoryId,
      categoryAssignmentMode: categorySelection.mode,
    );
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
    return _entry(
      amountScaled100: amountScaled100,
      categoryId:
          categorySelection.categoryId ?? this.partner.defaultCategoryId,
      categoryAssignmentMode: categorySelection.mode,
    );
  }

  @override
  Future<PartnerDirectoryEntry> updatePartner({
    required String partnerId,
    required String? displayNameOverride,
    required String defaultCategoryId,
  }) async => partner;

  LedgerEntryDetail _entry({
    int amountScaled100 = 100000,
    String? categoryId,
    ManualCategoryAssignmentMode categoryAssignmentMode =
        ManualCategoryAssignmentMode.partnerDefault,
  }) => LedgerEntryDetail(
    entryId: 'entry-1',
    partnerId: partner.partnerId,
    categoryId: categoryId ?? partner.defaultCategoryId,
    categoryAssignmentMode: categoryAssignmentMode,
    direction: LedgerDirection.expense,
    amountScaled100: amountScaled100,
    bookedLocalEpochDay: 20000,
    bookedLocalTimeMinutes: 600,
    occurredAtUtcMs: 1700000000000,
    note: 'Existing note',
    originKind: 'manual',
    notificationInboxId: null,
    coreRevision: 42,
    revision: 1,
  );
}
