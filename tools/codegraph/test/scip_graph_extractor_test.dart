import 'dart:io';

import 'package:fluvi_codegraph/fluvi_codegraph.dart';
import 'package:scip_dart/src/gen/scip.pb.dart';
import 'package:test/test.dart';

const _prefix = 'scip-dart pub fluvi 0.1.0+1 ';
const _classSymbol = '${_prefix}lib/`sample.dart`/Sample#';
const _constructorSymbol = '$_classSymbol`<constructor>`().';
const _methodSymbol = '${_classSymbol}run().';
const _parameterSymbol = '$_methodSymbol(amount)';
const _externalSymbol = 'scip-dart pub external 1.0.0 lib/`other.dart`/Other#';
const _queryAmountRangeControl =
    '${_prefix}lib/features/dashboard/query/presentation/`query_amount_range_control.dart`/QueryAmountRangeControl#';
const _dashboardCoreController =
    '${_prefix}lib/features/dashboard/application/`dashboard_core_controller.dart`/DashboardCoreController#';

void main() {
  group('ScipGraphExtractor', () {
    test('keeps repository definitions and local references only', () {
      final graph = const ScipGraphExtractor().extract(_sampleIndex());

      expect(
          graph.symbols.map((symbol) => symbol.rawSymbol),
          containsAll(<String>[
            _classSymbol,
            _constructorSymbol,
            _methodSymbol,
          ]));
      expect(graph.symbols.map((symbol) => symbol.rawSymbol),
          isNot(contains(_externalSymbol)));
      expect(graph.symbols.map((symbol) => symbol.rawSymbol),
          isNot(contains('local 1')));
      expect(graph.symbols.map((symbol) => symbol.rawSymbol),
          isNot(contains(_parameterSymbol)));
      expect(graph.referencesFor(_classSymbol), hasLength(3));
      expect(
          graph.referencesFor(_classSymbol).map((reference) => reference.file),
          containsAll(<String>[
            'lib/consumer.dart',
            'test/sample_test.dart',
          ]));
    });

    test('derives a constructor family using SCIP descriptor semantics', () {
      final graph = const ScipGraphExtractor().extract(_sampleIndex());

      final family = graph.familyFor(_classSymbol);

      expect(family.rootSymbol, _classSymbol);
      expect(family.members, contains(_constructorSymbol));
      expect(family.members, isNot(contains(_methodSymbol)));
    });

    test(
        'groups QueryAmountRangeControl and DashboardCoreController constructors safely',
        () {
      final graph = const ScipGraphExtractor().extract(
        _classFamilyIndex(<String>[
          _queryAmountRangeControl,
          _dashboardCoreController,
        ]),
      );

      for (final classSymbol in <String>[
        _queryAmountRangeControl,
        _dashboardCoreController,
      ]) {
        final family = graph.familyFor(classSymbol);
        expect(family.rootSymbol, classSymbol);
        expect(family.members, contains('$classSymbol`<constructor>`().'));
      }
    });

    test('labels graph edges as SCIP references rather than runtime calls', () {
      final graph = const ScipGraphExtractor().extract(_sampleIndex());

      expect(graph.edges, isNotEmpty);
      expect(graph.edges.every((edge) => edge.type == GraphEdgeType.reference),
          isTrue);
      expect(graph.edges.every((edge) => edge.basis == GraphEdgeBasis.scip),
          isTrue);
      expect(
        graph.edges
            .where((edge) =>
                edge.from == 'lib/consumer.dart' && edge.to == _classSymbol)
            .length,
        1,
      );
    });

    test('rejects malformed SCIP input', () async {
      final root =
          await Directory.systemTemp.createTemp('fluvi-codegraph-malformed-');
      addTearDown(() => root.delete(recursive: true));
      final indexFile = File('${root.path}/index.scip')
        ..writeAsBytesSync(<int>[1, 2, 3]);

      expect(() => ScipIndexReader.read(indexFile),
          throwsA(isA<FormatException>()));
    });

    test('reads a valid SCIP protobuf index from disk', () async {
      final root =
          await Directory.systemTemp.createTemp('fluvi-codegraph-protobuf-');
      addTearDown(() => root.delete(recursive: true));
      final indexFile = File('${root.path}/index.scip')
        ..writeAsBytesSync(_sampleIndex().writeToBuffer());

      final decoded = ScipIndexReader.read(indexFile);

      expect(decoded.metadata.toolInfo.version, '1.6.2');
      expect(decoded.documents, hasLength(3));
      expect(decoded.documents.first.relativePath, 'lib/sample.dart');
    });

    test('rejects a missing SCIP index', () {
      expect(
        () => ScipIndexReader.read(
          File(
              '${Directory.systemTemp.path}/fluvi-codegraph-missing-index.scip'),
        ),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}

Index _classFamilyIndex(List<String> classSymbols) {
  return Index(
    documents: <Document>[
      Document(
        relativePath: 'lib/families.dart',
        language: 'Dart',
        symbols: <SymbolInformation>[
          for (final classSymbol in classSymbols) ...<SymbolInformation>[
            SymbolInformation(
              symbol: classSymbol,
              kind: SymbolInformation_Kind.Class,
            ),
            SymbolInformation(
              symbol: '$classSymbol`<constructor>`().',
              kind: SymbolInformation_Kind.Constructor,
            ),
          ],
        ],
        occurrences: <Occurrence>[
          for (final classSymbol in classSymbols) ...<Occurrence>[
            Occurrence(
              range: <int>[0, 0, 0, 1],
              symbol: classSymbol,
              symbolRoles: SymbolRole.Definition.value,
            ),
            Occurrence(
              range: <int>[1, 0, 1, 1],
              symbol: '$classSymbol`<constructor>`().',
              symbolRoles: SymbolRole.Definition.value,
            ),
          ],
        ],
      ),
    ],
  );
}

Index _sampleIndex() {
  return Index(
    metadata: Metadata(
      projectRoot: 'file:///repo',
      toolInfo: ToolInfo(name: 'scip-dart', version: '1.6.2'),
    ),
    documents: <Document>[
      Document(
        relativePath: 'lib/sample.dart',
        language: 'Dart',
        symbols: <SymbolInformation>[
          SymbolInformation(
              symbol: _classSymbol, kind: SymbolInformation_Kind.Class),
          SymbolInformation(
              symbol: _constructorSymbol,
              kind: SymbolInformation_Kind.Constructor),
          SymbolInformation(
              symbol: _methodSymbol, kind: SymbolInformation_Kind.Method),
          SymbolInformation(
              symbol: _parameterSymbol, kind: SymbolInformation_Kind.Parameter),
          SymbolInformation(symbol: 'local 1'),
        ],
        occurrences: <Occurrence>[
          Occurrence(
              range: <int>[0, 6, 0, 12],
              symbol: _classSymbol,
              symbolRoles: SymbolRole.Definition.value),
          Occurrence(
              range: <int>[1, 2, 1, 8],
              symbol: _constructorSymbol,
              symbolRoles: SymbolRole.Definition.value),
          Occurrence(
              range: <int>[2, 2, 2, 5],
              symbol: _methodSymbol,
              symbolRoles: SymbolRole.Definition.value),
          Occurrence(
              range: <int>[2, 6, 2, 12],
              symbol: _parameterSymbol,
              symbolRoles: SymbolRole.Definition.value),
        ],
      ),
      Document(
        relativePath: 'lib/consumer.dart',
        language: 'Dart',
        occurrences: <Occurrence>[
          Occurrence(
              range: <int>[3, 4, 3, 10],
              symbol: _classSymbol,
              symbolRoles: SymbolRole.ReadAccess.value),
          Occurrence(
              range: <int>[3, 12, 3, 18],
              symbol: _classSymbol,
              symbolRoles: SymbolRole.ReadAccess.value),
          Occurrence(
              range: <int>[4, 4, 4, 10],
              symbol: _externalSymbol,
              symbolRoles: SymbolRole.ReadAccess.value),
        ],
      ),
      Document(
        relativePath: 'test/sample_test.dart',
        language: 'Dart',
        occurrences: <Occurrence>[
          Occurrence(
              range: <int>[5, 4, 5, 10],
              symbol: _classSymbol,
              symbolRoles: SymbolRole.ReadAccess.value | SymbolRole.Test.value),
        ],
      ),
    ],
  );
}
