import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../services/native_bridge.dart';
import '../settings/models/security_settings.dart';

class SecurityController extends ChangeNotifier {
  SecurityController(this._nativeBridge);

  final NativeBridge _nativeBridge;
  SecuritySettings _settings = SecuritySettings.defaults();
  var _loading = true;
  var _locked = false;
  var _authenticatingBiometric = false;
  var _settingsLoadGeneration = 0;
  var _authenticationEpoch = 0;
  var _biometricGeneration = 0;
  var _disposed = false;
  String? _error;

  SecuritySettings get settings => _settings;
  bool get loading => _loading;
  bool get locked => _locked;
  bool get authenticatingBiometric => _authenticatingBiometric;
  String? get error => _error;

  Future<void> start() async {
    await _load(lockIfEnabled: true, blocking: true);
  }

  Future<void> lockForResume() async {
    if (_settings.authEnabled) {
      _beginLockSession();
      _error = null;
      _notifyListeners();
    }
    await _load(lockIfEnabled: true, blocking: false);
  }

  Future<void> refreshSettings() async {
    await _load(lockIfEnabled: false, blocking: false);
  }

  void updateKnownSettings(SecuritySettings settings) {
    if (_disposed) return;
    _settingsLoadGeneration += 1;
    _settings = settings;
    _error = null;
    _loading = false;
    if (!settings.authEnabled) _unlockAndInvalidateAuthentication();
    _notifyListeners();
  }

  Future<void> _load({
    required bool lockIfEnabled,
    required bool blocking,
  }) async {
    final generation = ++_settingsLoadGeneration;
    final authenticationEpoch = _authenticationEpoch;
    if (blocking) _loading = true;
    _error = null;
    if (blocking) _notifyListeners();
    var authenticateBiometricAfterLoad = false;
    try {
      final payload = await _nativeBridge.expenseLoadSettings();
      if (!_isCurrentLoad(generation)) return;
      _settings = payload.securitySettings;
      if (lockIfEnabled &&
          _settings.authEnabled &&
          authenticationEpoch == _authenticationEpoch) {
        if (!_locked) _beginLockSession();
        authenticateBiometricAfterLoad = _settings.biometricReady;
      } else if (!_settings.authEnabled) {
        _unlockAndInvalidateAuthentication();
      }
    } catch (error) {
      if (!_isCurrentLoad(generation)) return;
      _error = error.toString();
      if (authenticationEpoch == _authenticationEpoch && !_locked) {
        _beginLockSession();
      }
    } finally {
      if (_isCurrentLoad(generation)) {
        _loading = false;
        _notifyListeners();
      }
    }
    if (authenticateBiometricAfterLoad && _isCurrentLoad(generation)) {
      unawaited(authenticateBiometric());
    }
  }

  Future<void> authenticateBiometric() async {
    if (_disposed ||
        !_locked ||
        !_settings.biometricReady ||
        _authenticatingBiometric) {
      return;
    }
    final generation = ++_biometricGeneration;
    final authenticationEpoch = _authenticationEpoch;
    _authenticatingBiometric = true;
    _error = null;
    _notifyListeners();
    try {
      final ok = await _nativeBridge.expenseAuthenticateBiometric();
      if (!_isCurrentBiometric(generation, authenticationEpoch)) return;
      if (ok) {
        _unlockAndInvalidateAuthentication();
        _notifyListeners();
      }
    } catch (error) {
      if (!_isCurrentBiometric(generation, authenticationEpoch)) return;
      _error = error.toString();
    } finally {
      if (!_disposed && generation == _biometricGeneration) {
        _authenticatingBiometric = false;
        _notifyListeners();
      }
    }
  }

  Future<void> unlockWithPin(String pin) async {
    if (_disposed || !_locked) return;
    final authenticationEpoch = _authenticationEpoch;
    final ok = await _nativeBridge.expenseVerifySecurityPin(pin);
    if (_disposed || authenticationEpoch != _authenticationEpoch) return;
    if (ok) {
      _unlockAndInvalidateAuthentication();
      _error = null;
    } else {
      _error = 'Hibás PIN.';
    }
    _notifyListeners();
  }

  bool _isCurrentLoad(int generation) {
    return !_disposed && generation == _settingsLoadGeneration;
  }

  bool _isCurrentBiometric(int generation, int authenticationEpoch) {
    return !_disposed &&
        generation == _biometricGeneration &&
        authenticationEpoch == _authenticationEpoch;
  }

  void _beginLockSession() {
    _locked = true;
    _authenticationEpoch += 1;
    _biometricGeneration += 1;
    _authenticatingBiometric = false;
  }

  void _unlockAndInvalidateAuthentication() {
    _locked = false;
    _authenticationEpoch += 1;
    _biometricGeneration += 1;
    _authenticatingBiometric = false;
  }

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _settingsLoadGeneration += 1;
    _authenticationEpoch += 1;
    _biometricGeneration += 1;
    super.dispose();
  }
}
