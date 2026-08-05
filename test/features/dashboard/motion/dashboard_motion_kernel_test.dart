import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_motion_kernel.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_motion_state.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_semantic_catalog.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test('100 semantic crossings perform direct immutable catalog selection', () {
    final catalog = _catalog(const YearMonth(year: 2026, month: 7));
    final selected = <DashboardSemanticEntry>[];
    final contexts = <DashboardMotionContext>[];
    final kernel = DashboardMotionKernel(
      catalog: catalog,
      initialLogicalIndex: 0,
      onSemanticCrossed: (entry, context) {
        selected.add(entry);
        contexts.add(context);
      },
    );
    addTearDown(kernel.dispose);

    kernel.beginGesture();
    for (var index = 0; index < 100; index += 1) {
      kernel.semanticCrossed(index);
    }

    expect(selected, hasLength(100));
    for (var index = 0; index < selected.length; index += 1) {
      final canonical = index % catalog.length;
      expect(selected[index], same(catalog[canonical]));
      expect(contexts[index].semanticIndex, canonical);
      expect(selected[index].queryKey, catalog[canonical].queryKey);
    }
    expect(kernel.state.gestureId, 1);
    expect(kernel.state.motionEpoch, 1);
    expect(kernel.state.activity, DashboardMotionActivity.drag);
  });

  test('cyclic day crossings normalize without constructing new entries', () {
    final catalog = _catalog(const YearMonth(year: 2026, month: 6));
    final selected = <DashboardSemanticEntry>[];
    final kernel = DashboardMotionKernel(
      catalog: catalog,
      initialLogicalIndex: 29,
      onSemanticCrossed: (entry, _) => selected.add(entry),
    );
    addTearDown(kernel.dispose);

    kernel.semanticCrossed(30);
    kernel.semanticCrossed(-1);

    expect(selected[0], same(catalog[0]));
    expect(selected[1], same(catalog[29]));
  });

  test('catalog replacement preserves controller and physics identity', () {
    final kernel = DashboardMotionKernel(
      catalog: _catalog(const YearMonth(year: 2026, month: 7)),
      initialLogicalIndex: 30,
    );
    addTearDown(kernel.dispose);
    final controller = kernel.carouselController;
    final scrollController = controller.scrollController;
    final physics = kernel.dashboardPhysics;

    kernel.installCatalog(
      _catalog(const YearMonth(year: 2026, month: 6)),
      selectedLogicalIndex: 29,
    );

    expect(kernel.state.semanticIndex, 29);
    expect(identical(kernel.carouselController, controller), isTrue);
    expect(identical(controller.scrollController, scrollController), isTrue);
    expect(identical(kernel.dashboardPhysics, physics), isTrue);
    expect(controller.physicsCreationCount, 1);
  });

  test('settle reports the already selected immutable semantic entry once', () {
    final settled = <DashboardSemanticEntry>[];
    final kernel = DashboardMotionKernel(
      catalog: _catalog(const YearMonth(year: 2026, month: 7)),
      initialLogicalIndex: 0,
      onSettled: (entry, _) => settled.add(entry),
    );
    addTearDown(kernel.dispose);

    kernel.beginGesture();
    kernel.semanticCrossed(5);
    kernel.settled(5);
    kernel.settled(5);

    expect(settled, [same(kernel.catalog[5])]);
    expect(kernel.state.activity, DashboardMotionActivity.idle);
    expect(kernel.state.velocity, 0);
  });
}

DashboardSemanticCatalog _catalog(YearMonth month) =>
    DashboardSemanticCatalog.forParent(
      parentScope: CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: MonthScope(month),
      ),
      childKind: DashboardChildKind.day,
    );
