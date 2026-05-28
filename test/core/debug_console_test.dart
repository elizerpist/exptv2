import 'package:exptv2/core/debug/debug_console.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(DebugConsole.clear);

  test('records timestamped entries and notifies listeners', () {
    var notifications = 0;
    void listener() => notifications += 1;
    DebugConsole.notifier.addListener(listener);
    addTearDown(() => DebugConsole.notifier.removeListener(listener));

    DebugConsole.log('recurring ghost created');

    expect(DebugConsole.entries, hasLength(1));
    expect(DebugConsole.entries.single, contains('recurring ghost created'));
    expect(
      DebugConsole.entries.single,
      matches(r'^\[\d{2}:\d{2}:\d{2}\.\d{2}\] '),
    );
    expect(notifications, 1);
  });

  test('clear removes entries and increments notifier', () {
    DebugConsole.log('one');
    DebugConsole.clear();

    expect(DebugConsole.entries, isEmpty);
    expect(DebugConsole.allText, '');
  });

  test('keeps only the newest max entries', () {
    for (var i = 0; i < 520; i += 1) {
      DebugConsole.log('row $i');
    }

    expect(DebugConsole.entries, hasLength(500));
    expect(DebugConsole.entries.first, contains('row 20'));
    expect(DebugConsole.entries.last, contains('row 519'));
  });
}
