import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../features/dashboard/presentation/core_modes/dashboard_header_category_scale.dart';
import '../../features/dashboard/presentation/core_modes/dashboard_header_orb_material.dart';
import '../../features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';

/// Sends semantic Header material input to the native keyguard card. This is
/// deliberately independent from AppWidget host count and from the Header's
/// paint ticker: one publication describes a scene; Android advances time.
final class DashboardKeyguardMaterialBridge {
  DashboardKeyguardMaterialBridge({
    required DashboardHeaderVisualController controller,
    required this.balanceFrame,
    required this.budgetFrame,
    required this.mindFrame,
    MethodChannel? channel,
  }) : _controller = controller,
       _channel = channel ?? const MethodChannel(_channelName),
       _session =
           'keyguard-${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(controller)}' {
    _controller.tuning.addListener(schedule);
    _controller.portalSettingsGeneration.addListener(schedule);
    _controller.orbExportCommitGeneration.addListener(_scheduleFinal);
    balanceFrame.addListener(schedule);
    budgetFrame.addListener(schedule);
    mindFrame.addListener(schedule);
    _channel.setMethodCallHandler(_onNativeMethodCall);
  }

  static const _channelName = 'fluvi/keyguard_material';

  final DashboardHeaderVisualController _controller;
  final ValueListenable<DashboardHeaderVisualFrame> balanceFrame;
  final ValueListenable<DashboardHeaderVisualFrame> budgetFrame;
  final ValueListenable<DashboardHeaderVisualFrame> mindFrame;
  final MethodChannel _channel;
  final String _session;
  Size? _geometry;
  Timer? _debounce;
  var _publishing = false;
  var _pending = false;
  var _generation = 0;
  var _disposed = false;

  Future<Object?> _onNativeMethodCall(MethodCall call) async {
    if (call.method == 'refreshScene') {
      _scheduleFinal();
      return null;
    }
    throw MissingPluginException(
      'Unknown keyguard material call: ${call.method}',
    );
  }

  void updateHeaderGeometry(Size value) {
    if (_disposed || value.isEmpty || _geometry == value) return;
    _geometry = value;
    schedule();
  }

  void schedule() {
    if (_disposed) return;
    _generation += 1;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 48), () {
      unawaited(_publish(_generation));
    });
  }

  void _scheduleFinal() {
    if (_disposed) return;
    _generation += 1;
    _debounce?.cancel();
    unawaited(_publish(_generation));
  }

  Future<void> _publish(int requestedGeneration) async {
    if (_disposed || _geometry == null) return;
    if (_publishing) {
      _pending = true;
      return;
    }
    _publishing = true;
    try {
      final target = await _channel.invokeMapMethod<Object?, Object?>(
        'sceneTarget',
      );
      if (_disposed || requestedGeneration != _generation) return;
      final frame = _frameForTarget(target);
      final snapshot = DashboardHeaderMaterialSnapshot.capture(
        controller: _controller,
        frame: frame,
      );
      final profile = snapshot.keyguardMaterialProfile(
        publisherSession: _session,
        publisherRevision: requestedGeneration,
        referenceGeometry: _geometry!,
        sceneIdentity: _sceneIdentity(target),
      );
      if (_disposed || requestedGeneration != _generation) return;
      await _channel.invokeMethod<Object?>('publishProfile', profile);
    } on MissingPluginException {
      // Non-Android/widget-test hosts have no native card sink.
    } on PlatformException {
      // The activity can be replaced while a semantic publication is queued.
    } finally {
      _publishing = false;
      if ((_pending || requestedGeneration != _generation) && !_disposed) {
        _pending = false;
        unawaited(_publish(_generation));
      }
    }
  }

  DashboardHeaderVisualFrame _frameForTarget(Map<Object?, Object?>? target) {
    final mode = target?['mode'] as String?;
    if (mode != 'budget') {
      return switch (mode) {
        'mind' => mindFrame.value,
        _ => balanceFrame.value,
      };
    }
    final tuning = _controller.tuning.value;
    if (tuning.budgetCategory.source !=
        DashboardBudgetHeaderColorSource.category) {
      return budgetFrame.value;
    }
    final colorId = target?['categoryColorId'] as String?;
    final scale = DashboardHeaderCategoryCompressedV1Scale.forColorIdOrNull(
      colorId,
    );
    if (scale == null) return budgetFrame.value;
    final remaining = (target?['remainingPercent'] as num?)?.toDouble();
    final window = DashboardHeaderCategoryWindowSampler.sample(
      scale: scale,
      remainingPercent: remaining,
      windowWidthPercent: tuning.budgetCategory.windowWidthPercent,
    );
    return BudgetHeaderCategoryColorScale.fromWindow(
      window: window,
      opacityScalePosition: tuning.budgetHeader.opacityPercent,
      staticSettingsGeneration: tuning.generation,
      headerIconColor: tuning.budgetHeader.iconColor.color,
      headerModeIconSizePercent: tuning.headerModeIconSizePercent,
    );
  }

  String _sceneIdentity(Map<Object?, Object?>? target) => <Object?>[
    target?['mode'],
    target?['timeAxis'],
    target?['direction'],
    target?['categoryId'],
    target?['focusGeneration'],
  ].join('|');

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _debounce?.cancel();
    _controller.tuning.removeListener(schedule);
    _controller.portalSettingsGeneration.removeListener(schedule);
    _controller.orbExportCommitGeneration.removeListener(_scheduleFinal);
    balanceFrame.removeListener(schedule);
    budgetFrame.removeListener(schedule);
    mindFrame.removeListener(schedule);
    _channel.setMethodCallHandler(null);
  }
}
