import 'dart:convert';
import 'dart:io';

import 'package:fluvi_codegraph/fluvi_codegraph.dart';
import 'package:scip_dart/src/gen/scip.pb.dart';
import 'package:test/test.dart';

const _symbol = 'scip-dart pub fluvi 0.1.0+1 lib/`changed.dart`/Changed#';

void main() {
  group('GraphArtifactWriter', () {
    test('writes byte-identical canonical outputs for the same graph',
        () async {
      final root =
          await Directory.systemTemp.createTemp('fluvi-codegraph-determinism-');
      addTearDown(() => root.delete(recursive: true));
      final graph = const ScipGraphExtractor().extract(_index());
      final provenance = const GraphProvenance(
        sourceHead: 'head',
        sourceParent: 'parent',
        sourceRef: 'refs/heads/example',
        scipDartVersion: '1.6.2',
        indexSha256: 'hash',
        documentCount: 2,
        occurrenceCount: 3,
        definedSymbolCount: 1,
      );
      final impact = const ChangedImpactBuilder().build(
        graph: graph,
        sourceHead: 'head',
        baseHead: 'parent',
        changedFiles: <String>['lib/changed.dart'],
      );

      final writer = GraphArtifactWriter(shardThresholdBytes: 1024 * 1024);
      final first = Directory('${root.path}/first');
      final second = Directory('${root.path}/second');
      await writer.write(
          graph: graph,
          provenance: provenance,
          changedImpact: impact,
          outputDirectory: first);
      await writer.write(
          graph: graph,
          provenance: provenance,
          changedImpact: impact,
          outputDirectory: second);

      expect(await _treeBytes(first), await _treeBytes(second));
      final manifest = jsonDecode(
        await File('${first.path}/manifest.json').readAsString(),
      ) as Map<String, dynamic>;
      expect(
        manifest['graph_artifact_commit_relation'],
        contains('may differ from source_head'),
      );
    });

    test(
        'measures output before deterministically sharding an oversized record set',
        () async {
      final root =
          await Directory.systemTemp.createTemp('fluvi-codegraph-shard-');
      addTearDown(() => root.delete(recursive: true));
      final graph = const ScipGraphExtractor().extract(_index());
      final provenance = const GraphProvenance(
        sourceHead: 'head',
        sourceParent: 'parent',
        sourceRef: 'refs/heads/example',
        scipDartVersion: '1.6.2',
        indexSha256: 'hash',
        documentCount: 2,
        occurrenceCount: 3,
        definedSymbolCount: 1,
      );
      final impact = const ChangedImpactBuilder().build(
        graph: graph,
        sourceHead: 'head',
        baseHead: 'parent',
        changedFiles: <String>['lib/changed.dart'],
      );

      await GraphArtifactWriter(shardThresholdBytes: 1).write(
        graph: graph,
        provenance: provenance,
        changedImpact: impact,
        outputDirectory: root,
      );

      expect(File('${root.path}/symbols.index.json').existsSync(), isTrue);
      expect(File('${root.path}/symbols/part-000.jsonl').existsSync(), isTrue);
      expect(File('${root.path}/symbols.json').existsSync(), isFalse);
      final index = jsonDecode(
              await File('${root.path}/symbols.index.json').readAsString())
          as Map<String, dynamic>;
      final firstShard =
          (index['shards'] as List<dynamic>).single as Map<String, dynamic>;
      expect(firstShard['first_key'], _symbol);
      expect(firstShard['last_key'], _symbol);

      final query = await GraphArtifactReader(root).query('Changed');
      expect(query.testReferences, hasLength(2));
      expect(
          query.testReferences
              .every((reference) => reference.file == 'test/changed_test.dart'),
          isTrue);
    });

    test('builds conservative changed impact without runtime-causality labels',
        () {
      final graph = const ScipGraphExtractor().extract(_index());
      final impact = const ChangedImpactBuilder().build(
        graph: graph,
        sourceHead: 'head',
        baseHead: 'parent',
        changedFiles: <String>['lib/changed.dart'],
      );

      expect(impact.candidateChangedSymbols.single.rawSymbol, _symbol);
      expect(
          impact.affectedTestLocations.single.file, 'test/changed_test.dart');
      expect(impact.affectedTestLocations.single.referenceCount, 2);
      expect(
          impact.affectedTestLocations.single.targetSymbols, <String>[_symbol]);
      final candidate =
          (impact.toJson()['candidate_changed_symbols']! as List<Object?>)
              .single;
      expect(candidate, _symbol);
      expect(jsonEncode(impact.toJson()), isNot(contains('CALL')));
      expect(jsonEncode(impact.toJson()), isNot(contains('DATA_FLOW')));
    });
  });
}

Future<Map<String, List<int>>> _treeBytes(Directory root) async {
  final files = <File>[];
  await for (final entity in root.list(recursive: true)) {
    if (entity is File) {
      files.add(entity);
    }
  }
  files.sort((left, right) => left.path.compareTo(right.path));
  return <String, List<int>>{
    for (final file in files)
      file.path.substring(root.path.length): await file.readAsBytes(),
  };
}

Index _index() {
  return Index(
    documents: <Document>[
      Document(
        relativePath: 'lib/changed.dart',
        language: 'Dart',
        symbols: <SymbolInformation>[
          SymbolInformation(
              symbol: _symbol, kind: SymbolInformation_Kind.Class),
        ],
        occurrences: <Occurrence>[
          Occurrence(
              range: <int>[0, 0, 0, 7],
              symbol: _symbol,
              symbolRoles: SymbolRole.Definition.value),
        ],
      ),
      Document(
        relativePath: 'test/changed_test.dart',
        language: 'Dart',
        occurrences: <Occurrence>[
          Occurrence(
              range: <int>[3, 4, 3, 11],
              symbol: _symbol,
              symbolRoles: SymbolRole.Test.value | SymbolRole.ReadAccess.value),
          Occurrence(
              range: <int>[4, 4, 4, 11],
              symbol: _symbol,
              symbolRoles: SymbolRole.Test.value | SymbolRole.ReadAccess.value),
        ],
      ),
    ],
  );
}
