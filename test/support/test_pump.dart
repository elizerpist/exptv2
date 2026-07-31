import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const dashboardTestSurfaceSize = Size(412, 892);

Future<void> pumpDashboardSurface(
  WidgetTester tester,
  Widget child, {
  Size surfaceSize = dashboardTestSurfaceSize,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, routedChild) => MediaQuery(
        data: MediaQueryData(
          size: surfaceSize,
          textScaler: TextScaler.linear(1),
          disableAnimations: true,
        ),
        child: routedChild!,
      ),
      home: child,
    ),
  );
}
