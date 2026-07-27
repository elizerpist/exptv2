# Balance V3 Bugfix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement and prove every `BUGFIX-20260726V3-001` through `012` against the frozen production Balance contract.

**Architecture:** A typed, provenance-carrying HTML contract is the only literal-value source for Balance visual code. A real `SpendeeBalanceDashboard` host at `412×892` supplies production geometry/material/semantics evidence. LogBox, FastInfo, detail cards, rail scheduling and the release gate are changed only through RED→GREEN test cycles and the final evidence ledger is completed only after all required proof passes.

**Tech Stack:** Flutter widget tests, `flutter_test`, existing `BalanceDebugTrace`, `TransactionStore`, shell gate, GitHub Actions.

## Global Constraints

- Canonical acceptance contract: `docs/superpowers/checklists/bugfix20260726v3.md`; this plan adds no requirements.
- Verify `sha256sum balance_latest_layout.html` is `ff7a00a7aeae8f636b08611443bd3975aec1303828ae5c80bce253ae1d29a2ed` before the first test and final evidence pass.
- Do not use screenshots, goldens, Playwright or Puppeteer for V3 verification.
- Every production-host host uses the real `SpendeeBalanceDashboard` beneath normal Balance theme/state at `Size(412, 892)`; never a copied card or generic `Scaffold` host.
- Test in Ubuntu proot only; each task below provides its exact `flutter test` command.
- Keep every V3 checklist row `NOT DONE` until all its listed literal clauses and the exact evidence command have passed.
- Do not commit, push, run a remote build, download an APK, or mark any row `DONE` before every V3 row is verified.
- Preserve all unrelated dirty worktree files.

## File Structure

| File | Responsibility |
| --- | --- |
| `lib/features/transactions/widgets/experimental/balance/spendee_balance_b3ma3_manifest.dart` | Typed frozen source metrics, SHA, selectors and line provenance. |
| `lib/features/transactions/widgets/experimental/balance/spendee_balance_visual_spec.dart` | Production visual values derived from the manifest. |
| `lib/features/transactions/widgets/experimental/balance/spendee_balance_post_content.dart` | Action/search/rail geometry. |
| `lib/features/transactions/widgets/experimental/balance/spendee_balance_dashboard.dart` | Direct-page surface composition and deferred scope publication. |
| `lib/features/transactions/widgets/experimental/balance/spendee_balance_ticking_carousel.dart` | Rail drag lifecycle propagation. |
| `lib/features/transactions/widgets/experimental/balance/spendee_balance_transaction_log.dart` | L1–L8 day/row material, right edit affordance, central avatar and swipe state. |
| `lib/features/transactions/widgets/experimental/balance/spendee_balance_cards.dart` | F1–F6 and D1–D5 individual layouts. |
| `lib/features/transactions/widgets/experimental/balance/spendee_balance_card_painters.dart` | FastInfo and detail paint geometry. |
| `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart` | Production callback boundary: scope commits and drag-safe background work. |
| `test/spendeetest/helpers/balance_production_host.dart` | Shared real-Balance host and inspection helpers. |
| `test/spendeetest/spendee_balance_html_contract_test.dart` | New frozen source parser contract. |
| `test/spendeetest/spendee_balance_production_contract_test.dart` | New production surface contract. |
| `test/spendeetest/spendee_balance_rail_performance_contract_test.dart` | New 14k trace contract. |
| `test/spendeetest/spendee_balance_transaction_log_test.dart` | L1–L8 regression contracts. |
| `test/spendeetest/spendee_balance_cards_test.dart` | F1–F6/D1–D5 regression contracts. |
| `test/spendeetest/spendee_balance_post_content_test.dart` | Action/search/rail regression contracts. |
| `tool/check_balance_v3_gate.sh`, `test/tool/check_balance_v3_gate_test.sh`, `.github/workflows/android-build.yml` | Failing release gate and CI enforcement. |
| `docs/superpowers/checklists/bugfix20260726v3.md` | Final evidence ledger and only then `DONE` statuses. |

---

### Task 1: Frozen HTML contract, manifest provenance and V3 proof mapping

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_balance_b3ma3_manifest.dart`
- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_balance_visual_spec.dart`
- Create: `test/spendeetest/spendee_balance_html_contract_test.dart`
- Create: `test/spendeetest/spendee_balance_v3_mapping_test.dart`

**Interfaces:**
- Produces `BalanceHtmlMetric(selector, lineRange, declarations, finalValue)` and `SpendeeBalanceB3mA3Manifest.v3Metrics`.
- Produces `SpendeeBalanceB3mA3Manifest.sourceSha256`, `fastInfoHeight == 128`, `detailCardHeight == 248`, and `detailStageHeight == 258`.
- The mapping test exposes a `Map<String, List<String>> v3ProofTests` whose keys are all twelve V3 IDs.

- [ ] **Step 1: Write the failing source-contract tests.**

```dart
test('frozen source SHA and final cascade declarations are authoritative', () {
  final source = File('balance_latest_layout.html').readAsStringSync();
  final parsed = BalanceHtmlContractParser.parse(source);
  expect(parsed.sha256, SpendeeBalanceB3mA3Manifest.sourceSha256);
  expect(parsed.finalValue('.stage2-redesign-insight-grid', 'height'), '128px');
  expect(parsed.valuesFor('.stage2-redesign-top-categories-detail', 'height'),
      containsAll(<String>['208px', '248px']));
  expect(parsed.finalValue('.stage2-redesign-top-categories-detail', 'height'), '248px');
});

test('a changed final declaration is rejected', () {
  final changed = _frozenHtml.replaceFirst('height: 248px;', 'height: 247px;');
  expect(() => BalanceHtmlContractParser.parseAndVerify(changed), throwsA(isA<BalanceHtmlContractError>()));
});

test('every V3 row has a production or trace proof mapping', () {
  expect(v3ProofTests.keys.toSet(), equals(_allV3Ids));
  expect(v3ProofTests.values.every((tests) => tests.isNotEmpty), isTrue);
});
```

- [ ] **Step 2: Run RED and confirm the current `72/208/218` manifest and absent parser fail.**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_balance_html_contract_test.dart test/spendeetest/spendee_balance_v3_mapping_test.dart'`

Expected: FAIL because `BalanceHtmlContractParser`/`v3ProofTests` do not exist and current manifest reports `72`, `208`, `218`.

- [ ] **Step 3: Add the minimal typed source contract and replace legacy manifest metrics.**

```dart
@immutable
class BalanceHtmlMetric {
  const BalanceHtmlMetric({
    required this.name,
    required this.selector,
    required this.lineRange,
    required this.declarations,
    required this.finalValue,
  });
  final String name;
  final String selector;
  final ({int start, int end}) lineRange;
  final Map<String, List<String>> declarations;
  final String finalValue;
}

static const sourceSha256 =
  'ff7a00a7aeae8f636b08611443bd3975aec1303828ae5c80bce253ae1d29a2ed';
static const fastInfoHeight = 128.0;
static const detailCardHeight = 248.0;
static const detailStageHeight = 258.0;
```

Keep parser I/O in the test; production code consumes the typed immutable metric list only. Record all FastInfo (`1936–2239`), detail (`3853–4436`) and LogBox (`4854–5003`) selectors with their final declarations.

- [ ] **Step 4: Run GREEN and inspect the parser reports generic `208px` plus final `248px`.**

Run: the Step 2 command.

Expected: PASS; mutation fixture throws `BalanceHtmlContractError`; the mapping has exactly `001…012`.

- [ ] **Step 5: Do not commit.**

Reason: the V3 release gate remains unresolved.

### Task 2: Real production Balance host and baseline surface/action/search contracts

**Files:**
- Create: `test/spendeetest/helpers/balance_production_host.dart`
- Create: `test/spendeetest/spendee_balance_production_contract_test.dart`
- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_balance_visual_spec.dart`
- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_balance_post_content.dart`
- Modify: `test/spendeetest/spendee_balance_post_content_test.dart`

**Interfaces:**
- Produces `pumpBalanceProductionHost(tester, {expanded, input, store})` which mounts the real Balance composition at `const Size(412, 892)`.
- Produces `decorationOf(tester, finder)` and `coloredAncestorsOf(tester, finder)` for real production nodes.
- Keys: inactive action material, SearchPill outer material/focus stroke, input, glyph, rail and page surface are stable `ValueKey`s.

- [ ] **Step 1: Write failing production-host tests for V3-001, V3-002 and the base of V3-007.**

```dart
testWidgets('V3-001 inactive action is opaque FEFEFF directly over page', (tester) async {
  await pumpBalanceProductionHost(tester);
  final action = find.byKey(const ValueKey('spendee-balance-income-action'));
  expect(decorationOf(tester, action).color, const Color(0xFFFEFEFF));
  expect(coloredAncestorsOf(tester, action), isNot(contains(const Color(0xFFFFFFFF))));
});

testWidgets('V3-002 focused SearchPill has one outer blue border and no input border', (tester) async {
  await pumpBalanceProductionHost(tester);
  await tester.tap(find.byKey(const ValueKey('spendee-balance-search-editable')));
  await tester.pump();
  expect(blueBorderCount(tester), 1);
  expect(effectiveInputDecoration(tester).border, InputBorder.none);
  expect(effectiveInputDecoration(tester).focusedBorder, InputBorder.none);
  expect(centerDelta(tester, searchGlyph, searchEditable), lessThanOrEqualTo(.5));
});
```

- [ ] **Step 2: Run RED.**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_balance_production_contract_test.dart'`

Expected: FAIL because the helper is absent and existing inactive material is `Color(0xF0FFFFFF)`.

- [ ] **Step 3: Implement only the required host helpers and source values.**

```dart
const inactiveActionSurfaceColor = Color(0xFFFEFEFF);

const InputDecoration(
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  errorBorder: InputBorder.none,
  focusedErrorBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
)
```

Apply `inactiveActionSurfaceColor` to the inactive action material; ensure no opaque ancestor is introduced behind its rounded corners. Keep the only focus `BorderSide(Color(0xFF2F80ED))` on the keyed outer pill, and use test host `MediaQuery(size: Size(412, 892))` plus normal Balance state/theme wiring.

- [ ] **Step 4: Run GREEN.**

Run: the Step 2 command.

Expected: PASS with direct rendered decoration and effective input checks.

### Task 3: LogBox L1–L8 as one indivisible production change

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_balance_transaction_log.dart`
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Modify: `test/spendeetest/spendee_balance_transaction_log_test.dart`
- Modify: `test/spendeetest/helpers/balance_production_host.dart`

**Interfaces:**
- `SpendeeBalanceTransactionLog.mountedRowBound(422) == 21` and `visibleRowBound(422) == 8`.
- Persisted record key: `spendee-balance-transaction-edit-record-<id>`; non-persisted ghost has no edit control.
- `BalanceDebugTrace` records `scroll_start`, `first_mounted_row_change`, `near_end`, `window_request`, `load_more_publish`, `first_frame_after_publish`, `scroll_end`.

- [ ] **Step 1: Replace legacy absence tests with failing L1–L8 production tests.**

```dart
testWidgets('V3-003 has one 24px right edit and no merchant/avatar pencil', (tester) async {
  await pumpBalanceProductionHost(tester, logGroups: multipleDayGroups);
  final edit = find.byKey(const ValueKey('spendee-balance-transaction-edit-record-1'));
  expect(edit, findsOneWidget);
  expect(tester.getSize(edit), const Size.square(24));
  expect(find.descendant(of: merchantOrAvatar(1), matching: pencilSvg), findsNothing);
});

testWidgets('V3-011 translates the complete row surface and resets safely', (tester) async {
  await pumpBalanceProductionHost(tester, logGroups: multipleDayGroups);
  await tester.drag(row(1), const Offset(100, 0));
  expect(transformOf(row(1)).getTranslation().x, 44);
  expect(isAncestorOf(transform(1), surface(1)), isTrue);
  expect(isAncestorOf(transform(1), edit), isTrue);
  expect(stationaryOpaqueAncestorsOf(surface(1)), isEmpty);
});
```

Also add failing exact assertions for L1 viewport/list flags and bounds, L2 day shell border/fill/shadow/inner light, L3 grid/padding/surface, L4 typography, L5 resolver-driven avatar update, L6 threshold/cancel/delete state, L7 empty state and L8 trace order.

- [ ] **Step 2: Run RED.**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_balance_transaction_log_test.dart'`

Expected: FAIL because current tests require no right edit, the production row has a merchant pencil, and the row uses a three-column content `Row`.

- [ ] **Step 3: Implement L1–L8 without a partial row tree.**

```dart
const _rowGrid = <double>[34, 10 /* gap */, 24];
// Layout order: avatar(34), flexible copy, amount(auto), edit(24), gap 10.

Transform.translate(
  offset: Offset(_visualOffset.value, 0),
  child: DecoratedBox(key: surfaceKey, decoration: rowSurface, child: rowContents),
)
```

Pass `onEditTransaction` through the day sliver and render exactly one persisted-record edit button with `24×24`, radius `8`, `#1A7D8798`, `pencil.svg 13×13 #7D8798`, traditional 2px/1px-offset outline and `.92` active scale. Remove the merchant pencil SVG; retain rename through long press, keyboard and semantics. Make the day material and row material satisfy L2/L3 without duplicate opaque stationary surfaces. Use `CategoryColorResolver.color(...)` and `CategorySlotIcon(... listenForSlotChanges: true, debugSource: 'balance-log-avatar')` as the sole avatar mapping. Add trace marks at the named lifecycle boundaries and generation-check every post-frame load-more callback.

- [ ] **Step 4: Run GREEN, then the production host subset.**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_balance_transaction_log_test.dart test/spendeetest/spendee_balance_production_contract_test.dart'`

Expected: PASS; all L1–L8 literal assertions use rendered production nodes.

### Task 4: Upper FastInfo F1–F6 and central hue contract

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_balance_cards.dart`
- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_balance_card_painters.dart`
- Modify: `test/spendeetest/spendee_balance_cards_test.dart`
- Modify: `test/spendeetest/spendee_balance_production_contract_test.dart`

**Interfaces:**
- `SpendeeBalanceFastInfoVisualStyle.resolve(kind, model)` returns one hue source for glyph, edge and glow.
- `SpendeeBalanceFastInfoBelt.cardWidthFor(378) == 120` and visible height is `128`.
- Each F2–F6 has its own production widget structure; shared shell only owns F1 properties.

- [ ] **Step 1: Write failing F1–F6 production tests for five variants and both ghost states.**

```dart
for (final kind in SpendeeBalanceFastInfoKind.values) {
  testWidgets('V3-008/012 $kind resolves its icon, edge and glow from one hue', (tester) async {
    await pumpBalanceProductionHost(tester, fastInfoKind: kind, ghostEnabled: true);
    final style = fastInfoStyleOf(tester, kind);
    expect(style.border.color, style.iconHue.withValues(alpha: 0x30 / 0xFF));
    expect(style.glow.color, style.iconHue.withValues(alpha: 0x1F / 0xFF));
    expect(tester.getSize(fastInfoSurface(kind)), const Size(120, 128));
  });
}
```

Assert F2 moon/vector/view label absolute location; F3 centred amount/direction; F4 live category asset; F5 20px trend row; F6 `#8B5CF6` recurring glyph and preserved data category. Assert gap `9`, direct page background in gaps, all F1 shell typographic/padding/shadow values, and ghost on/off material/position.

- [ ] **Step 2: Run RED.**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_balance_cards_test.dart'`

Expected: FAIL because present cards are `72px` high, use `20px` headers, shared body approximation and an upcoming recurring glyph of `#5F55EC`.

- [ ] **Step 3: Implement a strict shared shell plus distinct F2–F6 bodies.**

```dart
class SpendeeBalanceFastInfoVisualStyle {
  const SpendeeBalanceFastInfoVisualStyle({
    required this.iconHue,
    required this.iconBackground,
    required this.inset,
    this.gradient,
  });
  final Color iconHue;
  final Color iconBackground;
  final Color inset;
  final Gradient? gradient;
  Color get edge => iconHue.withValues(alpha: 0x30 / 0xFF);
  Color get glow => iconHue.withValues(alpha: 0x1F / 0xFF);
}

static const fastInfoHeight = 128.0;
static const fastInfoCardWidth = 120.0;
static const fastInfoPadding = EdgeInsets.fromLTRB(13, 14, 13, 30);
```

Use 27px icon/header geometry, 16px shared body value, 7.8px metadata and the F2–F6 literal hues/backgrounds/gradients. Do not route variant-specific structures through one generic `Column` which changes their F2–F6 contracts.

- [ ] **Step 4: Run GREEN in production and card test hosts.**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_balance_cards_test.dart test/spendeetest/spendee_balance_production_contract_test.dart'`

Expected: PASS for five kinds × ghost on/off with hue coupling.

### Task 5: Detail carousel D1–D5 at final `248/258` geometry

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_balance_cards.dart`
- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_balance_card_painters.dart`
- Modify: `test/spendeetest/spendee_balance_cards_test.dart`
- Modify: `test/spendeetest/spendee_balance_production_contract_test.dart`

**Interfaces:**
- `SpendeeBalanceDetailCarousel` page viewport is `248`, stage is `258`, dots are gap `4`/height `6`.
- Detail keyed surfaces expose card kind and dimension state for D2–D5 geometry assertions.

- [ ] **Step 1: Write failing production contract tests for D1–D5.**

```dart
testWidgets('V3-009 detail stage retains 248px pages without a compact clipping parent', (tester) async {
  await pumpBalanceProductionHost(tester, expanded: true);
  expect(tester.getSize(detailStage), const Size(378, 258));
  expect(tester.getSize(detailViewport), const Size(378, 248));
  expect(opaqueClippingAncestorBetween(detailViewport, detailCard), isFalse);
});
```

For each D2–D5 selector state assert shell fill/border/shadows/padding/title/ghost, exact rows, rails/chips, main tiles/copy/amount, ranked lists, D5 chart/fact geometry and page-content containment. Assert D3/D4 pink selected chips and D4 only `Havi`, `Éves`, `Összes`.

- [ ] **Step 2: Run RED.**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_balance_cards_test.dart test/spendeetest/spendee_balance_production_contract_test.dart'`

Expected: FAIL on legacy `208px` page and `218px` stage assertions.

- [ ] **Step 3: Replace compact metrics and implement D2–D5 literal grids.**

```dart
static const detailCardHeight = 248.0;
static const detailStageHeight = detailCardHeight + 4 + 6;
static const detailPadding = EdgeInsets.fromLTRB(16, 12, 16, 10);
```

Build D2/D3/D4 with `21,52,1,remaining` rows and D5 with `21,52,1,72,remaining`; use 46px tiles, D5 64px chart, all final rail geometry, and no `208px` parent or `ClipRect` that clips a `248px` child.

- [ ] **Step 4: Run GREEN.**

Run: the Step 2 command.

Expected: PASS in every required dimension state and real production expansion state.

### Task 6: Rail coalescing, direct page surfaces, search/rail geometry and 14k trace

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_balance_dashboard.dart`
- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_balance_post_content.dart`
- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_balance_ticking_carousel.dart`
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Create: `test/spendeetest/spendee_balance_rail_performance_contract_test.dart`
- Modify: `test/spendeetest/spendee_balance_post_content_test.dart`
- Modify: `test/spendeetest/spendee_balance_production_contract_test.dart`
- Modify: `test/spendeetest/spendee_balance_performance_test.dart`

**Interfaces:**
- `BalanceRailPublicationCoordinator.preview(key)`, `.settle(option)` and `.isDragging` separate visual state from publication.
- `BalanceDebugTrace` rail records final scope, `superseded`, duplicate final count, discarded frame resolve count and concurrent recurring/Stats count.

- [ ] **Step 1: Write failing V3-004/006/007 production and trace tests.**

```dart
testWidgets('V3-004 14k rail publishes only the settled unique scope', (tester) async {
  final trace = await driveRailTrace(tester, recordCount: 14000, scopes: [a, b, c, c]);
  expect(trace.completedRailLoadsFor(c.key), 1);
  expect(trace.duplicateFinalScopeLoads, 0);
  expect(trace.discardedScopeFrameResolves, 0);
  expect(trace.concurrentRecurringOrInactiveStatsDuringDrag, 0);
});

testWidgets('V3-006/007 rail and cards paint directly over page surface', (tester) async {
  await pumpBalanceProductionHost(tester, expanded: true, railAtMaximumScale: true);
  expect(ancestorColorsOf(timeRail), isNot(contains(isNot(const Color(0xFFF1F5F9)))));
  expect(railPaintBounds(tester).contains(tester.getRect(maxPill)), isTrue);
  expect(nearestVisibleColorBehindAllCardGaps(tester), const Color(0xFFF1F5F9));
});
```

- [ ] **Step 2: Run RED.**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_balance_rail_performance_contract_test.dart test/spendeetest/spendee_balance_post_content_test.dart test/spendeetest/spendee_balance_production_contract_test.dart'`

Expected: FAIL because `_selectScope` publishes each settle without an equal-key guard, there is no 14k trace accounting, and the rail uses a clipping viewport.

- [ ] **Step 3: Implement drag preview/settle publication and page-surface composition.**

```dart
void preview(BalanceTimeScopeOption option) => _preview = option;
void settle(BalanceTimeScopeOption option) {
  if (_lastPublishedKey == option.key) return;
  _lastPublishedKey = option.key;
  onPublish(option);
}
```

Wire ticker drag start/update/end through the coordinator; only `settle` calls the store callback. Trace discarded candidates as `superseded`; guard stale post-frame callbacks with generation and settled scope key. Suppress recurring ghost projection and inactive Stats prewarm while the coordinator is dragging. Remove opaque/dark rail/card host surfaces, restrict clipping to local card contents, and make max pill/glow bounds fit the rail paint region.

- [ ] **Step 4: Run GREEN and save the 14k trace textual result.**

Run: the Step 2 command.

Expected: PASS; trace includes one final `rail-load`, superseded count, zero duplicate/final discarded resolves, zero concurrent recurring/Stats work and event timing fields.

### Task 7: Enforced release gate, final verification and evidence ledger

**Files:**
- Create: `tool/check_balance_v3_gate.sh`
- Create: `test/tool/check_balance_v3_gate_test.sh`
- Modify: `.github/workflows/android-build.yml`
- Modify: `docs/superpowers/checklists/bugfix20260726v3.md`

**Interfaces:**
- `tool/check_balance_v3_gate.sh --check` exits non-zero whenever a V3 row is `NOT DONE`, `PARTIAL` or `BLOCKED`; accepts only all twelve `DONE` plus evidence fields.
- CI calls the gate before every build/artifact step.

- [ ] **Step 1: Write a failing shell test with unresolved and resolved checklist fixtures.**

```sh
set -eu
if tool/check_balance_v3_gate.sh --check test/tool/fixtures/v3-unresolved.md; then
  echo 'expected unresolved V3 gate to fail' >&2
  exit 1
fi
tool/check_balance_v3_gate.sh --check test/tool/fixtures/v3-resolved-with-evidence.md
```

- [ ] **Step 2: Run RED.**

Run: `sh test/tool/check_balance_v3_gate_test.sh`

Expected: FAIL because `tool/check_balance_v3_gate.sh` does not exist.

- [ ] **Step 3: Implement the rejecting gate and CI invocation.**

```sh
if rg -q 'BUGFIX-20260726V3-[0-9]{3}.*\b(NOT DONE|PARTIAL|BLOCKED)\b' "$checklist"; then
  echo 'Balance V3 release gate: unresolved checklist rows' >&2
  exit 1
fi
```

Require each row's evidence ledger command/result before accepting `DONE`; invoke the script as a required CI step before any Flutter build/upload/download command. Do not invoke it in success mode until all tests and ledger entries are complete.

- [ ] **Step 4: Run all V3 verification commands in proot, then update evidence.**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_balance_html_contract_test.dart test/spendeetest/spendee_balance_v3_mapping_test.dart test/spendeetest/spendee_balance_production_contract_test.dart test/spendeetest/spendee_balance_transaction_log_test.dart test/spendeetest/spendee_balance_cards_test.dart test/spendeetest/spendee_balance_rail_performance_contract_test.dart test/spendeetest/spendee_balance_post_content_test.dart'`

Run: `sh test/tool/check_balance_v3_gate_test.sh`

Run: `sha256sum balance_latest_layout.html`

Expected: all commands PASS; SHA remains frozen; saved 14k trace fields meet V3-004.

- [ ] **Step 5: Re-read the canonical checklist and enter truthful evidence before changing any status.**

For each V3 row append: exact command, passing result, named production test/trace and verified SHA. Only after all twelve evidence entries exist and every exact clause has passing proof, change all twelve statuses to `DONE` and run `tool/check_balance_v3_gate.sh --check` successfully. Do not commit, push, build or download an APK in this task; those remain outside the implementation plan until the user explicitly authorizes release actions.

## Coverage Review

| V3 IDs | Implementing task | Primary proof |
| --- | --- | --- |
| 001, 002 | 2 | production action/search material, effective input and geometry |
| 003, 011 | 3 | L1–L8 production LogBox geometry/material/semantics/trace |
| 004, 006, 007 | 6 | production rail/card ancestry and 14k trace |
| 005 | 1, 7 | full V3 mapping test and rejecting gate |
| 008, 012 | 4 | F1–F6 production contracts and central hue coupling |
| 009 | 5 | D1–D5 production contracts at 248/258 |
| 010 | 1 | SHA/final cascade parser and mutation fixture |

## Plan Self-Review

- All twelve canonical V3 IDs map to a task and a non-screenshot verification method.
- The sequence is parser → real production host → LogBox → FastInfo → detail cards → rail/surfaces → gate/evidence, as required.
- Every implementation task begins with a failing test and an exact proot command.
- No step authorizes a commit, push, build or APK download before all V3 proof exists.
