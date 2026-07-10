# Native IME Sheet Host Design

## Goal

Build a measurable Android-native IME-follow proof of concept for the sheet motion path. This is an architecture step, not another Flutter keyboard follower patch.

## Problem Evidence

The user logs show Android IME animation starts, but the first useful Flutter visual frame arrives around the middle of the native keyboard animation. Example: native session starts at `21:30:07.52` with `285ms` duration; first local Flutter sheet frame appears around `21:30:07.68` at `raw=146.9`. The visual path is late even when the local controller computes a plausible value.

## Architecture

Android owns outer sheet motion. A native overlay host contains a moving bottom sheet container. `WindowInsetsAnimationCompat.Callback.onProgress` reads `WindowInsetsCompat.Type.ime()` and applies `translationY` directly to the native moving container. Flutter does not receive per-frame motion.

Flutter owns only probe content in this pass. A dedicated Dart entrypoint renders a small diagnostic sheet with text fields and a close action. The native host embeds that Flutter content in a `FlutterView` backed by a dedicated cached engine for the probe.

The main Flutter app opens the POC through a semantic method call from Debug Console. The production AddTransaction FAB path remains unchanged until the native motion path is proven on device.

## Scope

Included:
- Native motion model for IME bottom inset to `translationY`.
- Native overlay host with `WindowInsetsAnimationCompat.Callback.onProgress`.
- Dedicated Flutter probe entrypoint and UI with text fields.
- Debug Console button to open the native IME sheet probe.
- Logs for native open/close and sampled IME translation.

Excluded:
- Full AddTransaction form migration.
- Category picker, recurring, budget, and edit transaction sheet migration.
- Replacing the FAB behavior.
- Global edge-to-edge/`adjustNothing` migration outside the probe host lifecycle.

## Acceptance

The checklist lives at `docs/superpowers/checklists/2026-07-10-native-ime-sheet-host-checklist.md`. This work is complete only when every POC item in that checklist is `DONE`, or when unfinished items are explicitly called out.
