# FAB Keyboard Sheet Refactor Design

## Context

The AddTransaction FAB sheet has gone through several native-host fixes, but user testing still shows lag, crashes, wrong keyboard-top tracking, a blank white native container before Flutter content paints, and missing swipe behavior. The most recent diagnosis points to an architectural split: the sheet content and footer are not moving as one coherent panel, and the native AddTransaction host adds a second Flutter lifecycle with focus and content-readiness races.

The approved direction is to stop using the native AddTransaction host for the normal FAB flow and rebuild the FAB sheet as a Flutter-owned sheet driven by a keyboard animation controller package.

## Requirements

- The FAB AddTransaction path must not call the native `openAddTransaction` host.
- The native IME probe/debug tooling may remain for diagnostics, but it must not prewarm or own the normal AddTransaction FAB sheet.
- The app root must provide `flutter_keyboard_controller` keyboard state to the main Flutter tree.
- The AddTransaction `SlideUpMenuCard` must use one panel-level keyboard height source for movement.
- The save footer must be part of the sheet's own panel coordinate system, with no separate keyboard-dependent footer lift.
- The form body must scroll when vertical space is constrained, while the save footer remains fixed at the panel bottom.
- Existing non-FAB sheets should not be refactored in this pass unless required for compilation.
- The refactor must have targeted tests and pass Flutter analysis through the Ubuntu proot Flutter toolchain.

## Architecture

The main app will wrap `Exptv2App` in `KeyboardProvider`. `SlideUpMenuCard` will gain an opt-in controller-driven keyboard avoidance mode. AddTransaction will opt into that mode, so the panel transform is driven by the package's frame-by-frame height notifier instead of the app's legacy `KeyboardInsetFollower`.

The AddTransaction sheet content remains a single panel: scrollable form body plus fixed footer. The footer keeps stable bottom padding based on device safe area only. It no longer switches padding based on keyboard visibility.

`ExptShell` will open AddTransaction directly through `_ShellSheetHostState.openTransaction` on FAB tap. The native `NativeImeSheetHost` remains available for the debug probe and existing tests, but automatic AddTransaction prewarm is removed so it does not create blank native containers or extra engine work during normal app startup.

## Verification

Targeted widget tests should prove the FAB opens the Flutter sheet and does not invoke `openAddTransaction`. AddTransaction tests should prove the non-native sheet renders a fixed footer in a scrollable body and opts into controller-driven keyboard motion. Existing native-host tests may remain as diagnostic coverage.

Final verification must run targeted tests first, then `flutter analyze` in Ubuntu proot. Android APK builds remain GitHub Actions work, not local Termux work.
