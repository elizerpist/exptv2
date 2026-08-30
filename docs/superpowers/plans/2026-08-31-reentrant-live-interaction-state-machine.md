# Reentrant live-interaction repair plan

> Source of truth: the acceptance checklist beside this plan. No milestone is
> created by this work. Physical validation remains user-only.

## 1. Establish failing contracts

- Add a Segmented SummaryPill widget regression for
  2025 → 2024 → 2025 without pointer release and with one frame per crossing.
- Add Avatar production-parent coverage proving readiness churn cannot absorb
  the second and repeated gestures.
- Extend the Mind production LogBox paint harness to distinguish exact empty
  payloads from non-empty renderability misses and to keep preview visible
  during delayed/rejected canonical completion.
- Run the narrow tests against the starting behavior and record the expected
  failures.

## 2. Repair Segmented per-gesture state

- Replace the origin/`_latestCandidate` pair with explicit gesture generation,
  origin, current semantic target, last emitted target, latest accepted target,
  and settle target.
- Emit a return-to-origin crossing whenever the current live target differs.
- Promote only the latest accepted live target at release.
- Remove any coupling between post-gesture canonical/background work and
  pointer admission.

## 3. Repair Avatar re-entry without weakening live data

- Remove the whole-rail `IgnorePointer` readiness gate.
- Keep target/resource readiness as an exact crossing-publication invariant.
- Add generation-scoped terminal diagnostics and idempotent release only where
  a red lifecycle test proves missing ownership.
- Preserve current complete focus/LogBox/Budget tick publication and the
  centered-carousel physics/controller identity.

## 4. Repair Mind production renderability and release reconciliation

- Keep the stable amount domain and frame-coalesced exact membership path.
- Reuse prepared row/text resources by immutable row/layout identity to stage
  the exact first live root.
- Keep live preview active through canonical release preparation; matching
  completion promotes with zero visual delta and stale/failing completion does
  not restore the old list or gate the next drag.
- Bound retained resource memory and add operation-count assertions.

## 5. Validate, review, commit, and deliver

- Format and analyze in Ubuntu proot.
- Run all directly affected tests, then the broader dashboard/homev2 suites,
  classifying inherited failures against the starting SHA.
- Review unstaged/staged diffs and checklist statuses; request code review.
- Create evidence-backed commit(s), push the branch, monitor the exact GitHub
  profile HUMAN_DIAGNOSTIC build, download the normal APK to
  `/storage/emulated/0/Download/fluvi`, and calculate SHA-256.
