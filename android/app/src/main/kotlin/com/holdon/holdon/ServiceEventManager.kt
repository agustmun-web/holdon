package com.holdon.holdon

import io.flutter.plugin.common.EventChannel

object ServiceEventManager {
    private var eventSink: EventChannel.EventSink? = null
    
    fun setEventSink(eventSink: EventChannel.EventSink?) {
        this.eventSink = eventSink
    }
    
    fun sendEvent(event: Map<String, Any>) {
        eventSink?.success(event)
    }
    
    fun sendError(errorCode: String, errorMessage: String, errorDetails: String?) {
        eventSink?.error(errorCode, errorMessage, errorDetails)
    }
}




