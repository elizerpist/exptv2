# Fluvi R54 exact-source navigation

Source `41add67b7f4d4ecdf7a0a48abff64ca85364ac9e`. Dart references are from SCIP Dart 1.6.2. Kotlin and packaging locations below were checked in source.

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
android/app/src/main/kotlin/tk/zwander/lockscreenwidgets/services/Accessibility.kt:38:    override fun showOrb(episode: Long, animate: Boolean): Boolean {
android/app/src/main/kotlin/tk/zwander/lockscreenwidgets/services/Accessibility.kt:47:    override fun hideOrb(reason: WaHideReason, unlock: WaUnlockTrigger?) = orb.hide(reason, unlock)
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:142:    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:144:        waCaptureChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fluvi/wa_lockscreen_capture")
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaCaptureTimeout.kt:34:    fun normalize() {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaCaptureTimeout.kt:41:    fun arm(capture: String, requested: Long): ArmResult {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaCaptureTimeout.kt:63:    fun restore(lease: Lease, disconnected: Boolean = false) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLastUnlock.kt:164:    fun committed(at: WaTime) = update { it.copy(childCommit = it.childCommit ?: at) }
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLastUnlock.kt:184:    internal fun publish(context: Context, record: WaUnlockRecord) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLastUnlock.kt:193:    fun request(context: Context, reply: (Map<String, String>) -> Unit) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenCapture.kt:106:    internal fun ingress(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenCapture.kt:133:    internal fun record(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenCapture.kt:155:    private fun trace(arm: Long, row: WaTraceRing.Row) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenCapture.kt:182:    fun request(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenCapture.kt:295:    private suspend fun freeze(context: Context, stop: Stop) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenCapture.kt:487:        fun sample() {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenCapture.kt:529:        fun snapshot(up: Long, elapsed: Long, stop: Stop, arm: ArmReport): Frozen = synchronized(samples) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:50:    protected abstract fun showOrb(episode: Long, animate: Boolean): Boolean
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:51:    protected abstract fun hideOrb(reason: WaHideReason, unlock: WaUnlockTrigger? = null): Long
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:178:    private fun checkState(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:218:    private fun offerScan(source: WaSource, type: Int = 0) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:294:    private fun terminalSignal(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:311:    private fun withdraw(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:346:    private fun record(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaWithdrawalEvidence.kt:19:    fun observe(row: WaTraceRing.Row) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaWithdrawalEvidence.kt:100:    fun probe(owner: WaAttachment, up: Long, begin: Long, end: Long, state: WaSystemState, crossed: Boolean, seq: Long) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:187:    private fun bindChild(frame: OrbRoot, child: WaSurfaceChild) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:199:    private fun embeddingFailed(frame: OrbRoot, child: WaSurfaceChild, reason: String) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:225:    private fun waitForDraw(frame: OrbRoot) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:256:    private fun startEntrance(frame: OrbRoot) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:318:    fun hide(reason: WaHideReason, trigger: WaUnlockTrigger? = null): Long {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:364:    private fun remove(frame: OrbRoot, retry: Boolean) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:563:        private fun publishNonzero() {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaSurfaceChild.kt:35:    fun attach(visual: View, diameter: Int) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaSurfaceChild.kt:60:    fun withdraw(receipt: ((WaTime) -> Unit)?): WaChildHide {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaSurfaceChild.kt:92:    fun dispose() {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaWakeEpisode.kt:82:    fun admit(state: WaSystemState): Boolean {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaWakeEpisode.kt:101:    fun attached(episode: Long) {
lib/core/debug/debug_console.dart:16:class DebugConsoleDialog extends StatefulWidget {
lib/core/debug/debug_console.dart:17:  const DebugConsoleDialog({
lib/core/debug/debug_console.dart:29:  State<DebugConsoleDialog> createState() => _DebugConsoleDialogState();
lib/core/debug/debug_console.dart:38:class _DebugConsoleDialogState extends State<DebugConsoleDialog> {
lib/core/debug/debug_console.dart:148:      await Clipboard.setData(
lib/core/debug/debug_console.dart:169:      await Clipboard.setData(
lib/core/debug/debug_console.dart:209:      await Clipboard.setData(ClipboardData(text: report));
lib/core/debug/debug_console.dart:254:    await Clipboard.setData(ClipboardData(text: text));
lib/core/debug/debug_console.dart:684:      return const DebugLockscreenCapture();
lib/app/shell/fluvi_app_shell.dart:1490:                                DebugFloatingButton(
lib/core/diagnostics/copy_last_unlock.dart:42:          await Clipboard.setData(ClipboardData(text: text));
lib/core/debug/debug_floating_button.dart:11:class DebugFloatingButton extends StatelessWidget {
lib/core/debug/debug_floating_button.dart:12:  const DebugFloatingButton({
lib/core/debug/debug_floating_button.dart:40:              builder: (_) => DebugConsoleDialog(
lib/core/debug/debug_lockscreen_capture.dart:10:class DebugLockscreenCapture extends StatefulWidget {
lib/core/debug/debug_lockscreen_capture.dart:11:  const DebugLockscreenCapture({super.key});
lib/core/debug/debug_lockscreen_capture.dart:14:  State<DebugLockscreenCapture> createState() => _DebugLockscreenCaptureState();
lib/core/debug/debug_lockscreen_capture.dart:17:class _DebugLockscreenCaptureState extends State<DebugLockscreenCapture>
lib/core/debug/debug_lockscreen_capture.dart:62:  Future<Map<String, Object?>> _request(String method) async =>
lib/core/debug/debug_lockscreen_capture.dart:77:      final status = await _request('status');
lib/core/debug/debug_lockscreen_capture.dart:97:      final status = Map<String, Object?>.of(await _request(method));
lib/core/debug/debug_lockscreen_capture.dart:107:          await Clipboard.setData(ClipboardData(text: text));
```

Android owns wake/withdrawal and one real WA AppWidget host. The separate Dart console starts and copies the bounded native capture via a method channel. Kotlin has source-navigation coverage only. Physical presentation requires a handset measurement.
