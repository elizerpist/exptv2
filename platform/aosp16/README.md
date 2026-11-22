# R29 SystemUI reference: incomplete checkpoint

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
canonical Fluvi source/generator digests, and all 36 generated shader variants.
It makes no changes to the AOSP tree. `--apply --allow-incomplete` stages this
**incomplete** bootstrap only after the Fluvi tracked source is committed and
AOSP has been checked clean; the output includes source and asset digests. This
is for further source review, not a bootable or tested image. The script refuses
to overwrite existing files. No AOSP tree, platform image or private evidence
is included in this repository.

The supplied `FluviOrbFramePolicyTest` is a unit test of the shared policy,
not a compositor/image test. Actual Soong build, SystemUI tests, boot, app-dead
wake/withdrawal and all optical endpoints remain **NOT RUN** until the missing
integration and a compatible Android 16 reference builder/device exist.
