import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/lock_screen_card/domain/lock_screen_card_repository.dart';

void main() {
  test('reads the actual Android channel lock-screen policy separately', () {
    final status = LockScreenCardStatus.fromMap(<Object?, Object?>{
      'configuration': <Object?, Object?>{},
      'content': <Object?, Object?>{},
      'statusChannelImportance': 'Csendes',
      'statusChannelLockscreenVisibility': 'Érzékeny tartalom szerint',
    });

    expect(status.statusChannelImportance, 'Csendes');
    expect(
      status.statusChannelLockscreenVisibility,
      'Érzékeny tartalom szerint',
    );
  });

  test('keeps older native payloads readable without claiming visibility', () {
    final status = LockScreenCardStatus.fromMap(<Object?, Object?>{
      'configuration': <Object?, Object?>{},
      'content': <Object?, Object?>{},
    });

    expect(status.statusChannelLockscreenVisibility, 'Rendszer szerinti');
  });
}
