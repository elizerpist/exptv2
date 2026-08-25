import 'dart:collection';

import 'package:flutter/foundation.dart';

/// The three complete dashboard body blocks which may be reordered by the
/// presentation tuner. This never represents business/query state.
enum DashboardBodyComponent { direction, summary, modeContent }

extension DashboardBodyComponentPresentation on DashboardBodyComponent {
  String get label => switch (this) {
    DashboardBodyComponent.direction => 'Bevétel / Kiadás',
    DashboardBodyComponent.summary => 'Summary',
    DashboardBodyComponent.modeContent => 'Mód tartalma',
  };
}

/// Immutable validated order: exactly the three body identities, once each.
@immutable
final class DashboardBodyOrder {
  DashboardBodyOrder(Iterable<DashboardBodyComponent> components)
    : components = UnmodifiableListView<DashboardBodyComponent>(
        List<DashboardBodyComponent>.of(components),
      ) {
    if (this.components.length != DashboardBodyComponent.values.length ||
        this.components.toSet().length !=
            DashboardBodyComponent.values.length ||
        !this.components.toSet().containsAll(DashboardBodyComponent.values)) {
      throw ArgumentError.value(
        components,
        'components',
        'A dashboard body order must contain every component exactly once.',
      );
    }
  }

  factory DashboardBodyOrder.defaultOrder() =>
      DashboardBodyOrder(DashboardBodyComponent.values);

  final UnmodifiableListView<DashboardBodyComponent> components;

  DashboardBodyOrder move(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= components.length ||
        newIndex < 0 ||
        newIndex >= components.length) {
      return this;
    }
    final next = List<DashboardBodyComponent>.of(components);
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    return DashboardBodyOrder(next);
  }

  @override
  bool operator ==(Object other) =>
      other is DashboardBodyOrder && listEquals(other.components, components);

  @override
  int get hashCode => Object.hashAll(components);
}

/// Dashboard-lifetime, session-only presentation owner shared by every mode.
final class DashboardBodyOrderController
    extends ValueNotifier<DashboardBodyOrder> {
  DashboardBodyOrderController() : super(DashboardBodyOrder.defaultOrder());

  void select(DashboardBodyOrder order) {
    if (value != order) value = order;
  }

  void move(int oldIndex, int newIndex) =>
      select(value.move(oldIndex, newIndex));
}
