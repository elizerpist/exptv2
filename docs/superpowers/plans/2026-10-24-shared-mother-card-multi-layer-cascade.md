# One shared Mother Card motion and multi-layer cascade

Starting HEAD: 2e809f2a5538f9ab637aa882da9231bc697f083e.
Work stays on refactor/mind-balance-continuous-mother-card. Preserve newer work
and historical untracked evidence. No reset, prototype copies or local APK build.

## Design and investigation

The current Mind physical top reuses its content zone2Shift and its height
collapses linearly. Budget/Balance lerp toward an already moving cascade target,
retaining the large target height. Balance's parent transform/opacity also binds
accepted focused avatar selectors to the analytical lower content.

Use one master separation and one shared physical policy. Expose the existing
HeaderCascadeMotion calculation as read-only frame data for unified Mind,
without changing structural layout or the existing split upper/lower outputs.
Resolve physical translation, narrowing and an explicit content-relative bottom
trajectory once in DashboardUnifiedMotherCardMotion. No new clock or second
implicit easing. Retain mode adapters only for content allocation/presentation.
Budget may keep its endpoint painter. Header shape/depth use the shared seam
shape and separation. Preserve direction/Summary/LogBox bounds.

Before choosing the lower-edge phase, measure old card/content/summary bounds at
35/50/65%, then compare the new geometry and rendered states. Use the existing
HTTP companion in its canonical project folder to explain the four motion
tracks and show old/new evidence. Expanded endpoints stay exact.

## Independent ownership and execution

1. Root: shared motion policy, resolver/frame read-only cascade inputs, three
   geometry adapters, Mind and Budget surface integration and shared geometry
   tests. Preserve Budget's actual upper/lower content transforms.
2. Balance stream: balance_dashboard_core_surface.dart, the four
   balance_*_focused_layout.dart files, a focused cascade helper, and dedicated
   Balance avatar cascade tests. Preserve lower content placement; compensate
   the selector's local transform correctly and avoid parent opacity suppressing
   the upper track. Do not edit common geometry or the resolver.
3. Evidence stream: dedicated baseline/measurement/visual tests and evidence
   data only; characterize old geometry, render old intermediate states and
   propose endpoint-independent acceptance checks. Do not edit production code,
   existing goldens or another stream's tests.
4. Root integrates and reviews the streams; validates all normalized tracks,
   continuity, reverse/input/state and clipping contracts; renders final
   0/first/early/35/50/65/near/collapsed states for all three modes. Update only
   affected goldens after inspecting evidence. Record measured bottom/content
   gaps and preserve accepted expanded images.
5. Proot analyze and relevant regression checks; commit and push this active
   branch; follow exact-SHA CI through normal human APK, download to
   /storage/emulated/0/Download/fluvi and verify size/SHA-256.

The physical-policy work, Balance selector work and evidence work have distinct
file ownership. Parallel work is useful here; integration and build delivery
remain sequential.

## Integration API

Root will expose frame.motherCardCascade (upper/lower, always resolved even
when Mind's structural lowerCardMotion remains null). The three geometry
adapters will delegate physical bounds to the same policy and retain existing
public properties. Balance's adapter will expose contentTransform (Matrix4)
for the exact accepted previous lower analytical placement; physical bodyBounds
must no longer determine that content transform. Balance owns its compensated
upper selector track and lower opacity grouping. Standalone focused layouts
without the motion scope retain their current exact expanded layout.
