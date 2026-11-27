package tk.zwander.lockscreenwidgets.services

import android.content.Intent
import com.fluvi.app.widget.orb.HeaderOrbBinding
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
        super.onServiceConnected()
        stopObserving?.invoke()
        stopObserving = binding.observe {
            val id = binding.readyId()
            if (id != observedId) {
                observedId = id
                refreshScene("content")
            } else if (id != null) {
                orb.resize(binding.sizeDp())
            }
        }
    }

    override fun contentAvailable() = binding.readyId() != null

    override fun hasOrb() = orb.attached

    override fun showOrb() {
        val id = binding.readyId() ?: return
        val info = binding.binding(id) ?: return
        orb.show(session, id, info, binding.sizeDp(), binding.placement())
    }

    override fun hideOrb(reason: String) = orb.hide(reason)

    override fun geometryChanged() = orb.resize(binding.sizeDp())

    override fun onUnbind(intent: Intent?): Boolean {
        stopObserving?.invoke()
        stopObserving = null
        observedId = null
        binding.syncService()
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        stopObserving?.invoke()
        stopObserving = null
        super.onDestroy()
    }
}
