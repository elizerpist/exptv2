package tk.zwander.lockscreenwidgets.services

import android.content.Intent
import com.fluvi.app.widget.orb.HeaderOrbBinding
import com.fluvi.wa.WaHideReason
import com.fluvi.wa.WaLockscreenService
import com.fluvi.wa.WaOrbWindow

/** Stable component name so an R49 update preserves the system's service setting. */
class Accessibility : WaLockscreenService() {
    private val binding by lazy { HeaderOrbBinding.get(this) }
    private val orb by lazy { WaOrbWindow(this, binding.host, binding::savePlacement) }
    private var stopObserving: (() -> Unit)? = null
    private var observedId: Int? = null

    override fun onServiceConnected() {
        binding.connected()
        orb.prepareStyles()
        super.onServiceConnected()
        stopObserving?.invoke()
        stopObserving = binding.observe {
            val id = binding.readyId()
            val changed = id != observedId
            observedId = id
            if (changed || id != null) orbContentChanged(changed)
        }
    }

    override fun contentAvailable() = binding.readyId() != null

    override fun orbOwner() = orb.owner

    override fun hasOrbAttachment() = orb.hasAttachment

    override fun ownsOrbEvent(windowId: Int) = orb.ownsEvent(windowId)

    override fun showOrb(episode: Long, animate: Boolean): Boolean {
        val id = binding.readyId() ?: return false
        val info = binding.binding(id) ?: return false
        val dp = binding.sizeDp()
        return orb.show(session, episode, id, info, dp, binding.placement(), animate, binding.style(dp)) {
            entranceAllowed(episode)
        }
    }

    override fun hideOrb(reason: WaHideReason) = orb.hide(reason)

    override fun geometryChanged() {
        val dp = binding.sizeDp()
        orb.resize(dp, binding.style(dp))
    }

    override fun onUnbind(intent: Intent?): Boolean {
        stopObserving?.invoke()
        stopObserving = null
        observedId = null
        val result = super.onUnbind(intent)
        binding.syncService()
        return result
    }

    override fun onDestroy() {
        stopObserving?.invoke()
        stopObserving = null
        super.onDestroy()
    }
}
