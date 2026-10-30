import 'package:fluvi/features/manual_transactions/application/manual_transaction_editor_preferences.dart';
import 'package:fluvi/features/manual_transactions/data/method_channel_manual_transaction_editor_preferences_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('fluvi/dashboard_presentation');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'legacy presentation enums are ignored for the new preference',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'readManualTransactionEditorSettings') {
          return <String, Object?>{'layout': 1, 'partnerPickerPresentation': 0};
        }
        return null;
      });

      final preferences =
          await MethodChannelManualTransactionEditorPreferencesStore(
            channel: channel,
          ).read();

      expect(preferences.showMetadataIconBackgrounds, isTrue);
    },
  );

  test(
    'metadata icon-background preference reads and writes independently',
    () async {
      Map<Object?, Object?>? written;
      messenger.setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'readManualTransactionEditorSettings':
            return <String, Object?>{'showMetadataIconBackgrounds': false};
          case 'writeManualTransactionEditorSettings':
            written = call.arguments as Map<Object?, Object?>;
            return null;
        }
        return null;
      });
      final store = MethodChannelManualTransactionEditorPreferencesStore(
        channel: channel,
      );

      expect((await store.read()).showMetadataIconBackgrounds, isFalse);
      await store.write(
        const ManualTransactionEditorPreferences(
          showMetadataIconBackgrounds: false,
        ),
      );

      expect(written, <Object?, Object?>{'showMetadataIconBackgrounds': false});
    },
  );
}
