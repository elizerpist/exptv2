import 'package:flutter/foundation.dart';

import 'browser_fullscreen_controller.dart';

BrowserFullscreenDriver createBrowserFullscreenDriver() =>
    const _UnavailableBrowserFullscreenDriver();

class _UnavailableBrowserFullscreenDriver implements BrowserFullscreenDriver {
  const _UnavailableBrowserFullscreenDriver();

  @override
  bool get isAvailable => false;

  @override
  bool get isFullscreen => false;

  @override
  void addStateListener(VoidCallback listener) {}

  @override
  void removeStateListener(VoidCallback listener) {}

  @override
  Future<void> enter() async {}

  @override
  Future<void> exit() async {}

  @override
  void dispose() {}
}
