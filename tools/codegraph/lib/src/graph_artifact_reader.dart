import 'dart:convert';
import 'dart:io';

import 'graph_models.dart';

class GraphArtifactReader {
  GraphArtifactReader(this.graphDirectory);

  final Directory graphDirectory;

  Future<GraphQueryResult> query(String symbolQuery) async {
    final symbols = (await _readDataset('symbols'))
        .map((record) => GraphSymbol.fromJson(record))
        .toList()
      ..sort((left, right) => left.rawSymbol.compareTo(right.rawSymbol));
    final symbolSnapshot = GraphSnapshot(
      symbols: symbols,
      references: const <GraphReference>[],
      edges: const <GraphEdge>[],
      statistics: const GraphStatistics(
        documentCount: 0,
        occurrenceCount: 0,
        definedSymbolCount: 0,
        repositoryDefinedSymbolCount: 0,
      ),
    );
    final symbol = symbolSnapshot.resolveSymbol(symbolQuery);
    if (symbol == null) {
      throw ArgumentError.value(
          symbolQuery, 'symbol', 'No unique graph symbol matches this query.');
    }
    final family = symbolSnapshot.familyFor(symbol.rawSymbol);
    final familyReferences = (await _readDataset('refs',
            keys: family.members.toSet()))
        .map(GraphReference.fromJson)
        .where((reference) => family.members.contains(reference.targetSymbol))
        .toList()
      ..sort((left, right) {
        final file = left.file.compareTo(right.file);
        if (file != 0) {
          return file;
        }
        final line = left.line.compareTo(right.line);
        return line != 0 ? line : left.column.compareTo(right.column);
      });
    return GraphQueryResult(
      symbol: symbol,
      familyMembers: family.members,
      productionReferences:
          familyReferences.where((reference) => !reference.isTest).toList(),
      testReferences:
          familyReferences.where((reference) => reference.isTest).toList(),
    );
  }

  Future<List<Map<String, Object?>>> _readDataset(
    String name, {
    Set<String>? keys,
  }) async {
    final monolithic = File('${graphDirectory.path}/$name.json');
    if (await monolithic.exists()) {
      return _decodeJsonList(await monolithic.readAsString());
    }
    final indexFile = File('${graphDirectory.path}/$name.index.json');
    if (!await indexFile.exists()) {
      throw FileSystemException(
          'No graph dataset found for $name', indexFile.path);
    }
    final index = _decodeMap(await indexFile.readAsString());
    final shards = index['shards'];
    if (shards is! List) {
      throw const FormatException('Malformed graph shard index.');
    }
    final records = <Map<String, Object?>>[];
    for (final shard in shards) {
      if (shard is! Map) {
        throw const FormatException('Malformed graph shard entry.');
      }
      final path = shard['path'];
      if (path is! String) {
        throw const FormatException('Graph shard entry is missing its path.');
      }
      final firstKey = shard['first_key'];
      final lastKey = shard['last_key'];
      if (keys != null &&
          firstKey is String &&
          lastKey is String &&
          !keys.any((key) =>
              key.compareTo(firstKey) >= 0 && key.compareTo(lastKey) <= 0)) {
        continue;
      }
      final lines = const LineSplitter()
          .convert(await File('${graphDirectory.path}/$path').readAsString());
      for (final line in lines) {
        if (line.isNotEmpty) {
          records.add(_decodeMap(line));
        }
      }
    }
    return records;
  }

  List<Map<String, Object?>> _decodeJsonList(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! List) {
      throw const FormatException('Graph dataset must be a JSON list.');
    }
    return decoded.map((record) {
      if (record is! Map) {
        throw const FormatException(
            'Graph dataset contains a non-object record.');
      }
      return Map<String, Object?>.from(record);
    }).toList();
  }

  Map<String, Object?> _decodeMap(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Graph JSON value must be an object.');
    }
    return Map<String, Object?>.from(decoded);
  }
}

String renderGraphQuery(GraphQueryResult result) {
  final consumerFiles = <String>{
    ...result.productionReferences.map((reference) => reference.file),
    ...result.testReferences.map((reference) => reference.file),
  }.toList()
    ..sort();
  final buffer = StringBuffer()
    ..writeln('SYMBOL')
    ..writeln(result.symbol.rawSymbol)
    ..writeln('DEFINITION')
    ..writeln(
        '${result.symbol.definitionFile ?? '-'}:${result.symbol.definitionRange?.startLine ?? '-'}')
    ..writeln('FAMILY MEMBERS');
  for (final member in result.familyMembers) {
    buffer.writeln(member);
  }
  buffer
    ..writeln('REFERENCES')
    ..writeln(
      'total=${result.productionReferences.length + result.testReferences.length} '
      'production=${result.productionReferences.length} tests=${result.testReferences.length}',
    )
    ..writeln('CONSUMER FILES');
  for (final file in consumerFiles) {
    buffer.writeln(file);
  }
  buffer.writeln('PRODUCTION REFERENCES');
  for (final reference in result.productionReferences) {
    buffer.writeln(
        '${reference.file}:${reference.line}:${reference.column} ${reference.role}');
  }
  buffer.writeln('TEST REFERENCES');
  for (final reference in result.testReferences) {
    buffer.writeln(
        '${reference.file}:${reference.line}:${reference.column} ${reference.role}');
  }
  return buffer.toString();
}
