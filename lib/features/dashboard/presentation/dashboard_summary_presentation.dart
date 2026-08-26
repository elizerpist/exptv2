import 'package:flutter/foundation.dart';

/// Presentation-only Summary controls. Temporal state, query keys and
/// carousel crossing ownership remain outside this dashboard-lifetime model.
enum SummaryModeSelectorLayout {
  current('Jelenlegi'),
  iconWithLabel('Ikon + címke'),
  largeIcon('Nagy ikon');

  const SummaryModeSelectorLayout(this.label);
  final String label;
}

enum SummaryTemporalFlingPresentation {
  current('Jelenlegi'),
  dynamicTrio('Dinamikus hármas');

  const SummaryTemporalFlingPresentation(this.label);
  final String label;
}

@immutable
final class DashboardSummaryPresentationSettings {
  const DashboardSummaryPresentationSettings({
    required this.showSeparators,
    required this.modeSelectorLayout,
    required this.temporalFlingPresentation,
  });

  const DashboardSummaryPresentationSettings.defaults()
    : showSeparators = true,
      modeSelectorLayout = SummaryModeSelectorLayout.current,
      temporalFlingPresentation = SummaryTemporalFlingPresentation.current;

  final bool showSeparators;
  final SummaryModeSelectorLayout modeSelectorLayout;
  final SummaryTemporalFlingPresentation temporalFlingPresentation;

  DashboardSummaryPresentationSettings copyWith({
    bool? showSeparators,
    SummaryModeSelectorLayout? modeSelectorLayout,
    SummaryTemporalFlingPresentation? temporalFlingPresentation,
  }) => DashboardSummaryPresentationSettings(
    showSeparators: showSeparators ?? this.showSeparators,
    modeSelectorLayout: modeSelectorLayout ?? this.modeSelectorLayout,
    temporalFlingPresentation:
        temporalFlingPresentation ?? this.temporalFlingPresentation,
  );

  @override
  bool operator ==(Object other) =>
      other is DashboardSummaryPresentationSettings &&
      other.showSeparators == showSeparators &&
      other.modeSelectorLayout == modeSelectorLayout &&
      other.temporalFlingPresentation == temporalFlingPresentation;

  @override
  int get hashCode => Object.hash(
    showSeparators,
    modeSelectorLayout,
    temporalFlingPresentation,
  );
}

final class DashboardSummaryPresentationController
    extends ValueNotifier<DashboardSummaryPresentationSettings> {
  DashboardSummaryPresentationController()
    : super(const DashboardSummaryPresentationSettings.defaults());

  void setSeparatorsVisible(bool visible) =>
      _set(value.copyWith(showSeparators: visible));

  void selectModeSelectorLayout(SummaryModeSelectorLayout layout) =>
      _set(value.copyWith(modeSelectorLayout: layout));

  void selectTemporalFlingPresentation(
    SummaryTemporalFlingPresentation presentation,
  ) => _set(value.copyWith(temporalFlingPresentation: presentation));

  void reset() => _set(const DashboardSummaryPresentationSettings.defaults());

  void _set(DashboardSummaryPresentationSettings next) {
    if (next != value) value = next;
  }
}

/// Pure, presentation-only geometry for the Dynamic Trio overlay. The
/// existing carousel remains the sole temporal selection and crossing owner;
/// this projection merely turns its fractional logical index into continuous
/// text scale and placement.
@immutable
final class SummaryDynamicTrioItemGeometry {
  const SummaryDynamicTrioItemGeometry({
    required this.scale,
    required this.centerY,
  });

  final double scale;
  final double centerY;
}

final class SummaryDynamicTrioGeometry {
  const SummaryDynamicTrioGeometry._();

  static const double minScale = .68;
  static const double maxScale = 1;
  static const double verticalStrideFraction = .28;

  static List<int> offsetsFor({
    required double rawIndex,
    required bool isMoving,
  }) {
    final center = rawIndex.round();
    if (!isMoving && (rawIndex - center).abs() < .001) {
      return <int>[center];
    }
    return <int>[center - 1, center, center + 1];
  }

  static SummaryDynamicTrioItemGeometry itemFor({
    required double height,
    required int offset,
    required double rawIndex,
  }) {
    final distance = (offset - rawIndex).abs();
    final proximity = (1 - distance.clamp(0.0, 1.0)).toDouble();
    return SummaryDynamicTrioItemGeometry(
      scale: minScale + (maxScale - minScale) * proximity,
      centerY:
          height / 2 + (offset - rawIndex) * height * verticalStrideFraction,
    );
  }
}
