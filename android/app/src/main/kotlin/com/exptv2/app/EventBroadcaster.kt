package com.exptv2.app

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

object EventBroadcaster {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var sink: EventChannel.EventSink? = null

    fun attach(eventSink: EventChannel.EventSink?) {
        mainHandler.post { sink = eventSink }
    }

    fun detach() {
        mainHandler.post { sink = null }
    }

    fun publish(event: NotificationEventEntity) {
        val payload = event.toMap()
        mainHandler.post { sink?.success(payload) }
    }
}
