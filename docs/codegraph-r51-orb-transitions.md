# Fluvi R51 exact-source navigation

Source `e7542639d22d78d10e7b123e836ee9bc9758c91a`. Dart references are from SCIP Dart 1.6.2. Kotlin and packaging locations below were checked in source.

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
android/app/src/main/kotlin/tk/zwander/lockscreenwidgets/services/Accessibility.kt:34:    override fun showOrb(episode: Long, animate: Boolean): Boolean {
android/app/src/main/kotlin/tk/zwander/lockscreenwidgets/services/Accessibility.kt:42:    override fun hideOrb(reason: WaHideReason) = orb.hide(reason)
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:140:    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:142:        waCaptureChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fluvi/wa_lockscreen_capture")
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenCapture.kt:65:    internal fun record(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenCapture.kt:82:    fun request(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenCapture.kt:136:    private suspend fun freeze(context: Context, stop: Stop) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenCapture.kt:280:        fun sample() {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenCapture.kt:314:        fun snapshot(up: Long, elapsed: Long, stop: Stop): Frozen = synchronized(samples) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:50:    protected abstract fun showOrb(episode: Long, animate: Boolean): Boolean
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:51:    protected abstract fun hideOrb(reason: WaHideReason): Long
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:148:    private fun checkState(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:170:    private fun offerScan(source: WaSource, type: Int = 0) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:238:    private fun terminalSignal(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:255:    private fun withdraw(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:278:    private fun record(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:153:    private fun waitForDraw(frame: OrbRoot, allowed: () -> Boolean) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:174:    private fun startEntrance(frame: OrbRoot) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:223:    fun hide(reason: WaHideReason): Long {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:248:    private fun remove(frame: OrbRoot, retry: Boolean) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaWakeEpisode.kt:82:    fun admit(state: WaSystemState): Boolean {
lib/app/shell/fluvi_app_shell.dart:1490:                                DebugFloatingButton(
lib/core/debug/debug_lockscreen_capture.dart:9:class DebugLockscreenCapture extends StatefulWidget {
lib/core/debug/debug_lockscreen_capture.dart:10:  const DebugLockscreenCapture({super.key});
lib/core/debug/debug_lockscreen_capture.dart:13:  State<DebugLockscreenCapture> createState() => _DebugLockscreenCaptureState();
lib/core/debug/debug_lockscreen_capture.dart:16:class _DebugLockscreenCaptureState extends State<DebugLockscreenCapture>
lib/core/debug/debug_lockscreen_capture.dart:60:  Future<Map<String, Object?>> _request(String method) async =>
lib/core/debug/debug_lockscreen_capture.dart:77:      final status = await _request('status');
lib/core/debug/debug_lockscreen_capture.dart:97:      final status = Map<String, Object?>.of(await _request(method));
lib/core/debug/debug_lockscreen_capture.dart:107:          await Clipboard.setData(ClipboardData(text: text));
lib/core/debug/debug_floating_button.dart:11:class DebugFloatingButton extends StatelessWidget {
lib/core/debug/debug_floating_button.dart:12:  const DebugFloatingButton({
lib/core/debug/debug_floating_button.dart:40:              builder: (_) => DebugConsoleDialog(
lib/core/debug/debug_console.dart:16:class DebugConsoleDialog extends StatefulWidget {
lib/core/debug/debug_console.dart:17:  const DebugConsoleDialog({
lib/core/debug/debug_console.dart:29:  State<DebugConsoleDialog> createState() => _DebugConsoleDialogState();
lib/core/debug/debug_console.dart:38:class _DebugConsoleDialogState extends State<DebugConsoleDialog> {
lib/core/debug/debug_console.dart:148:      await Clipboard.setData(
lib/core/debug/debug_console.dart:169:      await Clipboard.setData(
lib/core/debug/debug_console.dart:209:      await Clipboard.setData(ClipboardData(text: report));
lib/core/debug/debug_console.dart:254:    await Clipboard.setData(ClipboardData(text: text));
lib/core/debug/debug_console.dart:684:      return const DebugLockscreenCapture();
```

Android owns wake/withdrawal and one real WA AppWidget host. The separate Dart console starts and copies the bounded native capture via a method channel. Kotlin has source-navigation coverage only. Physical presentation requires a handset measurement.
