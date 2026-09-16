# Mind Year populated-payload readiness architecture card

## Physical failure and current evidence

The 2026-09-16 screenshot and frozen `Fluvi mind heatmap` log prove a
cross-surface data-liveness failure, not an empty year and not slow projection.
The screenshot has Income / 2026 / `4,938,000 Ft` and `42 tranzakció
listázva` while every annual MonthCard is neutral.  The frozen Drive export is
the document `1R2plbzazBUuuWoi_unktR_Lu7QNYgM9RPIH5J6ioNIM`, modified
`2026-09-16T13:46:32.002Z`: 323,737 UTF-8 bytes, SHA-256
`58b10f7256864db39055dfd3eeca2669e40f6423de6adc14eed437d47ba663ee`,
session `fluvi-1789566368119437`, sequences 1200--2199, 1,000 unique
contiguous runtime events.

For one populated 2026 crossing, Summary and preview LogBox paint at
`elapsedMicros=42,165,415` / `42,165,432`; the later first 2026 heatmap frame
with `preparedContributions=42` publishes at `43,497,426` and paints at
`43,509,978`.  A later repetition is Summary at `59,576,011` / list extent at
`59,576,036`, heatmap published at `60,884,744`, painted at `60,897,799`.
Both waits are about 1.3 seconds.  The eventual projection itself is only
93--180 microseconds.  Empty targets publish through the transient path in
the immediate frame.  Thus a Year identity or empty-frame test is not enough.

## One authority chain

| Concern | Existing owner | Required relationship |
| --- | --- | --- |
| Semantic/canonical Year | navigation via `DashboardCoreController` | The only canonical Year write path. |
| Accepted visible Year/G | existing segmented Core publication (`_SegmentedTemporalPaintTarget`) | One immutable accepted target that names the Summary/list visible generation. |
| List Phase-A payload | `DashboardCoreController` + existing prepared Time index/frame | May remain the list's own lightweight payload; rich LogBox scenes are not a heatmap dependency. |
| Annual compact membership/projection | Core's bounded `_MindAmountPreparedBaseSlot` and `MindYearHeatmapLiveProjection` | Must be ready from the same accepted Year/G/data revision before a populated Summary/list target becomes visibly publishable, or travel with that accepted resource. |
| MonthCard paint | `MindYearHeatmapViewport` / painter | Renders only the Core-published immutable frame; chooses no Year or data itself. |

No UI component gains a Year/write authority.  The heatmap must not consume a
rich LogBox scene, `TextPainter`, scroll viewport, Room result, or a second
Year cache.  The small annual aggregate remains a bounded immutable consumer
of the already-admitted prepared data.

## Mandatory visible-generation contract

For every Summary target `Y/G` that actually paints and whose list Phase-A
payload is paintable:

```
Summary Y/G + list Y/G
  => heatmap identity Y/G + exact colored day set for Y/G
  => MonthCard paint Y/G
```

The heatmap is allowed at most the immediately following render frame.  An
empty `Y` must produce its correct neutral real-day frame under the same rule.
A coalesced target that never Summary-paints is not owed a heatmap frame.  A
later canonical settle retires obsolete transient authority but may not defer
the active transient path.

## Structuring Apps rules applied

Skill: `/data/data/com.termux/files/home/.codex/skills/structuring-apps/SKILL.md`
(no version metadata).  The repair must retain one state owner/write path,
keep UI render/intent-only, keep multi-step workflow in the controller, reuse
the existing prepared-data mechanism rather than introduce a duplicate, and
add fail-closed boundary tests.  The existing Core/controller is the only
candidate place for a shared accepted Year/data publication invariant.

## No-touch and work bounds

- No Time carousel/controller/ScrollPosition/physics/direct-pointer changes.
- No canonical Query ownership or LogBox rich renderer change.
- No timer, debounce, wait-for-settle, target dropping, remount, key, cache
  flush, repository/Room call, index build, full ledger scan or TextPainter
  work for a Year crossing.
- Avatar floor, direction prepared bases, slider hot path and calendar
  geometry remain protected.

## First proven late owner

`RED MYPL-01` establishes an actual prepared 2026 list package with 42 rows,
three exact annual dates and a mounted MonthCard viewport.  On the unmodified
application parent it reaches `TIME_PHASE_A_CANDIDATE_PENDING`, then
`LIVE_INTERACTION_ACCEPTED`, `SUMMARY_TARGET_PAINTED exactPainted` and
nonzero `LOGBOX|VISIBLE_ROWS_BOUND`; the heatmap remains the previous empty
2027 frame after its one allowed next render frame.

The bounded admission diagnostic and current source identify the first owner:
the selector schedules `onVisualTargetPainted` only when its *initial*
crossing is already an exact live publication.  A populated Year that begins
Phase-A pending is accepted later by
`_promotePendingSegmentedTimePhaseACandidate`, but that promotion does not
re-enter the selector acknowledgement.  Consequently there is no
`SUMMARY_VISUAL_TARGET_ADMISSION` for that already visible list Year, despite
the prepared base and annual membership already being resident.  Empty Years
do not take this late Phase-A path, which explains the observed differential.

The repair keeps the same `_SegmentedTemporalPaintTarget` and adds no data
authority: after `_recordSegmentedTargetPaint` proves the exact accepted
Summary/list frame is actually painted, it calls the shared Core helper
`_admitMindYearHeatmapForSegmentedTarget` only when the normal renderer
acknowledgement has not already admitted that same accepted target. The helper
uses only the existing prepared base/annual membership and its existing
generation guards. It reads
no rich scene or text layout; the LogBox report is solely the already-existing
visible-generation acknowledgement.  The MonthCard frame is therefore
installed for the following render frame, while coalesced/unpainted candidates
continue to have no admission path.
