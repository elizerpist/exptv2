import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel.dart';

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 360, height: 80, child: child)),
  );
}

Widget _resizableHost(double width, Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: width, height: 80, child: child),
    ),
  );
}

void main() {
  testWidgets('renders fixed slots and exposes a transparent unclipped list', (
    tester,
  ) async {
    final controller = CenteredCarouselController(initialIndex: 2);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _host(
        CenteredCarousel<int>(
          items: const [0, 1, 2, 3, 4],
          controller: controller,
          spec: CenteredCarouselSpec(itemExtent: 72),
          height: 80,
          itemBuilder: (context, item, metrics) => SizedBox(
            key: ValueKey('item-$item'),
            width: 48,
            height: 48,
            child: ColoredBox(
              color: metrics.isSelected ? Colors.purple : Colors.white,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ListView), findsOneWidget);
    expect(find.byKey(const ValueKey('item-2')), findsOneWidget);
    expect(find.byType(Semantics), findsWidgets);
    expect(
      tester.widget<ListView>(find.byType(ListView)).clipBehavior,
      Clip.none,
    );
  });

  testWidgets('tap animates an item to the center and emits its selection', (
    tester,
  ) async {
    final controller = CenteredCarouselController(initialIndex: 0);
    addTearDown(controller.dispose);
    final selected = <int>[];

    await tester.pumpWidget(
      _host(
        CenteredCarousel<int>(
          items: const [0, 1, 2, 3, 4],
          controller: controller,
          spec: CenteredCarouselSpec(itemExtent: 72),
          height: 80,
          onSelectedChanged: selected.add,
          itemBuilder: (context, item, metrics) =>
              SizedBox(width: 48, height: 48, child: Text('$item')),
        ),
      ),
    );

    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    expect(controller.selectedIndex, 2);
    expect(selected, contains(2));
  });

  testWidgets('empty items render safely', (tester) async {
    final controller = CenteredCarouselController(initialIndex: 0);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _host(
        CenteredCarousel<int>(
          items: const [],
          controller: controller,
          spec: CenteredCarouselSpec(itemExtent: 72),
          height: 80,
          itemBuilder: (context, item, metrics) => const SizedBox.shrink(),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('drag releases onto the nearest centered item', (tester) async {
    final controller = CenteredCarouselController(initialIndex: 2);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _host(
        CenteredCarousel<int>(
          items: const [0, 1, 2, 3, 4],
          controller: controller,
          spec: CenteredCarouselSpec(itemExtent: 72),
          height: 80,
          itemBuilder: (context, item, metrics) =>
              SizedBox(width: 48, height: 48, child: Text('$item')),
        ),
      ),
    );
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(-60, 0));
    await tester.pumpAndSettle();

    expect(controller.selectedIndex, 3);
  });

  testWidgets('fling keeps velocity and can advance multiple items', (
    tester,
  ) async {
    final controller = CenteredCarouselController(initialIndex: 2);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _host(
        CenteredCarousel<int>(
          items: const [0, 1, 2, 3, 4, 5, 6],
          controller: controller,
          spec: CenteredCarouselSpec(itemExtent: 72),
          height: 80,
          itemBuilder: (context, item, metrics) =>
              SizedBox(width: 48, height: 48, child: Text('$item')),
        ),
      ),
    );
    await tester.pump();

    await tester.fling(find.byType(ListView), const Offset(-420, 0), 2200);
    await tester.pumpAndSettle();

    expect(controller.selectedIndex, greaterThan(2));
    expect(controller.selectedIndex, lessThanOrEqualTo(6));
  });

  testWidgets('resize preserves the selected item and recenters it', (
    tester,
  ) async {
    final controller = CenteredCarouselController(initialIndex: 2);
    addTearDown(controller.dispose);
    final carousel = CenteredCarousel<int>(
      items: const [0, 1, 2, 3, 4],
      controller: controller,
      spec: CenteredCarouselSpec(itemExtent: 72),
      height: 80,
      itemBuilder: (context, item, metrics) =>
          SizedBox(width: 48, height: 48, child: Text('$item')),
    );

    await tester.pumpWidget(_resizableHost(360, carousel));
    await tester.pump();
    controller.jumpToIndex(3);
    await tester.pump();

    await tester.pumpWidget(_resizableHost(420, carousel));
    await tester.pump();
    await tester.pump();

    expect(controller.selectedIndex, 3);
  });
}
