import 'dart:io';

// scip_dart 1.6.2 exposes generated SCIP protobuf types under src only.
// ignore: implementation_imports
import 'package:scip_dart/src/gen/scip.pb.dart';

class GitCommandResult {
  const GitCommandResult(this.exitCode, this.stdout, this.stderr);

  final int exitCode;
  final String stdout;
  final String stderr;
}

abstract interface class GitRunner {
  Future<GitCommandResult> run(
      Directory workingDirectory, List<String> arguments);
}

class ProcessGitRunner implements GitRunner {
  const ProcessGitRunner();

  @override
  Future<GitCommandResult> run(
      Directory workingDirectory, List<String> arguments) async {
    final result = await Process.run('git', arguments,
        workingDirectory: workingDirectory.path);
    return GitCommandResult(
        result.exitCode, result.stdout as String, result.stderr as String);
  }
}

class SourceProvenanceException implements Exception {
  const SourceProvenanceException(this.message);

  final String message;

  @override
  String toString() => 'SourceProvenanceException: $message';
}

class VerifiedSourceProvenance {
  const VerifiedSourceProvenance({
    required this.sourceHead,
    required this.sourceParent,
    required this.sourceRef,
    required this.sourceWorktreeRef,
  });

  final String sourceHead;
  final String sourceParent;
  final String sourceRef;
  final String sourceWorktreeRef;
}

/// Fails closed when an index's claimed source cannot be verified from Git.
class SourceProvenanceVerifier {
  SourceProvenanceVerifier({GitRunner? git})
      : _git = git ?? const ProcessGitRunner();

  final GitRunner _git;

  Future<VerifiedSourceProvenance> verify({
    required Directory sourceRoot,
    required String expectedHead,
    required String sourceRef,
  }) async {
    final head = await _required(sourceRoot, <String>['rev-parse', 'HEAD']);
    if (head != expectedHead) {
      throw SourceProvenanceException(
          'Source HEAD $head does not match claimed index HEAD $expectedHead.');
    }
    await _requireTrackedClean(sourceRoot, <String>['diff', '--quiet']);
    await _requireTrackedClean(
        sourceRoot, <String>['diff', '--cached', '--quiet']);
    final resolvedRef =
        await _required(sourceRoot, <String>['rev-parse', sourceRef]);
    if (resolvedRef != expectedHead) {
      throw SourceProvenanceException(
          'Source ref $sourceRef resolves to $resolvedRef, not $expectedHead.');
    }
    final parent =
        await _required(sourceRoot, <String>['rev-parse', '$expectedHead^']);
    final branch = await _worktreeRef(sourceRoot);
    return VerifiedSourceProvenance(
      sourceHead: expectedHead,
      sourceParent: parent,
      sourceRef: sourceRef,
      sourceWorktreeRef: branch,
    );
  }

  Directory sourceRootFromIndex(Index index) {
    final root = index.metadata.projectRoot;
    final uri = Uri.tryParse(root);
    if (uri == null || uri.scheme != 'file') {
      throw SourceProvenanceException(
          'SCIP metadata.project_root is not a file URI: $root');
    }
    return Directory(uri.toFilePath());
  }

  /// Resolves the source root claimed by SCIP and rejects an override that
  /// points at a different worktree. An index is evidence for one concrete
  /// source tree, not merely for any tree with a matching-looking branch.
  Directory sourceRootForIndex(
    Index index, {
    Directory? requestedSourceRoot,
  }) {
    final indexedRoot = sourceRootFromIndex(index);
    if (requestedSourceRoot == null) {
      return indexedRoot;
    }
    if (!indexedRoot.existsSync()) {
      throw SourceProvenanceException(
        'SCIP index source root does not exist: ${indexedRoot.path}',
      );
    }
    if (!requestedSourceRoot.existsSync()) {
      throw SourceProvenanceException(
        'Requested source root does not exist: ${requestedSourceRoot.path}',
      );
    }
    final indexedPath = indexedRoot.resolveSymbolicLinksSync();
    final requestedPath = requestedSourceRoot.resolveSymbolicLinksSync();
    if (indexedPath != requestedPath) {
      throw SourceProvenanceException(
        'Requested source root $requestedPath differs from SCIP '
        'metadata.project_root $indexedPath.',
      );
    }
    return requestedSourceRoot;
  }

  Future<String> currentHead(Directory sourceRoot) =>
      _required(sourceRoot, <String>['rev-parse', 'HEAD']);

  Future<String> currentBranch(Directory sourceRoot) async {
    final branch = await _worktreeRef(sourceRoot);
    return branch == 'DETACHED' ? currentHead(sourceRoot) : branch;
  }

  Future<List<String>> changedFiles({
    required Directory sourceRoot,
    required String baseHead,
    required String sourceHead,
  }) async {
    final result = await _git
        .run(sourceRoot, <String>['diff', '--name-only', baseHead, sourceHead]);
    if (result.exitCode != 0) {
      throw SourceProvenanceException(
          'Unable to read changed files: ${result.stderr.trim()}');
    }
    return result.stdout.split('\n').where((path) => path.isNotEmpty).toList()
      ..sort();
  }

  Future<void> _requireTrackedClean(
      Directory sourceRoot, List<String> arguments) async {
    final result = await _git.run(sourceRoot, arguments);
    if (result.exitCode == 0) {
      return;
    }
    if (result.exitCode == 1) {
      throw SourceProvenanceException(
          'Source worktree has tracked changes; refusing to claim index provenance.');
    }
    throw SourceProvenanceException(
        'Git ${arguments.join(' ')} failed: ${result.stderr.trim()}');
  }

  Future<String> _worktreeRef(Directory sourceRoot) async {
    final result =
        await _git.run(sourceRoot, <String>['branch', '--show-current']);
    if (result.exitCode != 0) {
      throw SourceProvenanceException(
          'Git branch --show-current failed: ${result.stderr.trim()}');
    }
    final branch = result.stdout.trim();
    return branch.isEmpty ? 'DETACHED' : branch;
  }

  Future<String> _required(Directory sourceRoot, List<String> arguments) async {
    final result = await _git.run(sourceRoot, arguments);
    if (result.exitCode != 0) {
      throw SourceProvenanceException(
          'Git ${arguments.join(' ')} failed: ${result.stderr.trim()}');
    }
    final value = result.stdout.trim();
    if (value.isEmpty) {
      throw SourceProvenanceException(
          'Git ${arguments.join(' ')} returned no value.');
    }
    return value;
  }
}
