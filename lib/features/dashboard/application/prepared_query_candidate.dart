import 'dart:async';

import 'package:flutter/foundation.dart';

import '../logbox/application/dashboard_logbox_scene_window.dart';
import '../query/application/query_composer_controller.dart';
import '../query/domain/current_ledger_query_scope.dart';
import '../query/domain/dashboard_directional_query_set.dart';
import '../query/domain/query_menu_data.dart';
import '../runtime/application/dashboard_data_runtime.dart';
import '../runtime/domain/dashboard_prepared_revision_bundle.dart';
import '../runtime/domain/prepared_dashboard_index.dart';
import '../time_navigation/application/dashboard_time_navigation_state.dart';
import '../time_navigation/domain/dashboard_temporal_availability.dart';

/// A complete but deliberately invisible dashboard revision prepared behind a
/// Query editing surface.  It owns no applied state: the core controller may
/// either atomically consume it or discard it without changing the dashboard.
@immutable
final class PreparedQueryCandidate {
  const PreparedQueryCandidate({
    required this.data,
    required this.composerIdentity,
    required this.editedScope,
    required this.facetPresentation,
    required this.requestTemplate,
    required this.availability,
    required this.publicationState,
    required this.bundle,
    required this.structuralWindow,
    required this.currentParentInteractionWindow,
    required this.sceneStaged,
  });

  /// The immutable, cross-session cache value. It deliberately excludes the
  /// composer session, facet presentation, and staged scene ownership.
  final PreparedQueryCandidateData data;
  final QueryComposerApplyIdentity? composerIdentity;
  final CurrentLedgerQueryScope editedScope;
  final QueryMenuData? facetPresentation;
  final DashboardIndexRequestTemplate requestTemplate;
  final DashboardTemporalAvailability availability;
  final DashboardNavigationState publicationState;
  final DashboardPreparedRevisionBundle bundle;
  final DashboardLogBoxSceneWindow structuralWindow;

  /// Complete bounded sibling domain for the candidate's initial parent.
  /// The Query sheet hides preparation of this bank, so an accepted Apply
  /// never hands the first rail gesture to a cancellable background warmup.
  final DashboardLogBoxSceneWindow currentParentInteractionWindow;

  /// True only while the existing scene-cache owner's private staged bank is
  /// still this exact window.  A cached immutable index remains reusable even
  /// after a newer candidate has replaced that staging slot.
  final bool sceneStaged;

  String get cacheKey => data.cacheKey;
  DashboardDirectionalQuerySet get directionalQueries =>
      data.directionalQueries;
  PreparedDashboardIndex get index => data.index;

  PreparedQueryCandidate copyWith({
    QueryMenuData? facetPresentation,
    bool? sceneStaged,
  }) => PreparedQueryCandidate(
    data: data,
    composerIdentity: composerIdentity,
    editedScope: editedScope,
    facetPresentation: facetPresentation ?? this.facetPresentation,
    requestTemplate: requestTemplate,
    availability: availability,
    publicationState: publicationState,
    bundle: bundle,
    structuralWindow: structuralWindow,
    currentParentInteractionWindow: currentParentInteractionWindow,
    sceneStaged: sceneStaged ?? this.sceneStaged,
  );
}

/// Reusable immutable prepared data. The controller's bounded LRU owns these
/// values across Query sheet sessions. A new session reconstructs its own
/// publication/staging wrapper around the exact data.
@immutable
final class PreparedQueryCandidateData {
  const PreparedQueryCandidateData({
    required this.cacheKey,
    required this.directionalQueries,
    required this.index,
  });

  final String cacheKey;
  final DashboardDirectionalQuerySet directionalQueries;
  final PreparedDashboardIndex index;
}

/// One exact in-flight candidate. Its future is shared by foreground Apply,
/// Query-menu draft preparation, and an admitted chip hotset member. A
/// same-identity foreground intent transfers the existing operation instead
/// of restarting the one native immutable-index build lane.
enum PreparedQueryCandidatePreparationOwner { foreground, queryChipHotset }

final class PreparedQueryCandidatePreparation {
  PreparedQueryCandidatePreparation({
    required this.generation,
    required this.cacheKey,
    required this.composerIdentity,
    this.owner = PreparedQueryCandidatePreparationOwner.foreground,
    this.queryChipPrewarmGeneration,
    this.facetPresentation,
  }) : completion = Completer<PreparedQueryCandidate?>();

  final int generation;
  final String cacheKey;
  QueryComposerApplyIdentity? composerIdentity;
  QueryMenuData? facetPresentation;
  PreparedQueryCandidatePreparationOwner owner;

  /// Non-null only for an operation that started as an admitted speculative
  /// hotset member. It remains immutable when foreground adopts it so the
  /// original speculative continuation can fail closed by its own generation.
  final int? queryChipPrewarmGeneration;
  final Completer<PreparedQueryCandidate?> completion;

  Future<PreparedQueryCandidate?> get future => completion.future;

  bool get isQueryChipHotset =>
      owner == PreparedQueryCandidatePreparationOwner.queryChipHotset;

  bool get wasQueryChipHotset => queryChipPrewarmGeneration != null;

  bool get isPromotedQueryChipHotset =>
      wasQueryChipHotset &&
      owner == PreparedQueryCandidatePreparationOwner.foreground;

  void promoteToForeground({
    required QueryComposerApplyIdentity? foregroundComposerIdentity,
    QueryMenuData? foregroundFacetPresentation,
  }) {
    owner = PreparedQueryCandidatePreparationOwner.foreground;
    composerIdentity = foregroundComposerIdentity;
    facetPresentation = foregroundFacetPresentation ?? facetPresentation;
  }
}
