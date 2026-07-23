import 'dart:async';

import 'package:exptv2/core/platform/browser_fullscreen_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrowserFullscreenController', () {
    test('ignores toggle when fullscreen is unavailable', () async {
      final driver = _FakeBrowserFullscreenDriver(isAvailable: false);
      final controller = BrowserFullscreenController(driver);
      addTearDown(controller.dispose);

      await controller.toggle();

      expect(driver.enterCalls, 0);
      expect(driver.exitCalls, 0);
      expect(controller.requestPending, isFalse);
    });

    test('enters and exits based on the current browser state', () async {
      final driver = _FakeBrowserFullscreenDriver();
      final controller = BrowserFullscreenController(driver);
      addTearDown(controller.dispose);

      await controller.toggle();
      expect(driver.enterCalls, 1);
      expect(controller.isFullscreen, isTrue);

      await controller.toggle();
      expect(driver.exitCalls, 1);
      expect(controller.isFullscreen, isFalse);
    });

    test('notifies when the browser changes fullscreen externally', () {
      final driver = _FakeBrowserFullscreenDriver();
      final controller = BrowserFullscreenController(driver);
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      driver.setFullscreenExternally(true);

      expect(controller.isFullscreen, isTrue);
      expect(notifications, 1);
    });

    test('suppresses a second toggle while a request is pending', () async {
      final driver = _FakeBrowserFullscreenDriver();
      final request = Completer<void>();
      driver.enterCompleter = request;
      final controller = BrowserFullscreenController(driver);
      addTearDown(controller.dispose);

      final first = controller.toggle();
      final second = controller.toggle();

      expect(controller.requestPending, isTrue);
      expect(driver.enterCalls, 1);
      await second;
      request.complete();
      await first;
      expect(controller.requestPending, isFalse);
      expect(driver.enterCalls, 1);
    });

    test('swallows a rejected request without reporting fullscreen', () async {
      final driver = _FakeBrowserFullscreenDriver()
        ..enterError = StateError('fullscreen denied');
      final controller = BrowserFullscreenController(driver);
      addTearDown(controller.dispose);

      await expectLater(controller.toggle(), completes);

      expect(controller.isFullscreen, isFalse);
      expect(controller.requestPending, isFalse);
      expect(driver.enterCalls, 1);
    });

    test('disposes the platform driver', () {
      final driver = _FakeBrowserFullscreenDriver();
      final controller = BrowserFullscreenController(driver);

      controller.dispose();

      expect(driver.disposed, isTrue);
    });
  });
}

class _FakeBrowserFullscreenDriver implements BrowserFullscreenDriver {
  _FakeBrowserFullscreenDriver({this.isAvailable = true});

  @override
  final bool isAvailable;

  var _isFullscreen = false;
  var enterCalls = 0;
  var exitCalls = 0;
  var disposed = false;
  Completer<void>? enterCompleter;
  Object? enterError;
  final List<VoidCallback> _listeners = <VoidCallback>[];

  @override
  bool get isFullscreen => _isFullscreen;

  @override
  void addStateListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeStateListener(VoidCallback listener) =>
      _listeners.remove(listener);

  @override
  Future<void> enter() async {
    enterCalls += 1;
    if (enterError case final error?) throw error;
    if (enterCompleter case final completer?) await completer.future;
    _isFullscreen = true;
    _notifyListeners();
  }

  @override
  Future<void> exit() async {
    exitCalls += 1;
    _isFullscreen = false;
    _notifyListeners();
  }

  void setFullscreenExternally(bool value) {
    _isFullscreen = value;
    _notifyListeners();
  }

  void _notifyListeners() {
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }

  @override
  void dispose() {
    disposed = true;
    _listeners.clear();
  }
}
