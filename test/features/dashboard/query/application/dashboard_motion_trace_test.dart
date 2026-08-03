import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_motion_trace.dart';

void main() {
  setUp(() {
    DashboardMotionTrace.clear();
    DashboardMotionTrace.enabled = true;
  });

  tearDown(() {
    DashboardMotionTrace.clear();
  });

  test('records numeric events in a bounded ring without formatting', () {
    for (var index = 0; index < DashboardMotionTrace.capacity + 3; index += 1) {
      DashboardMotionTrace.record(
        eventId: DashboardMotionEventId.previewCentered,
        physicalIndex: index,
        logicalIndex: index - 1,
        timestampMicros: index,
      );
    }

    final events = DashboardMotionTrace.export();
    expect(events, hasLength(DashboardMotionTrace.capacity));
    expect(events.first.physicalIndex, 3);
    expect(events.last.physicalIndex, DashboardMotionTrace.capacity + 2);
    expect(events.first.timestampMicros, 3);
  });

  test('disabled trace does not mutate the ring', () {
    DashboardMotionTrace.enabled = false;
    DashboardMotionTrace.record(
      eventId: DashboardMotionEventId.semanticSettle,
      physicalIndex: 5,
      logicalIndex: 2,
      timestampMicros: 1,
    );

    expect(DashboardMotionTrace.count, 0);
    expect(DashboardMotionTrace.export(), isEmpty);
  });
}
