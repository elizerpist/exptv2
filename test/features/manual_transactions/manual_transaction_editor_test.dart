import 'dart:ui' as ui;

import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/core/categories/domain/category_repository.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/design/dashboard_shadow_profile.dart';
import 'package:fluvi/core/design/fluvi_global_appearance.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_shadow_style.dart';
import 'package:fluvi/features/manual_transactions/application/manual_transaction_editor_preferences.dart';
import 'package:fluvi/features/manual_transactions/domain/manual_transaction_impact_repository.dart';
import 'package:fluvi/features/manual_transactions/domain/manual_transaction_models.dart';
import 'package:fluvi/features/manual_transactions/domain/manual_transaction_repository.dart';
import 'package:fluvi/features/manual_transactions/presentation/category_dropdown.dart';
import 'package:fluvi/features/manual_transactions/presentation/manual_transaction_editor.dart';
import 'package:fluvi/features/manual_transactions/presentation/partner_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

      expect(find.text('Tesco'), findsOneWidget);
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
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -260));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('manual-category-shopping')));
      await tester.pumpAndSettle();
      expect(find.text('Vásárlás'), findsOneWidget);

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
    'expense impact renders the overrun marker, hatch and positive excess',
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
        '1 000 Ft',
      );
      expect(find.text('Keret túllépése mentés után'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('manual-impact-budget-bar')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('manual-impact-limit-marker')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('manual-impact-overrun-hatch')),
        findsOneWidget,
      );
      expect(find.text('Túllépés'), findsOneWidget);
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
      '1 000 Ft',
    );
    expect(
      find.byKey(const ValueKey('manual-impact-limit-marker')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('manual-impact-overrun-hatch')),
      findsOneWidget,
    );
  });

  testWidgets('normal expense impact paints a full-width budget bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ManualTransactionEditor.create(
          repository: _FakeManualRepository(),
          categories: categories,
          direction: LedgerDirection.expense,
          impactRepository: const _FakeImpactRepository(
            categoryActualScaled100: 4800000,
            categoryLimitScaled100: 8000000,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('manual-amount-field')),
      '8 500',
    );
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
      '23 500 Ft',
    );
    final bar = tester.getRect(
      find.byKey(const ValueKey('manual-impact-budget-bar')),
    );
    expect(bar.height, 14);
    expect(bar.width, greaterThan(250));
    expect(
      find.byKey(const ValueKey('manual-impact-limit-marker')),
      findsNothing,
    );
    expect(find.text('Marad'), findsOneWidget);
  });

  testWidgets('missing category limit has no fictional budget bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ManualTransactionEditor.create(
          repository: _FakeManualRepository(),
          categories: categories,
          direction: LedgerDirection.expense,
          impactRepository: const _FakeImpactRepository(
            categoryLimitScaled100: null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('manual-quick-1000')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('A tranzakció hatása'),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Ehhez a kategóriához nincs havi keret.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('manual-impact-budget-bar')),
      findsNothing,
    );
  });

  testWidgets('partner searches start unfocused in both picker presentations', (
    tester,
  ) async {
    final preferences = _MemoryEditorPreferencesStore();
    await tester.pumpWidget(
      MaterialApp(
        home: ManualTransactionEditor.create(
          repository: _FakeManualRepository(),
          categories: categories,
          direction: LedgerDirection.expense,
          preferencesStore: preferences,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('manual-partner-field')));
    await tester.pumpAndSettle();
    var search = tester.widget<TextField>(
      find.byKey(const ValueKey('manual-partner-search')),
    );
    expect(search.focusNode?.hasFocus, isFalse);
    await tester.tap(find.byKey(const ValueKey('manual-partner-search')));
    await tester.pump();
    search = tester.widget<TextField>(
      find.byKey(const ValueKey('manual-partner-search')),
    );
    expect(search.focusNode?.hasFocus, isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('manual-partner-presentation-toggle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('manual-partner-dropdown-anchor')),
    );
    await tester.pumpAndSettle();
    search = tester.widget<TextField>(
      find.byKey(const ValueKey('manual-partner-search')),
    );
    expect(search.focusNode?.hasFocus, isFalse);
    await tester.tap(find.byKey(const ValueKey('manual-partner-search')));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('manual-partner-search')),
          )
          .focusNode
          ?.hasFocus,
      isTrue,
    );
  });

  testWidgets(
    'inline selectors push editor fields down, close one another and retain the draft',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final preferences = _MemoryEditorPreferencesStore()
        ..value = const ManualTransactionEditorPreferences(
          layout: ManualTransactionEditorLayout.hero,
          partnerPickerPresentation: ManualPartnerPickerPresentation.dropdown,
        );
      await tester.pumpWidget(
        MaterialApp(
          home: ManualTransactionEditor.create(
            repository: _FakeManualRepository(),
            categories: categories,
            direction: LedgerDirection.expense,
            preferencesStore: preferences,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('manual-amount-field')),
        '8 500',
      );
      final dateBefore = tester.getTopLeft(
        find.byKey(const ValueKey('manual-date-field')),
      );

      await tester.tap(
        find.byKey(const ValueKey('manual-category-dropdown-anchor')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('manual-inline-picker-panel')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('manual-category-search')),
            )
            .focusNode
            ?.hasFocus,
        isFalse,
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('manual-date-field'))).dy,
        greaterThan(dateBefore.dy),
      );
      expect(
        find.byKey(const ValueKey('manual-inline-picker-selected-check')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('manual-partner-dropdown-anchor')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('manual-category-search')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('manual-partner-search')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('manual-partner-search')),
            )
            .focusNode
            ?.hasFocus,
        isFalse,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('manual-amount-field')),
            )
            .controller
            ?.text,
        '8 500',
      );
    },
  );

  testWidgets('editor CTA group ends exactly at the safe-area edge', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: ManualTransactionEditor.create(
          repository: _FakeManualRepository(),
          categories: categories,
          direction: LedgerDirection.expense,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cancel = tester.getRect(
      find.byKey(const ValueKey('manual-cancel-button')),
    );
    final save = tester.getRect(
      find.byKey(const ValueKey('manual-save-button')),
    );
    expect(cancel.width, 104);
    expect(save.width, 120);
    expect(save.left - cancel.right, 12);
    expect(save.right, closeTo(370, .01));
    // With no system inset in this test view, the actual button body ends at
    // the viewport edge. SafeArea is the sole owner of a real device inset.
    expect(save.bottom, closeTo(844, .01));
  });

  testWidgets('footer lets the CTA shadow paint through the bottom safe area', (
    tester,
  ) async {
    final view = tester.view;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(390, 844);
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
    final previousDisableShadows = debugDisableShadows;
    debugDisableShadows = false;
    final shadows = DashboardShadowStyleController()
      ..select(DashboardShadowStyle.current);
    addTearDown(shadows.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(bottom: 24),
            viewPadding: const EdgeInsets.only(bottom: 24),
          ),
          child: child!,
        ),
        home: DashboardShadowStyleScope(
          controller: shadows,
          child: ManualTransactionEditor.create(
            repository: _FakeManualRepository(),
            categories: categories,
            direction: LedgerDirection.expense,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final save = tester.getRect(
      find.byKey(const ValueKey('manual-save-button')),
    );
    final cancel = tester.getRect(
      find.byKey(const ValueKey('manual-cancel-button')),
    );
    expect(save.bottom, closeTo(820, .01));
    expect(cancel.bottom, closeTo(820, .01));

    // The current depth profile has a downward card-foot shadow. Sampling in
    // the positive safe inset proves that the paint escaped the button's Ink
    // layer; the preceding implementation returned the untouched white
    // footer pixel here because _RenderInkFeatures clipped it to button size.
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('manual-editor-visual-boundary')),
    );
    final image = (await tester.runAsync(
      () => boundary.toImage(pixelRatio: 1),
    ))!;
    try {
      final bytes = (await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!.buffer.asUint8List();
      int luminanceAt(double x, double y) {
        final pixelX = x.floor().clamp(0, image.width - 1);
        final pixelY = y.floor().clamp(0, image.height - 1);
        final index = (pixelY * image.width + pixelX) * 4;
        return bytes[index] + bytes[index + 1] + bytes[index + 2];
      }

      final sampleY = save.bottom + 2;
      final background = luminanceAt(12, sampleY);
      expect(luminanceAt(cancel.center.dx, sampleY), lessThan(background));
      expect(luminanceAt(save.center.dx, sampleY), lessThan(background));
    } finally {
      image.dispose();
    }
    await expectLater(
      find.byKey(const ValueKey('manual-editor-visual-boundary')),
      matchesGoldenFile('../../goldens/manual_transaction_editor_footer.png'),
    );
    // TestWidgets verifies painting globals before addTearDown callbacks run.
    // Restore explicitly once both the pixel inspection and golden capture
    // have consumed the enabled shadow rendering.
    debugDisableShadows = previousDisableShadows;
  });

  for (final direction in LedgerDirection.values) {
    for (final profile in FluviDirectionColorProfile.values) {
      testWidgets(
        'hero uses the dedicated ${direction.name}/${profile.name} artwork',
        (tester) async {
          final tuning = ValueNotifier(
            DashboardHeaderVisualTuning.defaults().copyWith(
              globalAppearance: const FluviGlobalAppearance.defaults().copyWith(
                directionColorProfile: profile,
              ),
            ),
          );
          addTearDown(tuning.dispose);
          await tester.pumpWidget(
            MaterialApp(
              home: ManualTransactionEditor.create(
                repository: _FakeManualRepository(),
                categories: categories,
                direction: direction,
                headerVisualTuning: tuning,
              ),
            ),
          );
          await tester.pumpAndSettle();

          final image = tester.widget<Image>(
            find.byKey(
              ValueKey('manual-hero-artwork-${direction.name}-${profile.name}'),
            ),
          );
          expect(
            (image.image as AssetImage).assetName,
            'assets/fluvi/manual_transaction_hero/'
            '${direction == LedgerDirection.income ? 'income' : 'expense'}_${profile.name}.png',
          );
        },
      );
    }
  }

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
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
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
      expect(find.text('Közlekedés'), findsOneWidget);
    },
  );

  testWidgets(
    'category edit preserves the transaction selection and refreshes its row',
    (tester) async {
      final repository = _FakeManualRepository();
      final preferences = _MemoryEditorPreferencesStore()
        ..value = const ManualTransactionEditorPreferences(
          layout: ManualTransactionEditorLayout.hero,
          partnerPickerPresentation: ManualPartnerPickerPresentation.dropdown,
        );
      final categoryRepository = _FakeCategoryRepository(
        categories: categories,
        onUpdated: (category) {
          if (category.id != 'food') return;
          repository.partner = PartnerDirectoryEntry(
            partnerId: repository.partner.partnerId,
            displayName: repository.partner.displayName,
            originalName: repository.partner.originalName,
            defaultCategoryId: category.id,
            defaultCategoryName: category.name,
            categoryColorId: category.colorId,
            categoryIconId: category.iconId,
            isUncategorized: category.isSystemUncategorized,
            searchNames: repository.partner.searchNames,
          );
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ManualTransactionEditor.create(
            repository: repository,
            categories: categories,
            categoryRepository: categoryRepository,
            direction: LedgerDirection.expense,
            preferencesStore: preferences,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('manual-amount-field')),
        '1 000',
      );
      await tester.tap(
        find.byKey(const ValueKey('manual-partner-dropdown-anchor')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('manual-partner-partner-1')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('manual-category-dropdown-anchor')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('manual-category-shopping')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('manual-category-shopping')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('manual-category-dropdown-anchor')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('manual-category-edit-uncategorized')),
        findsNothing,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('manual-category-edit-food')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('manual-category-edit-food')));
      await tester.pumpAndSettle();
      expect(find.text('Kategória szerkesztése'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('category-editor-name-input')),
        'Friss élelmiszer',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('category-editor-save')),
      );
      await tester.tap(find.byKey(const ValueKey('category-editor-save')));
      await tester.pumpAndSettle();

      expect(categoryRepository.updated?.id, 'food');
      expect(categoryRepository.updated?.name, 'Friss élelmiszer');
      // Editing a different row never selects it: the existing partner's
      // entry override (shopping) remains the draft category assignment.
      expect(find.text('Vásárlás'), findsOneWidget);

      // Category metadata is also part of the partner directory rows. The
      // directory revision must evict the closed list's cache before reopen.
      await tester.tap(
        find.byKey(const ValueKey('manual-partner-dropdown-anchor')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Élelmiszer'), findsNothing);
      expect(find.text('Friss élelmiszer'), findsWidgets);
      await tester.tap(
        find.byKey(const ValueKey('manual-partner-dropdown-anchor')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('manual-category-dropdown-anchor')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Friss élelmiszer'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('manual-category-dropdown-anchor')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('manual-save-button')));
      await tester.pumpAndSettle();
      expect(
        repository.lastCategorySelection?.mode,
        ManualCategoryAssignmentMode.entryOverride,
      );
      expect(repository.lastCategorySelection?.categoryId, 'shopping');
    },
  );

  testWidgets(
    'editor uses borderless reference rows and expands the in-place note',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ManualTransactionEditor.create(
            repository: _FakeManualRepository(),
            categories: categories,
            direction: LedgerDirection.expense,
            impactRepository: const _FakeImpactRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Összeg'), findsOneWidget);
      expect(find.text('További adatok'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is InputDecorator &&
              widget.decoration.border is OutlineInputBorder,
        ),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('manual-date-field')), findsOneWidget);
      expect(find.byKey(const ValueKey('manual-time-field')), findsOneWidget);

      final compactHeight = tester
          .getSize(find.byKey(const ValueKey('manual-note-field')))
          .height;
      await tester.enterText(
        find.byKey(const ValueKey('manual-note-field')),
        'Első sor\nMásodik sor\nHarmadik sor',
      );
      await tester.pump();
      expect(
        tester.getSize(find.byKey(const ValueKey('manual-note-field'))).height,
        greaterThan(compactHeight),
      );
    },
  );

  testWidgets('hero income editor visual reference', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeManualRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ManualTransactionEditor.create(
          repository: repository,
          categories: categories,
          direction: LedgerDirection.income,
          preferencesStore: _MemoryEditorPreferencesStore(),
          impactRepository: const _FakeImpactRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('manual-amount-field')),
      '8 500',
    );
    await tester.tap(find.byKey(const ValueKey('manual-partner-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(repository.partner.displayName));
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

  testWidgets('expense overrun impact visual reference', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: ManualTransactionEditor.create(
          repository: _FakeManualRepository(),
          categories: categories,
          direction: LedgerDirection.expense,
          impactRepository: const _FakeImpactRepository(
            categoryActualScaled100: 0,
            categoryLimitScaled100: 1089464,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('manual-amount-field')),
      '30 000',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('manual-impact-budget-bar')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('manual-impact-value')))
          .data,
      '19 105,36 Ft',
    );
    expect(
      find.text('Havi keret: 10 894,64 Ft · Mentés után elköltve: 30 000 Ft'),
      findsOneWidget,
    );

    await expectLater(
      find.byKey(const ValueKey('manual-editor-visual-boundary')),
      matchesGoldenFile(
        '../../goldens/manual_transaction_editor_expense_overrun.png',
      ),
    );
  });

  testWidgets('normal expense impact visual reference', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: ManualTransactionEditor.create(
          repository: _FakeManualRepository(),
          categories: categories,
          direction: LedgerDirection.expense,
          impactRepository: const _FakeImpactRepository(
            categoryActualScaled100: 4800000,
            categoryLimitScaled100: 8000000,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('manual-amount-field')),
      '8 500',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('manual-impact-budget-bar')),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    await expectLater(
      find.byKey(const ValueKey('manual-editor-visual-boundary')),
      matchesGoldenFile(
        '../../goldens/manual_transaction_editor_expense_normal.png',
      ),
    );
  });

  testWidgets('partner dropdown opens without a keyboard visual reference', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final preferences = _MemoryEditorPreferencesStore()
      ..value = const ManualTransactionEditorPreferences(
        layout: ManualTransactionEditorLayout.hero,
        partnerPickerPresentation: ManualPartnerPickerPresentation.dropdown,
      );
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('manual-partner-dropdown-visual-boundary'),
        child: MaterialApp(
          home: ManualTransactionEditor.create(
            repository: _FakeManualRepository(),
            categories: categories,
            direction: LedgerDirection.expense,
            preferencesStore: preferences,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('manual-partner-dropdown-anchor')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('manual-partner-search')),
          )
          .focusNode
          ?.hasFocus,
      isFalse,
    );

    await expectLater(
      find.byKey(const ValueKey('manual-partner-dropdown-visual-boundary')),
      matchesGoldenFile(
        '../../goldens/manual_transaction_partner_dropdown_unfocused.png',
      ),
    );
  });

  testWidgets('category dropdown has the shared in-flow visual treatment', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('manual-category-dropdown-visual-boundary'),
        child: MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: CategoryDropdown(
                categories: categories,
                selectedCategoryId: 'food',
                inline: true,
                expanded: true,
                onExpandedChanged: (_) {},
                onSelected: (_) {},
                onCreate: () async {},
                onEdit: (_) async {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey('manual-category-dropdown-visual-boundary')),
      matchesGoldenFile(
        '../../goldens/manual_transaction_category_dropdown_inline.png',
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
  _FakeCategoryRepository({
    Iterable<FluviCategory> categories = const [],
    this.onUpdated,
  }) {
    for (final category in categories) {
      _categories[category.id] = category;
    }
  }

  final _categories = <String, FluviCategory>{};
  final ValueChanged<FluviCategory>? onUpdated;
  FluviCategory? created;
  FluviCategory? updated;

  @override
  Future<FluviCategory> createCategory({
    required String name,
    required String colorId,
    required String iconId,
  }) async {
    final category = FluviCategory(
      id: 'created-category',
      name: name,
      colorId: colorId,
      iconId: iconId,
      isSystemUncategorized: false,
      createdAtUtcMs: 1,
      updatedAtUtcMs: 1,
    );
    _categories[category.id] = category;
    return created = category;
  }

  @override
  Future<void> deleteCategory(String id) async {}

  @override
  Future<List<FluviCategory>> getCategories() async =>
      _categories.values.toList(growable: false);

  @override
  Future<FluviCategory?> getCategoryById(String id) async => _categories[id];

  @override
  Future<FluviCategory> updateCategory({
    required String id,
    required String name,
    required String colorId,
    required String iconId,
  }) async {
    final previous = _categories[id];
    final category = FluviCategory(
      id: id,
      name: name,
      colorId: colorId,
      iconId: iconId,
      isSystemUncategorized: previous?.isSystemUncategorized ?? false,
      createdAtUtcMs: previous?.createdAtUtcMs ?? 1,
      updatedAtUtcMs: (previous?.updatedAtUtcMs ?? 0) + 1,
    );
    _categories[id] = category;
    onUpdated?.call(category);
    return updated = category;
  }

  @override
  Stream<List<FluviCategory>> watchCategories() =>
      Stream.value(_categories.values.toList(growable: false));
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
  PartnerDirectoryEntry partner = const PartnerDirectoryEntry(
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
