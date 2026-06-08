import 'package:exptv2/features/transactions/export/transaction_export_row.dart';
import 'package:exptv2/features/transactions/sync/google_sheets_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds yearly sheet title and update range', () {
    expect(GoogleSheetsApiClient.yearTitle(2026), '2026');
    expect(GoogleSheetsApiClient.yearRange('2026'), "'2026'!A1:J");
  });

  test('rewriteYear clears and writes headers plus transaction rows', () async {
    final gateway = FakeSheetsGateway();
    final client = GoogleSheetsApiClient.gateway(gateway);

    await client.rewriteYear(
      spreadsheetId: 'sheet-id',
      year: 2026,
      rows: const [
        TransactionExportRow(
          id: 1,
          date: '2026.06.08',
          time: '09:15',
          type: 'expense',
          amount: '-1290',
          merchant: 'Corner Shop',
          userAssignedName: 'Kávé',
          categoryId: 6,
          category: 'Élelmiszer',
          recurring: false,
        ),
      ],
    );

    expect(gateway.clearedRanges, ["'2026'!A1:J"]);
    expect(gateway.updatedRanges, ["'2026'!A1:J"]);
    expect(gateway.valueInputOptions, ['RAW']);
    expect(gateway.updatedValues, [
      TransactionExportRow.headers,
      [
        1,
        '2026.06.08',
        '09:15',
        'expense',
        '-1290',
        'Corner Shop',
        'Kávé',
        6,
        'Élelmiszer',
        false,
      ],
    ]);
  });
}

class FakeSheetsGateway implements GoogleSheetsGateway {
  final clearedRanges = <String>[];
  final updatedRanges = <String>[];
  final valueInputOptions = <String>[];
  List<List<Object?>>? updatedValues;

  @override
  Future<GoogleSpreadsheetRef> createSpreadsheet(String title) async {
    return const GoogleSpreadsheetRef(
      id: 'sheet-id',
      url: 'https://docs.google.com/spreadsheets/d/sheet-id/edit',
    );
  }

  @override
  Future<Set<String>> listSheetTitles(String spreadsheetId) async {
    return const <String>{};
  }

  @override
  Future<void> addSheets({
    required String spreadsheetId,
    required Set<String> titles,
  }) async {}

  @override
  Future<void> clearValues({
    required String spreadsheetId,
    required String range,
  }) async {
    clearedRanges.add(range);
  }

  @override
  Future<void> updateValues({
    required String spreadsheetId,
    required String range,
    required List<List<Object?>> values,
    required String valueInputOption,
  }) async {
    updatedRanges.add(range);
    valueInputOptions.add(valueInputOption);
    updatedValues = values;
  }
}
