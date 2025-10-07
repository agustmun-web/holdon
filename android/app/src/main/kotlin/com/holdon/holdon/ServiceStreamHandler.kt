package com.holdon.holdon

import android.content.Context
import io.flutter.plugin.common.EventChannel

class ServiceStreamHandler(private val context: Context) : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private var _antiTheftService: AntiTheftService? = null

    val antiTheftService: AntiTheftService?
        get() = _antiTheftService

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        
        // Configurar el singleton para enviar eventos
        ServiceEventManager.setEventSink(events)
        
        // Obtener referencia al servicio si está ejecutándose
        _antiTheftService?.setEventSink(events)
        
        // Enviar evento de confirmación
        events?.success(mapOf(
            "type" to "stream_handler_ready",
            "message" to "Service stream handler ready"
        ))
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        ServiceEventManager.setEventSink(null)
        _antiTheftService?.setEventSink(null)
    }

    fun setAntiTheftService(service: AntiTheftService?) {
        _antiTheftService = service
        service?.setEventSink(eventSink)
    }
}