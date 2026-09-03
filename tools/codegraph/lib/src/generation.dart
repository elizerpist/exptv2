import 'dart:io';

import 'package:crypto/crypto.dart';

import 'changed_impact.dart';
import 'graph_artifact_writer.dart';
import 'graph_models.dart';
import 'provenance.dart';
import 'scip_graph_extractor.dart';

class GraphGenerationRequest {
  const GraphGenerationRequest({
    required this.indexFile,
    required this.outputDirectory,
    this.sourceRoot,
    this.expectedSourceHead,
    this.sourceRef,
    this.expectedIndexSha256,
  });

  final File indexFile;
  final Directory outputDirectory;
  final Directory? sourceRoot;
  final String? expectedSourceHead;
  final String? sourceRef;
  final String? expectedIndexSha256;
}

class GraphGenerationResult {
  const GraphGenerationResult({
    required this.provenance,
    required this.graph,
    required this.changedImpact,
    required this.writeResult,
  });

  final GraphProvenance provenance;
  final GraphSnapshot graph;
  final ChangedImpact changedImpact;
  final GraphWriteResult writeResult;
}

/// Reproducible generation that consumes an already generated SCIP index.
class GraphGenerationService {
  GraphGenerationService({
    ScipGraphExtractor? extractor,
    SourceProvenanceVerifier? provenanceVerifier,
    GraphArtifactWriter? artifactWriter,
  })  : _extractor = extractor ?? const ScipGraphExtractor(),
        _provenanceVerifier = provenanceVerifier ?? SourceProvenanceVerifier(),
        _artifactWriter = artifactWriter ?? GraphArtifactWriter();

  final ScipGraphExtractor _extractor;
  final SourceProvenanceVerifier _provenanceVerifier;
  final GraphArtifactWriter _artifactWriter;

  Future<GraphGenerationResult> generate(GraphGenerationRequest request) async {
    final index = ScipIndexReader.read(request.indexFile);
    final sourceRoot = _provenanceVerifier.sourceRootForIndex(
      index,
      requestedSourceRoot: request.sourceRoot,
    );
    final expectedHead = request.expectedSourceHead ??
        await _provenanceVerifier.currentHead(sourceRoot);
    final sourceRef = request.sourceRef ??
        await _provenanceVerifier.currentBranch(sourceRoot);
    final verified = await _provenanceVerifier.verify(
      sourceRoot: sourceRoot,
      expectedHead: expectedHead,
      sourceRef: sourceRef,
    );
    final indexHash = await _sha256(request.indexFile);
    if (request.expectedIndexSha256 != null &&
        request.expectedIndexSha256 != indexHash) {
      throw SourceProvenanceException(
        'Index SHA-256 $indexHash does not match expected ${request.expectedIndexSha256}.',
      );
    }
    final graph = _extractor.extract(index);
    final changedFiles = await _provenanceVerifier.changedFiles(
      sourceRoot: sourceRoot,
      baseHead: verified.sourceParent,
      sourceHead: verified.sourceHead,
    );
    final impact = const ChangedImpactBuilder().build(
      graph: graph,
      sourceHead: verified.sourceHead,
      baseHead: verified.sourceParent,
      changedFiles: changedFiles,
    );
    final provenance = GraphProvenance(
      sourceHead: verified.sourceHead,
      sourceParent: verified.sourceParent,
      sourceRef: verified.sourceRef,
      scipDartVersion: index.metadata.toolInfo.version,
      indexSha256: indexHash,
      documentCount: graph.statistics.documentCount,
      occurrenceCount: graph.statistics.occurrenceCount,
      definedSymbolCount: graph.statistics.definedSymbolCount,
      repositoryDefinedSymbolCount:
          graph.statistics.repositoryDefinedSymbolCount,
    );
    final writeResult = await _artifactWriter.write(
      graph: graph,
      provenance: provenance,
      changedImpact: impact,
      outputDirectory: request.outputDirectory,
    );
    return GraphGenerationResult(
      provenance: provenance,
      graph: graph,
      changedImpact: impact,
      writeResult: writeResult,
    );
  }
}

Future<String> _sha256(File file) async =>
    sha256.convert(await file.readAsBytes()).toString();
