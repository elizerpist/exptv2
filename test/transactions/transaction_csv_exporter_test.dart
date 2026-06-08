import 'package:exptv2/features/transactions/export/transaction_csv_exporter.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds transaction csv with stable header and category names', () {
    final csv = const TransactionCsvExporter().buildCsv(
      transactions: [
        TransactionRecord.fromMap({
          'id': 1,
          'date': '2026.06.08',
          'time': '09:15',
          'merchant': 'Corner Shop',
          'amount': -1290,
          'userAssignedName': 'Kávé',
          'transactionCategoryID': 6,
          'address': 'Budapest',
          'latitude': 47.5,
          'longitude': 19.1,
        }),
      ],
      categories: [_category(id: 6, name: 'Élelmiszer')],
    );

    expect(
      csv,
      'id,date,time,type,amount,merchant,userAssignedName,categoryId,category,address,latitude,longitude,recurring\n'
      '1,2026.06.08,09:15,expense,-1290,Corner Shop,Kávé,6,Élelmiszer,Budapest,47.5,19.1,false\n',
    );
  });

  test('escapes commas quotes and newlines for spreadsheet import', () {
    final csv = const TransactionCsvExporter().buildCsv(
      transactions: [
        TransactionRecord.fromMap({
          'id': 2,
          'date': '2026.06.08',
          'time': '10:00',
          'merchant': 'Bolt, "Market"',
          'amount': 5000,
          'userAssignedName': 'Line\nBreak',
          'transactionCategoryID': 7,
          'recurringRuleId': 12,
        }),
      ],
      categories: [_category(id: 7, name: 'Fizetés, bónusz')],
    );

    expect(
      csv,
      contains(
        '2,2026.06.08,10:00,income,5000,"Bolt, ""Market""","Line\nBreak",7,"Fizetés, bónusz",,,,true',
      ),
    );
  });
}

TransactionCategory _category({required int id, required String name}) {
  return TransactionCategory(
    transactionCategoryID: id,
    name: name,
    type: 'kiadás',
    colorSlot: null,
    iconSlot: null,
    backgroundColor: '#f3f4f6',
    icon: null,
    notification: null,
    hasLimit: false,
    limitAmount: 0,
    alertActive: false,
    isCustomIcon: false,
    originalIcon: null,
  );
}
