import 'package:flutter/services.dart';

/// This is intentionally separate from the editor's two presentation choices.
/// It controls only the visual shell of the centre-FAB action selector.
enum CreationSelectorDesign { refreshed, previous }

abstract interface class CreationSelectorPreferencesStore {
  Future<CreationSelectorDesign> read();
  Future<void> write(CreationSelectorDesign design);
}

final class DefaultCreationSelectorPreferencesStore
    implements CreationSelectorPreferencesStore {
  const DefaultCreationSelectorPreferencesStore();

  @override
  Future<CreationSelectorDesign> read() async =>
      CreationSelectorDesign.refreshed;

  @override
  Future<void> write(CreationSelectorDesign design) async {}
}

/// Uses the existing local dashboard-presentation storage.  The native host
/// treats an absent value as [CreationSelectorDesign.refreshed], so no first
/// opening can flash the retired design.
final class MethodChannelCreationSelectorPreferencesStore
    implements CreationSelectorPreferencesStore {
  MethodChannelCreationSelectorPreferencesStore({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('fluvi/dashboard_presentation');

  final MethodChannel _channel;

  @override
  Future<CreationSelectorDesign> read() async {
    try {
      final value = await _channel.invokeMethod<int>(
        'readCreationSelectorDesign',
      );
      return value == CreationSelectorDesign.previous.index
          ? CreationSelectorDesign.previous
          : CreationSelectorDesign.refreshed;
    } on PlatformException {
      return CreationSelectorDesign.refreshed;
    } on MissingPluginException {
      return CreationSelectorDesign.refreshed;
    }
  }

  @override
  Future<void> write(CreationSelectorDesign design) async {
    try {
      await _channel.invokeMethod<void>('writeCreationSelectorDesign', {
        'design': design.index,
      });
    } on PlatformException {
      // The selector remains usable in an unsupported host. The documented
      // new-design default is applied the next time it is opened.
    } on MissingPluginException {
      return;
    }
  }
}
