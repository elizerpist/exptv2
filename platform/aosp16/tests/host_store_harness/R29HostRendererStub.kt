package com.android.systemui.keyguard.fluvi
import com.fluvi.r29.contract.R29Descriptor
internal class R29PreparedOrb(val descriptor: R29Descriptor)
internal class R29HostRenderer {
    var pending: ((Result<R29PreparedOrb>) -> Unit)? = null
    fun prepare(descriptor: R29Descriptor, done: (Result<R29PreparedOrb>) -> Unit) { pending = done }
}
