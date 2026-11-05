package com.fluvi.app.lockscreen

import android.view.View
import android.widget.TextView
import com.fluvi.app.R

/**
 * The compact card deliberately has no scroll area.  Optional detail yields
 * before focus and the primary value when the user's font scale consumes the
 * fixed 120dp content box.
 */
internal object KeyguardCardContentOverflow {
    /** Returns whether a visibility change requires one follow-up layout pass. */
    fun fit(root: View): Boolean {
        val content = root.findViewById<View>(R.id.fluvi_financial_snapshot_content)
        val primary = root.findViewById<TextView>(R.id.fluvi_financial_snapshot_primary)
        val secondary = root.findViewById<TextView>(R.id.fluvi_financial_snapshot_secondary)
        val event = root.findViewById<TextView>(R.id.fluvi_financial_snapshot_event)

        // The footer is lowest priority.  Its RelativeLayout anchor makes its
        // bounds authoritative after the real parent has completed layout.
        if (event.visibility == View.VISIBLE && event.top < secondary.bottom) {
            event.visibility = View.GONE
            return true
        }
        // If hiding the footer did not leave a complete secondary line, hide
        // that optional explanation rather than clipping or growing the card.
        if (
            secondary.visibility == View.VISIBLE &&
                (secondary.top < primary.bottom || secondary.bottom > content.bottom - content.paddingBottom)
        ) {
            secondary.visibility = View.GONE
            return true
        }
        return false
    }
}
