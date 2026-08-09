import 'package:flutter/foundation.dart';

import '../../logbox/application/dashboard_log_viewport_state.dart';
import '../../logbox/application/dashboard_logbox_scene_window.dart';
import 'prepared_dashboard_index.dart';

/// Immutable publication identity for the complete rail-preview visual bank
/// derived from one exact prepared dashboard index.
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
/// matching complete rail-preview presentation bank.
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
    PreparedDashboardIndex index,
  ) {
    final identity = DashboardRailCriticalSceneBankIdentity.forIndex(index);
    return DashboardPreparedRevisionBundle(
      index: index,
      railCriticalSceneBankIdentity: identity,
      railCriticalSceneWindow: _railCriticalSceneWindowFor(index, identity),
    );
  }

  final PreparedDashboardIndex index;
  final DashboardRailCriticalSceneBankIdentity railCriticalSceneBankIdentity;
  final DashboardLogBoxSceneWindow railCriticalSceneWindow;

  int get coreRevision => index.coreRevision;
  int get indexGeneration => index.generation;

  static DashboardLogBoxSceneWindow _railCriticalSceneWindowFor(
    PreparedDashboardIndex index,
    DashboardRailCriticalSceneBankIdentity identity,
  ) {
    final payloads = <String, DashboardLogViewportState>{
      for (final frame in index.frames.values)
        frame.logBox.queryKey.value: frame.logBox,
    };
    return DashboardLogBoxSceneWindow(
      identity: identity.value,
      payloads: payloads.values.toList(growable: false),
    );
  }
}
