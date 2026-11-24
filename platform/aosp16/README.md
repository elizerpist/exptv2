# R38 SystemUI clock reference: incomplete, do not enable

The R38 source adds `0002-r38-clock-root.patch` at the pinned Android 16
`DefaultBlueprint` root. Its passive draw modifier preserves the existing six
measurables and uses only the resident image plus SystemUI scene inputs. The
reference store now has exact-session/sequence EMPTY bookkeeping and defers an
EMPTY callback until an image-free clock-root draw and frame-commit callback.
That callback is not a physical-display measurement.

**This reference is still incomplete and must remain unenrolled.** The shipped
app has no authenticated exclusive-owner handover into the host; pending
asynchronous legacy output has not been proved drained. The patched SystemUI
has not been Soong-built, booted, or exercised against actual transition and
outgoing-layer frames. No first-clock-frame, animation-continuity, exclusion,
or 10 ms result is established by source staging, a JVM test, or a commit
callback. A real-device or matched-image test is required before enabling it.

The missing app connection is concrete: production has no caller of
`R35ResidentPublisher.connectAfterDrain`, and `R29Ownership.appMayShow` is not
wired into both existing app admission and final native submission. Binding a
host without those guards could leave two owners of private pixels. The current
revisioned Flutter evidence explicitly qualifies only Budget's category-color
projection; Mind and Balance lack equivalent scope/revision provenance and
therefore cannot be advertised as FULL host generations. The reference must
fail closed for them until the real producers carry that provenance.

The separate application continuation `0905f0d6e81cba396663c6b09898171913c195a9`
adds a narrowly guarded production caller of that publisher. It checks the
actual SystemUI service signer, UID and clock-scene capability metadata before
pre-lock enrollment. In this initial reference path enrollment is restricted
to a fresh userdebug/eng installation, an unlocked first service, no previous
local reservation/output and the revisioned Budget category projection.
Unsupported stock phones and unsupported starting modes keep their existing
path. After reference enrollment, a later unsupported generation is withheld;
the current implementation does not prove a safe automatic return to stock.
The application and this reference patch have not been run together on
an Android 16 image; do not treat a successful connection or an offscreen
receiver as evidence of primary-clock composition or privacy.

The manifest patch advertises `com.fluvi.reference.CLOCK_SCENE_VERSION=1` for
this reference service. It is an identity/capability check, not evidence that
any frame passed, and does not authorize stock-device enrollment.

The two patch files and the renderer/store sources can be staged reproducibly
with the existing command below. The stager checks both patches against the
same AOSP parent and copies the clock-specific source from `clock/src`.
`--allow-incomplete` is mandatory and does not assert safety or completion.

The R38 reference checks the current renderer source digest; its only change
from the older pinned profile is three R35 publication calls below the exact
renderer prefix extracted by the stager. All shader and generator pins remain
unchanged. The phone APK is built separately from the R38 application commit.

## Earlier R29 bootstrap record

The following historical description records the state before the R38 clock
hook above; it does not override the incomplete R38 status and test limits.

**Status: NOT an integrated R29 build.** The bootstrap patch below registers a
reference-only service and stages its renderer assets, but it does not connect
that renderer to the actual lockscreen scene, implement the restrictive-frame
latch, prove an empty-frame acknowledgement, or establish the app's exclusive
owner and authoritative live-projection stream. The app client is not wired to
a production publisher. Do not treat this checkpoint as an R29 latency fix or
use it to display private data. The default stock ORB path is unchanged.

The intended AOSP `frameworks/base` parent is Android 16 tag
`android-16.0.0_r1`, peeled commit
`99b01a65cc4c104933788b3143285ab6bae65827`. The bootstrap service is inert by
default and requires the SystemUI secure setting `fluvi_r29_demo_enrolled`, a
userdebug/eng build, an unlocked foreground primary user, and the pinned Fluvi
package signer. It authenticates each Binder transaction. This guard is not a
replacement for the missing scene and freshness controls.

From a Fluvi checkout, generate the Android shader assets with the existing
Gradle task, then verify against a clean checkout of the pinned AOSP parent:

```sh
(cd android && ./gradlew :app:generateKeyguardHeaderMaterial --no-daemon)
python3 platform/aosp16/tools/stage_aosp_wip.py \
  --base /path/to/aosp/frameworks/base \
  --assets build/app/generated/keyguardHeaderMaterial/assets
```

The verifier checks the exact AOSP parent, a clean tree, patch applicability,
canonical Fluvi source/generator digests, and the committed SHA-256 list for all 36 generated shader variants and their metadata.
It makes no changes to the AOSP tree. `--apply --allow-incomplete` stages this
**incomplete** bootstrap only after the Fluvi tracked source is committed and
AOSP has been checked clean and no untracked platform files exist; the output includes source and asset digests. This
is for further source review, not a bootable or tested image. The script refuses
to overwrite existing files. No AOSP tree, platform image or private evidence
is included in this repository.

The supplied `FluviOrbFramePolicyTest` is a unit test of the shared policy,
not a compositor/image test. Actual Soong build, SystemUI tests, boot, app-dead
wake/withdrawal and all optical endpoints remain **NOT RUN** until the missing
integration and a compatible Android 16 reference builder/device exist.

## R29.1 partial checkpoint

The isolated Budget scene target now carries the core revision from one Room
read transaction, and the Dart material publication carries scoped provenance
when it derives the supported category palette. The host store now adopts
worker results on Main, suppresses stale READY delivery, distinguishes an
unexpected callback death from clean detach, and schedules static expiry. The
GPU preparation wait is bounded; an unconfirmed job remains quarantined.
These are preparatory changes only: **enrollment, exclusive old-owner drain,
real publisher-to-Binder delivery, the lockscreen composition and synchronous
restriction/empty-frame receipt are still absent**. Reference enrollment must
remain disabled and the patch remains the incomplete bootstrap above.

`tests/host_store_harness/run.sh` is a deterministic unit control for the
actual resident store using a fake renderer and explicit worker/Main queues.
Set `R29_KOTLIN_COMPILER_CP` to a Kotlin compiler/runtime classpath and
`R29_KOTLIN_STDLIB` to its stdlib jar. It is not a GPU, Binder, SystemUI or
physical-frame test.

The clock root observes process-local host availability, so a clock composition
created before the pre-lock service is bound can observe the subsequently
prepared runtime without initiating Binder discovery on wake. This wiring has
not yet been built with Soong or observed in a booted SystemUI image.
