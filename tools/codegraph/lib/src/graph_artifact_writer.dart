import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'changed_impact.dart';
import 'graph_models.dart';

class GraphArtifactDescription {
  const GraphArtifactDescription({
    required this.name,
    required this.storage,
    required this.recordCount,
    required this.paths,
    required this.byteCount,
  });

  final String name;
  final String storage;
  final int recordCount;
  final List<String> paths;
  final int byteCount;

  Map<String, Object> toJson() => <String, Object>{
        'name': name,
        'storage': storage,
        'record_count': recordCount,
        'paths': paths,
        'byte_count': byteCount,
      };
}

class GraphWriteResult {
  const GraphWriteResult(this.artifacts);

  final List<GraphArtifactDescription> artifacts;
}

/// Canonical JSON writer. It measures a full payload before electing sharding.
class GraphArtifactWriter {
  GraphArtifactWriter(
      {this.shardThresholdBytes = 2 * 1024 * 1024,
      this.recordsPerShard = 2000});

  final int shardThresholdBytes;
  final int recordsPerShard;

  final JsonEncoder _prettyJson = const JsonEncoder.withIndent('  ');

  Future<GraphWriteResult> write({
    required GraphSnapshot graph,
    required GraphProvenance provenance,
    required ChangedImpact changedImpact,
    required Directory outputDirectory,
  }) async {
    await outputDirectory.create(recursive: true);
    await _clearManagedOutputs(outputDirectory);

    final artifacts = <GraphArtifactDescription>[];
    artifacts.add(
      await _writeDataset(
        outputDirectory: outputDirectory,
        name: 'symbols',
        records: graph.symbols.map((symbol) => symbol.toJson()).toList(),
        keyOf: (record) => record['raw_symbol']! as String,
      ),
    );
    artifacts.add(
      await _writeDataset(
        outputDirectory: outputDirectory,
        name: 'refs',
        records:
            graph.references.map((reference) => reference.toJson()).toList(),
        keyOf: (record) => record['target_symbol']! as String,
      ),
    );
    artifacts.add(
      await _writeDataset(
        outputDirectory: outputDirectory,
        name: 'edges',
        records: graph.edges.map((edge) => edge.toJson()).toList(),
        keyOf: (record) => record['to']! as String,
      ),
    );

    final changedImpactFile =
        File('${outputDirectory.path}/changed-impact.json');
    final changedImpactBytes =
        await _writePrettyJson(changedImpactFile, changedImpact.toJson());
    artifacts.add(
      GraphArtifactDescription(
        name: 'changed-impact',
        storage: 'json',
        recordCount: changedImpact.directReferenceConsumers.length,
        paths: const <String>['changed-impact.json'],
        byteCount: changedImpactBytes,
      ),
    );

    final manifest = <String, Object?>{
      ...provenance.toJson(),
      'graph_artifact_commit_relation':
          'The Git commit containing this graph may differ from source_head; '
              'source_head is the indexed application source.',
      'artifacts': artifacts.map((artifact) => artifact.toJson()).toList(),
    };
    await _writePrettyJson(
        File('${outputDirectory.path}/manifest.json'), manifest);
    return GraphWriteResult(
        List<GraphArtifactDescription>.unmodifiable(artifacts));
  }

  Future<void> _clearManagedOutputs(Directory outputDirectory) async {
    const files = <String>[
      'manifest.json',
      'symbols.json',
      'symbols.index.json',
      'refs.json',
      'refs.index.json',
      'edges.json',
      'edges.index.json',
      'changed-impact.json',
    ];
    for (final name in files) {
      final file = File('${outputDirectory.path}/$name');
      if (await file.exists()) {
        await file.delete();
      }
    }
    for (final name in const <String>['symbols', 'refs', 'edges']) {
      final directory = Directory('${outputDirectory.path}/$name');
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  }

  Future<GraphArtifactDescription> _writeDataset({
    required Directory outputDirectory,
    required String name,
    required List<Map<String, Object?>> records,
    required String Function(Map<String, Object?> record) keyOf,
  }) async {
    final monolithic = '${_prettyJson.convert(records)}\n';
    final monolithicBytes = utf8.encode(monolithic);
    if (monolithicBytes.length <= shardThresholdBytes) {
      final path = '$name.json';
      await File('${outputDirectory.path}/$path')
          .writeAsBytes(monolithicBytes, flush: true);
      return GraphArtifactDescription(
        name: name,
        storage: 'json',
        recordCount: records.length,
        paths: <String>[path],
        byteCount: monolithicBytes.length,
      );
    }

    final shardDirectory = Directory('${outputDirectory.path}/$name');
    await shardDirectory.create(recursive: true);
    final shards = <Map<String, Object>>[];
    var byteCount = 0;
    for (var start = 0, part = 0;
        start < records.length;
        start += recordsPerShard, part++) {
      final end = (start + recordsPerShard).clamp(0, records.length);
      final text =
          '${records.sublist(start, end).map(jsonEncode).join('\n')}\n';
      final bytes = utf8.encode(text);
      final relativePath =
          '$name/part-${part.toString().padLeft(3, '0')}.jsonl';
      await File('${outputDirectory.path}/$relativePath')
          .writeAsBytes(bytes, flush: true);
      byteCount += bytes.length;
      shards.add(<String, Object>{
        'path': relativePath,
        'record_count': end - start,
        'first_key': keyOf(records[start]),
        'last_key': keyOf(records[end - 1]),
        'sha256': sha256.convert(bytes).toString(),
      });
    }
    final indexPath = '$name.index.json';
    final indexBytes = await _writePrettyJson(
      File('${outputDirectory.path}/$indexPath'),
      <String, Object>{
        'schema_version': 1,
        'record_count': records.length,
        'shards': shards,
      },
    );
    return GraphArtifactDescription(
      name: name,
      storage: 'jsonl_shards',
      recordCount: records.length,
      paths: <String>[
        indexPath,
        ...shards.map((shard) => shard['path']! as String)
      ],
      byteCount: byteCount + indexBytes,
    );
  }

  Future<int> _writePrettyJson(File file, Object value) async {
    final bytes = utf8.encode('${_prettyJson.convert(value)}\n');
    await file.writeAsBytes(bytes, flush: true);
    return bytes.length;
  }
}
