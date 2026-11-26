import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../features/dashboard/application/dashboard_core_mode_controller.dart';
import '../../features/dashboard/application/dashboard_mode_spec.dart';
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
    DashboardCoreModeController? activeMode,
    bool Function()? activeHeaderVisible,
    MethodChannel? channel,
  }) : _controller = controller,
       _activeMode = activeMode,
       _activeHeaderVisible = activeHeaderVisible,
       _channel = channel ?? const MethodChannel(_channelName),
       _session =
           'keyguard-${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(controller)}' {
    _controller.tuning.addListener(schedule);
    _controller.portalSettingsGeneration.addListener(schedule);
    _controller.orbExportCommitGeneration.addListener(_scheduleFinal);
    balanceFrame.addListener(schedule);
    budgetFrame.addListener(schedule);
    mindFrame.addListener(schedule);
    _activeMode?.addListener(schedule);
    _channel.setMethodCallHandler(_onNativeMethodCall);
  }

  static const _channelName = 'fluvi/keyguard_material';

  final DashboardHeaderVisualController _controller;
  final DashboardCoreModeController? _activeMode;
  final bool Function()? _activeHeaderVisible;
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
  String? _activeVisualKey;

  Future<Object?> _onNativeMethodCall(MethodCall call) async {
    if (call.method == 'refreshScene') {
      // Native may have discarded the prior generation after a privacy or
      // service change, even when the on-screen colours did not change.
      _activeVisualKey = null;
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
      _scheduleActiveHeader(_generation);
      unawaited(_publish(_generation));
    });
  }

  void _scheduleFinal() {
    if (_disposed) return;
    _generation += 1;
    _debounce?.cancel();
    _scheduleActiveHeader(_generation);
    unawaited(_publish(_generation));
  }

  /// Publishes the committed on-screen Header separately from the configured
  /// card projection. The latter must never select this source's mode or
  /// colour, and a pending frame must not survive a newer semantic change.
  void _scheduleActiveHeader(int requestedGeneration) {
    if (_disposed || _geometry == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_disposed ||
          requestedGeneration != _generation ||
          !(_activeHeaderVisible?.call() ?? true)) {
        return;
      }
      final geometry = _geometry;
      if (geometry == null) return;
      final mode = _activeMode?.committedMode.mode ?? DashboardMode.balance;
      final frame = switch (mode) {
        DashboardMode.balance => balanceFrame.value,
        DashboardMode.budget => budgetFrame.value,
        DashboardMode.mind => mindFrame.value,
      };
      final snapshot = DashboardHeaderMaterialSnapshot.capture(
        controller: _controller,
        frame: frame,
      );
      final modeEpoch = _activeMode?.committedModeEpoch ?? 0;
      final key =
          '${mode.name}|$modeEpoch|$geometry|${snapshot.orbVisualCacheKey}';
      if (key == _activeVisualKey) return;
      final profile = snapshot.keyguardMaterialProfile(
        publisherSession: _session,
        publisherRevision: requestedGeneration,
        referenceGeometry: geometry,
        sceneIdentity: 'active-header:${mode.name}:$modeEpoch',
      );
      profile['activeMode'] = mode.name;
      profile['modeEpoch'] = modeEpoch;
      profile['sourceAnimated'] = snapshot.isAnimated;
      unawaited(_publishActiveHeader(profile, key, requestedGeneration));
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  Future<void> _publishActiveHeader(
    Map<String, Object?> profile,
    String key,
    int requestedGeneration,
  ) async {
    try {
      final receipt = await _channel.invokeMapMethod<Object?, Object?>(
        'publishActiveHeaderProfile',
        profile,
      );
      if (!_disposed &&
          requestedGeneration == _generation &&
          receipt?['accepted'] == true) {
        _activeVisualKey = key;
      }
    } on MissingPluginException {
      // The optional active-header transport is unavailable on this host.
    } on PlatformException {
      // A rejected or detached publication must not become a cache hit.
    }
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
      // The provenance is captured in the same synchronous turn as the
      // selected frame. It does not itself authorize a lockscreen reveal.
      profile['r29Evidence'] = _r29Evidence(target);
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
    // Never turn the material currently visible in another dashboard scope
    // into this card's claimed financial colour.  The renderer still receives
    // the saved Header effect, speed and Portal settings; only the unavailable
    // financial palette is neutralised. In particular Mind has no native,
    // scope-revisioned score projection yet.
    if (target?['projectionAvailable'] != true) {
      return DashboardHeaderVisualFrame.staticTone(const Color(0xff718096));
    }
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
    if (scale == null) {
      return DashboardHeaderVisualFrame.staticTone(const Color(0xff718096));
    }
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

  Map<String, Object?> _r29Evidence(Map<Object?, Object?>? target) {
    final revision = target?['coreRevision'];
    final currentRevision = target?['r29CurrentCoreRevision'];
    final remaining = target?['remainingPercent'];
    final supported =
        target?['mode'] == 'budget' &&
        target?['projectionAvailable'] == true &&
        target?['r29SettingsCurrent'] == true &&
        revision is int &&
        revision > 0 &&
        revision == currentRevision &&
        target?['focusGeneration'] is int &&
        target?['r29LayoutRevision'] is int &&
        target?['r29PrivacyRevision'] is int &&
        _controller.tuning.value.budgetCategory.source ==
            DashboardBudgetHeaderColorSource.category &&
        DashboardHeaderCategoryCompressedV1Scale.forColorIdOrNull(
              target?['categoryColorId'] as String?,
            ) !=
            null &&
        remaining is num &&
        remaining.isFinite;
    return <String, Object?>{
      'targetCoreRevision': revision,
      'visualCoreRevision': supported ? revision : null,
      'currentCoreRevision': currentRevision,
      'focusGeneration': target?['focusGeneration'],
      'layoutRevision': target?['r29LayoutRevision'],
      'privacyRevision': target?['r29PrivacyRevision'],
      'visualProjectionFull':
          supported && target?['r29ShowFinancialDetails'] == true,
    };
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
    _activeMode?.removeListener(schedule);
    _channel.setMethodCallHandler(null);
  }
}
