import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/automation/data/method_channel_automation_repository.dart';
import 'package:fluvi/features/automation/presentation/recurring_transaction_wizard_page.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/manual_transactions/domain/manual_transaction_models.dart';
import 'package:fluvi/features/manual_transactions/domain/manual_transaction_repository.dart';
import 'package:fluvi/features/manual_transactions/presentation/partner_selector.dart';

void main() {
  const automation = MethodChannel('test/recurring-partner-avatar');

  setUpAll(() => PreparedVectorAssetAtlas.instance.prepare());

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(automation, (call) async {
          if (call.method == 'listProfiles') return const <Object>[];
          throw PlatformException(code: 'unexpected', message: call.method);
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(automation, null);
  });

  testWidgets(
    'recurring wizard snapshots the dashboard direction and never offers a second direction picker',
    (tester) async {
      for (final direction in LedgerDirection.values) {
        Map<Object?, Object?>? savedArguments;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(automation, (call) async {
              if (call.method == 'listProfiles') return const <Object>[];
              if (call.method == 'listRecurrenceOccurrences') {
                return const <Object>[];
              }
              if (call.method == 'createRecurringRule') {
                savedArguments = call.arguments! as Map<Object?, Object?>;
                return <String, Object?>{
                  'ruleId': 'rule-${direction.name}',
                  'name': 'Rögzített irány',
                  'partnerId': 'partner-spotify',
                  'categoryId': 'shopping',
                  'categoryAssignmentMode': 'partnerDefault',
                  'direction': direction.name,
                  'note': null,
                  'triggerKind': 'time',
                  'amountPolicy': 'fixed',
                  'amountScaled100': 1200000,
                  'dayOfMonth': 28,
                  'localTimeMinutes': 480,
                  'startLocalEpochDay': 20500,
                  'endLocalEpochDay': null,
                  'timezoneId': 'Europe/Budapest',
                  'isActive': true,
                  'ruleVersion': 1,
                };
              }
              throw PlatformException(code: 'unexpected', message: call.method);
            });
        await tester.pumpWidget(
          MaterialApp(
            home: RecurringTransactionWizardPage(
              repository: MethodChannelAutomationRepository(
                channel: automation,
              ),
              manualRepository: _PartnerRepository(),
              categories: <FluviCategory>[_category('shopping', 'Vásárlás')],
              initialDirection: direction,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            direction == LedgerDirection.income
                ? 'Új ismétlődő bevételi tranzakció'
                : 'Új ismétlődő kiadási tranzakció',
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (widget) => widget is DropdownButtonFormField<LedgerDirection>,
          ),
          findsNothing,
        );

        await tester.enterText(find.byType(TextField).first, 'Rögzített irány');
        await tester.tap(find.text('Partner kiválasztása'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Spotify'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Következő'));
        await tester.pumpAndSettle();
        expect(find.text('2 / 5 · Összeg beállítása'), findsOneWidget);
        await tester.enterText(
          find.byWidgetPredicate(
            (widget) =>
                widget is TextField && widget.decoration?.labelText == 'Összeg',
          ),
          '12000',
        );
        await tester.pump();
        await tester.tap(find.text('Következő'));
        await tester.pumpAndSettle();
        expect(find.text('3 / 5 · Gyakoriság és időzítés'), findsOneWidget);
        await tester.tap(find.text('Következő'));
        await tester.pumpAndSettle();
        expect(find.text('4 / 5 · Hogyan teljesüljön?'), findsOneWidget);
        await tester.tap(find.text('Következő'));
        await tester.pumpAndSettle();
        expect(find.text('5 / 5 · Ismétlődés áttekintése'), findsOneWidget);
        await tester.tap(find.text('Ismétlődés létrehozása'));
        await tester.pump();

        expect(savedArguments?['direction'], direction.name);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets(
    'recurring selected partner retains its catalog category avatar',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RecurringTransactionWizardPage(
            repository: MethodChannelAutomationRepository(channel: automation),
            manualRepository: _PartnerRepository(),
            categories: <FluviCategory>[
              _category('food', 'Élelmiszer'),
              _category('shopping', 'Vásárlás'),
            ],
            initialDirection: LedgerDirection.expense,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Partner kiválasztása'));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is PartnerCategoryAvatar &&
              widget.partner.categoryColorId == 'color_03' &&
              widget.partner.categoryIconId == 'icon_03',
        ),
        findsOneWidget,
        reason: 'The picker renders the partner default category icon.',
      );

      await tester.tap(find.text('Spotify'));
      await tester.pumpAndSettle();

      expect(find.text('Spotify'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is PartnerCategoryAvatar &&
              widget.partner.categoryColorId == 'color_03' &&
              widget.partner.categoryIconId == 'icon_03',
        ),
        findsOneWidget,
        reason:
            'The chosen recurring partner keeps its fetched visual snapshot; '
            'it does not rebuild as the former fixed storefront icon.',
      );
    },
  );

  testWidgets(
    'name-step input connection is replaced by decimal numeric amount input',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RecurringTransactionWizardPage(
            repository: MethodChannelAutomationRepository(channel: automation),
            manualRepository: _PartnerRepository(),
            categories: <FluviCategory>[_category('shopping', 'Vásárlás')],
            initialDirection: LedgerDirection.expense,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final name = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Megnevezés',
      );
      await tester.tap(name);
      await tester.enterText(name, 'Előfizetés');
      expect(
        (tester.testTextInput.setClientArgs!['inputType']
            as Map<String, dynamic>)['name'],
        'TextInputType.text',
      );

      await tester.tap(find.text('Partner kiválasztása'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spotify'));
      await tester.pumpAndSettle();

      // Reproduce a normal transition from a still active text connection.
      await tester.tap(name);
      await tester.pump();
      await tester.tap(find.text('Következő'));
      await tester.pump();

      final amount = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Összeg',
      );
      expect(amount, findsOneWidget);
      await tester.tap(amount);
      await tester.pump();
      final inputType =
          tester.testTextInput.setClientArgs!['inputType']
              as Map<String, dynamic>;
      expect(inputType['name'], 'TextInputType.number');
      expect(inputType['decimal'], isTrue);

      await tester.enterText(amount, '12.34');
      await tester.pump();
      await tester.tap(find.text('Következő'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Következő'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Következő'));
      await tester.pumpAndSettle();
      expect(find.text('Kiadás · 12.34 Ft'), findsOneWidget);
    },
  );
}

FluviCategory _category(String id, String name) => FluviCategory(
  id: id,
  name: name,
  colorId: 'color_02',
  iconId: 'icon_02',
  isSystemUncategorized: false,
  createdAtUtcMs: 0,
  updatedAtUtcMs: 0,
);

final class _PartnerRepository implements ManualTransactionRepository {
  static const PartnerDirectoryEntry _partner = PartnerDirectoryEntry(
    partnerId: 'partner-spotify',
    displayName: 'Spotify',
    originalName: 'SPOTIFY',
    defaultCategoryId: 'shopping',
    defaultCategoryName: 'Vásárlás',
    categoryColorId: 'color_03',
    categoryIconId: 'icon_03',
    isUncategorized: false,
    searchNames: <String>['Spotify', 'SPOTIFY'],
  );

  @override
  Future<List<PartnerDirectoryEntry>> listPartners() async => [_partner];

  @override
  Future<PartnerDirectoryEntry?> getPartnerById(String partnerId) async =>
      partnerId == _partner.partnerId ? _partner : null;

  @override
  Future<PartnerDirectoryEntry?> resolvePartner(String partnerId) =>
      getPartnerById(partnerId);

  @override
  Future<PartnerDirectoryEntry> updatePartner({
    required String partnerId,
    required String? displayNameOverride,
    required String defaultCategoryId,
  }) async => _partner;

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
  }) => throw UnimplementedError();

  @override
  Future<LedgerEntryDetail> getLedgerEntryById(String entryId) =>
      throw UnimplementedError();

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
  }) => throw UnimplementedError();
}
