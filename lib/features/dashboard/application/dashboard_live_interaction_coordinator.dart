import 'package:flutter/foundation.dart';

import '../query/domain/ledger_direction.dart';
import '../time_navigation/application/dashboard_time_navigation_state.dart';
import 'dashboard_ephemeral_focus_controller.dart';

/// Direct-manipulation sources that can replace the visible dashboard intent.
/// These are provenance only; the established navigation, direction, Budget
/// target and committed-query owners remain the sources of truth.
enum DashboardLiveInteractionSource {
  temporalSelector,
  summaryLevel,
  budgetAvatar,
  mindRange,
  logBoxCategory,
  partnerSwipe,
  search,
  facetClose,
  direction,
}

/// One immutable, process-local identity for an accepted dashboard intent.
///
/// This intentionally snapshots references owned elsewhere instead of
/// creating a second navigation/filter store. Consumers use its generation to
/// reject stale expensive scene/paging completions while immediate prepared
/// projections bind from this same semantic frame.
@immutable
final class DashboardLiveInteractionFrame {
  const DashboardLiveInteractionFrame({
    required this.generation,
    required this.source,
    required this.coreRevision,
    required this.direction,
    required this.temporalCandidate,
    required this.category,
    required this.partner,
    required this.normalizedSearch,
    this.budgetTargetHandle,
    this.effectiveQueryKey,
    this.preparedIndexGeneration,
    this.visibleFrameGeneration,
    this.presentationEpoch,
    this.minimumAmountScaled100,
    this.maximumAmountScaled100,
    this.interactionPublicationEpoch,
    this.producerLocalGeneration,
  });

  final int generation;
  final DashboardLiveInteractionSource source;
  final int? coreRevision;
  final LedgerDirection direction;
  final DashboardNavigationState temporalCandidate;
  final DashboardFocusFacet? category;
  final DashboardFocusFacet? partner;
  final String? normalizedSearch;
  final int? budgetTargetHandle;
  final String? effectiveQueryKey;
  final int? preparedIndexGeneration;
  final int? visibleFrameGeneration;
  final int? presentationEpoch;
  final int? minimumAmountScaled100;
  final int? maximumAmountScaled100;
  final int? interactionPublicationEpoch;
  final int? producerLocalGeneration;

  int get semanticTickSequence => generation;

  String get projectionKey =>
      'source:${source.name}|tick:$generation|'
      'rev:${coreRevision ?? 0}|dir:${direction.name}|'
      'scope:${temporalCandidate.effectiveScope}|'
      'query:${effectiveQueryKey ?? temporalCandidate.parentQueryKey.value}|'
      'target:${budgetTargetHandle ?? '-'}|'
      'category:${category?.id ?? '-'}|partner:${partner?.id ?? '-'}|'
      'search:${normalizedSearch?.length ?? 0}|'
      'amount:${minimumAmountScaled100 ?? '-'}..${maximumAmountScaled100 ?? '-'}|'
      'index:${preparedIndexGeneration ?? '-'}|'
      'frame:${visibleFrameGeneration ?? '-'}|'
      'epoch:${presentationEpoch ?? '-'}|'
      'publication:${interactionPublicationEpoch ?? '-'}|'
      'local:${producerLocalGeneration ?? '-'}';
}

/// Monotonic latest-wins owner for accepted live dashboard intent.
final class DashboardLiveInteractionCoordinator extends ChangeNotifier {
  DashboardLiveInteractionFrame? _frame;
  int _generation = 0;

  DashboardLiveInteractionFrame? get frame => _frame;
  int get generation => _generation;

  DashboardLiveInteractionFrame accept({
    required DashboardLiveInteractionSource source,
    required int? coreRevision,
    required LedgerDirection direction,
    required DashboardNavigationState temporalCandidate,
    required DashboardFocusFacet? category,
    required DashboardFocusFacet? partner,
    required String? normalizedSearch,
    int? budgetTargetHandle,
    String? effectiveQueryKey,
    int? preparedIndexGeneration,
    int? visibleFrameGeneration,
    int? presentationEpoch,
    int? minimumAmountScaled100,
    int? maximumAmountScaled100,
    int? interactionPublicationEpoch,
    int? producerLocalGeneration,
  }) {
    final next = DashboardLiveInteractionFrame(
      generation: ++_generation,
      source: source,
      coreRevision: coreRevision,
      direction: direction,
      temporalCandidate: temporalCandidate,
      category: category,
      partner: partner,
      normalizedSearch: normalizedSearch,
      budgetTargetHandle: budgetTargetHandle,
      effectiveQueryKey: effectiveQueryKey,
      preparedIndexGeneration: preparedIndexGeneration,
      visibleFrameGeneration: visibleFrameGeneration,
      presentationEpoch: presentationEpoch,
      minimumAmountScaled100: minimumAmountScaled100,
      maximumAmountScaled100: maximumAmountScaled100,
      interactionPublicationEpoch: interactionPublicationEpoch,
      producerLocalGeneration: producerLocalGeneration,
    );
    _frame = next;
    notifyListeners();
    return next;
  }

  bool isCurrent(DashboardLiveInteractionFrame frame) =>
      identical(_frame, frame) && frame.generation == _generation;
}
