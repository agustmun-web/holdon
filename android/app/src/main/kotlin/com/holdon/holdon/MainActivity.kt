package com.holdon.holdon

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "holdon.device_lock"
    private val VOLUME_CHANNEL = "holdon.volume_monitor"
    private val SERVICE_CHANNEL = "holdon.service_events"
    private var devicePolicyManager: DevicePolicyManager? = null
    private var adminComponent: ComponentName? = null
    private var audioManager: AudioManager? = null
    private var volumeReceiver: VolumeChangeReceiver? = null
    private var antiTheftService: AntiTheftService? = null
    private var serviceStreamHandler: ServiceStreamHandler? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Inicializar DevicePolicyManager
        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        adminComponent = ComponentName(this, DeviceAdminReceiver::class.java)
        
        // Inicializar AudioManager
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "lockDevice" -> {
                    lockDevice(result)
                }
                "requestAdminPermission" -> {
                    requestAdminPermission(result)
                }
                "isAdminActive" -> {
                    result.success(isAdminActive())
                }
                "setAlarmVolumeMax" -> {
                    setAlarmVolumeMax(result)
                }
                "startForegroundService" -> {
                    startForegroundService(call, result)
                }
                "stopForegroundService" -> {
                    stopForegroundService(result)
                }
                "stopAlarm" -> {
                    stopAlarm(result)
                }
                "restartDetection" -> {
                    restartDetection(result)
                }
                "getSensorStatus" -> {
                    getSensorStatus(result)
                }
                "setSensitivityLevel" -> {
                    setSensitivityLevel(call, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Configurar EventChannel para monitoreo de volumen
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, VOLUME_CHANNEL).setStreamHandler(
            VolumeStreamHandler(this)
        )
        
        // Configurar EventChannel para eventos del servicio
        serviceStreamHandler = ServiceStreamHandler(this)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SERVICE_CHANNEL).setStreamHandler(
            serviceStreamHandler
        )
        
        // Obtener referencia al servicio para control de alarma
        antiTheftService = serviceStreamHandler?.antiTheftService
    }

    private fun lockDevice(result: MethodChannel.Result) {
        try {
            if (isAdminActive()) {
                devicePolicyManager?.lockNow()
                result.success("Device locked successfully")
            } else {
                result.error("ADMIN_NOT_ACTIVE", "Device admin permission not granted", null)
            }
        } catch (e: Exception) {
            result.error("LOCK_FAILED", "Failed to lock device: ${e.message}", null)
        }
    }

    private fun requestAdminPermission(result: MethodChannel.Result) {
        try {
            val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
            intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
            intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, 
                "HoldOn needs device admin permission to lock the screen when theft is detected.")
            startActivity(intent)
            result.success("Admin permission request initiated")
        } catch (e: Exception) {
            result.error("PERMISSION_REQUEST_FAILED", "Failed to request admin permission: ${e.message}", null)
        }
    }

    private fun setAlarmVolumeMax(result: MethodChannel.Result) {
        try {
            val audioManager = this.audioManager ?: throw Exception("AudioManager not available")
            
            // Establecer volumen máximo para múltiples streams de audio
            val streamsToMaximize = listOf(
                AudioManager.STREAM_MUSIC,
                AudioManager.STREAM_ALARM,
                AudioManager.STREAM_NOTIFICATION,
                AudioManager.STREAM_RING
            )
            
            var successCount = 0
            for (streamType in streamsToMaximize) {
                try {
                    val maxVolume = audioManager.getStreamMaxVolume(streamType)
                    audioManager.setStreamVolume(streamType, maxVolume, 0)
                    successCount++
                } catch (e: Exception) {
                    // Continuar con otros streams si uno falla
                }
            }
            
            // Asegurar que el modo de sonido esté en NORMAL (no silencioso)
            audioManager.ringerMode = AudioManager.RINGER_MODE_NORMAL
            
            result.success("Volume set to maximum for $successCount streams")
        } catch (e: Exception) {
            result.error("VOLUME_SET_FAILED", "Failed to set volume to maximum: ${e.message}", null)
        }
    }
    
    private fun startForegroundService(call: MethodCall, result: MethodChannel.Result) {
        try {
            val showSensorValues = call.argument<Boolean>("showSensorValues") ?: true
            
            val intent = Intent(this, AntiTheftService::class.java).apply {
                putExtra("showSensorValues", showSensorValues)
            }
            
            startForegroundService(intent)
            
            // Obtener referencia al servicio después de iniciarlo
            // El servicio se conectará automáticamente cuando se cree
            result.success("Foreground service started")
        } catch (e: Exception) {
            result.error("SERVICE_START_FAILED", "Failed to start foreground service: ${e.message}", null)
        }
    }
    
    private fun stopForegroundService(result: MethodChannel.Result) {
        try {
            val intent = Intent(this, AntiTheftService::class.java)
            stopService(intent)
            result.success("Foreground service stopped")
        } catch (e: Exception) {
            result.error("SERVICE_STOP_FAILED", "Failed to stop foreground service: ${e.message}", null)
        }
    }
    
    private fun stopAlarm(result: MethodChannel.Result) {
        try {
            antiTheftService?.stopAlarm()
            result.success("Alarm stopped")
        } catch (e: Exception) {
            result.error("ALARM_STOP_FAILED", "Failed to stop alarm: ${e.message}", null)
        }
    }
    
    private fun restartDetection(result: MethodChannel.Result) {
        try {
            antiTheftService?.restartDetection()
            result.success("Detection restarted")
        } catch (e: Exception) {
            result.error("DETECTION_RESTART_FAILED", "Failed to restart detection: ${e.message}", null)
        }
    }
    
    private fun getSensorStatus(result: MethodChannel.Result) {
        try {
            val status = antiTheftService?.getSensorStatus() ?: mapOf<String, Any>()
            result.success(status)
        } catch (e: Exception) {
            result.error("STATUS_GET_FAILED", "Failed to get sensor status: ${e.message}", null)
        }
    }
    
    private fun setSensitivityLevel(call: MethodCall, result: MethodChannel.Result) {
        try {
            val level = call.argument<String>("level")
            if (level != null) {
                antiTheftService?.updateThresholdsByLevel(level)
                result.success("Sensitivity level set to: $level")
            } else {
                result.error("INVALID_ARGUMENT", "Level parameter is required", null)
            }
        } catch (e: Exception) {
            result.error("SENSITIVITY_SET_FAILED", "Failed to set sensitivity level: ${e.message}", null)
        }
    }
    
    private fun isAdminActive(): Boolean {
        return devicePolicyManager?.isAdminActive(adminComponent!!) ?: false
    }
}
