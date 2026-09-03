import 'dart:collection';

/// A zero-based SCIP source range.
class SourceRange {
  const SourceRange({
    required this.startLine,
    required this.startColumn,
    required this.endLine,
    required this.endColumn,
  });

  final int startLine;
  final int startColumn;
  final int endLine;
  final int endColumn;

  Map<String, Object> toJson() => <String, Object>{
        'start_line': startLine,
        'start_column': startColumn,
        'end_line': endLine,
        'end_column': endColumn,
      };

  factory SourceRange.fromJson(Map<String, Object?> json) {
    return SourceRange(
      startLine: json['start_line']! as int,
      startColumn: json['start_column']! as int,
      endLine: json['end_line']! as int,
      endColumn: json['end_column']! as int,
    );
  }
}

/// A repository-defined global SCIP symbol.
class GraphSymbol {
  const GraphSymbol({
    required this.rawSymbol,
    required this.definitionFile,
    required this.definitionRange,
    required this.kind,
    required this.humanName,
    required this.familyKey,
  });

  final String rawSymbol;
  final String? definitionFile;
  final SourceRange? definitionRange;
  final String? kind;
  final String? humanName;

  /// The raw class symbol for a supported class/constructor family.
  final String? familyKey;

  GraphSymbol copyWith({String? familyKey}) {
    return GraphSymbol(
      rawSymbol: rawSymbol,
      definitionFile: definitionFile,
      definitionRange: definitionRange,
      kind: kind,
      humanName: humanName,
      familyKey: familyKey ?? this.familyKey,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'raw_symbol': rawSymbol,
        'definition_file': definitionFile,
        'definition_range': definitionRange?.toJson(),
        'kind': kind,
        'human_name': humanName,
        'family_key': familyKey,
      };

  factory GraphSymbol.fromJson(Map<String, Object?> json) {
    final range = json['definition_range'];
    return GraphSymbol(
      rawSymbol: json['raw_symbol']! as String,
      definitionFile: json['definition_file'] as String?,
      definitionRange: range is Map<String, Object?>
          ? SourceRange.fromJson(range)
          : range is Map
              ? SourceRange.fromJson(Map<String, Object?>.from(range))
              : null,
      kind: json['kind'] as String?,
      humanName: json['human_name'] as String?,
      familyKey: json['family_key'] as String?,
    );
  }
}

/// A repository-local occurrence that references a repository-defined symbol.
class GraphReference {
  const GraphReference({
    required this.targetSymbol,
    required this.file,
    required this.line,
    required this.column,
    required this.role,
    required this.isTest,
    this.consumerSymbol,
  });

  final String targetSymbol;
  final String file;
  final int line;
  final int column;
  final String role;
  final bool isTest;

  /// SCIP occurrence enclosing ranges do not reliably identify a local owner.
  final String? consumerSymbol;

  String get stableKey =>
      '$targetSymbol\u0000$file\u0000$line\u0000$column\u0000$role';

  Map<String, Object?> toJson() => <String, Object?>{
        'target_symbol': targetSymbol,
        'file': file,
        'line': line,
        'column': column,
        'role': role,
        'is_test': isTest,
        'consumer_symbol': consumerSymbol,
      };

  factory GraphReference.fromJson(Map<String, Object?> json) {
    return GraphReference(
      targetSymbol: json['target_symbol']! as String,
      file: json['file']! as String,
      line: json['line']! as int,
      column: json['column']! as int,
      role: json['role']! as String,
      isTest: json['is_test']! as bool,
      consumerSymbol: json['consumer_symbol'] as String?,
    );
  }
}

enum GraphEdgeType { reference }

enum GraphEdgeBasis { scip }

/// An evidence-labelled SCIP reference edge, not a runtime graph edge.
class GraphEdge {
  const GraphEdge({
    required this.from,
    required this.to,
    required this.type,
    required this.basis,
    required this.file,
  });

  final String from;
  final String to;
  final GraphEdgeType type;
  final GraphEdgeBasis basis;
  final String file;

  String get stableKey => '$from\u0000$to\u0000${type.name}\u0000$file';

  Map<String, Object> toJson() => <String, Object>{
        'from': from,
        'to': to,
        'type': type.name,
        'basis': basis.name,
        'file': file,
      };
}

class GraphFamily {
  const GraphFamily({required this.rootSymbol, required this.members});

  final String rootSymbol;
  final List<String> members;
}

class GraphStatistics {
  const GraphStatistics({
    required this.documentCount,
    required this.occurrenceCount,
    required this.definedSymbolCount,
    required this.repositoryDefinedSymbolCount,
  });

  final int documentCount;
  final int occurrenceCount;

  /// All SCIP document symbol-information records, including local symbols.
  final int definedSymbolCount;

  /// Global repository symbols retained in [GraphSnapshot.symbols].
  final int repositoryDefinedSymbolCount;
}

class GraphSnapshot {
  GraphSnapshot({
    required List<GraphSymbol> symbols,
    required List<GraphReference> references,
    required List<GraphEdge> edges,
    required this.statistics,
  })  : symbols = List<GraphSymbol>.unmodifiable(symbols),
        references = List<GraphReference>.unmodifiable(references),
        edges = List<GraphEdge>.unmodifiable(edges);

  final List<GraphSymbol> symbols;
  final List<GraphReference> references;
  final List<GraphEdge> edges;
  final GraphStatistics statistics;

  late final Map<String, GraphSymbol> _symbolsByRaw = <String, GraphSymbol>{
    for (final symbol in symbols) symbol.rawSymbol: symbol,
  };

  GraphSymbol? symbolForRaw(String rawSymbol) => _symbolsByRaw[rawSymbol];

  List<GraphReference> referencesFor(String targetSymbol) {
    return List<GraphReference>.unmodifiable(
      references.where((reference) => reference.targetSymbol == targetSymbol),
    );
  }

  GraphFamily familyFor(String rawSymbol) {
    final symbol = _symbolsByRaw[rawSymbol];
    final root = symbol?.familyKey ?? rawSymbol;
    final members = symbols
        .where((candidate) =>
            candidate.rawSymbol == root || candidate.familyKey == root)
        .map((candidate) => candidate.rawSymbol)
        .toList()
      ..sort();
    if (!members.contains(root)) {
      members.insert(0, root);
    }
    return GraphFamily(
        rootSymbol: root, members: List<String>.unmodifiable(members));
  }

  GraphSymbol? resolveSymbol(String value) {
    final exact = _symbolsByRaw[value];
    if (exact != null) {
      return exact;
    }
    final matches =
        symbols.where((symbol) => symbol.humanName == value).toList();
    if (matches.length == 1) {
      return matches.single;
    }
    return null;
  }
}

class GraphProvenance {
  const GraphProvenance({
    required this.sourceHead,
    required this.sourceParent,
    required this.sourceRef,
    required this.scipDartVersion,
    required this.indexSha256,
    required this.documentCount,
    required this.occurrenceCount,
    required this.definedSymbolCount,
    this.repositoryDefinedSymbolCount,
  });

  final String sourceHead;
  final String sourceParent;
  final String sourceRef;
  final String scipDartVersion;
  final String indexSha256;
  final int documentCount;
  final int occurrenceCount;
  final int definedSymbolCount;
  final int? repositoryDefinedSymbolCount;

  Map<String, Object?> toJson() => <String, Object?>{
        'schema_version': 1,
        'source_head': sourceHead,
        'source_parent': sourceParent,
        'source_ref': sourceRef,
        'scip_dart_version': scipDartVersion,
        'index_sha256': indexSha256,
        'document_count': documentCount,
        'occurrence_count': occurrenceCount,
        'defined_symbol_count': definedSymbolCount,
        'repository_defined_symbol_count': repositoryDefinedSymbolCount,
      };
}

class GraphQueryResult {
  GraphQueryResult({
    required this.symbol,
    required List<String> familyMembers,
    required List<GraphReference> productionReferences,
    required List<GraphReference> testReferences,
  })  : familyMembers = List<String>.unmodifiable(familyMembers),
        productionReferences =
            List<GraphReference>.unmodifiable(productionReferences),
        testReferences = List<GraphReference>.unmodifiable(testReferences);

  final GraphSymbol symbol;
  final List<String> familyMembers;
  final List<GraphReference> productionReferences;
  final List<GraphReference> testReferences;
}

/// Utility for deterministic map grouping without leaking mutable maps.
Map<K, List<V>> immutableGroupedBy<K, V>(
    Iterable<V> values, K Function(V) keyOf) {
  final result = <K, List<V>>{};
  for (final value in values) {
    result.putIfAbsent(keyOf(value), () => <V>[]).add(value);
  }
  return UnmodifiableMapView<K, List<V>>(
    result.map(
        (key, value) => MapEntry<K, List<V>>(key, List<V>.unmodifiable(value))),
  );
}
