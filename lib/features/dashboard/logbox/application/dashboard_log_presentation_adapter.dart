import 'package:flutter/foundation.dart';

import '../../query/application/dashboard_presentation_store.dart';
import 'dashboard_log_view_models.dart';

/// Derived LogBox state. It observes the central presentation store but owns
/// no query, navigation, repository, or live-lease lifecycle.
class DashboardLogPresentationAdapter extends ChangeNotifier {
  DashboardLogPresentationAdapter({required DashboardPresentationStore store})
    : _store = store {
    _store.addListener(_handleStoreChanged);
    _store.addMetadataListener(_handleStoreChanged);
    _reproject();
  }

  final DashboardPresentationStore _store;
  DashboardLogViewportState? _state;
  int _projectionCount = 0;
  int _listRebindCount = 0;

  DashboardLogViewportState? get state => _state;
  int get projectionCount => _projectionCount;
  int get listRebindCount => _listRebindCount;

  void _handleStoreChanged() => _reproject();

  void _reproject() {
    final snapshot = _store.activeSnapshot;
    if (snapshot == null) return;
    final projected = DashboardLogViewModelProjector.presentSnapshot(snapshot);
    _projectionCount += 1;
    final previous = _state;
    if (previous != null && previous.hasSameVisualValue(projected)) {
      // A preview->committed promotion may alter only paging/provenance. Keep
      // the already projected group/row list instance and update metadata.
      _state = projected.copyWith(groups: previous.groups);
      if (_state!.isPreview == previous.isPreview &&
          _state!.nextCursor == previous.nextCursor) {
        return;
      }
      notifyListeners();
      return;
    }
    _listRebindCount += 1;
    _state = projected;
    notifyListeners();
  }

  @override
  void dispose() {
    _store.removeListener(_handleStoreChanged);
    _store.removeMetadataListener(_handleStoreChanged);
    super.dispose();
  }
}
