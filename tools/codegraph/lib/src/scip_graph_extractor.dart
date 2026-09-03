import 'dart:io';

// scip_dart 1.6.2 exposes generated SCIP protobuf types under src only.
// ignore: implementation_imports
import 'package:scip_dart/src/gen/scip.pb.dart';

import 'graph_models.dart';

class ScipIndexReader {
  const ScipIndexReader._();

  static Index read(File indexFile) {
    if (!indexFile.existsSync()) {
      throw FileSystemException('SCIP index does not exist', indexFile.path);
    }
    try {
      final index = Index.fromBuffer(indexFile.readAsBytesSync());
      if (!index.hasMetadata() && index.documents.isEmpty) {
        throw const FormatException(
            'The file does not contain a SCIP Index message.');
      }
      return index;
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException(
          'Unable to decode SCIP index at ${indexFile.path}: $error');
    }
  }
}

/// The sole owner of converting SCIP protobuf semantics into Fluvi graph data.
class ScipGraphExtractor {
  const ScipGraphExtractor();

  GraphSnapshot extract(Index index) {
    final documents = List<Document>.of(index.documents)
      ..sort((left, right) => left.relativePath.compareTo(right.relativePath));
    final definitions = <String, _DefinitionSeed>{};
    final definitionRanges = <String, SourceRange>{};
    var occurrenceCount = 0;
    var definedSymbolCount = 0;

    for (final document in documents) {
      occurrenceCount += document.occurrences.length;
      definedSymbolCount += document.symbols.length;
      for (final information in document.symbols) {
        if (!_isUsefulRepositorySymbol(information)) {
          continue;
        }
        final existing = definitions[information.symbol];
        final candidate = _DefinitionSeed(
          rawSymbol: information.symbol,
          file: document.relativePath,
          kind: _kindName(information.kind),
          humanName:
              ScipSymbolShape.tryParse(information.symbol)?.lastHumanName,
        );
        if (existing == null ||
            candidate.sortKey.compareTo(existing.sortKey) < 0) {
          definitions[information.symbol] = candidate;
        }
      }
    }

    final targetSymbols = definitions.keys.toSet();
    final references = <GraphReference>[];
    final seenReferences = <String>{};
    for (final document in documents) {
      for (final occurrence in document.occurrences) {
        final symbol = occurrence.symbol;
        if (!targetSymbols.contains(symbol)) {
          continue;
        }
        final range = _rangeFromScip(occurrence.range);
        if (_hasRole(occurrence.symbolRoles, SymbolRole.Definition)) {
          if (range != null) {
            final existing = definitionRanges[symbol];
            if (existing == null ||
                _rangeSortKey(range).compareTo(_rangeSortKey(existing)) < 0) {
              definitionRanges[symbol] = range;
            }
          }
          continue;
        }
        if (range == null) {
          continue;
        }
        final reference = GraphReference(
          targetSymbol: symbol,
          file: document.relativePath,
          line: range.startLine,
          column: range.startColumn,
          role: _roleName(occurrence.symbolRoles),
          isTest: _isTestPath(document.relativePath),
        );
        if (seenReferences.add(reference.stableKey)) {
          references.add(reference);
        }
      }
    }

    final symbols = definitions.values
        .map(
          (seed) => GraphSymbol(
            rawSymbol: seed.rawSymbol,
            definitionFile: seed.file,
            definitionRange: definitionRanges[seed.rawSymbol],
            kind: seed.kind,
            humanName: seed.humanName,
            familyKey: null,
          ),
        )
        .toList()
      ..sort((left, right) => left.rawSymbol.compareTo(right.rawSymbol));

    final classSymbols = <String>{
      for (final symbol in symbols)
        if (symbol.kind == SymbolInformation_Kind.Class.name) symbol.rawSymbol,
    };
    final completedSymbols = symbols.map((symbol) {
      if (symbol.kind == SymbolInformation_Kind.Class.name) {
        return symbol.copyWith(familyKey: symbol.rawSymbol);
      }
      if (symbol.kind == SymbolInformation_Kind.Constructor.name) {
        final parent =
            ScipSymbolShape.tryParse(symbol.rawSymbol)?.parentTypeRawSymbol;
        if (parent != null && classSymbols.contains(parent)) {
          return symbol.copyWith(familyKey: parent);
        }
      }
      return symbol;
    }).toList();

    references.sort(_compareReferences);
    final edgesByKey = <String, GraphEdge>{};
    for (final reference in references) {
      final edge = GraphEdge(
        from: reference.file,
        to: reference.targetSymbol,
        type: GraphEdgeType.reference,
        basis: GraphEdgeBasis.scip,
        file: reference.file,
      );
      edgesByKey.putIfAbsent(edge.stableKey, () => edge);
    }
    final edges = edgesByKey.values.toList()
      ..sort((left, right) {
        final target = left.to.compareTo(right.to);
        return target != 0 ? target : left.from.compareTo(right.from);
      });

    return GraphSnapshot(
      symbols: completedSymbols,
      references: references,
      edges: edges,
      statistics: GraphStatistics(
        documentCount: documents.length,
        occurrenceCount: occurrenceCount,
        definedSymbolCount: definedSymbolCount,
        repositoryDefinedSymbolCount: completedSymbols.length,
      ),
    );
  }
}

class _DefinitionSeed {
  const _DefinitionSeed({
    required this.rawSymbol,
    required this.file,
    required this.kind,
    required this.humanName,
  });

  final String rawSymbol;
  final String file;
  final String? kind;
  final String? humanName;

  String get sortKey => '$file\u0000$rawSymbol';
}

bool _isUsefulRepositorySymbol(SymbolInformation information) {
  final symbol = information.symbol;
  if (symbol.isEmpty || symbol.startsWith('local ')) {
    return false;
  }
  return switch (information.kind) {
    SymbolInformation_Kind.UnspecifiedKind ||
    SymbolInformation_Kind.File ||
    SymbolInformation_Kind.Namespace ||
    SymbolInformation_Kind.Parameter ||
    SymbolInformation_Kind.ParameterLabel ||
    SymbolInformation_Kind.SelfParameter ||
    SymbolInformation_Kind.ThisParameter ||
    SymbolInformation_Kind.TypeParameter =>
      false,
    _ => true,
  };
}

String? _kindName(SymbolInformation_Kind kind) {
  return kind == SymbolInformation_Kind.UnspecifiedKind ? null : kind.name;
}

bool _hasRole(int roles, SymbolRole role) => (roles & role.value) != 0;

String _roleName(int roles) {
  final names = <String>[];
  if (_hasRole(roles, SymbolRole.Test)) {
    names.add('test');
  }
  if (_hasRole(roles, SymbolRole.Import)) {
    names.add('import');
  }
  if (_hasRole(roles, SymbolRole.WriteAccess)) {
    names.add('write');
  }
  if (_hasRole(roles, SymbolRole.ReadAccess)) {
    names.add('read');
  }
  if (_hasRole(roles, SymbolRole.Generated)) {
    names.add('generated');
  }
  if (_hasRole(roles, SymbolRole.ForwardDefinition)) {
    names.add('forward_definition');
  }
  return names.isEmpty ? 'reference' : names.join('|');
}

SourceRange? _rangeFromScip(List<int> range) {
  if (range.length == 3) {
    return SourceRange(
      startLine: range[0],
      startColumn: range[1],
      endLine: range[0],
      endColumn: range[2],
    );
  }
  if (range.length == 4) {
    return SourceRange(
      startLine: range[0],
      startColumn: range[1],
      endLine: range[2],
      endColumn: range[3],
    );
  }
  return null;
}

String _rangeSortKey(SourceRange range) {
  return '${range.startLine.toString().padLeft(12, '0')}:${range.startColumn.toString().padLeft(12, '0')}';
}

bool _isTestPath(String path) {
  return path.startsWith('test/') ||
      path.startsWith('integration_test/') ||
      path.startsWith('test_driver/');
}

int _compareReferences(GraphReference left, GraphReference right) {
  final target = left.targetSymbol.compareTo(right.targetSymbol);
  if (target != 0) {
    return target;
  }
  final file = left.file.compareTo(right.file);
  if (file != 0) {
    return file;
  }
  final line = left.line.compareTo(right.line);
  if (line != 0) {
    return line;
  }
  final column = left.column.compareTo(right.column);
  if (column != 0) {
    return column;
  }
  return left.role.compareTo(right.role);
}

enum _DescriptorSuffix {
  namespace,
  type,
  term,
  method,
  typeParameter,
  parameter,
  meta,
  macro
}

class _ParsedDescriptor {
  const _ParsedDescriptor({
    required this.suffix,
    required this.rawName,
    required this.end,
  });

  final _DescriptorSuffix suffix;
  final String rawName;
  final int end;

  String get humanName {
    if (rawName.startsWith('`') &&
        rawName.endsWith('`') &&
        rawName.length >= 2) {
      return rawName.substring(1, rawName.length - 1).replaceAll('``', '`');
    }
    return rawName;
  }
}

/// Strict parser for the SCIP protocol's serialized Symbol descriptor grammar.
///
/// This parser is only used to associate a `Constructor` kind with the
/// immediately preceding `Type` descriptor. It never reconstructs source
/// references from text and deliberately returns null for unsupported shapes.
class ScipSymbolShape {
  const ScipSymbolShape._(this._raw, this._descriptors);

  final String _raw;
  final List<_ParsedDescriptor> _descriptors;

  String? get lastHumanName =>
      _descriptors.isEmpty ? null : _descriptors.last.humanName;

  String? get parentTypeRawSymbol {
    if (_descriptors.length < 2 ||
        _descriptors.last.suffix != _DescriptorSuffix.method) {
      return null;
    }
    final parent = _descriptors[_descriptors.length - 2];
    if (parent.suffix != _DescriptorSuffix.type) {
      return null;
    }
    return _raw.substring(0, parent.end);
  }

  static ScipSymbolShape? tryParse(String raw) {
    if (raw.startsWith('local ')) {
      return null;
    }
    var cursor = 0;
    for (var part = 0; part < 4; part++) {
      final end = _headerPartEnd(raw, cursor);
      if (end == null) {
        return null;
      }
      cursor = end + 1;
    }
    if (cursor >= raw.length) {
      return null;
    }
    final descriptors = <_ParsedDescriptor>[];
    while (cursor < raw.length) {
      final descriptor = _parseDescriptor(raw, cursor);
      if (descriptor == null) {
        return null;
      }
      descriptors.add(descriptor);
      cursor = descriptor.end;
    }
    return descriptors.isEmpty
        ? null
        : ScipSymbolShape._(
            raw, List<_ParsedDescriptor>.unmodifiable(descriptors));
  }

  static int? _headerPartEnd(String raw, int start) {
    var cursor = start;
    while (cursor < raw.length) {
      if (raw[cursor] == ' ') {
        if (cursor + 1 < raw.length && raw[cursor + 1] == ' ') {
          cursor += 2;
          continue;
        }
        return cursor;
      }
      cursor++;
    }
    return null;
  }

  static _ParsedDescriptor? _parseDescriptor(String raw, int start) {
    if (raw[start] == '[') {
      final nameEnd = _parseIdentifier(raw, start + 1);
      if (nameEnd == null || nameEnd >= raw.length || raw[nameEnd] != ']') {
        return null;
      }
      return _ParsedDescriptor(
        suffix: _DescriptorSuffix.typeParameter,
        rawName: raw.substring(start + 1, nameEnd),
        end: nameEnd + 1,
      );
    }
    if (raw[start] == '(') {
      final nameEnd = _parseIdentifier(raw, start + 1);
      if (nameEnd == null || nameEnd >= raw.length || raw[nameEnd] != ')') {
        return null;
      }
      return _ParsedDescriptor(
        suffix: _DescriptorSuffix.parameter,
        rawName: raw.substring(start + 1, nameEnd),
        end: nameEnd + 1,
      );
    }

    final nameEnd = _parseIdentifier(raw, start);
    if (nameEnd == null || nameEnd >= raw.length) {
      return null;
    }
    final name = raw.substring(start, nameEnd);
    switch (raw[nameEnd]) {
      case '/':
        return _ParsedDescriptor(
            suffix: _DescriptorSuffix.namespace,
            rawName: name,
            end: nameEnd + 1);
      case '#':
        return _ParsedDescriptor(
            suffix: _DescriptorSuffix.type, rawName: name, end: nameEnd + 1);
      case '.':
        return _ParsedDescriptor(
            suffix: _DescriptorSuffix.term, rawName: name, end: nameEnd + 1);
      case ':':
        return _ParsedDescriptor(
            suffix: _DescriptorSuffix.meta, rawName: name, end: nameEnd + 1);
      case '!':
        return _ParsedDescriptor(
            suffix: _DescriptorSuffix.macro, rawName: name, end: nameEnd + 1);
      case '(':
        var cursor = nameEnd + 1;
        while (
            cursor < raw.length && _isSimpleIdentifierCharacter(raw[cursor])) {
          cursor++;
        }
        if (cursor >= raw.length ||
            raw[cursor] != ')' ||
            cursor + 1 >= raw.length ||
            raw[cursor + 1] != '.') {
          return null;
        }
        return _ParsedDescriptor(
            suffix: _DescriptorSuffix.method, rawName: name, end: cursor + 2);
    }
    return null;
  }

  static int? _parseIdentifier(String raw, int start) {
    if (start >= raw.length) {
      return null;
    }
    if (raw[start] == '`') {
      var cursor = start + 1;
      while (cursor < raw.length) {
        if (raw[cursor] == '`') {
          if (cursor + 1 < raw.length && raw[cursor + 1] == '`') {
            cursor += 2;
            continue;
          }
          return cursor + 1;
        }
        cursor++;
      }
      return null;
    }
    var cursor = start;
    while (cursor < raw.length && _isSimpleIdentifierCharacter(raw[cursor])) {
      cursor++;
    }
    return cursor == start ? null : cursor;
  }

  static bool _isSimpleIdentifierCharacter(String value) {
    final code = value.codeUnitAt(0);
    return code >= 48 && code <= 57 ||
        code >= 65 && code <= 90 ||
        code >= 97 && code <= 122 ||
        value == '_' ||
        value == '+' ||
        value == '-' ||
        value == r'$';
  }
}
