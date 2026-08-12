import 'package:flutter/foundation.dart';

import '../../logbox/application/dashboard_log_viewport_state.dart';
import '../../logbox/application/dashboard_logbox_scene_window.dart';
import '../../query/domain/ledger_direction.dart';
import '../../time_navigation/application/dashboard_time_navigation_state.dart';
import 'prepared_dashboard_index.dart';

/// Immutable revision identity for rail-preview visual resources derived from
/// one exact prepared dashboard index.
@immutable
final class DashboardRailCriticalSceneBankIdentity {
  const DashboardRailCriticalSceneBankIdentity({
    required this.coreRevision,
    required this.indexGeneration,
  }) : assert(coreRevision > 0),
       assert(indexGeneration > 0);

  factory DashboardRailCriticalSceneBankIdentity.forIndex(
    PreparedDashboardIndex index,
  ) => DashboardRailCriticalSceneBankIdentity(
    coreRevision: index.coreRevision,
    indexGeneration: index.generation,
  );

  final int coreRevision;
  final int indexGeneration;

  String get value => 'rail-critical:rev:$coreRevision|index:$indexGeneration';

  @override
  bool operator ==(Object other) =>
      other is DashboardRailCriticalSceneBankIdentity &&
      other.coreRevision == coreRevision &&
      other.indexGeneration == indexGeneration;

  @override
  int get hashCode => Object.hash(coreRevision, indexGeneration);
}

/// The immutable scene requirements derived from one prepared dashboard index.
///
/// A structural publication needs only the first drawable parent payload. The
/// larger immediate rail domain is valuable for interaction, but it must not
/// delay publication of a Summary Pill target. Keeping both projections here
/// prevents a controller caller from accidentally making rail siblings part
/// of the foreground publication barrier again.
@immutable
final class DashboardPreparedRevisionBundle {
  DashboardPreparedRevisionBundle({
    required this.index,
    required this.railCriticalSceneBankIdentity,
    required this.structuralPublicationSceneWindow,
    required this.railInteractionSceneWindow,
  }) {
    if (index.coreRevision != railCriticalSceneBankIdentity.coreRevision ||
        index.generation != railCriticalSceneBankIdentity.indexGeneration) {
      throw ArgumentError(
        'Prepared index and rail-critical scene bank identities must match.',
      );
    }
  }

  factory DashboardPreparedRevisionBundle.forIndex(
    PreparedDashboardIndex index, {
    DashboardNavigationState? publicationState,
  }) {
    final identity = DashboardRailCriticalSceneBankIdentity.forIndex(index);
    return DashboardPreparedRevisionBundle(
      index: index,
      railCriticalSceneBankIdentity: identity,
      structuralPublicationSceneWindow: _structuralPublicationSceneWindowFor(
        index,
        identity,
        publicationState: publicationState,
      ),
      railInteractionSceneWindow: _railInteractionSceneWindowFor(
        index,
        identity,
        publicationState: publicationState,
      ),
    );
  }

  final PreparedDashboardIndex index;
  final DashboardRailCriticalSceneBankIdentity railCriticalSceneBankIdentity;

  /// Exact first-frame scenes for an uncommitted structural target.
  final DashboardLogBoxSceneWindow structuralPublicationSceneWindow;

  /// Current parent's complete immediate semantic rail domain for both
  /// synchronously reachable directions. This is background interaction work.
  final DashboardLogBoxSceneWindow railInteractionSceneWindow;

  int get coreRevision => index.coreRevision;
  int get indexGeneration => index.generation;

  static DashboardLogBoxSceneWindow _structuralPublicationSceneWindowFor(
    PreparedDashboardIndex index,
    DashboardRailCriticalSceneBankIdentity identity, {
    DashboardNavigationState? publicationState,
  }) {
    final payloads = <String, DashboardLogViewportState>{};
    if (publicationState == null) {
      for (final frame in index.frames.values) {
        payloads[frame.logBox.queryKey.value] = frame.logBox;
      }
    } else {
      // Direction is synchronously reachable UI state. The active temporal
      // parent must therefore be paint-ready for both directions. Children
      // belong to the interaction window and are intentionally not a
      // structural-publication precondition.
      for (final direction in LedgerDirection.values) {
        // The two directions may have different category/partner/temporal
        // templates.  Looking up the prepared parent is therefore the only
        // valid way to obtain the twin scope; copying filters from the
        // currently visible direction would leak its Query into the other
        // universe.
        final directionScope = index
            .catalogForIdentity(
              direction: direction,
              timeScope: publicationState.parentScope,
            )
            ?.parentScope;
        if (directionScope == null) continue;
        final parentQueryKey = directionScope.key;
        final parent = index.frameForKey(parentQueryKey).logBox;
        payloads[parent.queryKey.value] = parent;
        // An open rail paints its retained child rather than its parent. A
        // structural parent/plane transition can preserve that open state, so
        // its exact first child must join the O(1) publication window. Other
        // rail siblings remain interaction-only background work.
        if (publicationState.isRailOpen) {
          final childQueryKey = directionScope
              .copyWith(timeScope: publicationState.retainedChildScope)
              .key;
          final child = index.frameForKey(childQueryKey).logBox;
          payloads[child.queryKey.value] = child;
        }
      }
    }
    return _window(identity, payloads);
  }

  static DashboardLogBoxSceneWindow _railInteractionSceneWindowFor(
    PreparedDashboardIndex index,
    DashboardRailCriticalSceneBankIdentity identity, {
    DashboardNavigationState? publicationState,
  }) {
    final payloads = <String, DashboardLogViewportState>{};
    if (publicationState == null) {
      for (final frame in index.frames.values) {
        payloads[frame.logBox.queryKey.value] = frame.logBox;
      }
    } else {
      for (final direction in LedgerDirection.values) {
        final parentQueryKey = index
            .catalogForIdentity(
              direction: direction,
              timeScope: publicationState.parentScope,
            )
            ?.parentScope
            .key;
        if (parentQueryKey == null) continue;
        final parent = index.frameForKey(parentQueryKey).logBox;
        payloads[parent.queryKey.value] = parent;
        for (final semantic in index.catalogForKey(parentQueryKey).entries) {
          final child = index.frameForKey(semantic.queryKey).logBox;
          payloads[child.queryKey.value] = child;
        }
      }
    }
    return _window(identity, payloads);
  }

  static DashboardLogBoxSceneWindow _window(
    DashboardRailCriticalSceneBankIdentity identity,
    Map<String, DashboardLogViewportState> payloads,
  ) {
    return DashboardLogBoxSceneWindow(
      identity: identity.value,
      payloads:
          (payloads.values.toList()..sort(
                (left, right) =>
                    left.queryKey.value.compareTo(right.queryKey.value),
              ))
              .toList(growable: false),
    );
  }
}
