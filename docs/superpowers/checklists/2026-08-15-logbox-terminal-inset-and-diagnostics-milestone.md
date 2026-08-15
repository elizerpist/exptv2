# LogBox terminal inset and diagnostics milestone — acceptance checklist

## Architecture card

### Visual evidence and protected boundary

- Physical references inspected: `Screenshot_20260815-054909.png` and
  `Screenshot_20260815-054918.png` in
  `/storage/emulated/0/Pictures/Screenshots`.
- Protected Android interaction milestone:
  `155f18b62da6fd894f2992567a6d8dd25042f3a9`.
- Starting baseline: `6b9276337948cb7a6fa5ac47ad6c284fb94d2adf`.

The screenshots are the visual acceptance reference for this narrowly scoped
polish. A separate mockup would not clarify the already concrete viewport
geometry, so implementation is verified by RenderBox geometry tests and the
normal Android APK rather than a new visual prototype.

### Ownership and write path

```text
Scaffold.extendBody + MediaQuery bottom obstruction
                    |
                    v
DashboardLogBoxViewport: real viewport constraint
                    |
                    +--> Render surface: immutable virtual row geometry
                    |
                    +--> terminal sliver: bottom obstruction + shadow gutter
```

- The shell owns the physical body boundary and publishes the bottom
  obstruction through Flutter's `MediaQuery` contract.
- The viewport owns one `CustomScrollView` and adds one terminal sliver only
  after the LogBox content. It never changes cached row/page geometry.
- `CommittedLogViewportCache` retains immutable virtual geometry and bounded
  resources; it remains the only vertical resource owner.
- `ExplicitCommittedPagingController` remains the sole cursor/readiness owner.
- Diagnostic semantics remain owned by the vertical session observer and the
  paging controller; no physics behavior changes.

## Acceptance checklist

| ID | Source | Intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| VT-01 | User viewport root cause | Shell + LogBox viewport | The scroll viewport reaches the physical body bottom; navigation clearance does not reduce its dimension | App-shell RenderBox test + code inspection | DONE |
| VT-02 | User terminal-inset model | LogBox sliver layout | Terminal inset follows content only; it protects last-card shadow without becoming row/page geometry | Pure extent + widget tests | DONE |
| VT-03 | User short-list condition | LogBox sliver layout | Content that fits with its inset gains no meaningless scroll range | Pure extent test | DONE |
| VT-04 | User visual screenshots | LogBox surface/layout | No opaque/darker nested scroll strip; last-card paint space remains inside viewport | Source inspection + Android checklist | PARTIAL |
| VT-05 | User chip spacing | Header/viewport boundary | Facets add only a small tokenized 4–8dp gap; no facets retain current gap | RenderBox test | DONE |
| RD-01 | End-of-data trace | Paging controller | No request/defer/log occurs for an ordinal beyond `lastPossible` after end-of-data | Controller regression | DONE |
| RD-02 | Preview-to-committed trace | Render surface / viewport | Exact virtual scroll extent is authoritative before drag; no hidden post-start replacement | Widget regression | DONE |
| DG-01 | Telemetry trace | Vertical session diagnostics | Per-interaction preparation values cannot imply total zero with a positive per-interaction largest slice | Diagnostics regression | DONE |
| DG-02 | Telemetry trace | Input diagnostics | Pointer duration is down→up; ballistic-inclusive duration is named separately | Diagnostics regression | DONE |
| DG-03 | Telemetry trace | Ballistic diagnostics | Raw release and framework-applied ballistic velocities have distinct names and suppression context | Diagnostics regression | DONE |
| RT-01 | User retention warning | Candidate scene ownership | Candidate retention is only changed if pre-work rejection is locally provable; otherwise left unchanged and documented | Source audit | DONE |
| RT-02 | User empty warmup warning | Summary hotset owner | Known-empty hotsets skip scene construction only if an existing canonical empty state can be reused locally | Source audit / focused test | DONE |
| PR-01 | 155f18b milestone | Existing scroll architecture | Controller, position, physics, virtual geometry, bounded retention, and miss invariants stay intact | Approved milestone suite | DONE |
| QR-01 | Query contract | Existing Query architecture | Prepared hit/Apply/directional independence remain unchanged | Focused Query tests | DONE |
| MD-01 | User milestone request | `MILESTONE_COMMITS.md` | Records “Smooth vertical and horizontal scroll. No placeholder bug.” as human physical-device status, not CI claim | Document review | DONE |
| DL-01 | AGENTS.md delivery | GitHub Actions + Download | Exact normal `lib/main.dart` APK for pushed SHA is downloaded to `/storage/emulated/0/Download/fluvi` and hashed | Action/API + SHA-256 | NOT DONE |
| HV-01 | User matrix | Normal Android APK | Visual/interaction matrix is checked by a human | Human verification | NOT DONE |

## Guardrails

- No physics, controller, `ScrollPosition`, cache-size, page-size, lookahead,
  rail-scene, Query publication, virtual-geometry, avatar, or TextPainter hot
  path change.
- No golden tests, integration harness, timer/debounce repaint loop, or
  generated gesture playback.
- Automated tests prove architecture only. Smoothness remains a human Android
  acceptance claim.

## Automated evidence — 2026-08-15

- RED then GREEN evidence covered terminal extent, full physical viewport
  bounds, facet spacing, pre-drag exact virtual extent, impossible end-of-data
  reverse intent, diagnostics scopes, retention preflight, and canonical empty
  hotsets.
- Focused viewport/surface suite: 20 tests passed.
- `./scripts/test-fluvi-fast.sh`: passed.
- `./scripts/verify-fluvi-boundaries.sh`: passed.
- Full `flutter test --no-pub`: 520 tests passed.
- `flutter analyze --no-pub`: no issues.

## Remaining human delivery and acceptance

- VT-04 remains **PARTIAL**: source inspection confirms a transparent LogBox
  surface and terminal paint space, but the supplied Android visual matrix
  must confirm the absence of a darker scroll strip and final-card shadow clip.
- DL-01 remains **NOT DONE** until the pushed SHA's normal `lib/main.dart` APK
  is downloaded to `/storage/emulated/0/Download/fluvi` and hashed.
- HV-01 remains **NOT DONE** until the human runs the requested Android matrix;
  automated checks do not establish physical smoothness or final visual polish.
