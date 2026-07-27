/// Keeps a time-rail gesture visual until it settles, then publishes its
/// final scope exactly once. The dashboard owns the store mutation boundary.
class BalanceRailPublicationCoordinator {
  bool _isDragging = false;
  String? _previewKey;
  String? _lastPublishedKey;
  var _superseded = 0;
  var _duplicateFinalLoads = 0;

  bool get isDragging => _isDragging;
  int get superseded => _superseded;
  int get duplicateFinalLoads => _duplicateFinalLoads;

  void reconcileCommitted(String key) {
    if (!_isDragging && _lastPublishedKey == null) _lastPublishedKey = key;
  }

  void beginDrag(String key) {
    _isDragging = true;
    _previewKey = key;
  }

  void preview(String key) {
    if (!_isDragging) return;
    if (_previewKey != null && _previewKey != key) _superseded += 1;
    _previewKey = key;
  }

  bool settle(String key) {
    _isDragging = false;
    if (_lastPublishedKey == key) {
      _duplicateFinalLoads += 1;
      return false;
    }
    _lastPublishedKey = key;
    _previewKey = key;
    return true;
  }
}
