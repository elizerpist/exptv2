import 'dart:io';

import 'package:fluvi_codegraph/fluvi_codegraph.dart';
import 'package:scip_dart/src/gen/scip.pb.dart';
import 'package:test/test.dart';

void main() {
  group('SourceProvenanceVerifier', () {
    test(
        'fails closed when the checked-out source head differs from the claimed index head',
        () async {
      final verifier = SourceProvenanceVerifier(
        git: _FakeGit(<String, GitCommandResult>{
          'rev-parse HEAD': const GitCommandResult(0, 'different-head\n', ''),
          'diff --quiet': const GitCommandResult(0, '', ''),
          'diff --cached --quiet': const GitCommandResult(0, '', ''),
        }),
      );

      await expectLater(
        verifier.verify(
          sourceRoot: Directory.systemTemp,
          expectedHead: 'expected-head',
          sourceRef: 'refs/heads/example',
        ),
        throwsA(isA<SourceProvenanceException>()),
      );
    });

    test('rejects a source-root override that differs from the SCIP root',
        () async {
      final indexRoot =
          await Directory.systemTemp.createTemp('fluvi-codegraph-index-root-');
      final otherRoot =
          await Directory.systemTemp.createTemp('fluvi-codegraph-other-root-');
      addTearDown(() => indexRoot.delete(recursive: true));
      addTearDown(() => otherRoot.delete(recursive: true));
      final index = Index(
        metadata: Metadata(projectRoot: indexRoot.uri.toString()),
      );

      expect(
        () => SourceProvenanceVerifier().sourceRootForIndex(
          index,
          requestedSourceRoot: otherRoot,
        ),
        throwsA(isA<SourceProvenanceException>()),
      );
    });

    test('uses the exact head as the ref for a detached source checkout',
        () async {
      final verifier = SourceProvenanceVerifier(
        git: _FakeGit(<String, GitCommandResult>{
          'rev-parse HEAD': const GitCommandResult(0, 'head\n', ''),
          'diff --quiet': const GitCommandResult(0, '', ''),
          'diff --cached --quiet': const GitCommandResult(0, '', ''),
          'rev-parse head': const GitCommandResult(0, 'head\n', ''),
          'rev-parse head^': const GitCommandResult(0, 'parent\n', ''),
          'branch --show-current': const GitCommandResult(0, '\n', ''),
        }),
      );

      final verified = await verifier.verify(
        sourceRoot: Directory.systemTemp,
        expectedHead: 'head',
        sourceRef: 'head',
      );

      expect(verified.sourceWorktreeRef, 'DETACHED');
      expect(await verifier.currentBranch(Directory.systemTemp), 'head');
    });
  });

  group('GraphArtifactReader', () {
    test(
        'queries class family, production references, and test references from artifacts',
        () async {
      final root =
          await Directory.systemTemp.createTemp('fluvi-codegraph-query-');
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

      final result = await GraphArtifactReader(root).query('Sample');

      expect(result.symbol.rawSymbol, 'raw-class');
      expect(result.familyMembers, contains('raw-ctor'));
      expect(result.productionReferences.single.file, 'lib/use.dart');
      expect(result.testReferences.single.file, 'test/use_test.dart');
    });
  });
}

class _FakeGit implements GitRunner {
  _FakeGit(this._results);

  final Map<String, GitCommandResult> _results;

  @override
  Future<GitCommandResult> run(
      Directory workingDirectory, List<String> arguments) async {
    return _results[arguments.join(' ')] ??
        const GitCommandResult(1, '', 'missing fake response');
  }
}
