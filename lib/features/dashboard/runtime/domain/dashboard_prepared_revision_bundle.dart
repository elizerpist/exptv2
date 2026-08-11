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

/// The application-level atomic product of prepared navigation data and the
/// matching publication-critical rail-preview presentation bank.
@immutable
final class DashboardPreparedRevisionBundle {
  DashboardPreparedRevisionBundle({
    required this.index,
    required this.railCriticalSceneBankIdentity,
    DashboardLogBoxSceneWindow? railCriticalSceneWindow,
  }) : railCriticalSceneWindow =
           railCriticalSceneWindow ??
           _railCriticalSceneWindowFor(index, railCriticalSceneBankIdentity) {
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
      railCriticalSceneWindow: _railCriticalSceneWindowFor(
        index,
        identity,
        publicationState: publicationState,
      ),
    );
  }

  final PreparedDashboardIndex index;
  final DashboardRailCriticalSceneBankIdentity railCriticalSceneBankIdentity;
  final DashboardLogBoxSceneWindow railCriticalSceneWindow;

  int get coreRevision => index.coreRevision;
  int get indexGeneration => index.generation;

  static DashboardLogBoxSceneWindow _railCriticalSceneWindowFor(
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
      // domain must therefore be paint-ready for both directions, rather
      // than exposing the opposite direction while a rebase is pending.
      for (final direction in LedgerDirection.values) {
        final parentQueryKey = publicationState.parentQueryScope
            .copyWith(direction: direction)
            .key;
        final parent = index.frameForKey(parentQueryKey).logBox;
        payloads[parent.queryKey.value] = parent;
        for (final semantic in index.catalogForKey(parentQueryKey).entries) {
          final child = index.frameForKey(semantic.queryKey).logBox;
          payloads[child.queryKey.value] = child;
        }
      }
    }
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
