package com.holdon.holdon

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.util.Log
import io.flutter.plugin.common.EventChannel

class VolumeChangeReceiver(private val eventSink: EventChannel.EventSink?) : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "VolumeChangeReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Recibido broadcast: ${intent.action}")
        
        when (intent.action) {
            AudioManager.RINGER_MODE_CHANGED_ACTION -> {
                // Modo de sonido cambió (normal, vibrar, silencio)
                val ringerMode = intent.getIntExtra(AudioManager.EXTRA_RINGER_MODE, AudioManager.RINGER_MODE_NORMAL)
                val ringerModeText = when (ringerMode) {
                    AudioManager.RINGER_MODE_NORMAL -> "NORMAL"
                    AudioManager.RINGER_MODE_VIBRATE -> "VIBRAR"
                    AudioManager.RINGER_MODE_SILENT -> "SILENCIO"
                    else -> "DESCONOCIDO"
                }
                
                Log.d(TAG, "Modo de sonido cambió a: $ringerModeText")
                
                eventSink?.success(mapOf(
                    "type" to "ringer_mode_changed",
                    "ringerMode" to ringerMode,
                    "ringerModeText" to ringerModeText
                ))
            }
            "android.media.VOLUME_CHANGED_ACTION" -> {
                // Volumen de algún stream cambió
                val streamType = intent.getIntExtra("android.media.EXTRA_VOLUME_STREAM_TYPE", AudioManager.STREAM_MUSIC)
                val volume = intent.getIntExtra("android.media.EXTRA_VOLUME_STREAM_VALUE", 0)
                val previousVolume = intent.getIntExtra("android.media.EXTRA_PREV_VOLUME_STREAM_VALUE", 0)
                
                val streamTypeText = when (streamType) {
                    AudioManager.STREAM_MUSIC -> "MÚSICA"
                    AudioManager.STREAM_RING -> "LLAMADA"
                    AudioManager.STREAM_NOTIFICATION -> "NOTIFICACIÓN"
                    AudioManager.STREAM_ALARM -> "ALARMA"
                    AudioManager.STREAM_SYSTEM -> "SISTEMA"
                    else -> "DESCONOCIDO"
                }
                
                Log.d(TAG, "Volumen $streamTypeText cambió: $previousVolume -> $volume")
                
                eventSink?.success(mapOf(
                    "type" to "volume_changed",
                    "streamType" to streamType,
                    "streamTypeText" to streamTypeText,
                    "volume" to volume,
                    "previousVolume" to previousVolume,
                    "volumeDecreased" to (volume < previousVolume)
                ))
            }
            else -> {
                Log.d(TAG, "Acción de broadcast no manejada: ${intent.action}")
            }
        }
    }
}
