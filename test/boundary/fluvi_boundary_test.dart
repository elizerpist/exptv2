import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps the Flutter consumer separate from the Fluvi Room core', () {
    final root = Directory.current;
    final coreSource = _sourceText(root, 'android/fluvi-core');
    final flutterSource = _sourceText(root, 'lib');
    final pubspec = File('${root.path}/pubspec.yaml').readAsStringSync();
    final assetDirectories = RegExp(
      r'^\s*-\s+(assets/[^\s#]+)',
      multiLine: true,
    ).allMatches(pubspec).map((match) => match.group(1)!).toList();

    final boundaryScript = File(
      '${root.path}/scripts/verify-fluvi-boundaries.sh',
    );

    expect(boundaryScript.existsSync(), isTrue);
    expect(coreSource, isNot(contains('dev.flutter')));
    expect(coreSource, isNot(contains('io.flutter')));
    expect(coreSource, isNot(contains('com.android.application')));
    expect(coreSource, contains('internal abstract class FluviDatabase'));
    expect(coreSource, contains('internal object FluviDatabaseFactory'));
    expect(coreSource, contains('object FluviCoreFactory'));
    expect(flutterSource, isNot(contains('FluviCoreFactory')));
    expect(flutterSource, isNot(contains('androidx.room')));
    expect(flutterSource, isNot(contains('spendee')));
    expect(flutterSource, isNot(contains('exptv2')));
    expect(flutterSource, isNot(contains('repository')));
    expect(flutterSource, isNot(contains('query')));
    expect(assetDirectories, isNotEmpty);
    expect(assetDirectories, everyElement(startsWith('assets/fluvi/')));
    expect(
      assetDirectories,
      containsAll(<String>[
        'assets/fluvi/actions/',
        'assets/fluvi/brand/',
      ]),
    );
    expect(assetDirectories, isNot(contains('assets/fluvi/')));
    expect(pubspec, isNot(contains('http://')));
    expect(pubspec, isNot(contains('https://')));

    final boundaryResult = Process.runSync(
      'bash',
      [boundaryScript.path],
      workingDirectory: root.path,
    );
    expect(
      boundaryResult.exitCode,
      0,
      reason: boundaryResult.stderr.toString(),
    );
  });
}

String _sourceText(Directory root, String relativePath) {
  final directory = Directory('${root.path}/$relativePath');
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => !file.path.contains('${Platform.pathSeparator}build${Platform.pathSeparator}'))
      .where((file) => _isSourceFile(file.path))
      .map((file) => file.readAsStringSync())
      .join('\n');
}

bool _isSourceFile(String path) {
  return path.endsWith('.dart') ||
      path.endsWith('.kt') ||
      path.endsWith('.kts') ||
      path.endsWith('.java') ||
      path.endsWith('.xml');
}
