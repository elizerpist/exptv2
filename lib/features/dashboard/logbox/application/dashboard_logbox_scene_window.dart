import 'package:flutter/foundation.dart';

import 'dashboard_log_viewport_state.dart';

/// Immutable rail-reachable LogBox payload bank for one structural location.
///
/// It contains only already-projected bounded preview payloads. It is not a
/// vertical-list cache and never performs data access or formatting.
@immutable
final class DashboardLogBoxSceneWindow {
  DashboardLogBoxSceneWindow({
    required this.identity,
    required List<DashboardLogViewportState> payloads,
  }) : payloads = List<DashboardLogViewportState>.unmodifiable(payloads) {
    final viewportIds = <int>{};
    for (final payload in this.payloads) {
      if (!viewportIds.add(payload.viewportId)) {
        throw ArgumentError.value(
          payloads,
          'payloads',
          'A scene window cannot contain one viewport twice.',
        );
      }
    }
  }

  final String identity;
  final List<DashboardLogViewportState> payloads;

  int get previewRowCount => payloads.fold<int>(
    0,
    (count, payload) => count + payload.flatItems.length,
  );

  int get sceneCount => payloads.length;
}

/// The application coordinator requests this presentation capability before a
/// structural commit. The cache implementation owns the Flutter paragraphs;
/// the controller owns the ordering and input gate.
typedef DashboardLogBoxSceneWindowPreparer =
    Future<void> Function(
      DashboardLogBoxSceneWindow window, {
      required int? retainViewportId,
    });

typedef DashboardLogBoxSceneWindowActivator =
    void Function(DashboardLogBoxSceneWindow window);

typedef DashboardLogBoxSceneWindowReporter = Map<String, Object?> Function();
