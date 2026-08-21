# LogBox active-swipe horizontal escape — acceptance checklist

| ID | Requirement source | Owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SE-1 | Current physical swipe regression | `DashboardLogBoxViewport` physical scroll host | The hard-edge viewport begins at physical x=0 while preserving its structural top/bottom boundary. | Widget/render geometry test plus existing top-boundary test. | DONE |
| SE-2 | Current physical swipe regression | Static LogBox sliver placement | Resting cards retain the existing x=17 content inset; inactive content does not widen. | Widget render-rect assertion. | DONE |
| SE-3 | Current physical swipe regression | Existing canonical segment / transform path | An active segment can paint between x=0 and the resting inset and can move beyond x=0 until its existing cap. | Geometry/widget regression and existing kinematic test. | DONE |
| SE-4 | 4a83bc clipping boundary | `CustomScrollView` / RenderViewport | The 90 px painter overscan remains physically clipped at the structural LogBox top and bottom. | Existing hard-edge/top-header regression. | DONE |
| SE-5 | Canonical swipe contract | Static painter + active retained layer | Exactly one canonical active segment is painted; no clone or stationary source body returns. | Existing partner-swipe structural/morphology tests. | DONE |
| SE-6 | Protected scroll/focus contracts | Existing controller/cache/query owners | Controller, `ScrollPosition`, physics, virtual geometry, focus publication and retained base hotset ownership do not change. | Focus/cache/approved-milestone regressions. | DONE |
| SE-7 | Human APK delivery | Normal `lib/main.dart` APK | Normal APK is pushed, built online and downloaded; physical verification remains explicitly pending. | GitHub Actions artifact + SHA-256. | NOT DONE |
