# Balance visual customization implementation plan

> **For agentic workers:** Execute each task in order and keep the linked acceptance checklist current.

**Goal:** Add independent Balance appearance controls and consume existing large-card stretch in the shared first-page ranked-list layout while preserving the accepted carousel.

**Architecture:** `BalancePresentationSettings` remains the one immutable settings contract.  The visual tuner writes only to its controller.  The existing carousel resolves effective paint alpha from authored reference values plus settings.  A single ranked-list geometry resolver handles Top category and Top partner identically.

**Constraints:** Do not change carousel dimensions, scales, physics, controllers, selection, ranking/data, outer card-height computation, or non-Balance UI.  Defaults equal the pre-feature accepted appearance.  The source checklist is `docs/superpowers/checklists/2026-09-26-balance-visual-customization.md`.

## Task 1 — Lock settings behavior with RED tests

**Files:** `test/features/dashboard/presentation/balance_presentation_settings_test.dart`, `test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart`

- [x] Add tests for defaults, normalized 0/intermediate/1 opacity updates, enabled-state persistence and independent setters.
- [x] Add tuner tests requiring all five stable keys, labels/percentage presentation and isolated interaction outcomes.
- [x] Run the focused tests and observe RED before production changes.

## Task 2 — Add the centralized settings contract and tuner writers

**Files:** `lib/features/dashboard/presentation/core_modes/balance_presentation_settings.dart`, `lib/features/dashboard/presentation/dashboard_header_visual_tuner.dart`

- [x] Add the five explicit fields, equality/copy support, normalization and no-op updates to the existing controller.
- [x] Add the requested Hungarian Balance Carousel/Content Card controls with stable keys; keep them independent.
- [x] Re-run Task 1 tests to GREEN.

## Task 3 — Parameterize existing card paint and content outline

**Files:** `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`, `lib/features/dashboard/presentation/widgets/dashboard_placeholder_card.dart`, `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`

- [x] First add RED tests for independent effective tint/outline/wave values, unchanged mini-card bounds/controller identity, and content outline alpha.
- [x] Thread settings through existing hosts; retain authored dimensions/path and palette source.  Use a transparent same-width border at zero alpha.
- [x] Apply only the content outline alpha to the already selected semantic border source.
- [x] Re-run focused surface tests to GREEN and run `BCL-03` without updating the golden.

## Task 4 — Implement one stretch geometry resolver

**Files:** `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`, `lib/features/dashboard/presentation/core_modes/balance_linked_detail_card.dart`, `test/features/dashboard/presentation/balance_linked_detail_card_test.dart`

- [x] Add RED layout tests for baseline/stretched rank sizes, equal secondary avatars, rank-one cap, in-bounds rows, reduced bottom space and category/partner parity.
- [x] Expose the already-resolved principal content-stretch scalar on the immutable geometry frame; no outer geometry calculation changes.
- [x] Pass the scalar into the canonical page-one ranked-list resolver; distribute a bounded amount to equal secondary avatars and safe row gaps.
- [x] Re-run ranked and surface suites to GREEN.

## Task 5 — Verify, deliver, and record evidence

- [x] Format production and test Dart files.
- [x] Run every focused suite, default golden regression and targeted `flutter analyze` inside Ubuntu proot.
- [x] Re-read this plan, the checklist and the current reference implementation; update every acceptance status honestly.
- [ ] Commit app code/tests, push the feature branch, monitor the exact GitHub human diagnostic APK job, download the normal human APK to `/storage/emulated/0/Download/fluvi`, and record its SHA-256.
