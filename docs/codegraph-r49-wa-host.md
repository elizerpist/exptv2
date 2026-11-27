# R49 source inventory

Application `a614bf74f7a0b17d3ebc822daf167fba331ee6af`

The SCIP index covers Dart. Kotlin, Gradle and the merged Android ownership are traced through the sources below.

The vendored WA tree is `d00525e0c97815cbdf1c46ef806fffbd2100b10e`. The provider delivers to AppWidgetManager. The upstream host owns its frame and window.

```text
android/app/src/main/AndroidManifest.xml:24:            android:name="com.fluvi.app.runtime.FluviWidgetStartupProvider"
android/app/src/main/AndroidManifest.xml:78:            android:name=".widget.orb.FluviHeaderOrbWidgetProvider"
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:72:import com.fluvi.app.widget.orb.HeaderOrbWidgetContent
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1103:                        runCatching { startActivity(HeaderOrbWidgetContent.setupIntent(this)) }
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1109:                    HeaderOrbWidgetContent.execute {
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1112:                                "status" -> HeaderOrbWidgetContent.status(application)
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1114:                                    HeaderOrbWidgetContent.setSharing(application, call.arguments as Boolean)
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1117:                                "prepare" -> HeaderOrbWidgetContent.prepare(
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1122:                                    HeaderOrbWidgetContent.unavailable(call.argument("token"))
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1125:                                "publish" -> HeaderOrbWidgetContent.publish(
android/app/src/main/kotlin/com/fluvi/app/runtime/RetiredLockscreenState.kt:9:import com.fluvi.app.widget.orb.HeaderOrbWidgetContent
android/app/src/main/kotlin/com/fluvi/app/runtime/RetiredLockscreenState.kt:13:class FluviWidgetStartupProvider : ContentProvider() {
android/app/src/main/kotlin/com/fluvi/app/runtime/RetiredLockscreenState.kt:18:        HeaderOrbWidgetContent.execute { HeaderOrbWidgetContent.refresh(application) }
50:    private fun refresh(context: Context, ids: IntArray) {
103:    fun setSharing(context: Context, sharing: Boolean) {
118:    fun prepare(context: Context, mode: String, signature: String): Map<String, Any> {
143:    fun publish(
179:    fun refresh(context: Context, requested: IntArray = widgetIds(context)) {
210:            manager.updateAppWidget(id, views)
251:internal data class HeaderOrbPackage(
272:    fun decode(): List<Bitmap> = pngs.map { png ->
171:internal object FluviFinancialSnapshotWidgetCoordinator {
201:                runCatching { FinancialSnapshotQueries.resolve(application, current.asFinancialFocus()) }.getOrNull()
261:        val categories = FinancialSnapshotQueries.categories(application, current.direction)
263:            runCatching { FinancialSnapshotQueries.resolve(application, current.asFinancialFocus()) }
288:        FluviFinancialSnapshotWidgetCoordinator.onWidgetsChanged(context)
293:        FluviFinancialSnapshotWidgetCoordinator.onWidgetsChanged(context)
303:        FluviFinancialSnapshotWidgetCoordinator.refreshAsync(context, "optionsChanged")
308:        FluviFinancialSnapshotWidgetCoordinator.onWidgetsChanged(context)
312:        FluviFinancialSnapshotWidgetCoordinator.onWidgetsChanged(context)
319:            val configuration = FluviFinancialSnapshotWidgetCoordinator.configuration(context)
339:            renderCached(context, manager, FluviFinancialSnapshotWidgetCoordinator.ids(context))
345:            val configuration = FluviFinancialSnapshotWidgetCoordinator.configuration(application)
200:  late final DashboardHeaderWidgetPublisher _headerWidgetPublisher;
347:    _headerWidgetPublisher = DashboardHeaderWidgetPublisher(
524:      _headerWidgetPublisher.refresh();
1113:    _headerWidgetPublisher.dispose();
1232:        _headerWidgetPublisher.updateHeaderGeometry(
```
