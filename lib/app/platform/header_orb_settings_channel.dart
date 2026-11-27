import 'package:flutter/services.dart';

abstract final class HeaderOrbSettingsChannel {
  static const methods = MethodChannel('fluvi/header_orb_widget');
  static final changes = const EventChannel('fluvi/header_orb_state')
      .receiveBroadcastStream()
      .map((event) => Map<String, Object?>.from(event as Map));
}
