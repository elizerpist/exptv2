import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const dashboardTestSurfaceSize = Size(412, 892);
const dashboardTestDevicePixelRatio = 3.0;

Future<void> pumpDashboardSurface(
  WidgetTester tester,
  Widget child, {
  Size surfaceSize = dashboardTestSurfaceSize,
}) async {
  // Dashboard overlays intentionally read the FlutterView instead of only
  // MediaQuery so they match the actual physical viewport. Keep the test view
  // and the injected logical surface in lockstep; otherwise an overlay can be
  // laid out against the runner's default window while the Dashboard is tested
  // at another size.
  final view = tester.view;
  view.physicalSize = Size(
    surfaceSize.width * dashboardTestDevicePixelRatio,
    surfaceSize.height * dashboardTestDevicePixelRatio,
  );
  view.devicePixelRatio = dashboardTestDevicePixelRatio;
  addTearDown(() {
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });
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
