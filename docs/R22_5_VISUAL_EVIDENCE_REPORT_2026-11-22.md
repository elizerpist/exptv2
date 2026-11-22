# R22.5 private visual evidence collection

Application source remains `ad1eac09442cb8d78a992874d22157fe6bd5a05f`; R22.4 structural repair was accepted at the tested still-attached failure boundary, while its unmarked first-FULL and terminal-hide visual gates remain FAIL. This is evidence collection only; no production change, phone APK or physical acceptance is claimed. Physical result: PENDING, USER ONLY.

## Original unmarked screenshots, independently replayed

The source images are the original six numbered post-request samples for each background, 172×172 ROI `(456,1116)–(628,1288)`. Their H and P columns are **UNKNOWN/UNKNOWN**, because they contained no witness markers; no callback or acquisition timestamp is substituted for a pixel marker. The 84–87px contour and the <72px interior were compared independently with unchanged max-channel/sum thresholds. Times are API35 uptime acquisition start/end, not presentation or phone optical times.

| Background | Sample | Acquisition ms | Interior | Contour | H | P |
| --- | ---: | --- | --- | --- | --- | --- |
| white | 0 | 89619–89874 | FULL | FULL | UNKNOWN | UNKNOWN |
| white | 1 | 89874–90049 | NEUTRAL_A / CLIPPED | UNKNOWN | UNKNOWN | UNKNOWN |
| white | 2 | 90049–90310 | NEUTRAL_A / CLIPPED | NEUTRAL_A | UNKNOWN | UNKNOWN |
| white | 3 | 90310–90465 | NEUTRAL_A / CLIPPED | NEUTRAL_A | UNKNOWN | UNKNOWN |
| white | 4 | 90465–90661 | NEUTRAL_A / CLIPPED | NEUTRAL_A | UNKNOWN | UNKNOWN |
| white | 5 | 90662–90868 | NEUTRAL_A / CLIPPED | NEUTRAL_A | UNKNOWN | UNKNOWN |
| black | 0 | 109993–110237 | FULL | FULL | UNKNOWN | UNKNOWN |
| black | 1 | 110237–110440 | NEUTRAL_A / CLIPPED | UNKNOWN | UNKNOWN | UNKNOWN |
| black | 2 | 110440–110674 | NEUTRAL_A / CLIPPED | NEUTRAL_A | UNKNOWN | UNKNOWN |
| black | 3 | 110674–110894 | NEUTRAL_A / CLIPPED | NEUTRAL_A | UNKNOWN | UNKNOWN |
| black | 4 | 110894–111084 | NEUTRAL_A / CLIPPED | NEUTRAL_A | UNKNOWN | UNKNOWN |
| black | 5 | 111084–111223 | NEUTRAL_A / CLIPPED | NEUTRAL_A | UNKNOWN | UNKNOWN |

The neutral interiors are not uniquely classifiable: both `NEUTRAL_A` and `CLIPPED` match the <72px band; their contours distinguish these references. An independent replay compared FULL, STANDBY, BOOTSTRAP, NEUTRAL_A, NEUTRAL_B, UNDERLAY, OLD_SIZE and CLIPPED references. Its reproducible private analysis-script commit is `e2e3ba25ecc5fb619811012bb3eba88a8b71017c`; the local aggregate JSON SHA-256 is `73db68e4ab3554ea6a7e8026b512d19dbb515e2373cdcf98091e7b47e65b3e1b`. Whole ROI samples 2–5 match NEUTRAL_A.

Samples 1 vs 2 differ by 488 white / 492 black pixels of maximum RGB-channel delta ≥7, all at radius 85.5599–86.4437 px from `(85.5,85.5)`. Full ROI sample 1 is UNCLASSIFIED in both cases; a neutral interior is not a safe contour or layer identity. Samples are distinct captures, not consecutive display frames.

## Marked experiment

Neither marked arm reached a fixture, an emulator screenshot, or a calibration. All six new sample indices for **each** background are **NOT REACHED**, with H and P **UNKNOWN** and no acquisition interval. There is no first marked FULL sample from which to decide before/after hide or parent traversal. No callback or old unmarked image substitutes for a witness. The original unmarked FAIL remains FAIL.

The first private panel run `44968533805`, job `137042942401`, built both variants but failed while installing the system image: `No space left on device`. Its artifact is `14732912202` (8,214 bytes; SHA-256 `125717c33e3b555acbbbe4052ab45a0476a4177d25a6fd76578574d88e283e27`). The single permitted affected retry `44969628088`, job `137046331465`, passed the baseline build, overlay build, and KVM access; the API35 emulator itself then failed to create userdata, reporting 6,725.35 MB available versus 7,372.80 MB required, and timed out before either selector ran. The pre-build 7 GB check did not guarantee sufficient space remained after the builds and SDK setup. The job therefore failed for infrastructure, with no JUnit result and no screenshots, for both white and black. There was no third panel attempt.

The independently downloaded private retry artifact is `14734270325`, 9,013 bytes, SHA-256 `e4b36334abf40f5d6bc35801c7e386e9a1c6cd551f3201bb66047a5ab5fb6d8d`, expiry `2026-12-22T01:26:52Z`; the failed job log is retained in that private run. On the retry, baseline debug APK SHA-256 was `4c0f5985396b74a8c77daacbc215ef5600c1daa26076dc08cc8835be52df5ba9`, marked debug app `ae72fc6d8062b0f6656974c03fe53fe085411dcdc259b3a64bb7ba1afc323a83`, and marked instrumentation APK `99069418aefec3deadacbd8e84ff4ce3ad71e3ad03e96d2cc21c755205eb5c14`. These are debug measurement binaries, not a Human APK. Source `ad1eac09442cb8d78a992874d22157fe6bd5a05f`, run harness `bc9c9e8fad7844d41119961cc32b586586251154`, and overlay digest are distinct identities.

| Check | White | Black |
| --- | --- | --- |
| Original numbered samples 0–5 replayed | PASS | PASS |
| Offline missing/wrong/reversed synthetic witness controls | PASS | PASS |
| API35 device ready, target and fixture started | NOT REACHED | NOT REACHED |
| Real H-before/H-after and P-old/P-neutral calibration | NOT REACHED | NOT REACHED |
| Baseline/marked equivalence outside stamps | NOT REACHED | NOT REACHED |
| Six marked samples, exact child identity and teardown | NOT REACHED | NOT REACHED |

The synthetic controls establish parser behavior only; they do not establish on-device witness calibration or any physical presentation. Real marker absence/undecodability would be UNKNOWN. The original unmarked samples have no H/P state by construction.

## Validation inventory

- `git diff --check`: PASS for the ephemeral overlay; `bash scripts/verify-fluvi-boundaries.sh`: PASS; `flutter pub get`: PASS.
- `(cd android && ./gradlew :app:compileDebugKotlin :app:compileDebugAndroidTestKotlin :app:assembleDebug :app:assembleDebugAndroidTest --no-daemon --max-workers=3)`: final local PASS and private retry PASS. A prior local compile exposed a nullable reparent-transaction wiring error; the corrected overlay was rebuilt, and the failed log is retained.
- Original 12-image replay: PASS for source images and the unchanged whole-ROI comparison; the visual safety outcome is still FAIL. Expanded eight-reference replay: 12/12 processed, with overlapping interior references reported rather than forced to one state. Offline H/P missing, invalid and reversed synthetic controls: PASS for both background colors.
- Private analysis `44968818597`: PASS after the initial analysis job in `44968533805` failed with HTTP 401 due to artifact-token wiring. Source ZIPs and private aggregate verified independently by SHA-256.
- White selector and black selector: NOT RUN; API35 target preflight, live witness calibration, fixture, samples, pool and teardown: NOT REACHED. The infrastructure failures and the exact permitted retry are recorded above. No JUnit result or new visual safety PASS exists.
- Formal CI, Human delivery and phone validation are N/A for this evidence-only milestone. PHYSICAL VALIDATION — PENDING, USER ONLY. No ABBA, reader, cadence, overhead or prior matrix rerun was attempted.

## Controlled evidence and qualification boundaries

- Local source `/dev/shm/fluvi-r225-measure` is a detached worktree with an ephemeral debug-only source/test overlay; no application branch was promoted. Overlay patch SHA-256 `275ffd9de9e4da51e411a3a2980e94c931bd1e63ab0b48e9020190aeae62c4b2`. The retained-window hide observer appends the H movement to the existing exact-child transaction; P is drawn on the panel's parent canvas and only armed after the exact successful neutral bind.
- Offline marker parser wrong/missing/reversed controls PASS for both background colours. The actual emulator calibration is separately stated above. Kotlin debug and androidTest compilation passed locally after a first compile failed on a nullable `buildReparentTransaction` result; that wiring error and both logs are retained locally. Flutter/core boundaries and `git diff --check` passed.
- Private harness commit `d6ee6968e696c3635891e20a5a9ff010b2eb72af` first run 44968533805: unmodified and marked builds passed, but the API35 system-image installation exhausted the disposable runner disk before any selector. The separate analysis job initially received HTTP 401 from the source artifact endpoint; its authenticated, analysis-only wiring retry 44968818597 passed. The panel retry was the one permitted affected retry, with unused SDK images/toolchains removed on its disposable runner; the later userdata allocation nevertheless failed as stated above. No original unmarked selector, ABBA, cadence, reader, or Human delivery was rerun.
- Original 12 R22.4 artifacts were copied into a private Actions artifact `14732397308`, 43,425,362 bytes, SHA-256 `a9e3f85ca5e7a49bb15c764f12af67050ade09c804536fee3733b964ad38d0f9`; each inner original zip's SHA-256 was independently checked, as was the downloaded private artifact digest. The private repository reports `private=true` and only the owner collaborator; expires `2026-12-22T00:53:45Z`.
- The previous claim that public-repository workflow artifacts were exclusively project-restricted was not established: an unauthenticated GitHub-hosted runner got HTTP 401, but the scoped token of a separate private repository could download the public-source artifacts. GitHub documents that signed-in users with read access to a repository may download its artifacts; the source repository is public. The original artifact IDs were not deleted, so their broader authenticated-reader access remains until expiry. The private copies do not by themselves revoke those original URLs. The old Human builder artifact likewise remains in the public repository's Actions storage; no phone download was issued here.
- Existing exact-source graph remains tooling commit `f28fadc75e399868b8541a7d5617977b2a7de877`, manifest SHA-256 `63772aeb51033d51b8c2278137bd2286b7086d46b3e4b8b9324ff24e669f7b71`; native symbols are source navigation, not Kotlin SCIP coverage.
