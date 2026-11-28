# Fluvi R55 exact-source navigation

Source `1e15c448de5344825c4560b51d0f48e1204f3c46`. Dart references are from SCIP Dart 1.6.2. Kotlin and packaging locations below were checked in source.

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
android/app/src/main/kotlin/tk/zwander/lockscreenwidgets/services/Accessibility.kt:47:    override fun showOrb(episode: Long, animate: Boolean): Boolean {
android/app/src/main/kotlin/tk/zwander/lockscreenwidgets/services/Accessibility.kt:56:    override fun hideOrb(reason: WaHideReason, unlock: WaUnlockTrigger?) = orb.hide(reason, unlock)
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:143:    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:145:        waCaptureChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fluvi/wa_lockscreen_capture")
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1130:                        "status", "openAccessibility", "settingsResumed", "selectSize", "selectStyle", "setPermanentOrb" -> {
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1140:                                    "setPermanentOrb" -> binding.setPermanentOrb(requireNotNull(call.argument("enabled")))
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaAmbientAuthority.kt:61:    fun publish(ticket: Ticket, gate: WaAmbientGate, identity: WaAmbientIdentity?): Boolean {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaAmbientAuthority.kt:71:    fun revoke() {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaAmbientCapture.kt:22:    fun observedStatus(): String = if (sawDoze) "AOD_OBSERVED" else "AOD_UNKNOWN"
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaAmbientCapture.kt:28:    internal fun observe(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaAmbientOrbWindow.kt:37:    fun observe(gate: WaAmbientGate, key: WaAmbientIdentity?) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaAmbientOrbWindow.kt:113:    private fun awaitDraw(frame: Frame) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaAmbientOrbWindow.kt:146:    fun revoke(reason: String, error: String? = null) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaAmbientOrbWindow.kt:159:    private fun remove(frame: Frame, retry: Boolean) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaCaptureTimeout.kt:34:    fun normalize() {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaCaptureTimeout.kt:41:    fun arm(capture: String, requested: Long): ArmResult {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaCaptureTimeout.kt:63:    fun restore(lease: Lease, disconnected: Boolean = false) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLastUnlock.kt:172:            (record.trigger.cause == WaWithdrawalCause.APP_WINDOW_PRESENT && record.confirmation == null) ||
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLastUnlock.kt:199:    fun committed(at: WaTime) = update { it.copy(childCommit = it.childCommit ?: at) }
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLastUnlock.kt:225:    internal fun publish(context: Context, record: WaUnlockRecord) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLastUnlock.kt:234:    fun request(context: Context, reply: (Map<String, String>) -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/FluviHeaderOrbWidgetProvider.kt:79:            binding.restoreAmbient(owner, cached.generation)
android/app/src/main/kotlin/com/fluvi/app/widget/orb/FluviHeaderOrbWidgetProvider.kt:84:        binding.invalidateAmbient(owner)
android/app/src/main/kotlin/com/fluvi/app/widget/orb/FluviHeaderOrbWidgetProvider.kt:97:    fun publish(
android/app/src/main/kotlin/com/fluvi/app/widget/orb/FluviHeaderOrbWidgetProvider.kt:134:        binding.markReady(owner, true, prepared.ambient)
android/app/src/main/kotlin/com/fluvi/app/widget/orb/FluviHeaderOrbWidgetProvider.kt:139:    fun revoke(context: Context, widgetId: Int) {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/FluviHeaderOrbWidgetProvider.kt:153:        binding.markReady(owner, packet != null, prepared?.ambient?.takeIf { preparation?.owner != owner })
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenCapture.kt:106:    internal fun ingress(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenCapture.kt:133:    internal fun record(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenCapture.kt:155:    private fun trace(arm: Long, row: WaTraceRing.Row) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenCapture.kt:182:    fun request(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenCapture.kt:295:    private suspend fun freeze(context: Context, stop: Stop) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenCapture.kt:487:        fun sample() {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenCapture.kt:529:        fun snapshot(up: Long, elapsed: Long, stop: Stop, arm: ArmReport): Frozen = synchronized(samples) {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/FluviOrbWidget.kt:193:    fun requestRefresh(context: Context, reason: String) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:58:    protected abstract fun showOrb(episode: Long, animate: Boolean): Boolean
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:59:    protected abstract fun hideOrb(reason: WaHideReason, unlock: WaUnlockTrigger? = null): Long
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:208:    private fun reconcileAmbient(source: WaSource, state: WaSystemState, enabled: Boolean) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:227:    private fun canDrawAmbient(expectedSession: Long, identity: WaAmbientIdentity): Boolean {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:243:    private fun checkState(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:303:    private fun offerScan(source: WaSource, type: Int = 0, received: Long = 0, eventTime: Long = 0) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:363:                    val appWindow = result.reading == WaSceneReading.APP_WINDOW_PRESENT
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:368:                        WaWithdrawalCause.APP_WINDOW_PRESENT,
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:418:    private fun terminalSignal(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:441:    private fun withdraw(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:477:    private fun record(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:556:    APP_WINDOW_PRESENT(WaLockscreenScene.RESTRICTED),
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:587:        suspend fun inspect(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaLockscreenService.kt:598:                        return WaSceneReading.APP_WINDOW_PRESENT
android/app/src/main/kotlin/com/fluvi/app/widget/orb/HeaderOrbBinding.kt:132:    private fun revoke() {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/HeaderOrbBinding.kt:147:    fun observe(listener: () -> Unit): () -> Unit {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/HeaderOrbBinding.kt:155:    private fun publishState() {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/HeaderOrbBinding.kt:170:    fun markReady(owner: Authority, value: Boolean, frame: WaAmbientFrame?) {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/HeaderOrbBinding.kt:183:    fun invalidateAmbient(owner: Authority) {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/HeaderOrbBinding.kt:192:    fun restoreAmbient(owner: Authority, packet: String) {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/HeaderOrbBinding.kt:223:    fun setPermanentOrb(enabled: Boolean) {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/OrbCompatibilityFrameRenderer.kt:120:    fun sampleWindow(
android/app/src/main/kotlin/com/fluvi/app/widget/orb/OrbCompatibilityFrameRenderer.kt:136:    private fun sample(colors: IntArray, position: Float): Int {
android/app/src/main/kotlin/com/fluvi/app/widget/orb/OrbCompatibilityFrameRenderer.kt:571:    fun published(
android/app/src/main/kotlin/com/fluvi/app/widget/orb/OrbCompatibilityFrameRenderer.kt:696:        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, OrbFrameSequence>?): Boolean =
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaWindowObservations.kt:6:internal enum class WaWithdrawalCause { APP_WINDOW_PRESENT, PUBLIC_NEGATIVE, USER_PRESENT }
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaWindowObservations.kt:59:    fun snapshot() = result ?: row(WaScanDisposition.IN_FLIGHT, 0)
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaWindowObservations.kt:102:    fun snapshot(): WaWindowSummary {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaWindowObservations.kt:134:    fun attached(owner: WaAttachment, display: Int) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaWindowObservations.kt:147:        if (record.trigger.cause == WaWithdrawalCause.APP_WINDOW_PRESENT) pending = draft
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaWindowObservations.kt:159:    fun confirm(
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:183:    private fun bindChild(frame: OrbRoot, child: WaSurfaceChild) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:195:    private fun embeddingFailed(frame: OrbRoot, child: WaSurfaceChild, reason: String) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:221:    private fun waitForDraw(frame: OrbRoot) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:252:    private fun startEntrance(frame: OrbRoot) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:314:    fun hide(reason: WaHideReason, trigger: WaUnlockTrigger? = null): Long {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:323:                    (reason == WaHideReason.RESTRICTED && it.cause == WaWithdrawalCause.APP_WINDOW_PRESENT))
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:362:    private fun remove(frame: OrbRoot, retry: Boolean) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbWindow.kt:580:        private fun publishNonzero() {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaSurfaceChild.kt:35:    fun attach(visual: View, diameter: Int) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaSurfaceChild.kt:60:    fun withdraw(receipt: ((WaTime) -> Unit)?): WaChildHide {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaSurfaceChild.kt:92:    fun dispose() {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaWakeEpisode.kt:86:    fun admit(state: WaSystemState): Boolean {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaWakeEpisode.kt:105:    fun attached(episode: Long) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaWithdrawalEvidence.kt:19:    fun observe(row: WaTraceRing.Row) {
android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaWithdrawalEvidence.kt:100:    fun probe(owner: WaAttachment, up: Long, begin: Long, end: Long, state: WaSystemState, crossed: Boolean, seq: Long) {
lib/core/debug/debug_console.dart:16:class DebugConsoleDialog extends StatefulWidget {
lib/core/debug/debug_console.dart:17:  const DebugConsoleDialog({
lib/core/debug/debug_console.dart:29:  State<DebugConsoleDialog> createState() => _DebugConsoleDialogState();
lib/core/debug/debug_console.dart:38:class _DebugConsoleDialogState extends State<DebugConsoleDialog> {
lib/core/debug/debug_console.dart:148:      await Clipboard.setData(
lib/core/debug/debug_console.dart:169:      await Clipboard.setData(
lib/core/debug/debug_console.dart:209:      await Clipboard.setData(ClipboardData(text: report));
lib/core/debug/debug_console.dart:254:    await Clipboard.setData(ClipboardData(text: text));
lib/core/debug/debug_console.dart:684:      return const DebugLockscreenCapture();
lib/core/diagnostics/copy_last_unlock.dart:51:          await Clipboard.setData(ClipboardData(text: text));
lib/core/debug/debug_floating_button.dart:11:class DebugFloatingButton extends StatelessWidget {
lib/core/debug/debug_floating_button.dart:12:  const DebugFloatingButton({
lib/core/debug/debug_floating_button.dart:40:              builder: (_) => DebugConsoleDialog(
lib/app/shell/fluvi_app_shell.dart:1490:                                DebugFloatingButton(
lib/core/debug/debug_lockscreen_capture.dart:10:class DebugLockscreenCapture extends StatefulWidget {
lib/core/debug/debug_lockscreen_capture.dart:11:  const DebugLockscreenCapture({super.key});
lib/core/debug/debug_lockscreen_capture.dart:14:  State<DebugLockscreenCapture> createState() => _DebugLockscreenCaptureState();
lib/core/debug/debug_lockscreen_capture.dart:17:class _DebugLockscreenCaptureState extends State<DebugLockscreenCapture>
lib/core/debug/debug_lockscreen_capture.dart:62:  Future<Map<String, Object?>> _request(String method) async =>
lib/core/debug/debug_lockscreen_capture.dart:77:      final status = await _request('status');
lib/core/debug/debug_lockscreen_capture.dart:97:      final status = Map<String, Object?>.of(await _request(method));
lib/core/debug/debug_lockscreen_capture.dart:107:          await Clipboard.setData(ClipboardData(text: text));
```

The settings switch writes a default-off native preference. The WA service gates the separate static window with fresh display and lock state, cached packet identity and its Main-owned ticket. The interactive host keeps the metadata-first application veto and the confirmed ordinary unlock record. Both Copy actions use the native channel. Kotlin has source-navigation coverage only. Physical presentation requires a handset measurement.
