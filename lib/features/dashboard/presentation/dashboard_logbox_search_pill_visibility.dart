import 'package:flutter/widgets.dart';

import '../../../core/design/dashboard_mode_palette.dart';

/// Presentation-only visibility of the fixed Ledger SearchPill slot.
enum DashboardLogBoxSearchPillVisibility { shown, hidden }

@immutable
final class DashboardLogBoxSearchPillSettings {
  const DashboardLogBoxSearchPillSettings({
    this.visibility = DashboardLogBoxSearchPillVisibility.shown,
  });

  static const defaults = DashboardLogBoxSearchPillSettings();

  final DashboardLogBoxSearchPillVisibility visibility;

  bool get isVisible => visibility == DashboardLogBoxSearchPillVisibility.shown;

  DashboardLogBoxSearchPillSettings copyWith({
    DashboardLogBoxSearchPillVisibility? visibility,
  }) => DashboardLogBoxSearchPillSettings(
    visibility: visibility ?? this.visibility,
  );

  @override
  bool operator ==(Object other) =>
      other is DashboardLogBoxSearchPillSettings &&
      other.visibility == visibility;

  @override
  int get hashCode => visibility.hashCode;
}

/// The one geometry contract shared by the header and the scroll viewport.
/// Hiding SearchPill removes only its own before/after gaps and height; the
/// count lane and all row/scroll identities remain untouched.
@immutable
final class DashboardLogBoxHeaderLayout {
  const DashboardLogBoxHeaderLayout(this.settings);

  final DashboardLogBoxSearchPillSettings settings;

  bool get showsSearchPill => settings.isVisible;

  static const searchPillFootprint =
      DashboardLogBoxTokens.ledgerCountToSearchGap +
      DashboardLogBoxTokens.ledgerSearchPillHeight +
      DashboardLogBoxTokens.ledgerSearchToListGap;

  static const countLaneHeight =
      DashboardLogBoxTokens.ledgerHeaderTopInset +
      DashboardLogBoxTokens.ledgerCountHeight;

  double referenceHeightFor({required bool showSearchPill}) => showSearchPill
      ? DashboardLogBoxTokens.summaryHeaderHeight
      : countLaneHeight;

  double heightForScale(double scale) =>
      referenceHeightFor(showSearchPill: showsSearchPill) * scale;

  double get reclaimedViewportHeight =>
      showsSearchPill ? 0 : searchPillFootprint;
}

final class DashboardLogBoxSearchPillController
    extends ValueNotifier<DashboardLogBoxSearchPillSettings> {
  DashboardLogBoxSearchPillController()
    : super(DashboardLogBoxSearchPillSettings.defaults);

  void setVisible(bool visible) {
    final next = value.copyWith(
      visibility: visible
          ? DashboardLogBoxSearchPillVisibility.shown
          : DashboardLogBoxSearchPillVisibility.hidden,
    );
    if (next != value) value = next;
  }

  void reset() => value = DashboardLogBoxSearchPillSettings.defaults;
}

final class DashboardLogBoxSearchPillScope
    extends InheritedNotifier<DashboardLogBoxSearchPillController> {
  const DashboardLogBoxSearchPillScope({
    super.key,
    required DashboardLogBoxSearchPillController? controller,
    required super.child,
  }) : super(notifier: controller);

  static DashboardLogBoxSearchPillSettings settingsOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<DashboardLogBoxSearchPillScope>()
          ?.notifier
          ?.value ??
      DashboardLogBoxSearchPillSettings.defaults;

  static DashboardLogBoxHeaderLayout layoutOf(BuildContext context) =>
      DashboardLogBoxHeaderLayout(settingsOf(context));
}
