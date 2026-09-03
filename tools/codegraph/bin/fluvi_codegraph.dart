import 'dart:io';

import 'package:fluvi_codegraph/fluvi_codegraph.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty ||
      arguments.first == '--help' ||
      arguments.first == '-h') {
    _printUsage();
    return;
  }
  try {
    switch (arguments.first) {
      case 'generate':
        await _generate(arguments.skip(1).toList());
      case 'query':
        await _query(arguments.skip(1).toList());
      default:
        throw _CliException('Unknown command: ${arguments.first}');
    }
  } on _CliException catch (error) {
    stderr.writeln(error.message);
    _printUsage(stderr);
    exitCode = 64;
  } on SourceProvenanceException catch (error) {
    stderr.writeln(error);
    exitCode = 65;
  } on FileSystemException catch (error) {
    stderr.writeln(error);
    exitCode = 66;
  } on ArgumentError catch (error) {
    stderr.writeln(error);
    exitCode = 67;
  } catch (error, stackTrace) {
    stderr.writeln('fluvi_codegraph failed: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

Future<void> _generate(List<String> arguments) async {
  final options = _parseOptions(arguments);
  final indexPath = options['index'] ?? 'index.scip';
  final graphPath = options['graph'] ?? 'docs/codegraph';
  final result = await GraphGenerationService().generate(
    GraphGenerationRequest(
      indexFile: File(indexPath),
      outputDirectory: Directory(graphPath),
      sourceRoot: options['source-root'] == null
          ? null
          : Directory(options['source-root']!),
      expectedSourceHead: options['source-head'],
      sourceRef: options['source-ref'],
      expectedIndexSha256: options['expected-index-sha256'],
    ),
  );
  stdout.writeln('SOURCE_HEAD=${result.provenance.sourceHead}');
  stdout.writeln('SOURCE_PARENT=${result.provenance.sourceParent}');
  stdout.writeln('SOURCE_REF=${result.provenance.sourceRef}');
  stdout.writeln('INDEX_SHA256=${result.provenance.indexSha256}');
  for (final artifact in result.writeResult.artifacts) {
    stdout.writeln(
      'ARTIFACT ${artifact.name} storage=${artifact.storage} '
      'records=${artifact.recordCount} bytes=${artifact.byteCount}',
    );
  }
}

Future<void> _query(List<String> arguments) async {
  final options = _parseOptions(arguments);
  final graph = options['graph'];
  final symbol = options['symbol'];
  if (graph == null || graph.isEmpty) {
    throw const _CliException('query requires --graph <directory>.');
  }
  if (symbol == null || symbol.isEmpty) {
    throw const _CliException(
        'query requires --symbol <name-or-raw-scip-symbol>.');
  }
  final result = await GraphArtifactReader(Directory(graph)).query(symbol);
  stdout.write(renderGraphQuery(result));
}

Map<String, String> _parseOptions(List<String> arguments) {
  final options = <String, String>{};
  for (var index = 0; index < arguments.length; index += 2) {
    final flag = arguments[index];
    if (!flag.startsWith('--')) {
      throw _CliException('Expected an option beginning with --, got $flag.');
    }
    if (index + 1 >= arguments.length) {
      throw _CliException('Option $flag requires a value.');
    }
    final value = arguments[index + 1];
    if (value.startsWith('--')) {
      throw _CliException('Option $flag requires a value.');
    }
    options[flag.substring(2)] = value;
  }
  return options;
}

void _printUsage([IOSink? sink]) {
  final output = sink ?? stdout;
  output.writeln('Usage:');
  output
      .writeln('  dart run tools/codegraph/bin/fluvi_codegraph.dart generate');
  output.writeln('    --index index.scip --graph docs/codegraph');
  output.writeln('    --source-head <sha> --source-ref <git-ref>');
  output.writeln(
      '    [--source-root <repo-root>] [--expected-index-sha256 <sha256>]');
  output.writeln('  dart run tools/codegraph/bin/fluvi_codegraph.dart query');
  output
      .writeln('    --graph docs/codegraph --symbol <name-or-raw-scip-symbol>');
}

class _CliException implements Exception {
  const _CliException(this.message);

  final String message;
}
