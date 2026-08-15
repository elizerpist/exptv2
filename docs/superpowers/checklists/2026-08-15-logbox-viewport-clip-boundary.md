# LogBox viewport clipping boundary — acceptance checklist

- [x] VC-1: outer `DashboardLogBoxViewport` `CustomScrollView` explicitly owns `Clip.hardEdge`.
- [x] VC-2: local canonical swipe stack may retain `Clip.none`, but remains under that outer viewport.
- [x] VC-3: header and facet chips remain structural siblings, with no in-scroll spacer.
- [x] VC-4: controller, position, physics and authoritative virtual extent remain unchanged.
- [x] VC-5: active swipe still travels past `-screenLeft` as the outer viewport clips only offscreen pixels.
- [x] VC-6: focus lazy projection and base hotset restoration remain unaffected.
- [ ] VC-7: normal `lib/main.dart` APK is delivered for pending human verification.
