import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_event.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/core/diagnostics/fluvi_onscreen_diagnostics.dart';

void main() {
  setUp(FluviDiagnosticLogger.clear);

  test('retains 999 and exactly 1000 chronological diagnostic entries', () {
    for (var index = 0; index < 999; index += 1) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'D$index',
          flowId: 'Q-test',
          queryKey: 'expense|month:2026-07',
          totalMinor: index,
          entryCount: 1,
        ),
      );
    }

    expect(FluviDiagnosticLogger.entries, hasLength(999));
    expect(FluviDiagnosticLogger.entries.first.stage, 'D0');
    expect(FluviDiagnosticLogger.entries.last.stage, 'D998');

    FluviDiagnosticLogger.log(
      const FluviDiagnosticEvent(stage: 'D999', flowId: 'Q-test'),
    );

    expect(FluviDiagnosticLogger.maxEntries, 1000);
    expect(FluviDiagnosticLogger.entries, hasLength(1000));
    expect(FluviDiagnosticLogger.entries.first.stage, 'D0');
    expect(FluviDiagnosticLogger.entries.last.stage, 'D999');
    expect(
      FluviDiagnosticLogger.entries.last.toLine(),
      contains('[FLOW][D999] flowId=Q-test'),
    );
  });

  test('evicts exactly the oldest entry at diagnostic entry 1001', () {
    for (var index = 0; index <= 1000; index += 1) {
      FluviDiagnosticLogger.log(FluviDiagnosticEvent(stage: 'D$index'));
    }

    final entries = FluviDiagnosticLogger.entries;
    expect(entries, hasLength(1000));
    expect(entries.first.stage, 'D1');
    expect(entries.last.stage, 'D1000');
    expect(
      entries.map((event) => event.stage),
      orderedEquals(List<String>.generate(1000, (index) => 'D${index + 1}')),
    );
  });

  test('keeps the exported capture at the same exact 1000-entry boundary', () {
    FluviDiagnosticLogger.startCapture();
    for (var index = 0; index < 1000; index += 1) {
      FluviDiagnosticLogger.log(FluviDiagnosticEvent(stage: 'CAPTURE-$index'));
    }

    final capture = FluviDiagnosticLogger.captureEntries;
    expect(capture, hasLength(1000));
    expect(capture.first.stage, 'CAPTURE-0');
    expect(capture.last.stage, 'CAPTURE-999');
    expect(
      capture.map((event) => event.stage),
      orderedEquals(List<String>.generate(1000, (index) => 'CAPTURE-$index')),
      reason:
          'The copy/export path must expose the same newest 1000 diagnostic '
          'records as the on-screen history, not a second hidden capacity.',
    );
  });

  test('multiple wraparounds stay bounded and preserve session totals', () {
    for (var index = 0; index < 3507; index += 1) {
      FluviDiagnosticLogger.log(FluviDiagnosticEvent(stage: 'D$index'));
    }

    expect(FluviDiagnosticLogger.retainedEntryCount, 1000);
    expect(FluviDiagnosticLogger.sessionEventCount, 3507);
    expect(FluviDiagnosticLogger.entryAt(0).stage, 'D2507');
    expect(FluviDiagnosticLogger.entryAt(999).stage, 'D3506');
    expect(
      FluviDiagnosticLogger.entryAt(999).sequence,
      greaterThan(FluviDiagnosticLogger.entryAt(0).sequence!),
    );
  });

  test('latest export describes the retained rolling window', () {
    for (var index = 0; index <= 1000; index += 1) {
      FluviDiagnosticLogger.log(FluviDiagnosticEvent(stage: 'D$index'));
    }

    final text = FluviDiagnosticLogger.latestText();
    expect(text, contains('LIVE_TAIL'));
    expect(text, contains('sessionEventCount=1001'));
    expect(text, contains('retainedCount=1000'));
    expect(text, contains('firstRetainedSequence='));
    expect(text, contains('[FLOW][D1]'));
    expect(text, isNot(contains('[FLOW][D0]')));
    expect(text, contains('[FLOW][D1000]'));
  });

  test('user marker is an ordered timestamped event with context', () {
    FluviDiagnosticLogger.log(const FluviDiagnosticEvent(stage: 'BEFORE'));
    FluviDiagnosticLogger.markUserBug(
      'mind_slider',
      context: const <String, Object?>{'mode': 'mind', 'direction': 'expense'},
    );

    final marker = FluviDiagnosticLogger.entries.last;
    expect(marker.stage, 'USER_MARK');
    expect(marker.scope, contains('issue=mind_slider'));
    expect(marker.scope, contains('mode=mind'));
    expect(
      marker.sequence,
      greaterThan(FluviDiagnosticLogger.entries.first.sequence!),
    );
    expect(marker.timestamp, isNotNull);
    expect(marker.elapsedMicros, isNotNull);
  });

  testWidgets('rapid bursts batch UI publication without dropping events', (
    tester,
  ) async {
    var notifications = 0;
    void listener() => notifications += 1;
    FluviDiagnosticLogger.notifier.addListener(listener);
    addTearDown(() => FluviDiagnosticLogger.notifier.removeListener(listener));
    final beforePublications = FluviDiagnosticLogger.uiPublicationCount;

    for (var index = 0; index < 400; index += 1) {
      FluviDiagnosticLogger.log(FluviDiagnosticEvent(stage: 'BURST-$index'));
    }
    expect(FluviDiagnosticLogger.retainedEntryCount, 400);
    expect(notifications, 0);

    await tester.pump();
    expect(notifications, 1);
    expect(FluviDiagnosticLogger.uiPublicationCount - beforePublications, 1);
    expect(FluviDiagnosticLogger.entries.last.stage, 'BURST-399');
  });

  test('clear removes entries without retaining business state', () {
    FluviDiagnosticLogger.log(
      const FluviDiagnosticEvent(stage: 'D10', message: '689 000 Ft'),
    );

    FluviDiagnosticLogger.clear();

    expect(FluviDiagnosticLogger.entries, isEmpty);
    expect(FluviDiagnosticLogger.allText, isEmpty);
  });

  test('clear live preserves the monotonic process-session event count', () {
    FluviDiagnosticLogger.log(const FluviDiagnosticEvent(stage: 'FIRST'));
    FluviDiagnosticLogger.clearLive();

    expect(FluviDiagnosticLogger.retainedEntryCount, 0);
    expect(FluviDiagnosticLogger.sessionEventCount, 1);
    FluviDiagnosticLogger.log(const FluviDiagnosticEvent(stage: 'SECOND'));
    expect(FluviDiagnosticLogger.sessionEventCount, 2);
  });

  test(
    'stamps every retained record with monotonic sequence and elapsed time',
    () {
      FluviDiagnosticLogger.log(const FluviDiagnosticEvent(stage: 'FIRST'));
      FluviDiagnosticLogger.log(const FluviDiagnosticEvent(stage: 'SECOND'));

      final first = FluviDiagnosticLogger.entries[0];
      final second = FluviDiagnosticLogger.entries[1];
      expect(first.sequence, isNotNull);
      expect(second.sequence, greaterThan(first.sequence!));
      expect(first.elapsedMicros, isNotNull);
      expect(second.elapsedMicros, greaterThanOrEqualTo(first.elapsedMicros!));
      expect(first.toLine(), contains('seq=${first.sequence}'));
      expect(first.toLine(), contains('elapsedMicros=${first.elapsedMicros}'));
    },
  );

  test('a frozen capture survives ten thousand general diagnostic events', () {
    final captureId = FluviDiagnosticLogger.startCapture();
    FluviDiagnosticLogger.log(
      const FluviDiagnosticEvent(
        stage: 'VERTICAL_PAGE_COMMITTED',
        queryKey: 'expense|day:2026-07-07',
      ),
    );
    FluviDiagnosticLogger.stopCapture();

    for (var index = 0; index < 10000; index += 1) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(stage: 'BACKGROUND-$index'),
      );
    }

    expect(FluviDiagnosticLogger.captureId, captureId);
    expect(FluviDiagnosticLogger.captureFrozen, isTrue);
    expect(
      FluviDiagnosticLogger.captureEntries.map((event) => event.stage),
      containsAll(<String>[
        'CAPTURE_STARTED',
        'VERTICAL_PAGE_COMMITTED',
        'CAPTURE_STOPPED',
      ]),
    );
    expect(
      FluviDiagnosticLogger.captureEntries.every(
        (event) => event.captureId == captureId,
      ),
      isTrue,
    );
  });

  test('coalesces consecutive repeated cache misses in a capture', () {
    FluviDiagnosticLogger.startCapture();
    for (var index = 0; index < 3; index += 1) {
      FluviDiagnosticLogger.log(
        const FluviDiagnosticEvent(
          stage: 'VERTICAL_CACHE_MISS',
          queryKey: 'expense|day:2026-07-07',
          error: 'Page 6 was not drawable.',
        ),
      );
    }
    FluviDiagnosticLogger.stopCapture();

    final misses = FluviDiagnosticLogger.captureEntries
        .where((event) => event.stage == 'VERTICAL_CACHE_MISS')
        .toList(growable: false);
    expect(misses, hasLength(1));
    expect(misses.single.repeatCount, 3);
    final report = FluviDiagnosticLogger.captureReport();
    expect(
      (report['counters'] as Map<Object?, Object?>)['verticalCacheMisses'],
      3,
    );
    expect(
      (report['stageCounts'] as Map<Object?, Object?>)['VERTICAL_CACHE_MISS'],
      3,
    );
  });

  test(
    'replays actual bound Header renderer evidence into a later capture',
    () {
      FluviDiagnosticLogger.log(
        const FluviDiagnosticEvent(
          stage: 'HEADER_RENDER_BACKEND_BOUND',
          scope: 'backend=fragmentShader physicalWidth=1236',
        ),
      );
      FluviDiagnosticLogger.log(
        const FluviDiagnosticEvent(
          stage: 'HEADER_SHADER_READY',
          scope: 'programIdentity=17 shaderIdentity=23',
        ),
      );
      FluviDiagnosticLogger.log(
        const FluviDiagnosticEvent(
          stage: 'HEADER_RENDER_FIDELITY_CONFIG',
          scope: 'fieldEvaluationMode=perFragment',
        ),
      );
      FluviDiagnosticLogger.log(
        const FluviDiagnosticEvent(
          stage: 'HEADER_PORTAL_INNER_CHANNEL_BOUND',
          scope: 'enabled=true inputSignature=portal-a',
        ),
      );
      FluviDiagnosticLogger.log(
        const FluviDiagnosticEvent(
          stage: 'HEADER_STATIC_COLOR_RENDERER_BOUND',
          scope: 'renderer=budget2CssLinearGradient fieldStopCount=10',
        ),
      );

      FluviDiagnosticLogger.startCapture();
      final replayed = FluviDiagnosticLogger.captureEntries
          .where(
            (event) => event.scope?.contains('captureReplay=true') ?? false,
          )
          .toList(growable: false);

      expect(
        replayed.map((event) => event.stage),
        containsAllInOrder(<String>[
          'HEADER_RENDER_BACKEND_BOUND',
          'HEADER_SHADER_READY',
          'HEADER_RENDER_FIDELITY_CONFIG',
          'HEADER_PORTAL_INNER_CHANNEL_BOUND',
          'HEADER_STATIC_COLOR_RENDERER_BOUND',
        ]),
      );
      expect(
        replayed
            .singleWhere(
              (event) => event.stage == 'HEADER_RENDER_FIDELITY_CONFIG',
            )
            .scope,
        contains('fieldEvaluationMode=perFragment'),
      );
    },
  );

  test('explicit profile diagnostics use the same policy as debug', () {
    expect(
      fluviOnscreenDiagnosticsEnabledFor(
        debugMode: false,
        requestedByCompileTimeFlag: true,
      ),
      isTrue,
    );
    expect(
      fluviOnscreenDiagnosticsEnabledFor(
        debugMode: false,
        requestedByCompileTimeFlag: false,
      ),
      isFalse,
    );
    expect(
      fluviOnscreenDiagnosticsEnabledFor(
        debugMode: true,
        requestedByCompileTimeFlag: false,
      ),
      isTrue,
    );
  });

  test('mirrors bounded Header renderer proof events to the physical log', () {
    expect(
      FluviDiagnosticLogger.isPlatformTraceStage('HEADER_RENDER_BACKEND_BOUND'),
      isTrue,
    );
    expect(
      FluviDiagnosticLogger.isPlatformTraceStage('HEADER_SHADER_READY'),
      isTrue,
    );
    expect(
      FluviDiagnosticLogger.isPlatformTraceStage(
        'HEADER_RENDER_FIDELITY_CONFIG',
      ),
      isTrue,
    );
    expect(
      FluviDiagnosticLogger.isPlatformTraceStage('HEADER_DEEP_DRIFT_BOUND'),
      isTrue,
    );
    expect(
      FluviDiagnosticLogger.isPlatformTraceStage(
        'HEADER_PORTAL_INNER_CHANNEL_BOUND',
      ),
      isTrue,
    );
    expect(
      FluviDiagnosticLogger.isPlatformTraceStage(
        'HEADER_PORTAL_FRAGMENT_INPUT_BOUND',
      ),
      isTrue,
    );
    expect(
      FluviDiagnosticLogger.isPlatformTraceStage(
        'HEADER_STATIC_COLOR_RENDERER_BOUND',
      ),
      isTrue,
    );
    expect(
      FluviDiagnosticLogger.isPlatformTraceStage('HEADER_SPACE_FABRIC_BOUND'),
      isTrue,
    );
    expect(
      FluviDiagnosticLogger.isPlatformTraceStage(
        'HEADER_SPACE_FABRIC_LIVENESS',
      ),
      isTrue,
    );
    expect(
      FluviDiagnosticLogger.isPlatformTraceStage(
        'BUDGET_HEADER_COOL_COLOR_BOUND',
      ),
      isTrue,
    );
    expect(
      FluviDiagnosticLogger.isPlatformTraceStage(
        'BUDGET_HEADER_COOL_WINDOW_CHANGED',
      ),
      isTrue,
    );
    expect(FluviDiagnosticLogger.isPlatformTraceStage('HEADER_TICK'), isFalse);
  });
}
