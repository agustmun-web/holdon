package com.holdon.holdon

import android.app.*
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.AudioManager
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import io.flutter.plugin.common.EventChannel
import kotlin.math.sqrt

class AntiTheftService : Service(), SensorEventListener {
    
    companion object {
        private const val NOTIFICATION_ID = 1
        private const val CHANNEL_ID = "holdon_antitheft_channel"
        private const val TAG = "AntiTheftService"
    }
    
    // Umbrales de detección variables (por defecto NORMAL)
    private var accelerationThreshold = 50.0
    private var gyroscopeThreshold = 9.0
    
    private var sensorManager: SensorManager? = null
    private var accelerometer: Sensor? = null
    private var gyroscope: Sensor? = null
    private var powerManager: PowerManager? = null
    private var wakeLock: PowerManager.WakeLock? = null
    
    private var eventSink: EventChannel.EventSink? = null
    private var showSensorValues = true
    
    // Estado de detección
    private var isActive = false
    private var isAlarmActive = false
    private var accelerometerEventCount = 0
    private var gyroscopeEventCount = 0
    
    
    // Binder para comunicación con la actividad
    private val binder = LocalBinder()
    
    /**
     * Actualiza los umbrales de detección según el nivel de sensibilidad
     * 
     * @param level Nivel de sensibilidad: "BAJA", "NORMAL", o "ALTA"
     */
    fun updateThresholdsByLevel(level: String) {
        when (level.uppercase()) {
            "BAJA" -> {
                // Sensibilidad baja = umbrales altos (más difícil de disparar)
                accelerationThreshold = 80.0
                gyroscopeThreshold = 14.4
                Log.d(TAG, "🔧 Sensibilidad BAJA: Aceleración=${accelerationThreshold}, Giroscopio=${gyroscopeThreshold}")
            }
            "NORMAL" -> {
                // Sensibilidad normal = umbrales intermedios
                accelerationThreshold = 50.0
                gyroscopeThreshold = 9.0
                Log.d(TAG, "🔧 Sensibilidad NORMAL: Aceleración=${accelerationThreshold}, Giroscopio=${gyroscopeThreshold}")
            }
            "ALTA" -> {
                // Sensibilidad alta = umbrales bajos (más fácil de disparar)
                accelerationThreshold = 30.0
                gyroscopeThreshold = 5.4
                Log.d(TAG, "🔧 Sensibilidad ALTA: Aceleración=${accelerationThreshold}, Giroscopio=${gyroscopeThreshold}")
            }
            else -> {
                Log.w(TAG, "⚠️ Nivel de sensibilidad desconocido: $level. Usando NORMAL por defecto.")
                accelerationThreshold = 50.0
                gyroscopeThreshold = 9.0
            }
        }
    }
    
    inner class LocalBinder : Binder() {
        fun getService(): AntiTheftService = this@AntiTheftService
    }
    
    override fun onBind(intent: Intent?): IBinder = binder
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "AntiTheftService onCreate")
        
        // Inicializar sensores
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_LINEAR_ACCELERATION)
        gyroscope = sensorManager?.getDefaultSensor(Sensor.TYPE_GYROSCOPE)
        
        // Inicializar PowerManager para mantener el dispositivo despierto
        powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager?.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "HoldOn::AntiTheftWakeLock"
        )
        
        createNotificationChannel()
        
        // Obtener referencia al ServiceStreamHandler desde MainActivity
        try {
            val mainActivity = this as? MainActivity
            if (mainActivity != null) {
                // Esta es una forma alternativa de obtener la referencia
                Log.d(TAG, "MainActivity reference obtenida")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error al obtener referencia a MainActivity: ${e.message}")
        }
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "AntiTheftService onStartCommand")
        
        // Obtener parámetros del intent
        showSensorValues = intent?.getBooleanExtra("showSensorValues", true) ?: true
        
        // Crear notificación y iniciar como foreground service
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        // Iniciar detección
        startDetection()
        
        return START_STICKY // Reiniciar automáticamente si es terminado
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "AntiTheftService onDestroy")
        
        stopDetection()
        
        // Liberar wake lock de manera segura
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
                Log.d(TAG, "WakeLock liberado correctamente")
            } else {
                Log.d(TAG, "WakeLock no estaba bloqueado")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error al liberar WakeLock: ${e.message}")
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "HoldOn Anti-Theft Detection",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitoreo continuo de sensores para detección de robo"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("HoldOn - Protección Activa")
            .setContentText("Monitoreando sensores para detectar robo")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .build()
    }
    
    fun setEventSink(eventSink: EventChannel.EventSink?) {
        this.eventSink = eventSink
        Log.d(TAG, "EventSink configurado: ${eventSink != null}")
    }
    
    private fun startDetection() {
        if (isActive) {
            Log.d(TAG, "Detección ya está activa - Reiniciando sensores")
            // Desregistrar listeners existentes para evitar duplicados
            sensorManager?.unregisterListener(this)
        }
        
        isActive = true
        accelerometerEventCount = 0
        gyroscopeEventCount = 0
        
        Log.d(TAG, "Iniciando detección - Estado: isActive=$isActive")
        
        // Adquirir wake lock para mantener el dispositivo despierto de manera segura
        try {
            if (wakeLock?.isHeld != true) {
                wakeLock?.acquire(10*60*1000L /*10 minutes*/)
                Log.d(TAG, "WakeLock adquirido correctamente")
            } else {
                Log.d(TAG, "WakeLock ya estaba bloqueado")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error al adquirir WakeLock: ${e.message}")
        }
        
        // Verificar que los sensores estén disponibles
        val hasAccelerometer = accelerometer != null
        val hasGyroscope = gyroscope != null
        Log.d(TAG, "Sensores disponibles - Acelerómetro: $hasAccelerometer, Giroscopio: $hasGyroscope")
        
        // Registrar listeners de sensores
        if (hasAccelerometer) {
            accelerometer?.let { sensor ->
                val success = sensorManager?.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI) ?: false
                Log.d(TAG, "Acelerómetro registrado: $success")
            }
        } else {
            Log.e(TAG, "Acelerómetro no disponible")
        }
        
        if (hasGyroscope) {
            gyroscope?.let { sensor ->
                val success = sensorManager?.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI) ?: false
                Log.d(TAG, "Giroscopio registrado: $success")
            }
        } else {
            Log.e(TAG, "Giroscopio no disponible")
        }
        
        Log.d(TAG, "Detección iniciada completamente")
        ServiceEventManager.sendEvent(mapOf(
            "type" to "service_started",
            "message" to "Servicio de detección iniciado"
        ))
    }
    
    private fun ensureDetectionActive() {
        if (!isActive) {
            Log.d(TAG, "Detección no activa - Reiniciando")
            startDetection()
        } else {
            // Verificar que los sensores estén registrados y funcionando
            val hasAccelerometer = accelerometer != null
            val hasGyroscope = gyroscope != null
            
            if (hasAccelerometer && hasGyroscope) {
                Log.d(TAG, "Sensores verificados - Detección activa")
                
                // Verificar que los listeners estén registrados
                try {
                    // Intentar registrar los sensores nuevamente para asegurar que estén activos
                    accelerometer?.let { sensor ->
                        sensorManager?.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
                        Log.d(TAG, "Acelerómetro re-registrado")
                    }
                    
                    gyroscope?.let { sensor ->
                        sensorManager?.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
                        Log.d(TAG, "Giroscopio re-registrado")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error al re-registrar sensores: ${e.message}")
                }
            } else {
                Log.d(TAG, "Sensores no disponibles - Reiniciando detección")
                startDetection()
            }
        }
    }
    
    private fun reactivateSensorListeners() {
        Log.d(TAG, "Reactivando listeners de sensores específicamente")
        
        // Asegurar que el servicio esté activo
        if (!isActive) {
            Log.d(TAG, "Servicio no activo - Iniciando detección completa")
            startDetection()
            return
        }
        
        // Verificar que los sensores estén disponibles
        val hasAccelerometer = accelerometer != null
        val hasGyroscope = gyroscope != null
        
        if (!hasAccelerometer || !hasGyroscope) {
            Log.e(TAG, "Sensores no disponibles - Acelerómetro: $hasAccelerometer, Giroscopio: $hasGyroscope")
            return
        }
        
        try {
            // Desregistrar listeners existentes para evitar duplicados
            sensorManager?.unregisterListener(this)
            Log.d(TAG, "Listeners existentes desregistrados")
            
            // Registrar nuevamente los listeners de sensores
            accelerometer?.let { sensor ->
                sensorManager?.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
                Log.d(TAG, "Listener de acelerómetro reactivado")
            }
            
            gyroscope?.let { sensor ->
                sensorManager?.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
                Log.d(TAG, "Listener de giroscopio reactivado")
            }
            
            Log.d(TAG, "Listeners de sensores reactivados exitosamente")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error al reactivar listeners de sensores: ${e.message}")
            // En caso de error, intentar reiniciar la detección completa
            startDetection()
        }
    }
    
    private fun stopDetection() {
        if (!isActive) return
        
        isActive = false
        isAlarmActive = false
        
        // Desregistrar listeners de sensores
        sensorManager?.unregisterListener(this)
        
        // NO liberar wake lock aquí - se liberará en onDestroy()
        // wakeLock?.release()
        
        Log.d(TAG, "Detección detenida")
        ServiceEventManager.sendEvent(mapOf(
            "type" to "service_stopped",
            "message" to "Servicio de detección detenido"
        ))
    }
    
    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null) return
        
        // Verificar que la detección esté activa
        if (!isActive) {
            Log.w(TAG, "Evento de sensor recibido pero detección no activa - Reactivando")
            ensureDetectionActive()
            return
        }
        
        // Log para verificar que los sensores están funcionando
        if (event.sensor.type == Sensor.TYPE_LINEAR_ACCELERATION) {
            accelerometerEventCount++
            if (accelerometerEventCount % 50 == 0) { // Log cada 50 eventos para no saturar
                Log.d(TAG, "Acelerómetro funcionando - Evento #$accelerometerEventCount")
            }
        } else if (event.sensor.type == Sensor.TYPE_GYROSCOPE) {
            gyroscopeEventCount++
            if (gyroscopeEventCount % 50 == 0) { // Log cada 50 eventos para no saturar
                Log.d(TAG, "Giroscopio funcionando - Evento #$gyroscopeEventCount")
            }
        }
        
        when (event.sensor.type) {
            Sensor.TYPE_LINEAR_ACCELERATION -> {
                val magnitude = calculateMagnitude(event.values[0], event.values[1], event.values[2])
                
                // Enviar datos de sensor si está habilitado
                if (showSensorValues && accelerometerEventCount % 10 == 0) {
                    ServiceEventManager.sendEvent(mapOf(
                        "type" to "sensor_data",
                        "sensorType" to "accelerometer",
                        "x" to event.values[0],
                        "y" to event.values[1],
                        "z" to event.values[2],
                        "magnitude" to magnitude,
                        "eventCount" to accelerometerEventCount
                    ))
                }
                
                // Verificar umbral
                if (magnitude > accelerationThreshold) {
                    checkForTheftDetection("accelerometer", magnitude)
                }
            }
            
            Sensor.TYPE_GYROSCOPE -> {
                val magnitude = calculateMagnitude(event.values[0], event.values[1], event.values[2])
                
                // Enviar datos de sensor si está habilitado
                if (showSensorValues && gyroscopeEventCount % 10 == 0) {
                    ServiceEventManager.sendEvent(mapOf(
                        "type" to "sensor_data",
                        "sensorType" to "gyroscope",
                        "x" to event.values[0],
                        "y" to event.values[1],
                        "z" to event.values[2],
                        "magnitude" to magnitude,
                        "eventCount" to gyroscopeEventCount
                    ))
                }
                
                // Verificar umbral
                if (magnitude > gyroscopeThreshold) {
                    checkForTheftDetection("gyroscope", magnitude)
                }
            }
        }
    }
    
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // No necesario para esta implementación
    }
    
    private fun calculateMagnitude(x: Float, y: Float, z: Float): Double {
        return sqrt((x * x + y * y + z * z).toDouble())
    }
    
    private fun checkForTheftDetection(sensorType: String, magnitude: Double) {
        if (isAlarmActive) return
        
        Log.d(TAG, "Posible robo detectado: $sensorType, magnitud: $magnitude")
        
        // Activar alarma
        triggerAlarm()
    }
    
    private fun triggerAlarm() {
        if (isAlarmActive) return
        
        isAlarmActive = true
        
        Log.d(TAG, "ALARMA ACTIVADA - ROBO DETECTADO")
        
        // Establecer volumen al máximo inmediatamente al activar la alarma
        setAlarmVolumeMax()
        
        // Enviar evento de alarma a Flutter
        ServiceEventManager.sendEvent(mapOf(
            "type" to "alarm_triggered",
            "message" to "Alarma activada por detección de robo"
        ))
        
        // IMPORTANTE: NO detener la detección - solo marcar alarma como activa
        // Los listeners de sensores continúan funcionando para futuros robos
        // La detección se mantiene activa en segundo plano
        Log.d(TAG, "Detección continúa activa - Listo para futuros robos")
    }
    
    fun stopAlarm() {
        if (!isAlarmActive) return
        
        isAlarmActive = false
        
        Log.d(TAG, "Alarma detenida - Reiniciando detección completa")
        
        // Resetear contadores
        accelerometerEventCount = 0
        gyroscopeEventCount = 0
        
        // Reiniciar completamente la detección para asegurar que funcione
        stopDetection()
        
        // Pequeña pausa para asegurar que los listeners se desregistren completamente
        Thread.sleep(100)
        
        startDetection()
        
        // Enviar evento de detención a Flutter
        ServiceEventManager.sendEvent(mapOf(
            "type" to "alarm_stopped",
            "message" to "Alarma detenida - Sistema reiniciado"
        ))
    }
    
    fun restartDetection() {
        Log.d(TAG, "Reiniciando detección manualmente")
        stopDetection()
        Thread.sleep(200)
        startDetection()
    }
    
    fun getSensorStatus(): Map<String, Any> {
        return mapOf(
            "isActive" to isActive,
            "isAlarmActive" to isAlarmActive,
            "accelerometerAvailable" to (accelerometer != null),
            "gyroscopeAvailable" to (gyroscope != null),
            "accelerometerEventCount" to accelerometerEventCount,
            "gyroscopeEventCount" to gyroscopeEventCount,
            "wakeLockHeld" to (wakeLock?.isHeld ?: false)
        )
    }
    
    private fun setAlarmVolumeMax() {
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            
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
                    Log.e(TAG, "Error al establecer volumen máximo para stream $streamType: ${e.message}")
                }
            }
            
            // Asegurar que el modo de sonido esté en NORMAL (no silencioso)
            audioManager.ringerMode = AudioManager.RINGER_MODE_NORMAL
            
            Log.d(TAG, "Volumen establecido al máximo para $successCount streams")
        } catch (e: Exception) {
            Log.e(TAG, "Error al establecer volumen máximo: ${e.message}")
        }
    }
}
