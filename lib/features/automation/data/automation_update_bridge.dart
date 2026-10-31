import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// A wake-up only. Persisted Core data remains authoritative, but a listener
/// callback received while Flutter is alive can refresh Automation and Inbox
/// without polling. Events missed in the background are recovered on resume.
final class AutomationUpdateBridge {
  AutomationUpdateBridge._();

  static const _channel = EventChannel('com.fluvi/automation_updates');

  static Stream<void> get changes => Platform.isAndroid
      ? _channel.receiveBroadcastStream().map<void>((_) {})
      : const Stream<void>.empty();
}
