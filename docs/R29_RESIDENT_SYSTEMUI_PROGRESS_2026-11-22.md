# R29 resident SystemUI: partial source checkpoint

The owner rejected R27's appearance and withdrawal on application source
`ebe3568f8cca34c0d3ac0942b989f8a117daaf90`; no new calibrated handset timings
were supplied. This checkpoint does not implement the complete R29 handoff.

Added a bounded typed descriptor, signer/UID policy, sequence/coalescing and
fail-closed frame-policy units; a separate ownership state machine; a mapper that
does not send category identifiers; a producer snapshot builder which requires
matching source/data/focus/layout/privacy evidence; an explicit authenticated
host-client prototype; source-only host store, GPU-prepared renderer and Binder
service; deterministic extraction and validation of canonical shader assets;
and a **WIP** AOSP manifest/Soong bootstrap patch. The default app and actual
lockscreen drawing paths are not wired to these prototypes.

The verified baseline is AOSP `frameworks/base`
`99b01a65cc4c104933788b3143285ab6bae65827`. The WIP patch applies cleanly to
that exact sparse checkout. All 18 effects and both variants were checked
against the original generator's asset metadata; the extracted renderer and
host source compiled against the Android 35 SDK. This is not a Soong or
SystemUI build, and not a visual or cross-process proof.

Local evidence before this checkpoint: project boundary script PASS; targeted
Kotlin tests and `compileDebugAndroidTestKotlin` PASS after a JUnit API repair;
full `:app:testDebugUnitTest` 326/326 PASS after one infrastructure retry. The
first full attempt was 291/326 PASS, 35 FAIL because native test libraries
could not be extracted into the full `/dev/shm` filesystem. That failure and
the compiler/test-wiring failures are retained separately. Staging tests: two
PASS including corrupted-shader rejection. No Android device/emulator or KVM is
available on this host.

Missing: authoritative projection revisions and invalidation wired to the
publisher; actual durable suppression/drain of old owners and final DIRECT
boundary checks; revoke/empty acknowledgement; root Compose and restrictive
transition integration; host Robolectric/instrumentation and composed-image
controls; full AOSP build/boot; exact-source graph; fresh signed producer APK;
CI; and physical validation. No same-frame, app-dead, privacy, unlock or
10 ms claim can be made from these tests. Stock R27 behavior and its open shade
privacy risk remain. PHYSICAL VALIDATION — PENDING, USER ONLY.
