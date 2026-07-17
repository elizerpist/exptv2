import 'package:exptv2/services/preview/preview_native_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seed covers current, adjacent, and prior-year UI states', () {
    final state = PreviewNativeState.seeded(now: DateTime(2026, 7, 18));

    expect(
      state.categories.where((row) => row['type'] == 'kiadás'),
      hasLength(6),
    );
    expect(
      state.categories.where((row) => row['type'] == 'bevétel'),
      hasLength(2),
    );
    expect(
      state.transactions.where(
        (row) => row['date'].toString().startsWith('2026.07'),
      ),
      hasLength(12),
    );
    expect(
      state.transactions.where(
        (row) => row['date'].toString().startsWith('2026.06'),
      ),
      hasLength(4),
    );
    expect(
      state.transactions.where(
        (row) => row['date'].toString().startsWith('2025.'),
      ),
      hasLength(4),
    );
    expect(state.securitySettings['pinEnabled'], isFalse);
    expect(state.securitySettings['biometricAvailable'], isFalse);
  });

  test('reset restores fixtures and monotonic IDs', () {
    final state = PreviewNativeState.seeded(now: DateTime(2026, 7, 18));
    final first = state.takeTransactionId();
    state.transactions.clear();
    state.reset();
    final afterReset = state.takeTransactionId();

    expect(state.transactions, isNotEmpty);
    expect(afterReset, first);
  });

  test('reset replaces nested parser fixture data', () {
    final state = PreviewNativeState.seeded(now: DateTime(2026, 7, 18));
    final profiles = state.notificationParserConfig['profiles']! as List;
    final firstProfile = profiles.first as Map<String, Object?>;
    firstProfile['name'] = 'Mutated';

    state.reset();

    final resetProfiles = state.notificationParserConfig['profiles']! as List;
    final resetProfile = resetProfiles.first as Map<String, Object?>;
    expect(resetProfile['name'], isNot('Mutated'));
  });
}
