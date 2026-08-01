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

class _PreviewRebuildingCarousel extends StatefulWidget {
  const _PreviewRebuildingCarousel({required this.controller});

  final CenteredCarouselController controller;

  @override
  State<_PreviewRebuildingCarousel> createState() =>
      _PreviewRebuildingCarouselState();
}

class _PreviewRebuildingCarouselState
    extends State<_PreviewRebuildingCarousel> {
  int _previewRebuilds = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      height: 80,
      child: CenteredCarousel<int>(
        items: List<int>.generate(31, (index) => index),
        controller: widget.controller,
        spec: CenteredCarouselSpec(itemExtent: 72),
        height: 80,
        onPreviewChanged: (_) {
          setState(() {
            _previewRebuilds++;
          });
        },
        itemBuilder: (context, item, metrics) => SizedBox(
          key: ValueKey('rebuild-item-$item-$_previewRebuilds'),
          width: 48,
          height: 48,
          child: Text('$item'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('generated belt can rebase without changing its logical item', (
    tester,
  ) async {
    final controller = CenteredCarouselController(initialIndex: 0);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _host(
        CenteredCarousel<int>(
          dataSource: GeneratedCarouselDataSource<int>((index) => index),
          controller: controller,
          spec: CenteredCarouselSpec(itemExtent: 72),
          height: 80,
          itemBuilder: (context, item, metrics) =>
              SizedBox(width: 48, height: 48, child: Text('$item')),
        ),
      ),
    );
    await tester.pump();

    controller.jumpToIndex(
      CenteredCarouselController.virtualAnchorIndex + 5001,
    );
    expect(controller.selectedIndex, 105001);

    expect(controller.rebaseIfNeeded(), isTrue);
    expect(controller.selectedIndex, 105001);
    expect(
      controller.selectedPhysicalIndex,
      CenteredCarouselController.virtualAnchorIndex,
    );
    expect(controller.rawCenteredIndex, 100000);
  });

  testWidgets('renders fixed slots inside a hard-clipped centered viewport', (
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
      Clip.hardEdge,
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

  testWidgets(
    'preview-driven parent rebuild does not collapse a child fling to one item',
    (tester) async {
      final controller = CenteredCarouselController(initialIndex: 10);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(_PreviewRebuildingCarousel(controller: controller)),
      );
      await tester.pump();

      await tester.fling(find.byType(ListView), const Offset(-420, 0), 2200);
      await tester.pumpAndSettle();

      expect(controller.selectedIndex, greaterThan(11));
    },
  );

  testWidgets('tap retargets the rail immediately during an active fling', (
    tester,
  ) async {
    final controller = CenteredCarouselController(initialIndex: 3);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _host(
        CenteredCarousel<int>(
          items: List.generate(9, (index) => index),
          controller: controller,
          spec: CenteredCarouselSpec(itemExtent: 72),
          height: 80,
          itemBuilder: (context, item, metrics) => SizedBox(
            key: ValueKey('carousel-item-$item'),
            width: 48,
            height: 48,
            child: Text('$item'),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.fling(find.byType(ListView), const Offset(-240, 0), 1800);
    await tester.pump(const Duration(milliseconds: 50));
    final viewport = tester.getRect(
      find.byKey(const ValueKey('centered-carousel-viewport')),
    );
    final targetIndex = controller.selectedIndex + 1;
    final sidePadding = (viewport.width - 72) / 2;
    final targetCenterX =
        viewport.left +
        sidePadding +
        targetIndex * 72 -
        controller.scrollController.offset +
        36;
    await tester.tapAt(Offset(targetCenterX, viewport.center.dy));
    await tester.pumpAndSettle();

    expect(controller.selectedIndex, targetIndex);
  });

  testWidgets('latest tap owns the settled callback', (tester) async {
    final controller = CenteredCarouselController(initialIndex: 0);
    addTearDown(controller.dispose);
    final settled = <int>[];

    await tester.pumpWidget(
      _host(
        CenteredCarousel<int>(
          items: List.generate(9, (index) => index),
          controller: controller,
          spec: CenteredCarouselSpec(itemExtent: 72),
          height: 80,
          onSelectionSettled: settled.add,
          itemBuilder: (context, item, metrics) =>
              SizedBox(width: 48, height: 48, child: Text('$item')),
        ),
      ),
    );
    await tester.pump();

    final firstTap = controller.animateToIndex(6);
    await tester.pump(const Duration(milliseconds: 30));
    final secondTap = controller.animateToIndex(2);
    await tester.pumpAndSettle();
    await firstTap;
    await secondTap;

    expect(controller.selectedIndex, 2);
    expect(settled, [2]);
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
