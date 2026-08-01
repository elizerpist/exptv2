# Fluvi web layout parity checklist

Reference behavior: the installed APK layout is the source of truth. Web must
keep the existing responsive dashboard geometry and match the APK's top content
origin without introducing a second whole-shell scale. This checklist is
superseded for the current native-parity pass by
`2026-07-31-fluvi-native-web-parity.md`.

| ID | Source instruction | Intended code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| WEB-APK-01 | User: web igazodjon az APK méretéhez és elrendezéséhez | `DashboardLayoutMetrics`, `CoreDashboard` | A dashboard metrikák content-originból indulnak; nincs második teljes-shell skála | Geometry test and source inspection | DONE |
| WEB-APK-02 | User: a webes extra felső terület ne tolja le a headert | `core_dashboard.dart`, `dashboard_layout_metrics.dart` | Weben a content-origin metrikák és 20 px design spacing mozgatja együtt a dashboard tartalmát; natívon a korábbi referencia-origin változatlan marad | Focused widget test and source inspection | DONE |
| WEB-APK-03 | User: APK-hoz igazodó webes méret | `web/index.html` | Mobil böngésző CSS viewportja `device-width` alapján indul | Source inspection, HTTP 200 check, release web build | DONE |
| WEB-APK-04 | User: jelenlegi működés maradjon | app shell/dashboard | APK-n a meglévő shell és interakciók változatlanok; weben a fullscreen és BNB03 működik | Targeted analyze/test and release web build; visual confirmation by user | PARTIAL — user visual confirmation pending |
| WEB-APK-05 | User: fekete Android status bar maradjon változatlan | `web/index.html`, `fluvi_app_shell.dart` | Nincs status-bar színmódosítás, Scaffold-transform vagy webes status-bar mögé rajzolás | Source inspection and release build | DONE |
| WEB-APK-06 | User: a top inset pontosan egyszer legyen alkalmazva | `core_dashboard.dart`, `dashboard_layout_metrics.dart` | Weben egyetlen 20 px content padding és origin-normalizálás van; natívan nincs új top padding vagy metrikaeltolás | Focused widget test and source inspection | DONE |
| WEB-APK-07 | User: bottom navigation maradjon a viewport alján | `fluvi_app_shell.dart` | A BNB-03 továbbra is a Scaffold bottomNavigationBar ágán, `SafeArea(top: false)` alatt marad | Source inspection and release build | DONE |

## Architecture card

- Single owner: `CoreDashboard` owns the dashboard content top-inset normalization.
- Existing owners retained: `DashboardLayoutMetrics` owns dashboard geometry;
  `Bnb03BottomNavigation` owns its component rendering; `FluviAppShell` owns
  shell selection and navigation state.
- No duplicate dashboard or navigation layout is introduced. The dashboard
  content receives one platform-dependent top inset; the bottom safe area
  remains owned by `FluviAppShell`.
- Required evidence: focused viewport geometry test, source inspection,
  `flutter analyze`, and release web build. Golden tests are not required by
  the user; visual confirmation remains with the user.
