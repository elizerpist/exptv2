# R29 resident SystemUI ORB — incomplete implementation report

## Status and artifacts

This is **not the complete R29 repair**. The shipped APK is a review-only WIP.
The app-side publisher, its durable exclusive ownership/drain and the real
SystemUI lockscreen composition and restrictive-frame latch are not wired.
The WIP SystemUI bootstrap is not a deployable integrated solution. The R27
phone rejection and the existing privacy failures remain open.

| Item | Result |
| --- | --- |
| Producer APK | [Direct anonymous download](https://media.githubusercontent.com/media/elizerpist/exptv2/df182f34cc453c8828375a73398e523860265a5e/fluvi_R29_WIP_REVIEW_5bb91aed3ab1.apk), **review only**; source `5bb91aed3ab1a2e7ce4c6114d069a4d13fd21595` |
| APK identity | 120789303 bytes; SHA-256 `256d31d1fb07691e6696966d688082c44b2cd262075589b0fb7cda7f3770eb3a`; package `com.fluvi.app`, versionCode 1; profile HUMAN_DIAGNOSTIC |
| Download/signature | Fresh anonymous full GET HTTP 200, same length/SHA; ZIP, alignment, v2/v3 signature and signer `faedbe8483532ebb1412bf4d8387c36ff6bbcd4b1da560ba0eabbaea9bad49fb` passed. Three AOT ABI source/purpose markers and WIP DEX markers passed; all 471 non-signature payload entries matched the runner APK. |
| Update install | [Private API35 run 45077510333](https://github.com/elizerpist/pushparserv2/actions/runs/45077510333), job 137377940024, artifact 14776002022: R27 → WIP `adb install -r` passed and a demo-data sentinel survived. This is not a physical-device result. |
| Current source | `implement/r29-resident-systemui` at `9d9444795ea34e64525e990f5c08d1b655a6fdaf`; the two later commits after the APK source change only staging tools/tests, not the app executable. The APK is not relabelled with this newer SHA. |
| Host patch | [WIP bootstrap](https://github.com/elizerpist/exptv2/blob/9d9444795ea34e64525e990f5c08d1b655a6fdaf/platform/aosp16/patches/0001-r29-host-bootstrap-WIP.patch), SHA-256 `d11979969378a3dee98666fd3237b623ee3bf5acd2757db70212f0c7c7766a15`; applies against `frameworks/base` `99b01a65cc4c104933788b3143285ab6bae65827`. It is not the complete scene/DI/eligibility patch. |
| Host build/boot | **NOT RUN.** No full AOSP tree or suitably provisioned builder was found; this VM has approximately 33 GiB RAM, a 63 GiB filesystem and no KVM. A runner-inventory API call returned HTTP 403, so other authorized builders could not be established. No Cuttlefish system image exists for this source pair. |

The verified WIP source includes the bounded data-only descriptor, input
validation and ownership reducers, canonical material mapper, unaffiliated
client and host store/service/renderer source, deterministic renderer extraction,
and hash-pinned generated assets. These components have not been connected to
a real first-frame decision and do not deliver the requested behavior.

## Verification

| Gate | Exact result |
| --- | --- |
| App Kotlin / AndroidTest compilation | PASS for source `5bb91aed…`; initial Android test compilation failed on unavailable `assertThrows`, then passed after the test API correction. A subsequent source/test edit during compilation also failed and was rerun on a stable source. |
| Full app JVM | First run FAIL 35/326 from disk exhaustion extracting Robolectric/Conscrypt libraries; one retry using another temporary directory PASS 326/326. Original XML/logs retained. |
| Flutter | FAIL: 2777 passed, 115 failed, 3 skipped. The same 115 test names failed in the saved R27 run, and no tracked Dart/test/pubspec files changed between R27 and the WIP. This does not establish each failure's cause. The first WIP run was interrupted due to disk pressure; the first alternate-temp start failed because its directory was absent; the corrected run produced these numbers. |
| Flutter boundaries | PASS 12/12 for the dashboard interaction, Human APK delivery and Avatar profile boundary files. |
| Lower-environment offline controls | PASS using the existing fake-adb wrapper; no real device was involved. |
| Android 35 changed-path controls | [Private run 45076752427](https://github.com/elizerpist/pushparserv2/actions/runs/45076752427) **FAIL overall** on app `5bb91aed…`: all 3 new Parcel tests passed; 10 of the 16 inherited ORB controls passed, 6 failed or did not reach the target boundary. This is unmodified API35, not a patched Android 16 host. |
| Renderer/asset staging | Initial coherent shader+metadata tamper was incorrectly accepted (**RED**); pinning all 72 files made all 3 renderer staging tests pass. An injected copy failure initially left an empty file (**RED**); the corrected script passed 2 rollback/untracked-file controls. The ignored-file control also failed in the first rollback run because that earlier injected failure had dirtied its shared fixture; this was cleaned and the corrected controls passed. |
| Source-only host compile/policy | Extracted canonical renderer and host Kotlin compile against Android API 35 after replacing an SDK-hidden platform constant; 2 host policy JVM tests passed. This is not Soong, SystemUiRoboTests, SystemUITests or pixel evidence. |
| Exact-source graph for APK | [Manifest](https://github.com/elizerpist/exptv2/blob/f0834d6abe278298a05d8a8720ca1501316156ba/docs/codegraph/manifest.json), graph commit `f0834d6abe278298a05d8a8720ca1501316156ba`, source `5bb91aed…`, SHA-256 `284a6909d45cbe05813a63d197b26135912457c301e56fa1ff3704ed7a6152c3`; [run 45076570895](https://github.com/elizerpist/exptv2/actions/runs/45076570895) PASS. Kotlin/AOSP navigation is a manual inventory; SCIP coverage is Dart only. |
| Current WIP source graph | [Manifest](https://github.com/elizerpist/exptv2/blob/66baadf21ae6c7dfa39e4422841863acf435897c/docs/codegraph/manifest.json), graph commit `66baadf21ae6c7dfa39e4422841863acf435897c`, source `9d944479…`, SHA-256 `115f3fc67b827d92e550ff5da129640fc384a78aff62117988cfcbb2efbdd266`; [run 45079503592](https://github.com/elizerpist/exptv2/actions/runs/45079503592) PASS. This is the WIP tooling tip, not the APK source. |
| Formal ordinary CI and five native scopes on a completed candidate | **NOT RUN**; no completed candidate exists. |

The six API35 inherited controls did not reach these boundaries:

- `direct-pending` and `direct-stable`: no complete positive real DIRECT snapshot.
- `stale-ingress`: no real first FULL paint.
- `visible-unlock`: locked sleep timed out.
- `opening-service-positive`: sleep/locked timed out.
- `opening-service-negative`: no clean eligible post-marker checkpoint.

The exact private [evidence branch](https://github.com/elizerpist/pushparserv2/tree/0d054c6f28899c4ef63049707f8a0a51c07c3f62)
contains the initial and corrected logs, private golden images and the API35
artifact. Native ZIP SHA-256 `23bf2a27e48714ad229384fd8b138932649f68781a12ebef0f1542421ad0e08d`
was independently fetched via authenticated LFS and checked. The initial LFS
verification checkout returned a pointer until LFS was installed locally; the
corrected fetch verified the full 12893538 bytes. No raw screenshots or logs are
on the public APK branch.

## Frame and physical outcomes

No custom SystemUI was compiled or booted. The unpatched-stock/no-accessibility,
one-frame-late, retained-old-frame and full-screen image controls have not been
executed on an integrated R29 host. No app-stopped wake or withdrawal trial was
possible. All of these remain separate **NOT RUN** gates.

The three required maxima are unmeasured: physical wake → first correct FULL
pixel; first eligible lockscreen frame → that pixel; and first visible
unlock/restriction → confirmed ORB absence. No ≤10 ms claim is made.
**PHYSICAL VALIDATION — PENDING, USER ONLY.** An ordinary stock Android phone
cannot activate this privileged reference-host prototype with the APK alone.
