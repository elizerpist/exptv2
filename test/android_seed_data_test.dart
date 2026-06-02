import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('android seed spans five years and bumps demo seed version', () {
    final source = File(
      'android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSeedData.kt',
    ).readAsStringSync();

    expect(source, contains('const val version = 2026060301'));
    expect(source, contains('private const val seedStartYear = 2021'));
    expect(source, contains('private const val seedStartMonth = 6'));
    expect(source, contains('private const val seedMonthCount = 61'));
    expect(source, contains('while (monthOffset < seedMonthCount)'));
  });
}
