import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'browser_fullscreen_controller.dart';

BrowserFullscreenDriver createBrowserFullscreenDriver() =>
    _WebBrowserFullscreenDriver();

class _WebBrowserFullscreenDriver implements BrowserFullscreenDriver {
  _WebBrowserFullscreenDriver() {
    _fullscreenChangeListener = ((web.Event _) {
      for (final listener in List<VoidCallback>.of(_listeners)) {
        listener();
      }
    }).toJS;
    web.document.addEventListener(
      'fullscreenchange',
      _fullscreenChangeListener,
    );
  }

  final List<VoidCallback> _listeners = <VoidCallback>[];
  late final web.EventListener _fullscreenChangeListener;
  var _disposed = false;

  @override
  bool get isAvailable {
    if (_disposed || web.document.documentElement == null) return false;
    try {
      return web.document.fullscreenEnabled;
    } catch (_) {
      return false;
    }
  }

  @override
  bool get isFullscreen {
    if (_disposed) return false;
    try {
      return web.document.fullscreenElement != null;
    } catch (_) {
      return false;
    }
  }

  @override
  void addStateListener(VoidCallback listener) {
    if (!_disposed) _listeners.add(listener);
  }

  @override
  void removeStateListener(VoidCallback listener) =>
      _listeners.remove(listener);

  @override
  Future<void> enter() async {
    final root = web.document.documentElement;
    if (!isAvailable || root == null) return;
    await root.requestFullscreen().toDart;
  }

  @override
  Future<void> exit() async {
    if (!isFullscreen) return;
    await web.document.exitFullscreen().toDart;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    web.document.removeEventListener(
      'fullscreenchange',
      _fullscreenChangeListener,
    );
    _listeners.clear();
  }
}
