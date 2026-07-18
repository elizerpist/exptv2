import 'package:flutter/foundation.dart';

abstract class BrowserFullscreenDriver {
  bool get isAvailable;

  bool get isFullscreen;

  void addStateListener(VoidCallback listener);

  void removeStateListener(VoidCallback listener);

  Future<void> enter();

  Future<void> exit();

  void dispose();
}

class BrowserFullscreenController extends ChangeNotifier {
  BrowserFullscreenController(this._driver) {
    _driver.addStateListener(_handleDriverStateChanged);
  }

  final BrowserFullscreenDriver _driver;
  var _requestPending = false;
  var _disposed = false;

  bool get isAvailable => _driver.isAvailable;

  bool get isFullscreen => _driver.isFullscreen;

  bool get requestPending => _requestPending;

  Future<void> toggle() async {
    if (!isAvailable || _requestPending || _disposed) return;
    _requestPending = true;
    _notifyIfMounted();
    try {
      if (isFullscreen) {
        await _driver.exit();
      } else {
        await _driver.enter();
      }
    } catch (error) {
      debugPrint('[BrowserFullscreen] request failed: $error');
    } finally {
      _requestPending = false;
      _notifyIfMounted();
    }
  }

  void _handleDriverStateChanged() => _notifyIfMounted();

  void _notifyIfMounted() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _driver.removeStateListener(_handleDriverStateChanged);
    _driver.dispose();
    super.dispose();
  }
}
