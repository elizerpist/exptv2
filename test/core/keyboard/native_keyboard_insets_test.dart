import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/core/keyboard/keyboard_inset_follower.dart';
import 'package:exptv2/core/keyboard/native_keyboard_insets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    DebugConsole.clear();
    NativeKeyboardInsets.instance.debugResetForTesting();
  });

  tearDown(() {
    NativeKeyboardInsets.instance.debugResetForTesting();
  });

  testWidgets(
    'keyboard follower rejects fresh native IME sample behind fallback',
    (tester) async {
      tester.view.viewInsets = const FakeViewPadding(bottom: 251.8);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetViewInsets();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: KeyboardInsetFollower(
            debugLabel: 'TestKeyboard',
            builder: (context, metrics, child) {
              return Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  'raw=${metrics.rawInset.toStringAsFixed(1)} '
                  'source=${metrics.source}',
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('raw=251.8 source=flutter-viewInsets'), findsOneWidget);

      NativeKeyboardInsets.instance.debugSetSampleForTesting(
        NativeKeyboardInsetSample(
          inset: 9.5,
          source: 'native-ime',
          phase: 'progress',
          sequence: 7,
          receivedAt: DateTime.now(),
          frameNanos: 123,
        ),
      );
      await tester.pump();

      expect(find.text('raw=251.8 source=flutter-viewInsets'), findsOneWidget);
      expect(DebugConsole.allText, contains('source=flutter-viewInsets'));
      expect(DebugConsole.allText, contains('phase=native-behind-fallback'));
      expect(DebugConsole.allText, contains('seq=7'));
    },
  );

  testWidgets('keyboard follower interpolates active IME session locally', (
    tester,
  ) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 252);
    tester.view.devicePixelRatio = 1;
    var latestRawInset = 0.0;
    var latestSource = '';
    addTearDown(() {
      tester.view.resetViewInsets();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: KeyboardInsetFollower(
          debugLabel: 'SessionKeyboard',
          builder: (context, metrics, child) {
            latestRawInset = metrics.rawInset;
            latestSource = metrics.source;
            return Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                'raw=${metrics.rawInset.toStringAsFixed(1)} '
                'source=${metrics.source}',
              ),
            );
          },
        ),
      ),
    );

    final sessionStart = DateTime.now().add(const Duration(seconds: 1));
    NativeKeyboardInsets.instance.debugSetSessionForTesting(
      NativeKeyboardAnimationSession(
        phase: KeyboardAnimationPhase.start,
        sequence: 12,
        startInset: 0,
        endInset: 252,
        currentInset: 0,
        duration: const Duration(milliseconds: 200),
        fraction: 0,
        receivedAt: DateTime.now(),
        startedAt: sessionStart,
        nativeSource: 'WindowInsetsAnimation',
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(latestRawInset, moreOrLessEquals(126, epsilon: 1));
    expect(latestSource, 'local-ime-session');
  });

  testWidgets(
    'keyboard follower keeps delayed IME session on remaining clock',
    (tester) async {
      tester.view.viewInsets = const FakeViewPadding(bottom: 252);
      tester.view.devicePixelRatio = 1;
      var latestRawInset = 0.0;
      var latestSource = '';
      addTearDown(() {
        tester.view.resetViewInsets();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: KeyboardInsetFollower(
            debugLabel: 'DelayedSessionKeyboard',
            builder: (context, metrics, child) {
              latestRawInset = metrics.rawInset;
              latestSource = metrics.source;
              return Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  'raw=${metrics.rawInset.toStringAsFixed(1)} '
                  'source=${metrics.source}',
                ),
              );
            },
          ),
        ),
      );

      NativeKeyboardInsets.instance.debugSetSessionForTesting(
        NativeKeyboardAnimationSession(
          phase: KeyboardAnimationPhase.start,
          sequence: 21,
          startInset: 0,
          endInset: 252,
          currentInset: 126,
          duration: const Duration(milliseconds: 200),
          fraction: 0.5,
          receivedAt: DateTime.now(),
          startedAt: DateTime.now().subtract(const Duration(milliseconds: 100)),
          nativeSource: 'WindowInsetsAnimation',
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(latestSource, 'local-ime-session');
      expect(latestRawInset, greaterThan(160));
      expect(latestRawInset, lessThan(235));
    },
  );

  test('stale native IME sample falls back even when inset matches', () {
    final now = DateTime(2026, 7, 10, 18, 50);

    final resolved = NativeKeyboardInsetResolver.resolve(
      nativeSample: NativeKeyboardInsetSample(
        inset: 252.2,
        source: 'native-ime',
        phase: 'end',
        sequence: 63,
        receivedAt: now.subtract(const Duration(seconds: 4)),
        nativeSource: 'WindowInsetsAnimation',
      ),
      fallbackInset: 252.2,
      now: now,
    );

    expect(resolved.inset, 252.2);
    expect(resolved.source, 'flutter-viewInsets');
    expect(resolved.phase, 'native-stale');
    expect(resolved.sequence, 63);
    expect(resolved.ageMs, 4000);
  });

  test('native sample gate suppresses duplicate progress frames', () {
    final gate = NativeKeyboardInsetSampleGate();
    final now = DateTime(2026, 7, 10, 18, 50);

    NativeKeyboardInsetSample sample(double inset, String phase, int sequence) {
      return NativeKeyboardInsetSample(
        inset: inset,
        source: 'native-ime',
        phase: phase,
        sequence: sequence,
        receivedAt: now,
      );
    }

    expect(gate.shouldPublish(sample(0, 'progress', 1)), isTrue);
    expect(gate.shouldPublish(sample(0.1, 'progress', 2)), isFalse);
    expect(gate.shouldPublish(sample(10.7, 'progress', 3)), isTrue);
    expect(gate.shouldPublish(sample(10.8, 'progress', 4)), isFalse);
    expect(gate.shouldPublish(sample(10.8, 'end', 5)), isTrue);
  });

  test('native IME session event is parsed with geometry and timing', () {
    final session = NativeKeyboardAnimationSession.fromEvent({
      'kind': 'session',
      'phase': 'start',
      'seq': 42,
      'startImeDp': 0.0,
      'endImeDp': 252.2,
      'imeDp': 10.7,
      'durationMs': 220,
      'fraction': 0.044,
      'startedAtEpochMs': 1783711663000,
      'eventNanos': 123456789,
      'nativeSource': 'WindowInsetsAnimation',
    });

    expect(session, isNotNull);
    expect(session!.phase, KeyboardAnimationPhase.start);
    expect(session.sequence, 42);
    expect(session.startInset, 0.0);
    expect(session.endInset, 252.2);
    expect(session.currentInset, 10.7);
    expect(session.duration, const Duration(milliseconds: 220));
    expect(session.fraction, 0.044);
    expect(
      session.startedAt,
      DateTime.fromMillisecondsSinceEpoch(1783711663000),
    );
    expect(session.nativeSource, 'WindowInsetsAnimation');
  });

  test('motion coordinator rejects fresh native sample that lags fallback', () {
    final now = DateTime(2026, 7, 10, 19, 27, 43, 890);

    final resolved = KeyboardInsetMotionCoordinator.resolveIdle(
      nativeSample: NativeKeyboardInsetSample(
        inset: 9.5,
        source: 'native-ime',
        phase: 'progress',
        sequence: 4,
        receivedAt: now.subtract(const Duration(milliseconds: 91)),
        nativeSource: 'WindowInsetsAnimation',
      ),
      fallbackInset: 251.8,
      now: now,
    );

    expect(resolved.inset, 251.8);
    expect(resolved.source, 'flutter-viewInsets');
    expect(resolved.phase, 'native-behind-fallback');
    expect(resolved.sequence, 4);
  });

  test('motion coordinator interpolates active IME session locally', () {
    final startedAt = DateTime(2026, 7, 10, 19, 27, 43, 800);
    final session = NativeKeyboardAnimationSession(
      phase: KeyboardAnimationPhase.start,
      sequence: 4,
      startInset: 0,
      endInset: 252,
      currentInset: 9.5,
      duration: const Duration(milliseconds: 200),
      fraction: 0.044,
      receivedAt: startedAt,
      eventNanos: 1,
      nativeSource: 'WindowInsetsAnimation',
    );

    final halfway = KeyboardInsetMotionCoordinator.interpolateSession(
      session: session,
      now: startedAt.add(const Duration(milliseconds: 100)),
      fallbackInset: 252,
    );

    expect(halfway.source, 'local-ime-session');
    expect(halfway.phase, 'session-active');
    expect(halfway.inset, moreOrLessEquals(137.1, epsilon: 1));
  });
}
