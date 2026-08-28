import 'package:flutter/widgets.dart';

import '../../../core/design/dashboard_mode_palette.dart';

/// Presentation-only visibility of the fixed Ledger SearchPill slot.
enum DashboardLogBoxSearchPillVisibility { shown, hidden }

/// Presentation-only treatment for active direct-manipulation facets.
enum DashboardQueryFacetPillStyle { current, solidAvatarColor }

/// The external body strip is the baseline. When the SearchPill is hidden,
/// `insideSearchPill` deterministically falls back to that strip so a live
/// filter can never become inaccessible.
enum DashboardQueryFacetPlacement { bodyTop, insideSearchPill }

@immutable
final class DashboardLogBoxSearchPillSettings {
  const DashboardLogBoxSearchPillSettings({
    this.visibility = DashboardLogBoxSearchPillVisibility.shown,
    this.queryFacetPillStyle = DashboardQueryFacetPillStyle.current,
    this.queryFacetPlacement = DashboardQueryFacetPlacement.bodyTop,
  });

  static const defaults = DashboardLogBoxSearchPillSettings();

  final DashboardLogBoxSearchPillVisibility visibility;
  final DashboardQueryFacetPillStyle queryFacetPillStyle;
  final DashboardQueryFacetPlacement queryFacetPlacement;

  bool get isVisible => visibility == DashboardLogBoxSearchPillVisibility.shown;

  bool get facetsInsideVisibleSearchPill =>
      isVisible &&
      queryFacetPlacement == DashboardQueryFacetPlacement.insideSearchPill;

  DashboardLogBoxSearchPillSettings copyWith({
    DashboardLogBoxSearchPillVisibility? visibility,
    DashboardQueryFacetPillStyle? queryFacetPillStyle,
    DashboardQueryFacetPlacement? queryFacetPlacement,
  }) => DashboardLogBoxSearchPillSettings(
    visibility: visibility ?? this.visibility,
    queryFacetPillStyle: queryFacetPillStyle ?? this.queryFacetPillStyle,
    queryFacetPlacement: queryFacetPlacement ?? this.queryFacetPlacement,
  );

  @override
  bool operator ==(Object other) =>
      other is DashboardLogBoxSearchPillSettings &&
      other.visibility == visibility &&
      other.queryFacetPillStyle == queryFacetPillStyle &&
      other.queryFacetPlacement == queryFacetPlacement;

  @override
  int get hashCode =>
      Object.hash(visibility, queryFacetPillStyle, queryFacetPlacement);
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

  void selectQueryFacetPillStyle(DashboardQueryFacetPillStyle style) {
    final next = value.copyWith(queryFacetPillStyle: style);
    if (next != value) value = next;
  }

  void selectQueryFacetPlacement(DashboardQueryFacetPlacement placement) {
    final next = value.copyWith(queryFacetPlacement: placement);
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
