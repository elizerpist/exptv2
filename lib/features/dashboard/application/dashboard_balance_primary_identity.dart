import 'package:flutter/foundation.dart';

/// Immutable upstream provenance for one Balance primary-card projection.
///
/// This neutral identity is shared by the independent Balance projections. Its
/// input is limited to already admitted directional prepared memberships; it
/// has no repository, Query, scene, or widget capability.
@immutable
final class DashboardBalancePrimaryIdentity {
  const DashboardBalancePrimaryIdentity({
    required this.upstreamScopeKey,
    required this.indexGeneration,
    required this.coreRevision,
  });

  final String upstreamScopeKey;
  final int indexGeneration;
  final int coreRevision;

  @override
  bool operator ==(Object other) =>
      other is DashboardBalancePrimaryIdentity &&
      other.upstreamScopeKey == upstreamScopeKey &&
      other.indexGeneration == indexGeneration &&
      other.coreRevision == coreRevision;

  @override
  int get hashCode =>
      Object.hash(upstreamScopeKey, indexGeneration, coreRevision);
}
