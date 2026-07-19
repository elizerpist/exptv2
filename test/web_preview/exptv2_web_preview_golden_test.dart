import 'package:exptv2/exptv2_app.dart';
import 'package:exptv2/features/stats/stats_page.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:exptv2/services/preview/preview_native_bridge_transport.dart';
import 'package:exptv2/services/preview/preview_native_state.dart';
import 'package:exptv2/state/event_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/channel_tolerance_golden_comparator.dart';
import '../helpers/stats_test_frame_worker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    StatsPage.debugRenderFrameWorkerOverride =
        const TestImmediateStatsFrameWorker();
    _setPlatformChannelStubs();
  });

  tearDown(() {
    StatsPage.debugRenderFrameWorkerOverride = null;
    _clearPlatformChannelStubs();
  });

  const cases = <_GoldenCase>[
    _GoldenCase(
      name: 'mobile 412x915',
      size: Size(412, 915),
      fileName: 'exptv2-mobile-412x915.png',
    ),
    _GoldenCase(
      name: 'narrow 360x800',
      size: Size(360, 800),
      fileName: 'exptv2-narrow-360x800.png',
    ),
    _GoldenCase(
      name: 'desktop 1280x900',
      size: Size(1280, 900),
      fileName: 'exptv2-desktop-1280x900.png',
    ),
  ];

  for (final goldenCase in cases) {
    testWidgets('production preview renders ${goldenCase.name}', (
      tester,
    ) async {
      tester.view.physicalSize = goldenCase.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = PreviewNativeState.seeded(now: DateTime(2026, 7, 18));
      final bridge = NativeBridge(
        transport: PreviewNativeBridgeTransport(state: state),
      );
      final store = EventStore(bridge, realtimeEnabled: false);
      addTearDown(() async {
        store.dispose();
        await state.dispose();
      });

      await tester.pumpWidget(
        Exptv2App(
          store: store,
          nativeBridge: bridge,
          statsRenderFrameWorker: const TestImmediateStatsFrameWorker(),
          webPreviewFrameEnabled: true,
        ),
      );
      await tester.pumpAndSettle();

      final root = find.byType(Exptv2App);
      expect(root, findsOneWidget);
      expect(tester.getSize(root), goldenCase.size);
      expect(
        tester.getSize(find.byKey(const ValueKey('web-preview-frame'))),
        Size(
          goldenCase.size.width.clamp(0, 480).toDouble(),
          goldenCase.size.height,
        ),
      );
      expect(find.byKey(const ValueKey('expt-bottom-nav')), findsOneWidget);
      expect(find.byKey(const ValueKey('summary-pill')), findsOneWidget);
      _expectNoFlutterExceptions(tester);

      final previousGoldenComparator = goldenFileComparator;
      goldenFileComparator = ChannelToleranceGoldenComparator(
        Uri.parse('test/web_preview/exptv2_web_preview_golden_test.dart'),
        maxChannelDelta: 2,
      );
      addTearDown(() => goldenFileComparator = previousGoldenComparator);

      await expectLater(
        root,
        matchesGoldenFile('../goldens/web_preview/${goldenCase.fileName}'),
      );
      _expectNoFlutterExceptions(tester);
    });
  }
}

class _GoldenCase {
  const _GoldenCase({
    required this.name,
    required this.size,
    required this.fileName,
  });

  final String name;
  final Size size;
  final String fileName;
}

void _expectNoFlutterExceptions(WidgetTester tester) {
  final exceptions = <Object>[];
  Object? exception;
  while ((exception = tester.takeException()) != null) {
    exceptions.add(exception!);
  }
  expect(
    exceptions,
    isEmpty,
    reason: exceptions.map((error) => error.toString()).join('\n'),
  );
}

void _setPlatformChannelStubs() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final channel in <MethodChannel>[
    const MethodChannel('exptv2/native_ime_sheet'),
    const MethodChannel('flutter_keyboard_controller/keyboard_events'),
    const MethodChannel('exptv2/recurring_alarm'),
    const MethodChannel('exptv2/keyboard_insets'),
  ]) {
    messenger.setMockMethodCallHandler(channel, (call) async => false);
  }
}

void _clearPlatformChannelStubs() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final channel in <MethodChannel>[
    const MethodChannel('exptv2/native_ime_sheet'),
    const MethodChannel('flutter_keyboard_controller/keyboard_events'),
    const MethodChannel('exptv2/recurring_alarm'),
    const MethodChannel('exptv2/keyboard_insets'),
  ]) {
    messenger.setMockMethodCallHandler(channel, null);
  }
}
