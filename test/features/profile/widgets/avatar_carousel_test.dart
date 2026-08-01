import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/profile/widgets/avatar_carousel.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_controller.dart';

void main() {
  testWidgets('avatar adapter renders through the shared centered engine', (
    tester,
  ) async {
    final controller = CenteredCarouselController(initialIndex: 1);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 100,
            child: AvatarCarousel<Widget>(
              controller: controller,
              avatars: const [
                ColoredBox(color: Colors.red),
                ColoredBox(color: Colors.blue),
                ColoredBox(color: Colors.green),
              ],
              itemBuilder: (context, avatar, metrics) => avatar,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('centered-carousel-viewport')),
      findsOneWidget,
    );
    expect(find.byType(Scrollable), findsOneWidget);
  });
}
