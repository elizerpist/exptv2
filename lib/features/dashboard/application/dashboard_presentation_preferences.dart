import 'dart:async';

import 'package:flutter/foundation.dart';

import '../mind/domain/mind_year_heatmap_presentation_settings.dart';

/// Persisted user choices that affect presentation only.
///
/// This value deliberately excludes financial, query, navigation and prepared
/// dashboard state. Its storage mechanism belongs to a core data adapter.
final class DashboardPresentationPreferences {
  const DashboardPresentationPreferences({
    required this.sumVisualStyle,
    required this.showSumLayoutChooser,
    required this.showYearMotherCardActions,
    required this.balanceUsesChildCards,
  });

  final MindSumVisualStyle sumVisualStyle;
  final bool showSumLayoutChooser;
  final bool showYearMotherCardActions;
  final bool balanceUsesChildCards;

  static const defaults = DashboardPresentationPreferences(
    sumVisualStyle: MindSumVisualStyle.current,
    showSumLayoutChooser: true,
    showYearMotherCardActions: true,
    balanceUsesChildCards: true,
  );

  @override
  bool operator ==(Object other) =>
      other is DashboardPresentationPreferences &&
      other.sumVisualStyle == sumVisualStyle &&
      other.showSumLayoutChooser == showSumLayoutChooser &&
      other.showYearMotherCardActions == showYearMotherCardActions &&
      other.balanceUsesChildCards == balanceUsesChildCards;

  @override
  int get hashCode => Object.hash(
    sumVisualStyle,
    showSumLayoutChooser,
    showYearMotherCardActions,
    balanceUsesChildCards,
  );
}

/// Port owned by application code; platform storage is implemented by core
/// data adapters rather than dashboard widgets.
abstract interface class DashboardPresentationPreferencesStore {
  Future<DashboardPresentationPreferences> read();

  Future<void> write(DashboardPresentationPreferences preferences);
}

/// Dashboard-lifetime presentation state and persistence coordinator.
///
/// Its listeners receive immediate local changes. Storage failures are
/// intentionally non-blocking because visual preferences must not affect the
/// protected dashboard interaction path.
final class DashboardPresentationPreferencesController
    extends ValueNotifier<DashboardPresentationPreferences> {
  DashboardPresentationPreferencesController({
    required DashboardPresentationPreferencesStore store,
  }) : _store = store,
       super(DashboardPresentationPreferences.defaults);

  final DashboardPresentationPreferencesStore _store;

  Future<void> restore() async {
    try {
      final restored = await _store.read();
      value = restored;
    } catch (_) {
      // Defaults remain active when platform persistence is unavailable.
    }
  }

  void setPreferences(DashboardPresentationPreferences next) {
    if (next == value) return;
    value = next;
    unawaited(_persist(next));
  }

  Future<void> _persist(DashboardPresentationPreferences next) async {
    try {
      await _store.write(next);
    } catch (_) {
      // A transient persistence failure must not block visual interaction.
    }
  }
}

/// Standalone widgets/tests deliberately have no platform persistence.
final class InMemoryDashboardPresentationPreferencesStore
    implements DashboardPresentationPreferencesStore {
  InMemoryDashboardPresentationPreferencesStore([
    this._value = DashboardPresentationPreferences.defaults,
  ]);

  DashboardPresentationPreferences _value;

  @override
  Future<DashboardPresentationPreferences> read() async => _value;

  @override
  Future<void> write(DashboardPresentationPreferences preferences) async {
    _value = preferences;
  }
}
