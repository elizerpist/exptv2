package com.fluvi.app.lockscreen

/** Routes the retained root's normal View click path. Keeping this decision
 * separate makes an accessibility ACTION_CLICK follow the exact same rule as
 * a physical short tap, even after CARD <-> ORB changes on one root. */
internal class KeyguardCardClickRouter(
    private val onCardOpen: () -> Unit,
    private val onOrbTapConsumed: () -> Unit,
) {
    fun onRootClick(presentationMode: KeyguardCardPresentationMode) {
        when (presentationMode) {
            KeyguardCardPresentationMode.CARD -> onCardOpen()
            KeyguardCardPresentationMode.ORB -> onOrbTapConsumed()
        }
    }
}
