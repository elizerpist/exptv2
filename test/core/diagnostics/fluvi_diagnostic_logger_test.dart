import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_event.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/core/diagnostics/fluvi_onscreen_diagnostics.dart';

void main() {
  setUp(FluviDiagnosticLogger.clear);

  test('keeps the Spendee bounded ring buffer and formats flow metadata', () {
    for (var index = 0; index < 1100; index += 1) {
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

    expect(FluviDiagnosticLogger.entries, hasLength(1000));
    expect(FluviDiagnosticLogger.entries.first.stage, 'D100');
    expect(FluviDiagnosticLogger.entries.last.stage, 'D1099');
    expect(
      FluviDiagnosticLogger.entries.last.toLine(),
      contains('[FLOW][D1099] flowId=Q-test'),
    );
  });

  test('clear removes entries without retaining business state', () {
    FluviDiagnosticLogger.log(
      const FluviDiagnosticEvent(stage: 'D10', message: '689 000 Ft'),
    );

    FluviDiagnosticLogger.clear();

    expect(FluviDiagnosticLogger.entries, isEmpty);
    expect(FluviDiagnosticLogger.allText, isEmpty);
  });

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
      FluviDiagnosticLogger.isPlatformTraceStage('BUDGET_HEADER_PALETTE_BOUND'),
      isTrue,
    );
    expect(
      FluviDiagnosticLogger.isPlatformTraceStage(
        'BUDGET_HEADER_PALETTE_WINDOW_BOUND',
      ),
      isTrue,
    );
    expect(FluviDiagnosticLogger.isPlatformTraceStage('HEADER_TICK'), isFalse);
  });
}
