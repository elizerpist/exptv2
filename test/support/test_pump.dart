import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const dashboardTestSurfaceSize = Size(412, 892);

Future<void> pumpDashboardSurface(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(dashboardTestSurfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, routedChild) => MediaQuery(
        data: const MediaQueryData(
          size: dashboardTestSurfaceSize,
          textScaler: TextScaler.linear(1),
          disableAnimations: true,
        ),
        child: routedChild!,
      ),
      home: child,
    ),
  );
}
