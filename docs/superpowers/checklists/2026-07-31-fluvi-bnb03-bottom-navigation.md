# Fluvi BNB-03 bottom navigation checklist

Reference: `/storage/emulated/0/spendee/final/bnb03_bottom_navigation.dart`

| ID | Source instruction | Intended code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| BNB03-01 | User: add BNB-03 as an alternative; do not delete the existing bottom nav | `lib/app/shell/` | Existing convex navigation file remains; BNB-03 is a separate widget and is the selected shell variant | Source inspection | DONE |
| BNB03-02 | User: use `iconsax_plus: ^1.0.0` and selected icon states | `pubspec.yaml`, `bnb03_bottom_navigation.dart` | Dependency is declared and BNB-03 switches linear/bold Iconsax icons by selection | Dependency/source inspection | DONE |
| BNB03-03 | User: use the BNB-03 geometry, colors, center action and overflow | `bnb03_bottom_navigation.dart` | 428×75 bar geometry, 96×96 raised center action, exact colors and scaled layout are retained | Reference comparison and user visual inspection | DONE — source copied byte-for-byte from the supplied BNB-03 reference |
| BNB03-04 | User: switch the shell to this alternative with `extendBody` and `SafeArea` | `fluvi_app_shell.dart` | Shell uses `Scaffold(extendBody: true)` and `SafeArea(top: false, ...)` around BNB-03 | Source inspection and release build | DONE |
| BNB03-05 | User: Figma typography uses SF Pro Text Regular | `bnb03_bottom_navigation.dart`, `assets/` | Component requests `SF Pro Text`; a bundled font is registered if the supplied asset exists | Asset/source inspection | PARTIAL — no SF Pro font file exists in the supplied final directory |
| BNB03-06 | Earlier user instruction: add fullscreen button | `fluvi_app_shell.dart`, `core/platform/` | App-owned fullscreen button is present in the shell and invokes the platform adapter | Source inspection and widget test | DONE |
