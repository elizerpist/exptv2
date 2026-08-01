# Fluvi convex center bottom navigation checklist

| ID | Source instruction | Intended code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| NAV-01 | User request: white background must rise in a convex center bump, not a notch | `lib/app/shell/fluvi_bottom_navigation.dart` | A custom painter draws a horizontal side edge and a symmetric 110–130 px, 20–28 px raised center using two cubic Bézier curves | Painter source inspection and direct running-web visual inspection | NOT DONE |
| NAV-02 | User request: the center action stays inside the bottom-nav reserved area | `FluviBottomNavigation` Stack | The 64 px gradient `+` button is positioned inside the nav widget at the raised center; no Scaffold FAB is introduced | Widget geometry test and source inspection | NOT DONE |
| NAV-03 | User request: preserve gradient, icons, labels and behavior | `FluviBottomNavigation`, `FluviCenterFab` | Existing Dashboard/Settings semantics, labels, colors, gradient and disabled behavior remain unchanged | Widget test and source inspection | NOT DONE |
| NAV-04 | User request: handle SafeArea and avoid clipping/overflow/layout jumps | `FluviBottomNavigation` and visual tokens | Nav content is 110–120 px plus the device bottom inset; the painter and children remain inside their bounds | Widget geometry test, overflow test, release web build | NOT DONE |
