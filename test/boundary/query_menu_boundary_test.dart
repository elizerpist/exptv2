import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Query Menu keeps one SQL owner and one reusable sheet boundary', () {
    final root = Directory.current;
    final querySource = _source(root, 'lib/features/dashboard/query');
    final sharedSheet = File(
      '${root.path}/lib/shared/presentation/fluvi_slide_up_sheet.dart',
    ).readAsStringSync();
    final coreRead = File(
      '${root.path}/android/fluvi-core/src/main/kotlin/com/fluvi/core/query/'
      'FluviLedgerReadService.kt',
    ).readAsStringSync();
    final querySheet = File(
      '${root.path}/lib/features/dashboard/query/presentation/query_menu_sheet.dart',
    ).readAsStringSync();

    expect(querySource, contains('CurrentLedgerQueryScope'));
    expect(querySource, isNot(contains('androidx.room')));
    expect(querySource, isNot(contains('FluviDatabase')));
    expect(sharedSheet, isNot(contains('features/dashboard/query')));
    expect(sharedSheet, isNot(contains('MethodChannel')));
    expect(coreRead, contains('suspend fun queryMenuFacets'));
    expect(coreRead, contains('private suspend fun where('));
    expect(querySheet, contains('CategoryVisualResolver.resolve'));
    expect(querySheet, isNot(contains('PartnerColorResolver')));
    expect(querySheet, isNot(contains('BottomSheet')));
  });
}

String _source(Directory root, String relative) =>
    Directory('${root.path}/$relative')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) {
          return file.path.endsWith('.dart');
        })
        .map((file) => file.readAsStringSync())
        .join('\n');
