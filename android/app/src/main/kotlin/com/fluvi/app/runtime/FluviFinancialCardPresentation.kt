package com.fluvi.app.runtime

import android.graphics.Bitmap
import android.graphics.Color

/**
 * The only presentation boundary shared by the RemoteViews widget and the
 * native keyguard overlay.  Privacy is resolved before a renderer receives
 * fields, so a discreet renderer cannot accidentally retain a prior full
 * amount, partner, category, score, or state colour.
 */
internal data class FluviFinancialCardPresentation(
    val focus: String,
    val primary: String,
    val secondary: String,
    val event: String?,
    val eventLabel: String?,
    val contentDescription: String,
    val orb: Bitmap,
    val showToggle: Boolean,
    val toggleLabel: String,
    val full: Boolean,
    /** Stable rendered-input identity. Bitmap allocation identity is not a
     * visual change and must never trigger an accessibility-window update. */
    val visualKey: String,
)

internal object FluviFinancialCardPresenter {
    private val neutral = FluviLockScreenCardContent(
        focus = "Fluvi",
        primary = "",
        secondary = "",
        event = null,
        eventLabel = null,
        accentColor = Color.rgb(70, 105, 157),
        available = true,
    )

    fun discreet(): FluviFinancialCardPresentation = FluviFinancialCardPresentation(
        focus = "Fluvi · Pénzügyi pillanatkép",
        primary = "Pénzügyi pillanatkép",
        secondary = "A részletek feloldás után láthatók",
        event = null,
        eventLabel = null,
        contentDescription = "Fluvi · Pénzügyi pillanatkép",
        orb = neutral.orbBitmap(),
        showToggle = false,
        toggleLabel = "",
        full = false,
        visualKey = "discreet:v1",
    )

    fun loading(): FluviFinancialCardPresentation = FluviFinancialCardPresentation(
        focus = "Fluvi · Pénzügyi pillanatkép",
        primary = "Adatok frissítése",
        secondary = "A kiválasztott fókusz betöltése folyamatban van",
        event = null,
        eventLabel = null,
        contentDescription = "Fluvi pénzügyi pillanatkép",
        orb = neutral.orbBitmap(),
        showToggle = false,
        toggleLabel = "",
        full = true,
        visualKey = "loading:v1",
    )

    /**
     * A persisted invalid keyguard focus is not a transient loading state.
     * Keep the card useful without repeatedly starting a resolver that cannot
     * succeed (for example, an old Budget choice without a category).
     *
     * This contains no financial value. The code is deliberately mapped to a
     * short user-facing state here instead of exposing an exception message.
     */
    fun unavailable(code: String): FluviFinancialCardPresentation = FluviFinancialCardPresentation(
        focus = "Fluvi · Pénzügyi pillanatkép",
        primary = "A kártya fókusza hiányos",
        secondary = when (code) {
            "missingCategory" -> "Válassz Budget kategóriát a Fluviban"
            else -> "Nyisd meg a Fluvit a kártya beállításához"
        },
        event = null,
        eventLabel = null,
        contentDescription = "Fluvi pénzügyi pillanatkép: a kártya fókusza hiányos",
        orb = neutral.orbBitmap(),
        showToggle = false,
        toggleLabel = "",
        full = true,
        visualKey = "unavailable:v1:$code",
    )

    fun full(content: FluviLockScreenCardContent, showEvent: Boolean): FluviFinancialCardPresentation {
        val eventIsPrimary = showEvent && content.event != null
        return FluviFinancialCardPresentation(
            focus = content.focus,
            primary = if (eventIsPrimary) requireNotNull(content.event) else content.primary,
            secondary = if (eventIsPrimary) content.eventLabel ?: "Utolsó tétel" else content.secondary,
            event = if (eventIsPrimary) null else content.event,
            eventLabel = if (eventIsPrimary) null else content.eventLabel,
            contentDescription = content.focus,
            orb = content.orbBitmap(),
            showToggle = content.event != null,
            toggleLabel = if (eventIsPrimary) "Fő érték" else "Utolsó tétel",
            full = true,
            visualKey = listOf(
                "full:v1",
                content.focus,
                content.primary,
                content.secondary,
                content.event.orEmpty(),
                content.eventLabel.orEmpty(),
                content.accentColor.toString(),
                eventIsPrimary.toString(),
            ).joinToString("\u001f"),
        )
    }
}
