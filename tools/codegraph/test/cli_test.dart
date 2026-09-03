import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('query command reports family and test references from graph artifacts',
      () async {
    final root = await Directory.systemTemp.createTemp('fluvi-codegraph-cli-');
    addTearDown(() => root.delete(recursive: true));
    await File('${root.path}/manifest.json')
        .writeAsString('{"schema_version":1}');
    await File('${root.path}/symbols.json').writeAsString(
      '[{"raw_symbol":"raw-class","human_name":"Sample","family_key":"raw-class"},'
      '{"raw_symbol":"raw-ctor","human_name":"<constructor>","family_key":"raw-class"}]',
    );
    await File('${root.path}/refs.json').writeAsString(
      '[{"target_symbol":"raw-class","file":"lib/use.dart","line":1,"column":2,"role":"read","is_test":false},'
      '{"target_symbol":"raw-ctor","file":"test/use_test.dart","line":3,"column":4,"role":"read","is_test":true}]',
    );
    await File('${root.path}/edges.json').writeAsString('[]');
    await File('${root.path}/changed-impact.json').writeAsString('{}');

    final result = await Process.run(
      Platform.resolvedExecutable,
      <String>[
        'run',
        'bin/fluvi_codegraph.dart',
        'query',
        '--graph',
        root.path,
        '--symbol',
        'Sample',
      ],
      workingDirectory: Directory.current.path,
    );

    expect(result.exitCode, 0, reason: result.stderr as String);
    expect(result.stdout, contains('REFERENCES'));
    expect(result.stdout, contains('FAMILY MEMBERS'));
    expect(result.stdout, contains('raw-ctor'));
    expect(result.stdout, contains('CONSUMER FILES'));
    expect(result.stdout, contains('TEST REFERENCES'));
    expect(result.stdout, contains('test/use_test.dart:3:4'));
  });
}
