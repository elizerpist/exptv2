package com.fluvi.app

import io.flutter.plugin.common.StandardMethodCodec

/**
 * Adapts native automation results at the platform boundary. Core use cases
 * correctly use Kotlin [Unit] for successful commands without a domain
 * payload, but Unit itself is not a StandardMethodCodec value.
 */
internal fun automationMethodChannelResponse(value: Any?): Any? {
    val response = if (value === Unit) null else value
    // Preflight the exact envelope before a MethodChannel.Result is answered.
    // This turns an unsupported transport object into one controlled error,
    // instead of letting a reply encoding exception escape after a committed
    // database mutation.
    StandardMethodCodec.INSTANCE.encodeSuccessEnvelope(response)
    return response
}
