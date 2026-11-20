# R15 holder and installed-identity test source graph

Indexed source `6d03df62af5c0b02fe86efcf2085c5c7916d1149`, parent
`03677d622f0dd9873b6e1c2d323c3e1f2a7a1b5e`. Source checkout
`/workspace/r15-visual-harness`; tooling checkout
`/workspace/r15-holder-graph-tooling`. This is a separately identified
debug-test successor of application experiment `96cf20d4`, not a qualified
Human release or a relabeling of its CI runs.

SCIP-Dart 1.6.2 index SHA-256
`4de71f94d5a6e0463cd27d2ea4622a4434dce4991a93d066754a1a607b79bf59`;
manifest SHA-256
`531045e5450f3c67743e8dcf86679b538b1806652eb2ba5730002f98524ca111`.
The manifest records 808 documents, 20,269 repository symbols, 136,449
references and 42,246 edges. All 102 shard hashes and record counts were
verified. Tooling analysis and 16 tests passed. SCIP covers Dart only;
Kotlin is a source-checked inventory, not a SCIP result.

The application acquisition, eligibility, current classification, hide and
bounded export chain is documented in
`docs/codegraph-r15-export-correction-2026-11-20.md`. This successor adds an
instrumentation barrier after a real `SurfaceHolder.lockHardwareCanvas` in
`android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt`.
The debug source-set hook can hold the worker; profile/release source-set
constants disable it. A profile Kotlin compilation with the Flutter build task
excluded and a `javap` inspection found no hook reference in the worker's
profile bytecode, while the debug bytecode contains it. This is not a signed
APK or a runtime privacy qualification.

`android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR15HeldCanvasInstrumentationTest.kt`
captures the genuine service attachment/generation and holder operation,
triggers system unlock, observes local invisibility and remove ordering, then
releases the held worker. Its screenshot crops are explicitly UNCLASSIFIED;
they are not a calibrated first/last visible ORB oracle.
`scripts/verify-keyguard-installed-apk.sh` records package path, split list,
command exits and source/installed SHA-256, before and after R12 specimens.
`scripts/test-keyguard-apk-install.py` exercises matching and failing receipts.
The required calibrated service compositor/privacy and balanced acquisition
comparisons remain separate and cannot be inferred from these nodes.
