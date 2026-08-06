import 'package:fluvi/app/fluvi_app.dart';
import 'package:fluvi/app/shell/bnb03_bottom_navigation.dart';
import 'package:fluvi/app/shell/fluvi_bottom_navigation.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/data/empty_dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots into the fixed Fluvi dashboard shell', (tester) async {
    await tester.pumpWidget(
      const FluviApp(
        dashboardRepository: EmptyDashboardDataRuntimeRepository(),
      ),
    );
    expect(
      find.byKey(const ValueKey('dashboard-bootstrap-surface')),
      findsOneWidget,
    );
    expect(find.text('—'), findsNothing);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('fluvi-app-shell')), findsOneWidget);
    expect(find.byKey(const ValueKey('core-dashboard')), findsOneWidget);
    expect(find.text('—'), findsNothing);
    expect(find.byType(Bnb03BottomNavigation), findsOneWidget);
    expect(
      find.byKey(const ValueKey('fluvi-fullscreen-button')),
      findsOneWidget,
    );
  });

  testWidgets('bootstrap failure replaces the spinner and retry can recover', (
    tester,
  ) async {
    final repository = _FailOnceDashboardRepository();
    await tester.pumpWidget(FluviApp(dashboardRepository: repository));
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('dashboard-bootstrap-failure-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard-bootstrap-surface')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('dashboard-bootstrap-retry')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('core-dashboard')), findsOneWidget);
    expect(repository.prepareCount, 2);
  });

  testWidgets('BNB keeps the purple outer ring separate from the FAB core', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Bnb03BottomNavigation(
          selected: Bnb03Item.home,
          onChanged: (_) {},
        ),
      ),
    );

    final ring = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('bnb03-fab-outer-purple-ring')),
    );

    expect(ring.painter, isA<CustomPainter>());
    expect(ring.child, isA<Padding>());

    final fabCore = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('bnb03-fab-core')),
    );

    expect(fabCore.painter, isA<CustomPainter>());
    expect(fabCore.child, isA<Center>());
  });

  testWidgets('paints the bottom system inset white behind the navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(412, 800),
          padding: EdgeInsets.only(bottom: 48),
          viewPadding: EdgeInsets.only(bottom: 48),
        ),
        child: const FluviApp(
          dashboardRepository: EmptyDashboardDataRuntimeRepository(),
        ),
      ),
    );

    final background = find.byKey(
      const ValueKey('fluvi-bottom-safe-area-background'),
    );

    expect(background, findsOneWidget);
    expect(tester.widget<ColoredBox>(background).color, Colors.white);
    expect(tester.getRect(background).height, closeTo(48, 0.001));
  });

  testWidgets('keeps the raised center action inside the reserved nav area', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 412,
            height: FluviVisualTokens.navigationHeight,
            child: FluviBottomNavigation(onDashboardTap: () {}),
          ),
        ),
      ),
    );

    final navigation = tester.getRect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.painter is FluviConvexCenterBottomNavigationPainter,
      ),
    );
    final centerAction = tester.getRect(
      find.byKey(const ValueKey('fluvi-center-fab')),
    );

    expect(navigation.height, greaterThanOrEqualTo(110));
    expect(navigation.height, lessThanOrEqualTo(144));
    expect(centerAction.width, closeTo(64, 0.001));
    expect(centerAction.height, closeTo(64, 0.001));
    expect(centerAction.top - navigation.top, closeTo(10, 2));
    expect(centerAction.left, greaterThanOrEqualTo(navigation.left));
    expect(centerAction.right, lessThanOrEqualTo(navigation.right));
    expect(centerAction.top, greaterThanOrEqualTo(navigation.top));
    expect(centerAction.bottom, lessThanOrEqualTo(navigation.bottom));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.painter is FluviConvexCenterBottomNavigationPainter,
      ),
      findsOneWidget,
    );
  });
}

final class _FailOnceDashboardRepository
    implements DashboardDataRuntimeRepository {
  final EmptyDashboardDataRuntimeRepository _empty =
      const EmptyDashboardDataRuntimeRepository();
  int prepareCount = 0;

  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(1);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) {
    prepareCount += 1;
    if (prepareCount == 1) {
      return Future<PreparedDashboardIndex>.error(
        StateError('synthetic bootstrap failure'),
      );
    }
    return _empty.prepareIndex(request, token);
  }

  @override
  Future<DashboardPreparedFrame> readCommittedPage(
    DashboardCommittedPageRequest request, {
    required Map<String, Object?> after,
    required DashboardPreparedFrame currentFrame,
  }) => _empty.readCommittedPage(
    request,
    after: after,
    currentFrame: currentFrame,
  );

  @override
  Map<String, Object?> performanceReport() => _empty.performanceReport();
}
