# Widgets Anywhere 4.7.5 attribution

The R44.8 frame is adapted from `WidgetFrameDelegate.kt` (layout parameters,
window add and removal, and the delayed second `canShow` check) and
`SafeWindowManager.kt` at zacharee/LockscreenWidgets commit
`9c7fed25ec833197656dec57427be4c26fc66138`. Copyright 2020 and 2023 Zachary
Wander. Both upstream MIT license files are preserved verbatim in
`android/app/src/main/assets/third_party/widgets-anywhere-4.7.5/`.

The adaptation hosts one Fluvi material view rather than an AppWidgetHost,
adds `FLAG_NOT_TOUCHABLE`, coalesces identical pending requests, requires a
caller-owned current authorization for both checks, omits entrance and exit
fades, and immediately hides before `removeViewImmediate`. It does not import
the upstream private display-manager interfaces, preview/force-show routes,
widget discovery, integrations, analytics, or another service. View draw and
window-manager return are observations, not proof of physical presentation.
