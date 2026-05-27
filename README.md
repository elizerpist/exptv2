# Exptv2

Automatic expense tracker shell built in Flutter.

This app is forked from `pushparserv2` and keeps its Android notification/accessibility capture engine integrated as infrastructure. The current UI intentionally shows only the first blank app shell: bottom navigation, centered FAB, blank pages, and a Settings page with the push parser app filter input plus installed-app picker control.

## Current Scope

- Push notification scraper engine remains in the app but is not connected to expense creation yet.
- Bottom nav and FAB match the old React Native project sizing and core colors.
- Home, Groceries, and Notifications tabs are blank placeholders.
- Settings contains the app regex input and installed-app picker inherited from the push parser UI.

## Local Path

```text
/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2
```

## Build

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```
