# Dashboard single-data-runtime final evidence report

Date: 2026-08-06

Baseline: `1bb0f1d51c30f37065da591391acb18d195111f5`

Final implementation and APK source: `0adac49af1eadd3eb09e06bf773549dac111704b`

Branch: `refactor/dashboard-single-data-runtime`

Checkpoint tag: `milestone/dashboard-before-single-data-runtime-20260806`

GitHub Actions evidence: run
[`31093929434`](https://github.com/elizerpist/exptv2/actions/runs/31093929434)

Overall acceptance: **NOT MERGE-READY**. The architecture, correctness,
zero-navigation-I/O, UI-isolate frame and delivery gates pass. The required
physical-device raster gate has not run because `adb devices -l` exposes no
device. The headless x86_64 `swangle` emulator fails the raster thresholds, so
those thresholds are reported as FAIL rather than treated as physical-device
evidence.

## 1. Proven root cause

The previous refactor made child previews RAM-backed but retained
`DashboardCommittedQueryController.commit()` as a data-acquisition owner.
Every settle cancelled an exact-scope EventChannel subscription, subscribed a
new one, observed the Room revision, called `readSlice`, encoded a new payload,
decoded/projected it in Dart and republished presentation. Parent, plane and
direction changes could also build parent-scoped PreparedDecks. The two
sources overlapped the next gesture and unrelated SummaryPill, amount and SVG
tickers. A populated scope consequently imposed more post-settle CPU,
allocation and bridge work than an empty scope.

The milestone A-J logcat proves the repeated path with 62 occurrences each of
`NATIVE_WATCH_SUBSCRIBED`, `ACTIVE_QUERY_SCOPE`, `READ_SERVICE_INVOKED` and
`NATIVE_WATCH_CANCELLED`. The current run contains zero occurrences of all
four legacy events.

## 2. Old and new call graphs

Old canonical path:

```text
gesture / structural navigation
  -> navigation state
  -> parent PreparedDeck lookup/build
  -> MethodChannel + six-query parent batch on a miss
  -> preview visible publication
  -> settle
  -> DashboardCommittedQueryController.commit
  -> cancel old exact-scope EventChannel
  -> subscribe new exact-scope EventChannel
  -> Room revision observation + readSlice
  -> native frame mapping/encoding
  -> bridge payload
  -> Dart worker decode/format/group/project
  -> second visible publication and LogBox/amount binding
```

New bootstrap/data-change path:

```text
seed-ready nonzero core revision
  -> prepare and retain 53 unique dashboard vector pictures
  -> one process/session global core-revision subscription
  -> DashboardDataRuntime latest-wins generation
  -> one five-query Room batch on Dispatchers.IO
  -> native aggregation + bounded preview-row mapping
  -> one deduplicated FLDI v3 binary payload
  -> Dart worker-isolate decode/format/group/project
  -> one immutable PreparedDashboardIndex
  -> atomic index + first valid frame publication
  -> interaction barrier opens

real database revision
  -> same latest-wins background build
  -> pending while any motion lane is active
  -> atomic swap on first stable idle display frame
```

New navigation path:

```text
gesture / SummaryPill / plane / parent / direction / rail intent
  -> synchronous navigation metadata
  -> immutable semantic catalog O(1) lookup
  -> PreparedDashboardIndex.frames[QueryKey] O(1) lookup
  -> immutable visible-frame reference selection
  -> at most one last-target publication per display frame

settle
  -> retained-child and committed metadata update only
  -> no visual snapshot, query, watch, page, bind or animation restart
```

The only exact-scope acquisition left is:

```text
committed LogBox vertical near-end
  -> ExplicitCommittedPagingController
  -> bounded keyset page read
  -> generation/revision/query/navigation guarded append
```

## 3. Final architecture and ownership

- `DashboardDataRuntime` owns one `GlobalCoreRevisionObserver`, one
  `PreparedDashboardIndexBuilder`, current/pending indexes and the idle-frame
  swap.
- `PreparedDashboardIndex` contains both directions and every bounded
  SUM/year/month/day frame needed by interaction. Missing periods resolve to
  deterministic zero frames in RAM.
- `DashboardPresentationController` owns only synchronous selection,
  coalescing and committed metadata. Its module cannot import repository,
  MethodChannel/EventChannel, SQL or index-build APIs.
- `ExplicitCommittedPagingController` is the only detailed acquisition owner
  and accepts only `explicitCommittedVerticalPaging`.
- `PreparedVectorAssetAtlas` is a process-lifetime bootstrap barrier. It
  decodes 53 unique assets once, publishes immutable handle tables atomically
  and leaves zero vector decode or asset lookup in row creation/motion.
- Amount, count and LogBox preview are fields of the same immutable prepared
  frame and therefore share one QueryKey and core revision.

## 4. Deleted legacy pipeline

Deleted production owners and contracts:

- `DashboardObservationSession.kt` and the native exact-scope dashboard query
  EventChannel;
- native `FluviPreparedDeckModels.kt` and its old codec path;
- Dart PreparedDeck model, cache, pipeline, binary codec, repository, empty
  adapter and MethodChannel adapter;
- `DashboardCommittedQueryController` and its live-watch/query ownership;
- old bounded query cache and navigation-triggered prewarm path;
- settle-time visual publication and tests that required live acquisition.

There is no feature flag, legacy fallback or second production source of
truth.

## 5. Modified file inventory

The baseline-to-implementation diff contains 165 tracked paths. The complete
machine-readable list is reproducible with:

```bash
git diff --name-status \
  1bb0f1d51c30f37065da591391acb18d195111f5 \
  0adac49af1eadd3eb09e06bf773549dac111704b
```

The ownership groups are:

- Android bridge/codec: `MainActivity.kt`, `DashboardBinaryCodec.kt`,
  `DashboardQueryArguments.kt` and their tests;
- Room/core: database v3 schema/migration, DAO rows/queries,
  `FluviLedgerReadService.kt`, `FluviPreparedDashboardIndexModels.kt` and
  native query/stress tests;
- runtime: all files under `lib/features/dashboard/runtime/`;
- presentation: `dashboard_bootstrap_controller.dart`,
  `dashboard_core_controller.dart`, `core_dashboard.dart`, SummaryPill,
  LogBox, direction toggle, brand lockup and visible-frame ownership;
- assets: `prepared_vector_asset_atlas.dart`, 50 category vectors, two
  direction vectors, one brand vector and catalog generation tooling;
- validation: runtime/boundary/widget/profile tests, A-J report schema,
  workflow and dashboard architecture documents.

## 6. Rail and physics non-change proof

`git diff` from baseline to implementation is empty for all five files, and
their SHA-256 values are unchanged:

| File | Baseline/final SHA-256 |
|---|---|
| `time_refinement_rail.dart` | `e669d118a2dd6607d295543ddc848f1683d538486b1270b02b8e981b1fbf684a` |
| `centered_carousel_physics.dart` | `1b3539cea8ac2870f7fae2c64e78f657187df0046b01d77e21c295c8c2c8a5ec` |
| `centered_carousel_controller.dart` | `2ce33c8a88a52585049d6cb95304e0487097a3e00bbf52b5e694ecb3d1350bbb` |
| `centered_carousel.dart` | `d454fc2608fbf4532745fe39e0c4b9c6aaefdc511e3f946b6788899f8bf8fcc6` |
| `dashboard_motion_kernel.dart` | `dc4858703d344adad3bf89bbf75e03711a6a3a101052aa1f509666ef6002a376` |

The A-J identity snapshots also report controller, physics and ScrollPosition
recreation counts of zero.

## 7. SQL, native watch and bridge counts

| Counter | Milestone A-J | Final A-J interaction delta |
|---|---:|---:|
| navigation-triggered prepared-deck calls | 4 | 0 |
| navigation-triggered deck platform payloads | 4 / 85,813 bytes | 0 / 0 bytes |
| navigation-triggered committed-frame payload decodes | 13 | 0 |
| minimum measured navigation-triggered SQL (deck builds only) | 24 | 0 |
| `NATIVE_WATCH_SUBSCRIBED` in complete run | 62 | 0 |
| `NATIVE_WATCH_CANCELLED` in complete run | 62 | 0 |
| `READ_SERVICE_INVOKED` in complete run | 62 | 0 |
| navigation index builds | n/a | 0 |
| navigation explicit page reads | 0 | 0 |

The final bootstrap performs exactly five counted SQL reads per app session:
partner metadata, one daily aggregate batch, one ordered bounded preview
cursor, category metadata and core revision. Navigation performs none. The
aggregate EXPLAIN plan uses the chronological index, the preview plan uses
`index_fluvi_ledger_entries_dashboard_preview`, and the passing Robolectric
plan test proves neither plan creates a `TEMP B-TREE` sort.

The global revision observer subscribes exactly once per runtime session; this
is asserted by the runtime and fake-transport integration tests. It is not an
exact-scope observer and navigation never replaces it.

## 8. A-J emulator profile

Environment: Android 15 x86_64, four-core KVM emulator, headless `swangle`,
Vulkan disabled, Flutter profile mode, verbose flow logging disabled. Times are
milliseconds.

| Scenario | Baseline UI p95 | Final UI p95 | Final UI p99/max | Final raster p95 | Final raster p99/max | Target/settle |
|---|---:|---:|---:|---:|---:|---:|
| A Summary SUM/year/month | 14.258 | 10.463 | 10.709 | 491.141 | 501.633 | 13/13 |
| B year/month populated | 18.094 | 11.036 | 14.579 | 414.487 | 440.757 | 3/3 |
| C year/month empty | 3.798 | 3.759 | 5.439 | 321.994 | 343.468 | 3/3 |
| D month/day, 94 rows | 9.716 | 13.394 | 14.791 | 334.430 | 486.264 | 22/22 |
| E month/day empty | 5.495 | 4.720 | 4.966 | 462.861 | 501.624 | 22/22 |
| F parent while rail open | 1.953 | 1.996 | 5.005 | 336.185 | 496.503 | 13/13 |
| G direction while rail open | 8.293 | 11.717 | 11.717 | 344.723 | 344.723 | 13/13 |
| H pulse + parent navigation | 4.617 | 5.606 | 10.920 | 437.645 | 489.610 | 13/13 |
| I first fling | 10.615 | 11.825 | 17.623 | 345.313 | 356.445 | 22/22 |
| J tenth fling | 6.665 | 8.446 | 21.184 | 341.674 | 353.779 | 22/22 |

Across all ten final scenarios:

- worst UI p95: 13.394 ms; worst UI p99/max: 21.184 ms;
- UI target evaluation: PASS (`p95 < 16.7`, `p99 < 24`, no frame > 48);
- raster target evaluation on this emulator: FAIL;
- SQL/platform/index-build/page-read/decode/projection duration during motion:
  all zero;
- repository reads, live lease starts, LogBox projections, formatting and
  vector decodes during motion: all zero;
- maximum visible publishes per display frame: one;
- controller, physics and ScrollPosition recreations: zero;
- GC pause count and measured GC pause time: zero;
- maximum RSS allocation burst: 7,995,392 bytes;
- peak process RSS: 297,406,464 bytes;
- prepared index estimate: 5,035,814 bytes;
- native payload: 193,830 bytes;
- first valid paint range across clean scenario launches: 1.240–1.939 s;
- 53 unique vector pictures prepared once in 264.326 ms and zero during
  interaction.

The emulator raster values are not labeled smoothness evidence. The baseline
on the same runner was already 246–270 ms raster p95; the final runner remains
far beyond a physical display budget. The committed machine-readable physical
gate therefore has `passed: false`.

## 9. Empty/populated, first/warm and rail comparisons

| Pair | Semantic sequence | Target/settle | Motion duration | Result |
|---|---|---:|---:|---|
| year/month populated | `7,8,9,10,11,0,1,2,3` | 3/3 | 4464.683 ms | same motion path |
| year/month empty | `7,8,9,10,11,0,1,2,3` | 3/3 | 4524.336 ms | same motion path |
| month/day 94 rows | `14,15,16,17,18,19,20,21,22` | 22/22 | 4643.658 ms | same motion path |
| month/day empty | `14,15,16,17,18,19,20,21,22` | 22/22 | 4388.609 ms | same motion path |
| first fling | `14,15,16,17,18,19,20,21,22` | 22/22 | 4449.104 ms | six coalesced visible frames |
| tenth fling | `14,15,16,17,18,19,20,21,22` | 22/22 | 4586.165 ms | six coalesced visible frames |

Endpoint delta is zero children for both density pairs and first/warm. First
and tenth visible sequences are both `14,15,16,17,18,22`, so the first fling
does publish intermediate prepared values. Month/day and year/month both have
zero data work and use the unchanged carousel engine.

Summary scenario A has UI p95 10.463 ms and p99/max 10.709 ms. Its structural
navigation legitimately rebuilds the structural regions, but a rail crossing
does not: populated rail scenarios report dashboard-root, header, rail and SVG
pulse subtree rebuild counts of zero. The pulse controller identity/restart
invariants are covered by widget tests.

## 10. 10k/50k/100k native stress fixtures

All fixtures use five SQL calls, retain 90 bounded unique preview rows, produce
33 frames and estimate the native bounded index at 29,772 bytes.

| Entries | SQL | Query | Aggregate | Mapping | Total | Peak observed heap |
|---:|---:|---:|---:|---:|---:|---:|
| 10,000 | 341.849 ms | 353.955 ms | 50.843 ms | 4.709 ms | 360.076 ms | 130,458,592 B |
| 50,000 | 772.752 ms | 774.048 ms | 55.147 ms | 1.914 ms | 776.069 ms | 131,266,360 B |
| 100,000 | 1427.534 ms | 1428.356 ms | 56.955 ms | 1.631 ms | 1430.087 ms | 121,023,640 B |

The period count does not change SQL count or retained preview cardinality.
Runtime grows with ledger rows scanned, while the interactive index's bounded
row component remains constant.

## 11. Tests and build evidence

Local Ubuntu/proot:

```bash
proot-distro login ubuntu -- bash -lc '
  cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi &&
  find test -type f -name "*_test.dart" ! -name "*_golden_test.dart" -print0 |
    xargs -0 /home/flutteruser/flutter/bin/flutter test'

proot-distro login ubuntu -- bash -lc '
  cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi &&
  /home/flutteruser/flutter/bin/flutter analyze'

./scripts/verify-fluvi-boundaries.sh
```

Results: 237/237 Flutter tests PASS, `flutter analyze` reports no issues, and
the boundary verifier passes. No golden test or golden asset was added.

GitHub Actions run `31093929434`:

- Room/native core: 50/50 PASS;
- Android bridge/codec: 5/5 PASS;
- Flutter analyze: no issues;
- Flutter non-golden suite: 237/237 PASS;
- current A-J profile job: PASS;
- milestone comparison profile job: PASS;
- debug APK build/publish: PASS.

## 12. Physical-device validation procedure

Current connection evidence is `adb devices -l` with no attached device, so
this was not executed. On an x86_64 Flutter host with a physical Android device
authorized over ADB:

```bash
export ANDROID_SERIAL='<physical-device-serial>'
flutter build apk --profile \
  --target=integration_test/dashboard_interaction_profile_test.dart \
  --dart-define=FLUVI_VERBOSE_FLOW=false \
  --dart-define=FLUVI_REQUIRE_PHYSICAL_FRAME_TARGETS=true

./scripts/run-dashboard-profile.sh \
  --use-application-binary=build/app/outputs/flutter-apk/app-profile.apk
```

Use the same unlocked device, refresh rate, thermal state and scripted A–J
gestures for baseline/final. Keep the app foregrounded and do not interact
during the run. Archive `build/dashboard_profile_*.json` and
`build/dashboard-profile-diagnostics/`. The command fails if any physical UI
or raster p95 is at least 16.7 ms, p99 at least 24 ms, or maximum exceeds 48
ms. It also fails independently on any navigation data-I/O or vector decode.

## 13. APK delivery

The debug APK was built by the successful workflow from the final
implementation commit and published as release `fluvi-debug-0adac49`.

- Local path: `/storage/emulated/0/Download/fluvi/fluvi_0adac49.apk`
- Size: 148,529,931 bytes
- SHA-256:
  `0e79053847d3fcb5879b93bfd93b34fe41d94b40e1939df5c89141a90b5add14`
- Release asset digest: the same SHA-256
- ZIP/APK integrity: PASS, every compressed entry tested successfully

## 14. Acceptance invariant table

| Invariant | Result | Evidence |
|---|---|---|
| one canonical dashboard data runtime | PASS | architecture boundary/source scan |
| no PreparedDeck/live-watch fallback | PASS | deleted files and forbidden-symbol test |
| global revision observer subscribes once/session | PASS | runtime fake-repository test |
| navigation is synchronous O(1) RAM lookup | PASS | controller API and architecture test |
| navigation-triggered SQL | PASS: 0 | A-J counters |
| navigation-triggered native subscribe/cancel | PASS: 0/0 | A-J logcat/counters |
| navigation-triggered bridge payload | PASS: 0 | A-J repository delta |
| motion-time formatting/grouping/sorting | PASS: 0 | profile counters/boundary test |
| motion-time LogBox projection | PASS: 0 | profile counters |
| motion-time vector decode/asset load | PASS: 0 | atlas/profile counters |
| first fling publishes intermediate prepared values | PASS | I sequence and controller test |
| empty/populated endpoint difference ≤ 1 | PASS: 0 | B/C and D/E targets |
| first/tenth endpoint and sequence parity | PASS | I/J targets/sequences |
| month/day and year/month use identical motion engine | PASS | unchanged hashes/counters |
| visible QueryKey equals expected QueryKey | PASS | assertions/property tests/A-J output |
| visible revision equals installed index revision | PASS | assertions/revision tests |
| amount/count/LogBox share one prepared frame | PASS | immutable model assertions |
| settle before/after visual frame is identical | PASS | settle no-op test/counters |
| settle starts acquisition | PASS: 0 | controller and profile counters |
| only explicit vertical near-end pages | PASS | paging architecture/widget tests |
| stale generation/revision callback rejected | PASS | deterministic delayed tests |
| pending revision swaps only after all motion is idle | PASS | scheduler integration test |
| rail/controller/physics/position identity stable | PASS | hashes, widget/profile identities |
| dashboard root/header/rail rebuild per crossing | PASS: 0 | profile counters |
| frame coalescing has no backlog | PASS | max one publish/frame tests/profile |
| no golden test | PASS | diff/test scan |
| required Flutter/native test suites | PASS | CI run `31093929434` |
| emulator UI p95/p99/max targets | PASS | 13.394 / 21.184 / 21.184 ms worst case |
| emulator raster p95/p99/max targets | **FAIL** | 491.141 / 501.633 / 501.633 ms worst case |
| physical-device UI/raster targets | **FAIL: NOT RUN** | no ADB physical device available |

Because the last two rows are FAIL, this branch is deliberately not described
as merge-ready despite the completed architecture and green correctness CI.
