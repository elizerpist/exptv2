# R29.1 resident SystemUI ORB — partial checkpoint report

This checkpoint is **not the completed R29.1 implementation**. The actual
publisher-to-Binder coordinator, explicit reference enrollment, old-owner
suppression and drain at the display lanes, SystemUI clock-root draw and
restrictive-frame/EMPTY receipt have not been connected. Reference enrollment
must stay disabled. On an unmodified phone this APK continues to use the
existing accessibility/ORB route and does not demonstrate the requested
SystemUI first-frame behavior. The owner already rejected WIP 5bb91aed for
visible lag; a repeat stock-phone test is not evidence for the new host.

## APK and identity

- [Anonymous, direct review-only HUMAN_DIAGNOSTIC APK](https://media.githubusercontent.com/media/elizerpist/exptv2/dc15a70f17a70685fa87c493b95c4149e04be135/fluvi_R29_1_WIP_REVIEW_de807259cd37.apk)
- Application commit `de807259cd370d18e422772ed0943b8d65be4bca`, parent
  `9d9444795ea34e64525e990f5c08d1b655a6fdaf`, branch
  `implement/r29-resident-systemui`; artifact commit
  `dc15a70f17a70685fa87c493b95c4149e04be135`.
- `com.fluvi.app`, versionCode 1, profile HUMAN_DIAGNOSTIC; 120789303 bytes,
  SHA-256 `057406296e14bb10c6dbe6ae94e5f6d7564bed02a89c8787bf23c4b9b6fec773`.
- v2/v3 signer SHA-256
  `faedbe8483532ebb1412bf4d8387c36ff6bbcd4b1da560ba0eabbaea9bad49fb`.
  Independently retrieved anonymously with HTTP 200 and checked the full size,
  hash, package and signature. The three packaged AOT ABIs contain the full
  application SHA and HUMAN_DIAGNOSTIC marker. All 471 non-signature ZIP
  payload entries match the runner output.
- [Builder run 45120769042](https://github.com/elizerpist/exptv2/actions/runs/45120769042)
  passed. [Private API35 update run 45121872782](https://github.com/elizerpist/pushparserv2/actions/runs/45121872782),
  job `137517256257`, artifact `14794351216`, installed this APK with
  `adb install -r` over the actual signed 5bb91aed WIP and preserved a demo
  sentinel. This is emulator update-compatibility evidence, not a phone or
  modified-SystemUI visual result.

## Implemented scope

The selected Budget material projection now reads core revision, category,
limits and total under one Room transaction, while reusing the prior limit
calculation. The native sceneTarget and Dart producer carry conservative
focus/layout/privacy/core provenance; a mismatched snapshot target is rejected.
There is a persistent, fail-closed, currently unconnected reference ownership
store. The host's prepared slot is adopted on Main before READY; invalidate,
reset, clean detach and callback death are separately handled. Static expiry
is scheduled; fence preparation uses a bounded wait with one release-only
quarantine. The separate-module frame policy types are public. No real
SystemUI draw or old-owner exclusivity is claimed.

## Tests and failures

- `git diff --check` and `bash scripts/verify-fluvi-boundaries.sh`: PASS.
- Android `:app:generateKeyguardHeaderMaterial :app:compileDebugKotlin
  :app:compileDebugAndroidTestKotlin` and `:app:testDebugUnitTest --tests
  '*R29*' --tests '*KeyguardR27VirginDirectPolicyTest'`: PASS, 27 tests.
- Full `:app:testDebugUnitTest`: PASS, 329 tests; full
  `:fluvi-core:testDebugUnitTest`: PASS, 150 tests.
- `flutter analyze --no-fatal-infos`: PASS with 22 informational issues;
  focused real Dart producer tests: PASS, 3 tests. Full `flutter test`:
  **FAIL**, 2780 passed, 115 failed, 3 skipped. The 115 failing test names
  match the prior 5bb91aed run exactly; that does not establish each cause.
- Platform staging unit tests: PASS, 5 tests, against the pinned clean AOSP
  checkout and generated assets. The incomplete bootstrap applied on a
  disposable worktree. Host Kotlin compiled against Android SDK and the
  separately compiled policy controls passed 2/2; neither is a Soong build.
  The controlled Worker/Main store harness passed adoption, invalidate,
  reset, callback-death and static-expiry controls, with a fake renderer.
- RED controls preserved: real seeded sceneTarget had `coreRevision=null`
  instead of 2; publisher accepted a mismatched target revision; host Worker
  output became current before Main adoption; a separate Kotlin test module
  could not access the internal policy types. These were followed by the
  targeted PASS results above.
- The first Room fixture compile failed from a missing AndroidX test import;
  its first execution could not write the default Robolectric Maven cache.
  Both were fixed as test infrastructure. The first focused Dart green run
  failed due to an active ticker at fixture cleanup; an explicit finally fixed
  it. A staging invocation used empty same-command shell-variable expansions
  and was rerun with explicit paths. The first anonymous verification shell
  exited 141 on an `aapt | head` SIGPIPE after its hash check; a second full
  anonymous download completed and passed all checks. The artifact README's
  initial diff check detected Markdown trailing spaces; a later documentation
  commit fixed those spaces without changing the immutable APK URL.
- The prior API35 run 45076752427 had 10/16 inherited controls pass, with six
  failures or setup boundaries not reached; the three R29 Parcel tests passed.
  R22.4 visual privacy FAIL and the R27 shade ambiguity remain open.
- [Exact-source API35 run 45120980237](https://github.com/elizerpist/pushparserv2/actions/runs/45120980237): **FAIL**, build job `137514447034` PASS, device job `137518058898` FAIL. All 3 R29 Parcel controls and 10/16 inherited controls passed. Six did not reach their asserted prerequisites: `direct-pending` and `direct-stable` lacked a complete positive real DIRECT snapshot; `stale-ingress` did not reach first FULL paint; `visible-unlock` did not reach DIRECT reveal acknowledgement; `opening-service-positive` saw no real shade ingress; `opening-service-negative` saw no real framework exclusion ingress. App/test APK SHA-256 values were `3e4e06f963193fd689fe1eb94a06564328347b3f7656222c57e086cf20e33b49` and `1e2a971d384c05991d0e87b62604b5a6ad0ecb39caa0835b9ba69c3e6639acbc`. Private artifacts `14794415854` and `14794382110` retain the pair and native evidence. These are unmodified API35 controls, not patched-SystemUI tests.
- Ordinary public CI and formal `r12_live`, `r12_static`, `r12_legacy`,
  `r12_contract` and `full` scopes on a completed R29.1 source: NOT RUN;
  there is no completed integrated source. No public raw screenshots or traces
  were uploaded. Raw local test logs and failed golden images are preserved
  on the [private evidence branch](https://github.com/elizerpist/pushparserv2/tree/23fce4e7df657b6a9a393d219f66d6ef09e236ad).

## Source graph and platform limits

- Exact-source graph commit `d0a6c6b8f7b6a0465d4667236f5b84e004a888e0`,
  [manifest](https://github.com/elizerpist/exptv2/blob/d0a6c6b8f7b6a0465d4667236f5b84e004a888e0/docs/codegraph/manifest.json),
  manifest SHA-256 `02b6a7462459652e0509c01fda87c5949fc6e2d05566f7d92ed6e69b33af97cd`.
- SCIP-Dart 1.6.2, source `de807259cd370d18e422772ed0943b8d65be4bca`,
  index SHA-256 `a779445a5593da9ea4cebe63ca41d655a2899f4983b229ad2d13efb88a6a54c3`,
  809 documents, 20271 symbols, 136479 references and 42258 edges. Kotlin and
  AOSP are covered only by the [source inventory](https://github.com/elizerpist/exptv2/blob/d0a6c6b8f7b6a0465d4667236f5b84e004a888e0/docs/codegraph-r29-1-checkpoint-inventory.md).
- The only available [platform patch](https://github.com/elizerpist/exptv2/blob/de807259cd370d18e422772ed0943b8d65be4bca/platform/aosp16/patches/0001-r29-host-bootstrap-WIP.patch)
  remains **incomplete**. Its SHA-256 is
  `d11979969378a3dee98666fd3237b623ee3bf5acd2757db70212f0c7c7766a15`;
  exact AOSP frameworks/base parent
  `99b01a65cc4c104933788b3143285ab6bae65827`. A staged-source receipt SHA-256
  is `2495fc32409050609860cc755e12ed77c95d096a7e85392a8b79957e69ba753c`.
  Full Soong build, platform image, boot, actual clock-root rendering, app-dead
  wake and app-dead withdrawal are NOT RUN. This host has 33 GiB RAM, a 63 GiB
  filesystem and no `/dev/kvm`; no complete AOSP checkout or proven capable
  remote platform builder was found, and runner inventory returned HTTP 403.
  Missing platform capacity does not explain or excuse the unfinished source.

The requested physical wake→first FULL pixel, first eligible clock frame→FULL
pixel, and first restrictive/unlock frame→absence are each **UNMEASURED**.
No ≤10 ms claim is supported. **PHYSICAL VALIDATION — PENDING, USER ONLY.**
