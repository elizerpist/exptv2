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
  String? _error;

  SecuritySettings get settings => _settings;
  bool get loading => _loading;
  bool get locked => _locked;
  bool get authenticatingBiometric => _authenticatingBiometric;
  String? get error => _error;

  Future<void> start() async {
    await _load(lockIfEnabled: true);
  }

  Future<void> lockForResume() async {
    await _load(lockIfEnabled: true);
  }

  Future<void> refreshSettings() async {
    await _load(lockIfEnabled: false);
  }

  Future<void> _load({required bool lockIfEnabled}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final payload = await _nativeBridge.expenseLoadSettings();
      _settings = payload.securitySettings;
      if (lockIfEnabled && _settings.authEnabled) {
        _locked = true;
        if (_settings.biometricReady) {
          unawaited(authenticateBiometric());
        }
      } else if (!_settings.authEnabled) {
        _locked = false;
      }
    } catch (error) {
      _error = error.toString();
      _locked = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> authenticateBiometric() async {
    if (!_settings.biometricReady || _authenticatingBiometric) return;
    _authenticatingBiometric = true;
    _error = null;
    notifyListeners();
    try {
      final ok = await _nativeBridge.expenseAuthenticateBiometric();
      if (ok) _locked = false;
    } catch (error) {
      _error = error.toString();
    } finally {
      _authenticatingBiometric = false;
      notifyListeners();
    }
  }

  Future<void> unlockWithPin(String pin) async {
    final ok = await _nativeBridge.expenseVerifySecurityPin(pin);
    if (ok) {
      _locked = false;
      _error = null;
    } else {
      _error = 'Hibás PIN.';
    }
    notifyListeners();
  }
}
