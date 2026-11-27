# Widgets Anywhere 4.7.5 lockscreen subset

Derived from Zachary Wander's Widgets Anywhere at
`9c7fed25ec833197656dec57427be4c26fc66138` (R49 source tree
`d00525e0c97815cbdf1c46ef806fffbd2100b10e`). The two upstream licenses are in
the library's packaged assets.

| Upstream source and symbol | Retained source and symbol |
| --- | --- |
| `App.kt` and `LSDisplayManager`, display power initialization | `WaLockscreenService`, default-display power listener |
| `services/Accessibility.kt`, service connection and replacement of pending accessibility work | `WaLockscreenService`, service connection and scan replacement |
| `common/util/AccessibilityUtils.kt`, `runAccessibilityJob`, `runWindowOperation`, `processWindows`, `IDMaps` | `WaLockscreenService`, `refreshScene`, `WaLockscreenScene` |
| `util/WidgetFrameDelegate.kt`, ordinary `canShow`, `updateWindowState`, window add/update/remove | `WaLockscreenService`, fresh-add recheck; `WaOrbWindow`, window operations |
| `WidgetHostCompat`, host 1003 and attach/listen lifecycle | `WaOrbHost` and `WaOrbWindow` |

These are the source files in the focused library. The accessibility
component, provider, binding, resources and material owner belong to Fluvi.
The drag state and fixed circular geometry replace WA's grid/edit controls.
