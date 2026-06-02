import 'dart:async';

import 'package:flutter/foundation.dart';

import '../features/settings/models/notification_parser_rule.dart';
import '../models/installed_app.dart';
import '../models/notification_event.dart';
import '../models/service_status.dart';
import '../services/native_bridge.dart';

class EventStore extends ChangeNotifier {
  EventStore(this._bridge, {this.realtimeEnabled = true});

  final NativeBridge _bridge;
  final bool realtimeEnabled;
  final List<NotificationEvent> _events = <NotificationEvent>[];
  StreamSubscription<NotificationEvent>? _subscription;

  bool filterEnabled = false;
  String filterText = '';
  String? filterError;
  RegExp? _lastValidRegex;
  ServiceStatus? status;
  NotificationParserConfig notificationParserConfig =
      NotificationParserConfig.defaults();
  String? selectedNotificationParserProfileId;
  bool loading = false;

  List<NotificationParserProfile> get notificationParserProfiles =>
      notificationParserConfig.profiles;

  NotificationParserProfile get selectedNotificationParserProfile =>
      notificationParserConfig.selected(selectedNotificationParserProfileId);

  NotificationParserRule get notificationParserRule =>
      selectedNotificationParserProfile.rule;

  NotificationParserPreview get notificationParserPreview =>
      selectedNotificationParserProfile.preview;

  List<NotificationEvent> get events {
    final regex = filterEnabled ? _lastValidRegex : null;
    if (regex == null) return List<NotificationEvent>.unmodifiable(_events);
    return List<NotificationEvent>.unmodifiable(
      _events.where((event) => event.matchesApp(regex)),
    );
  }

  Future<void> start() async {
    loading = true;
    notifyListeners();
    _events
      ..clear()
      ..addAll(await _bridge.loadEvents());
    notificationParserConfig = await _bridge.loadNotificationParserProfiles();
    selectedNotificationParserProfileId = _firstProfileId();
    status = await _bridge.getStatus();
    loading = false;
    notifyListeners();
    if (realtimeEnabled) {
      _subscription ??= _bridge.watchEvents().listen((event) {
        _events.add(event);
        notifyListeners();
      });
    }
  }

  Future<void> refreshStatus() async {
    status = await _bridge.getStatus();
    notifyListeners();
  }

  Future<void> setCaptureMode(CaptureMode mode) async {
    await _bridge.setCaptureMode(mode);
    await refreshStatus();
  }

  Future<List<InstalledApp>> listInstalledApps() => _bridge.listInstalledApps();

  Future<void> loadNotificationParserRule() => loadNotificationParserProfiles();

  Future<void> loadNotificationParserProfiles() async {
    notificationParserConfig = await _bridge.loadNotificationParserProfiles();
    selectedNotificationParserProfileId = _firstProfileId();
    notifyListeners();
  }

  Future<void> setNotificationParserRule(NotificationParserRule rule) async {
    await updateSelectedNotificationParserProfile(
      selectedNotificationParserProfile.copyWith(rule: rule),
      saveIfReady: true,
    );
  }

  void selectNotificationParserProfile(String id) {
    selectedNotificationParserProfileId = id;
    notifyListeners();
  }

  Future<void> addNotificationParserProfile() async {
    final nextIndex = notificationParserProfiles.length + 1;
    final profile = NotificationParserProfile.defaults(index: nextIndex)
        .copyWith(
          id: 'profile-${DateTime.now().millisecondsSinceEpoch}',
          name: 'Profil $nextIndex',
        );
    notificationParserConfig = notificationParserConfig.upsert(profile);
    selectedNotificationParserProfileId = profile.id;
    notifyListeners();
    await _saveNotificationParserProfiles();
  }

  Future<void> setNotificationParserProfileEnabled(
    String id,
    bool enabled,
  ) async {
    final profile = notificationParserConfig
        .selected(id)
        .copyWith(enabled: enabled);
    notificationParserConfig = notificationParserConfig.upsert(profile);
    notifyListeners();
    await _saveNotificationParserProfiles();
  }

  Future<void> updateSelectedNotificationParserProfile(
    NotificationParserProfile profile, {
    bool saveIfReady = false,
  }) async {
    notificationParserConfig = notificationParserConfig.upsert(profile);
    selectedNotificationParserProfileId = profile.id;
    notifyListeners();
    if (!saveIfReady || !profile.preview.isReady) return;
    await _saveNotificationParserProfiles();
  }

  Future<void> saveSelectedNotificationParserProfile() async {
    if (!selectedNotificationParserProfile.preview.isReady) return;
    await _saveNotificationParserProfiles();
  }

  Future<void> _saveNotificationParserProfiles() async {
    notificationParserConfig = await _bridge.saveNotificationParserProfiles(
      notificationParserConfig,
    );
    final selectedExists = notificationParserProfiles.any(
      (profile) => profile.id == selectedNotificationParserProfileId,
    );
    selectedNotificationParserProfileId = selectedExists
        ? selectedNotificationParserProfileId
        : _firstProfileId();
    notifyListeners();
  }

  String? _firstProfileId() {
    return notificationParserProfiles.isEmpty
        ? null
        : notificationParserProfiles.first.id;
  }

  void selectInstalledApp(InstalledApp app) {
    final appName = app.displayName;
    filterText = appName;
    filterEnabled = true;
    filterError = null;
    _lastValidRegex = RegExp(
      '^${RegExp.escape(appName)}\$',
      caseSensitive: false,
    );
    notifyListeners();
  }

  void setFilterEnabled(bool value) {
    filterEnabled = value;
    notifyListeners();
  }

  void setFilterText(String value) {
    filterText = value;
    if (value.trim().isEmpty) {
      filterError = null;
      _lastValidRegex = null;
      notifyListeners();
      return;
    }
    try {
      _lastValidRegex = RegExp(value, caseSensitive: false);
      filterError = null;
    } on FormatException catch (error) {
      filterError = error.message;
    }
    notifyListeners();
  }

  Future<void> openNotificationAccessSettings() =>
      _bridge.openNotificationAccessSettings();

  Future<void> openAccessibilitySettings() =>
      _bridge.openAccessibilitySettings();

  Future<void> openAppInfoSettings() => _bridge.openAppInfoSettings();

  Future<void> requestPostNotifications() => _bridge.requestPostNotifications();

  Future<void> sendTestNotification() => _bridge.sendTestNotification();

  Future<void> clearDatabase() async {
    await _bridge.clearDatabase();
    _events.clear();
    await refreshStatus();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
