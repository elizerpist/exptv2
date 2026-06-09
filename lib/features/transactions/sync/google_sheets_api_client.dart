import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;

import '../export/transaction_export_row.dart';

class GoogleSpreadsheetRef {
  const GoogleSpreadsheetRef({required this.id, required this.url});

  final String id;
  final String url;
}

abstract class GoogleSheetsGateway {
  Future<GoogleSpreadsheetRef> createSpreadsheet(String title);

  Future<Set<String>> listSheetTitles(String spreadsheetId);

  Future<void> addSheets({
    required String spreadsheetId,
    required Set<String> titles,
  });

  Future<void> clearValues({
    required String spreadsheetId,
    required String range,
  });

  Future<void> updateValues({
    required String spreadsheetId,
    required String range,
    required List<List<Object?>> values,
    required String valueInputOption,
  });
}

abstract class GoogleSheetsApiClientContract {
  Future<GoogleSpreadsheetRef> createSpreadsheet(String title);

  Future<void> ensureYearSheets({
    required String spreadsheetId,
    required Set<int> years,
  });

  Future<void> rewriteYear({
    required String spreadsheetId,
    required int year,
    required List<TransactionExportRow> rows,
  });
}

class GoogleSheetsApiClient implements GoogleSheetsApiClientContract {
  GoogleSheetsApiClient(http.Client client)
    : this.gateway(GoogleSheetsApiGateway(sheets.SheetsApi(client)));

  const GoogleSheetsApiClient.gateway(this._gateway);

  final GoogleSheetsGateway _gateway;

  static String yearTitle(int year) => year.toString();

  static String yearRange(String title) {
    final escapedTitle = title.replaceAll("'", "''");
    return "'$escapedTitle'!A1:J";
  }

  @override
  Future<GoogleSpreadsheetRef> createSpreadsheet(String title) {
    return _gateway.createSpreadsheet(title);
  }

  @override
  Future<void> ensureYearSheets({
    required String spreadsheetId,
    required Set<int> years,
  }) async {
    final expectedTitles = years.map(yearTitle).toSet();
    final existingTitles = await _gateway.listSheetTitles(spreadsheetId);
    final missingTitles = expectedTitles.difference(existingTitles);
    if (missingTitles.isEmpty) return;
    await _gateway.addSheets(
      spreadsheetId: spreadsheetId,
      titles: missingTitles,
    );
  }

  @override
  Future<void> rewriteYear({
    required String spreadsheetId,
    required int year,
    required List<TransactionExportRow> rows,
  }) async {
    final range = yearRange(yearTitle(year));
    final values = <List<Object?>>[
      TransactionExportRow.headers,
      for (final row in rows) row.values,
    ];

    await _gateway.clearValues(spreadsheetId: spreadsheetId, range: range);
    await _gateway.updateValues(
      spreadsheetId: spreadsheetId,
      range: range,
      values: values,
      valueInputOption: 'RAW',
    );
  }
}

class GoogleSheetsApiGateway implements GoogleSheetsGateway {
  const GoogleSheetsApiGateway(this._api);

  final sheets.SheetsApi _api;

  @override
  Future<GoogleSpreadsheetRef> createSpreadsheet(String title) async {
    final spreadsheet = await _api.spreadsheets.create(
      sheets.Spreadsheet(
        properties: sheets.SpreadsheetProperties(title: title),
      ),
      $fields: 'spreadsheetId,spreadsheetUrl',
    );
    final id = spreadsheet.spreadsheetId;
    final url = spreadsheet.spreadsheetUrl;
    if (id == null || url == null) {
      throw StateError('Google Sheets did not return spreadsheet metadata.');
    }
    return GoogleSpreadsheetRef(id: id, url: url);
  }

  @override
  Future<Set<String>> listSheetTitles(String spreadsheetId) async {
    final spreadsheet = await _api.spreadsheets.get(
      spreadsheetId,
      $fields: 'sheets(properties(title))',
    );
    return {
      for (final sheet in spreadsheet.sheets ?? const <sheets.Sheet>[])
        if (sheet.properties?.title != null) sheet.properties!.title!,
    };
  }

  @override
  Future<void> addSheets({
    required String spreadsheetId,
    required Set<String> titles,
  }) async {
    if (titles.isEmpty) return;
    await _api.spreadsheets.batchUpdate(
      sheets.BatchUpdateSpreadsheetRequest(
        requests: [
          for (final title in titles)
            sheets.Request(
              addSheet: sheets.AddSheetRequest(
                properties: sheets.SheetProperties(title: title),
              ),
            ),
        ],
      ),
      spreadsheetId,
    );
  }

  @override
  Future<void> clearValues({
    required String spreadsheetId,
    required String range,
  }) async {
    await _api.spreadsheets.values.clear(
      sheets.ClearValuesRequest(),
      spreadsheetId,
      range,
    );
  }

  @override
  Future<void> updateValues({
    required String spreadsheetId,
    required String range,
    required List<List<Object?>> values,
    required String valueInputOption,
  }) async {
    await _api.spreadsheets.values.update(
      sheets.ValueRange(range: range, majorDimension: 'ROWS', values: values),
      spreadsheetId,
      range,
      valueInputOption: valueInputOption,
    );
  }
}
