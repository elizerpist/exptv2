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

  test('reads independent discreet widget configuration and host count', () {
    final status = LockScreenCardStatus.fromMap(<Object?, Object?>{
      'configuration': <Object?, Object?>{'enabled': false},
      'content': <Object?, Object?>{},
      'widget': <Object?, Object?>{
        'configuration': <Object?, Object?>{
          'mode': 'balance',
          'timeAxis': 'month',
          'direction': 'expense',
          'eventLine': 'related',
          'privacy': 'discreet',
          'valid': true,
        },
        'content': <Object?, Object?>{
          'focus': 'Balance · Hónap',
          'primary': '+33 200 Ft',
          'secondary': 'Hónap nettó',
          'available': true,
        },
        'hostWidgetCount': 2,
        'lockscreenPlacementVerified': false,
      },
    });

    expect(status.configuration.enabled, isFalse);
    expect(status.widget.configuration.privacy, LockScreenCardPrivacy.discreet);
    expect(status.widget.hostWidgetCount, 2);
    expect(status.widget.lockscreenPlacementVerified, isFalse);
  });

  test(
    'native accessibility overlay starts opt-in and discreet after migration',
    () {
      final status = LockScreenCardStatus.fromMap(<Object?, Object?>{
        'configuration': <Object?, Object?>{},
        'content': <Object?, Object?>{},
        'nativeCard': <Object?, Object?>{},
      });

      expect(status.nativeCard.configuration.requested, isFalse);
      expect(status.nativeCard.configuration.showFinancialDetails, isFalse);
      expect(
        status.nativeCard.configuration.animationMode,
        NativeKeyguardCardAnimationMode.orbOnly,
      );
      expect(
        status.nativeCard.configuration.presentationMode,
        NativeKeyguardCardPresentationMode.card,
      );
      expect(status.nativeCard.systemServiceEnabled, isFalse);
      expect(status.nativeCard.serviceConnected, isFalse);
    },
  );

  test('native service status is distinct from user request', () {
    final status = LockScreenCardStatus.fromMap(<Object?, Object?>{
      'configuration': <Object?, Object?>{},
      'content': <Object?, Object?>{},
      'nativeCard': <Object?, Object?>{
        'requested': true,
        'showFinancialDetails': false,
        'systemServiceEnabled': true,
        'serviceConnected': false,
        'lastDecisionReason': 'HIDDEN_DISCONNECTED',
      },
    });

    expect(status.nativeCard.configuration.requested, isTrue);
    expect(status.nativeCard.systemServiceEnabled, isTrue);
    expect(status.nativeCard.serviceConnected, isFalse);
    expect(status.nativeCard.configuration.showFinancialDetails, isFalse);
  });

  test('keeps the three native material modes round-trippable', () {
    for (final mode in NativeKeyguardCardAnimationMode.values) {
      final value = NativeKeyguardCardConfiguration(
        requested: true,
        showFinancialDetails: false,
        verticalOffsetDp: 0,
        animationMode: mode,
      );
      final parsed = NativeKeyguardCardStatus.fromMap(
        value.toMap(),
      ).configuration;
      expect(parsed.animationMode, mode);
    }
  });

  test('native keyguard focus is independent and keeps a Budget category', () {
    const value = NativeKeyguardCardConfiguration(
      requested: true,
      showFinancialDetails: true,
      verticalOffsetDp: 12,
      animationMode: NativeKeyguardCardAnimationMode.orbOnly,
      focus: NativeKeyguardCardFocus(
        mode: LockScreenCardMode.budget,
        timeAxis: LockScreenCardTimeAxis.month,
        direction: LockScreenCardDirection.expense,
        categoryId: 'food',
      ),
    );

    final parsed = NativeKeyguardCardStatus.fromMap(
      value.toMap(),
    ).configuration;
    expect(parsed.focus.mode, LockScreenCardMode.budget);
    expect(parsed.focus.categoryId, 'food');
    expect(parsed.focus.valid, isTrue);
  });

  test('native card and standalone orb positions remain separate on wire', () {
    const patch = NativeKeyguardCardLayoutPatch(
      presentationMode: NativeKeyguardCardPresentationMode.orb,
      cardPosition: NativeKeyguardCardCardPosition(.7),
      orbPosition: NativeKeyguardCardOrbPosition(.2, .8),
    );

    expect(patch.toMap(), <String, Object?>{
      'presentationMode': 'orb',
      'cardPosition': <String, Object?>{'yFraction': .7},
      'orbPosition': <String, Object?>{'xFraction': .2, 'yFraction': .8},
    });
  });

  test('unknown native presentation migrates safely to card', () {
    final status = NativeKeyguardCardStatus.fromMap(<Object?, Object?>{
      'presentationMode': 'future-shape',
    });

    expect(
      status.configuration.presentationMode,
      NativeKeyguardCardPresentationMode.card,
    );
  });
}
