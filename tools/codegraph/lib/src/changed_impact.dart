import 'graph_models.dart';

/// One source file that directly references one or more candidate symbols.
///
/// It is deliberately a one-hop SCIP summary, not a runtime impact edge.
class ImpactConsumer {
  ImpactConsumer({
    required this.file,
    required this.isTest,
    required List<String> targetSymbols,
    required this.referenceCount,
    required this.firstLine,
    required this.firstColumn,
  }) : targetSymbols = List<String>.unmodifiable(targetSymbols);

  final String file;
  final bool isTest;
  final List<String> targetSymbols;
  final int referenceCount;
  final int firstLine;
  final int firstColumn;

  Map<String, Object> toJson() => <String, Object>{
        'file': file,
        'is_test': isTest,
        'target_symbols': targetSymbols,
        'reference_count': referenceCount,
        'first_line': firstLine,
        'first_column': firstColumn,
        'basis': 'scip_reference',
      };
}

class ChangedImpact {
  ChangedImpact({
    required this.sourceHead,
    required this.baseHead,
    required List<String> changedFiles,
    required List<GraphSymbol> candidateChangedSymbols,
    required List<ImpactConsumer> directReferenceConsumers,
  })  : changedFiles = List<String>.unmodifiable(changedFiles),
        candidateChangedSymbols =
            List<GraphSymbol>.unmodifiable(candidateChangedSymbols),
        directReferenceConsumers =
            List<ImpactConsumer>.unmodifiable(directReferenceConsumers),
        affectedTestLocations = List<ImpactConsumer>.unmodifiable(
          directReferenceConsumers.where((consumer) => consumer.isTest),
        ),
        affectedProductionLocations = List<ImpactConsumer>.unmodifiable(
          directReferenceConsumers.where((consumer) => !consumer.isTest),
        );

  final String sourceHead;
  final String baseHead;
  final List<String> changedFiles;

  /// A file-level conservative set, never a claim that a symbol body changed.
  final List<GraphSymbol> candidateChangedSymbols;
  final List<ImpactConsumer> directReferenceConsumers;
  final List<ImpactConsumer> affectedTestLocations;
  final List<ImpactConsumer> affectedProductionLocations;

  Map<String, Object> toJson() => <String, Object>{
        'schema_version': 1,
        'source_head': sourceHead,
        'base_head': baseHead,
        'changed_files': changedFiles,
        // Full definition records live in symbols.json. Keeping raw identities
        // here makes this a compact, conservative file-level candidate list.
        'candidate_changed_symbols':
            candidateChangedSymbols.map((symbol) => symbol.rawSymbol).toList(),
        'candidate_changed_symbols_basis':
            'repository definitions whose definition_file is in changed_files; symbol bodies are not range-diffed',
        'direct_reference_consumers': directReferenceConsumers
            .map((consumer) => consumer.toJson())
            .toList(),
        'affected_test_locations':
            affectedTestLocations.map((consumer) => consumer.toJson()).toList(),
        'affected_production_locations': affectedProductionLocations
            .map((consumer) => consumer.toJson())
            .toList(),
      };
}

class ChangedImpactBuilder {
  const ChangedImpactBuilder();

  ChangedImpact build({
    required GraphSnapshot graph,
    required String sourceHead,
    required String baseHead,
    required List<String> changedFiles,
  }) {
    final sortedFiles = List<String>.of(changedFiles)..sort();
    final candidates = graph.symbols
        .where((symbol) => sortedFiles.contains(symbol.definitionFile))
        .toList()
      ..sort((left, right) => left.rawSymbol.compareTo(right.rawSymbol));
    final targetSymbols = <String>{};
    for (final candidate in candidates) {
      targetSymbols.addAll(graph.familyFor(candidate.rawSymbol).members);
    }

    final accumulators = <String, _ImpactConsumerAccumulator>{};
    for (final reference in graph.references
        .where((reference) => targetSymbols.contains(reference.targetSymbol))) {
      final key = '${reference.file}\u0000${reference.isTest}';
      accumulators
          .putIfAbsent(
            key,
            () => _ImpactConsumerAccumulator(
              file: reference.file,
              isTest: reference.isTest,
            ),
          )
          .add(reference);
    }
    final consumers =
        accumulators.values.map((accumulator) => accumulator.build()).toList()
          ..sort((left, right) {
            final file = left.file.compareTo(right.file);
            return file != 0
                ? file
                : left.isTest.toString().compareTo(right.isTest.toString());
          });

    return ChangedImpact(
      sourceHead: sourceHead,
      baseHead: baseHead,
      changedFiles: sortedFiles,
      candidateChangedSymbols: candidates,
      directReferenceConsumers: consumers,
    );
  }
}

class _ImpactConsumerAccumulator {
  _ImpactConsumerAccumulator({required this.file, required this.isTest});

  final String file;
  final bool isTest;
  final Set<String> _targetSymbols = <String>{};
  var _referenceCount = 0;
  int? _firstLine;
  int? _firstColumn;

  void add(GraphReference reference) {
    _targetSymbols.add(reference.targetSymbol);
    _referenceCount++;
    if (_firstLine == null ||
        reference.line < _firstLine! ||
        reference.line == _firstLine! && reference.column < _firstColumn!) {
      _firstLine = reference.line;
      _firstColumn = reference.column;
    }
  }

  ImpactConsumer build() {
    final targetSymbols = _targetSymbols.toList()..sort();
    return ImpactConsumer(
      file: file,
      isTest: isTest,
      targetSymbols: targetSymbols,
      referenceCount: _referenceCount,
      firstLine: _firstLine!,
      firstColumn: _firstColumn!,
    );
  }
}
