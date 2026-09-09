# Hardened K Avatar profile task report

Status: local implementation and focused verification complete; actual exact-SHA Android profile JSON remains **PARTIAL / awaiting CI**. This report does not claim production-composition, APK, or physical correctness completion.

Specification: `user-prompt.txt` §§10–12, checklist AVL-16, architecture card `../../architecture/2026-09-09-avatar-target-liveness.md`, written plan Task 4. Work was limited to the existing integration profile, its existing pure report validator, report tests, and one profile boundary test. No production, fixture, Core, rail, cache, composition-test, driver, or workflow source was edited by this task.

## Ownership and changes

- `integration_test/support/dashboard_profile_report.dart` remains the sole profile validator. It has no Flutter, controller, repository, cache, or timer dependency. A shared final-target validator checks both each fling and the overall final report; no second validation mechanism was introduced.
- `integration_test/dashboard_interaction_profile_test.dart` observes the real persistent rail/Core/presentation owners. K starts with its Time rail closed in the seeded July month; it performs four real alternating Avatar flings with no Time gesture. Before measurement it inspects the existing immutable native membership, requiring eight nonempty category row sets, pairwise disjoint IDs, a nonempty aggregate, and equality with the actual prepared month entry count. This inspection does not prepare another index or scene.
- Each fling must pass its own eight-second completion window before the next pointer starts. The old `if (avatarPaints.isNotEmpty) return` escape is removed. After the performance trace's renderer wait, the final owners are read and validated again to catch a delayed old canonical publication.
- The inherited large integration-test file remains one profile harness with scenario preparation, measurement and report collection. The added functions only inspect existing owners and collect bounded evidence; all acceptance rules stay in its existing pure report owner.

## Required field provenance

| Evidence | Actual source |
|---|---|
| Physical centered/settled handle | Mounted `CenteredCarousel.controller.rawCenteredLogicalIndex`, normalized by the real catalog count; final center must be within 0.01 item of its integer center |
| Latest desired handle | Last real `AV\|PREVIEW_REQUESTED` event in that flight |
| Latest semantic handle | `Core.liveInteractions.frame.budgetTargetHandle` |
| Exact painted/List handle and query | Core's actual `budgetAvatarTargetPainted` acknowledgement emitted after LogBox paint |
| Selected Budget handle | Mounted rail's `DashboardBudgetPresentationController.value.selectedHandle` |
| Focus handle/category digest | Core ephemeral focus category mapped through the real Budget catalog |
| Visible category/query digest | Core visible LogBox payload scope and visible-frame query |
| Canonical category/query digest | Navigation's committed parent scope and committed paging query key; `currentQuery` remains the separate base Query authority |
| Pending candidate count | Core `budgetAvatarFocusHotsetDiagnostics['pendingCandidate']` |
| Exact-local unavailable count | Actual bounded diagnostic `reason=exactLocalHotsetUnavailable` events |
| Nonempty requested count | Real preview requests matched to the verified current-month target membership |
| Nonempty accepted count | Core `AV\|VISIBLE_PUBLICATION_ACCEPTED` events with real `entryCount > 0` |
| Nonempty painted count | Actual acknowledgement with `exactEmpty == false` and readable Phase-A rows |
| Final Header/progress paints and values | Last actual `BUDGET_HEADER_PAINTED` / `BUDGET_PROGRESS_PAINTED` events in the flight, including handle, revision and both scaled values; checked against the current Budget presentation |
| Final exact/canonical/equality flags | Computed from the above real owners and paint acknowledgements; validator also compares the raw fields independently |
| Generic coordinator rejects | Real `AV\|PREVIEW_REJECTED reason=coordinatorRejected` events; required zero |
| Time interaction count | Observed Core Time rail / summary-shell motion lanes during K; required zero |

Additional terminal accounting requires requested count = terminal count = sum of `AV|PREVIEW_TERMINAL` classifications, with a positive `acceptedExactNonEmptyPainted` count for every fling. Unknown and `explicitInvariantFailure` classifications fail. Legitimate superseded first-target classifications are permitted only alongside this full terminal accounting and each exact nonempty final-target invariant.

The integration driver already writes structured report maps on failure. K now exports `dashboard_avatar_target_completion_evidence` on completion or timeout, and `dashboard_avatar_final_target_evidence` after the trace renderer wait, preserving actual invalid evidence for CI inspection rather than substituting a successful result.

## Red/green evidence

All commands used Ubuntu proot; no Termux-host Flutter test/analyze or local APK build was run. Common command prefix:

```sh
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi-avatar-target-liveness-codex-20260909 && /home/flutteruser/flutter/bin/flutter ...'
```

- Initial genuine report red: `flutter test --no-pub test/performance/dashboard_profile_report_test.dart --reporter failures-only` — **17 passed, 25 failed**. The existing validator returned normally for the supplied aa61242 empty-only K JSON, mismatched final handles/categories/queries/values, unresolved candidates, a Time reset, an earlier failed flight, and a single fling. Recorded in `profile-red-report.log`.
- Terminal-contract red: `flutter test --no-pub test/performance/dashboard_profile_report_test.dart --plain-name "Avatar K" --reporter failures-only` — **26 passed, 3 failed** for unknown/invariant-failure terminals and missing terminal completion. Recorded in `profile-terminal-red.log`.
- Superseded-first-request red: `flutter test --no-pub test/performance/dashboard_profile_report_test.dart --plain-name "Avatar K permits a superseded first request" --reporter failures-only` — **1 intended failure**, legacy first-target gate rejected legitimate `staleRejected` despite strict final proof. Recorded in `profile-superseded-red.log`.
- Final green: `flutter test --no-pub test/performance/dashboard_profile_report_test.dart test/boundary/dashboard_avatar_profile_boundary_test.dart --reporter failures-only` — **48 passed**, recorded in `profile-green.log`.
- Focused analysis: `flutter analyze --no-pub integration_test/dashboard_interaction_profile_test.dart integration_test/support/dashboard_profile_report.dart test/performance/dashboard_profile_report_test.dart test/boundary/dashboard_avatar_profile_boundary_test.dart` — **No issues found**, recorded in `profile-analyze.log`.
- Format: Ubuntu Dart `format --output=none --set-exit-if-changed` on those four files — **4 files, 0 changed**.
- Scoped `git diff --check` — **clean**.

## Remaining evidence / coordination

| Requirement | Status |
|---|---|
| Every §11.3 required K field implemented | DONE — source inspection and strict validator |
| Empty-only baseline, earlier paint/final pending, stale canonical, mismatched surfaces rejected | DONE — focused negative tests |
| Repeated real-fling harness with disjoint nonempty native fixture | DONE — implementation and analyzer; runtime evidence below remains pending |
| Terminal accounting and per-flight final gate | DONE — focused validator/boundary tests |
| Actual exact-SHA Android K JSON with four completed flights | PARTIAL — root delivery/CI must run and inspect it |
| Physical correctness of new candidate | PENDING — USER ONLY |

Core contract consumed: numeric `pendingCandidate` count 0/1, existing live semantic frame and actual paint notifier; coordinator emits one typed `AV|PREVIEW_TERMINAL` per preview. No extra production getter is required. No commits, pushes, or APKs were created by this task.

AA61242 AVATAR CORRECTNESS — PHYSICALLY REJECTED BASELINE

AA61242 / E8 MOTION — PRESERVED BY PROFILE TASK (production motion untouched)

NEW AVATAR CANDIDATE — PHYSICAL VALIDATION PENDING, USER ONLY
