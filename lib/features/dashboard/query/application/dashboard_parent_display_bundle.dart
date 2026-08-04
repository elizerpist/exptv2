import 'package:flutter/foundation.dart';

import '../data/dashboard_child_preview_bundle.dart';
import '../domain/current_ledger_query_scope.dart';
import 'dashboard_presentation_store.dart';

/// The complete data contract required before a parent scope can become the
/// visible dashboard owner.
///
/// The parent snapshot and its child preview bundle are prepared together,
/// but widgets still receive only the immutable snapshot selected by the
/// presentation store. This object is a readiness boundary, not a second
/// query or widget cache.
@immutable
class DashboardParentDisplayBundle {
  const DashboardParentDisplayBundle({
    required this.parentSnapshot,
    this.childPreviewBundle,
    this.childPreviewReady = true,
  });

  final DashboardPresentationSnapshot parentSnapshot;
  final DashboardChildPreviewBundle? childPreviewBundle;
  final bool childPreviewReady;

  LedgerQueryKey get parentQueryKey => parentSnapshot.queryKey;

  bool get isComplete {
    final childBundle = childPreviewBundle;
    return parentSnapshot.hasValue &&
        parentSnapshot.scope != null &&
        parentSnapshot.scope!.key == parentQueryKey &&
        !parentSnapshot.isLoading &&
        !parentSnapshot.isStale &&
        !parentSnapshot.hasError &&
        childPreviewReady &&
        (childBundle == null ||
            (childBundle.parentQueryKey == parentQueryKey &&
                (parentSnapshot.coreRevision == null ||
                    parentSnapshot.coreRevision == childBundle.coreRevision)));
  }
}
