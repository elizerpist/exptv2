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
