# Fluvi R50 exact-source navigation

Source `c1e674b2bcf31feab2ce5f5143b5032a109215ba`. Dart references are from SCIP Dart 1.6.2. Kotlin and packaging locations below were checked in source.

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

## Android and Dart call sites

```text
android/app/src/main/kotlin/com/fluvi/app/widget/orb/FluviHeaderOrbWidgetProvider.kt:24:class FluviHeaderOrbWidgetProvider : AppWidgetProvider() {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/FluviHeaderOrbWidgetProvider.kt:38:    private fun refresh(context: Context, ids: IntArray) {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/FluviHeaderOrbWidgetProvider.kt:71:    fun prepare(context: Context, binding: HeaderOrbBinding, signature: String): Map<String, Any> {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/FluviHeaderOrbWidgetProvider.kt:91:    fun publish(
android/app/src/main/kotlin/com/fluvi/app/widget/orb/FluviHeaderOrbWidgetProvider.kt:133:    fun revoke(context: Context, widgetId: Int) {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/FluviHeaderOrbWidgetProvider.kt:141:    fun refresh(context: Context, binding: HeaderOrbBinding) {
android/app/src/main/kotlin/tk/zwander/lockscreenwidgets/services/Accessibility.kt:15:    override fun onServiceConnected() {
android/app/src/main/kotlin/tk/zwander/lockscreenwidgets/services/Accessibility.kt:34:    override fun showOrb() {
android/app/src/main/kotlin/tk/zwander/lockscreenwidgets/services/Accessibility.kt:40:    override fun hideOrb(reason: String) = orb.hide(reason)
android/app/src/main/kotlin/com/fluvi/app/widget/orb/HeaderOrbBinding.kt:67:    private fun migrate() {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/HeaderOrbBinding.kt:124:    private fun revoke() {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/HeaderOrbBinding.kt:145:    private fun publishState() {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/HeaderOrbBinding.kt:197:    fun settingsResumed(activity: Activity, resumed: Boolean) {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/HeaderOrbBinding.kt:206:    fun selectSize(activity: Activity, resumed: Boolean, dp: Int) {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/HeaderOrbBinding.kt:229:    private fun maybeBind(activity: Activity, resumed: Boolean) {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/HeaderOrbBinding.kt:260:    fun bindResult(requestCode: Int, result: Int, data: Intent?) {
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:117:    private var headerOrbStates: EventChannel? = null
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1148:        headerOrbStates = EventChannel(flutterEngine.dartExecutor.binaryMessenger, "fluvi/header_orb_state")
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1299:        headerOrbStates?.setStreamHandler(null)
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1300:        headerOrbStates = null
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:2770:    private fun preparedQueryRequestIdentity(
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:3126:    private fun preparedIndexRequestIdentity(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:51:    protected abstract fun showOrb()
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:52:    protected abstract fun hideOrb(reason: String)
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:68:    override fun onServiceConnected() {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:116:    protected fun refreshScene(reason: String) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:158:    private suspend fun addAfterRecheck(id: Long) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:243:        suspend fun inspect(windows: List<AccessibilityWindowInfo>, powerNode: AccessibilityNodeInfo?): WaLockscreenScene {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:57:    fun show(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:136:    fun hide(reason: String) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:194:    private fun safeUpdate(position: Pair<Int, Int>, dimensions: Geometry): Boolean {
lib/features/header_orb/presentation/header_orb_setup_page.dart:8:class HeaderOrbSetupPage extends StatefulWidget {
lib/app/platform/dashboard_header_widget_publisher.dart:12:final class DashboardHeaderWidgetPublisher {
lib/app/platform/dashboard_header_widget_publisher.dart:83:      final snapshot = DashboardHeaderMaterialSnapshot.capture(
lib/app/shell/fluvi_app_shell.dart:329:    unawaited(_restoreHeaderOrb());
lib/app/shell/fluvi_app_shell.dart:1010:  Future<void> _restoreHeaderOrb() async {
lib/app/shell/fluvi_app_shell.dart:1040:  void _measureHeaderOrb(Size size, double pixelRatio) {
lib/app/shell/fluvi_app_shell.dart:1348:                                            onHeaderGeometry: _measureHeaderOrb,
76:    bash ./gradlew ":app:assemble${mode^}" \
77:        :app:processDebugMainManifest :app:processProfileMainManifest :app:processReleaseMainManifest \
80:        --no-daemon --max-workers=3 --console=plain > "$stage/runtime-dependencies.txt"
85:        python3 "$root/scripts/verify-r50-host.py" --manifest "$stage/manifest-$variant.xml"
93:python3 scripts/verify-r50-host.py --apk "$out"
```

The publisher follows Balance colors and native binding authority. Android displays one regular AppWidget inside WA host 1003. Physical presentation is a handset measurement.
