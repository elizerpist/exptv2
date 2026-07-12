import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../services/native_bridge.dart';
import '../settings/models/security_settings.dart';
import 'security_controller.dart';

class SecurityGateController {
  _SecurityGateState? _state;

  void updateSettings(SecuritySettings settings) {
    _state?._updateKnownSettings(settings);
  }

  void _attach(_SecurityGateState state) {
    _state = state;
  }

  void _detach(_SecurityGateState state) {
    if (identical(_state, state)) _state = null;
  }
}

class SecurityGate extends StatefulWidget {
  const SecurityGate({
    super.key,
    required this.nativeBridge,
    required this.child,
    this.controller,
    this.onUnlocked,
  });

  final NativeBridge nativeBridge;
  final Widget child;
  final SecurityGateController? controller;
  final VoidCallback? onUnlocked;

  @override
  State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate>
    with WidgetsBindingObserver {
  late SecurityController _controller;
  final _pinController = TextEditingController();
  var _wasBackgrounded = false;
  var _reportedUnlocked = false;
  var _childMounted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller?._attach(this);
    _controller = SecurityController(widget.nativeBridge);
    _controller.addListener(_onChanged);
    unawaited(_controller.start());
  }

  @override
  void didUpdateWidget(covariant SecurityGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (oldWidget.nativeBridge == widget.nativeBridge) return;
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _childMounted = false;
    _controller = SecurityController(widget.nativeBridge);
    _controller.addListener(_onChanged);
    unawaited(_controller.start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller?._detach(this);
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _wasBackgrounded = true;
      return;
    }
    if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      _reportedUnlocked = false;
      unawaited(_controller.lockForResume());
    }
  }

  void _onChanged() {
    if (!_controller.loading && !_controller.locked) _childMounted = true;
    if (mounted) setState(() {});
  }

  void _updateKnownSettings(SecuritySettings settings) {
    _controller.updateKnownSettings(settings);
  }

  @override
  Widget build(BuildContext context) {
    final childVisible = !_controller.loading && !_controller.locked;
    if (childVisible) {
      _reportUnlockedOnce();
    } else {
      _reportedUnlocked = false;
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_childMounted)
          TickerMode(
            enabled: childVisible,
            child: Offstage(offstage: !childVisible, child: widget.child),
          )
        else
          const SizedBox.expand(),
        if (_controller.loading)
          const ColoredBox(
            color: AppColors.gray100,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_controller.locked)
          _LockScreen(
            controller: _pinController,
            error: _controller.error,
            biometricReady: _controller.settings.biometricReady,
            authenticatingBiometric: _controller.authenticatingBiometric,
            onUnlock: _unlock,
            onBiometric: _controller.authenticateBiometric,
          ),
      ],
    );
  }

  Future<void> _unlock() async {
    await _controller.unlockWithPin(_pinController.text);
    if (!_controller.locked) _pinController.clear();
  }

  void _reportUnlockedOnce() {
    if (_reportedUnlocked || widget.onUnlocked == null) return;
    _reportedUnlocked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _controller.loading || _controller.locked) return;
      widget.onUnlocked?.call();
    });
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({
    required this.controller,
    required this.error,
    required this.biometricReady,
    required this.authenticatingBiometric,
    required this.onUnlock,
    required this.onBiometric,
  });

  final TextEditingController controller;
  final String? error;
  final bool biometricReady;
  final bool authenticatingBiometric;
  final Future<void> Function() onUnlock;
  final Future<void> Function() onBiometric;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.gray100,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock, size: 42, color: AppColors.gray800),
                  const SizedBox(height: 18),
                  const Text(
                    'Feloldás',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.gray800,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    key: const ValueKey('lock-pin-input'),
                    controller: controller,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 14),
                  FilledButton(
                    key: const ValueKey('lock-unlock-button'),
                    onPressed: onUnlock,
                    child: const Text('Belépés'),
                  ),
                  if (biometricReady) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const ValueKey('lock-biometric-button'),
                      onPressed: authenticatingBiometric ? null : onBiometric,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Biometria'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
