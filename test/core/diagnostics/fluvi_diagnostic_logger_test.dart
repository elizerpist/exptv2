import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_event.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/core/diagnostics/fluvi_onscreen_diagnostics.dart';

void main() {
  setUp(FluviDiagnosticLogger.clear);

  test('keeps the Spendee bounded ring buffer and formats flow metadata', () {
    for (var index = 0; index < 520; index += 1) {
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

    expect(FluviDiagnosticLogger.entries, hasLength(500));
    expect(FluviDiagnosticLogger.entries.first.stage, 'D20');
    expect(FluviDiagnosticLogger.entries.last.stage, 'D519');
    expect(
      FluviDiagnosticLogger.entries.last.toLine(),
      contains('[FLOW][D519] flowId=Q-test'),
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
}
