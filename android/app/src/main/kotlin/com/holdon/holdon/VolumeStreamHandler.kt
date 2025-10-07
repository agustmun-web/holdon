package com.holdon.holdon

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import android.util.Log
import io.flutter.plugin.common.EventChannel

class VolumeStreamHandler(private val context: Context) : EventChannel.StreamHandler {
    companion object {
        private const val TAG = "VolumeStreamHandler"
    }
    
    private var eventSink: EventChannel.EventSink? = null
    private var volumeReceiver: VolumeChangeReceiver? = null
    private var isListening = false

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Log.d(TAG, "Iniciando monitoreo de volumen")
        
        eventSink = events
        volumeReceiver = VolumeChangeReceiver(events)
        
        val filter = IntentFilter()
        filter.addAction(AudioManager.RINGER_MODE_CHANGED_ACTION)
        filter.addAction("android.media.VOLUME_CHANGED_ACTION")
        
        try {
            context.registerReceiver(volumeReceiver, filter)
            isListening = true
            Log.d(TAG, "BroadcastReceiver registrado exitosamente")
            
            // Enviar evento de confirmación
            events?.success(mapOf(
                "type" to "volume_monitoring_started",
                "message" to "Monitoreo de volumen iniciado"
            ))
        } catch (e: Exception) {
            Log.e(TAG, "Error al registrar BroadcastReceiver: ${e.message}")
            events?.error("REGISTRATION_ERROR", "Error al registrar receiver de volumen", e.message)
        }
    }

    override fun onCancel(arguments: Any?) {
        Log.d(TAG, "Deteniendo monitoreo de volumen")
        
        eventSink = null
        volumeReceiver?.let { receiver ->
            try {
                if (isListening) {
                    context.unregisterReceiver(receiver)
                    isListening = false
                    Log.d(TAG, "BroadcastReceiver desregistrado exitosamente")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error al desregistrar BroadcastReceiver: ${e.message}")
            }
        }
        volumeReceiver = null
    }
    
    fun isVolumeMonitoringActive(): Boolean {
        return isListening && volumeReceiver != null
    }
}
