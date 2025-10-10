package com.holdon.holdon

import android.app.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.AudioManager
import android.os.Binder
import android.os.Build
import android.os.CountDownTimer
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
    
    // Protocolo de Bolsillo
    private var isPocketProtocolActive = false
    private var pocketTimer: CountDownTimer? = null
    private val POCKET_LUX_THRESHOLD = 1.0f
    
    private var sensorManager: SensorManager? = null
    private var accelerometer: Sensor? = null
    private var gyroscope: Sensor? = null
    private var lightSensor: Sensor? = null
    private var powerManager: PowerManager? = null
    private var wakeLock: PowerManager.WakeLock? = null
    
    // BroadcastReceiver para detectar desbloqueo del dispositivo
    private var userPresentReceiver: BroadcastReceiver? = null
    
    private var eventSink: EventChannel.EventSink? = null
    private var showSensorValues = true
    
    // Estado de detección
    private var isActive = false
    private var isAlarmActive = false
    private var accelerometerEventCount = 0
    private var gyroscopeEventCount = 0
    private var lightSensorEventCount = 0
    
    
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
        lightSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_LIGHT)
        
        // Inicializar BroadcastReceiver para detectar desbloqueo
        userPresentReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == Intent.ACTION_USER_PRESENT) {
                    Log.d(TAG, "Usuario desbloqueó el dispositivo - Cancelando temporizador de bolsillo")
                    cancelPocketTimer()
                }
            }
        }
        
        // Registrar el BroadcastReceiver
        val filter = IntentFilter(Intent.ACTION_USER_PRESENT)
        registerReceiver(userPresentReceiver, filter)
        
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
        
        // Cancelar temporizador de bolsillo si está activo
        cancelPocketTimer()
        
        // Desregistrar BroadcastReceiver
        try {
            userPresentReceiver?.let { receiver ->
                unregisterReceiver(receiver)
                Log.d(TAG, "BroadcastReceiver desregistrado correctamente")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error al desregistrar BroadcastReceiver: ${e.message}")
        }
        
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
            // Desregistrar solo acelerómetro y giroscopio para evitar duplicados
            // El sensor de luz DEBE mantenerse activo
            accelerometer?.let { sensor ->
                sensorManager?.unregisterListener(this, sensor)
            }
            gyroscope?.let { sensor ->
                sensorManager?.unregisterListener(this, sensor)
            }
            Log.d(TAG, "💡 Sensor de Luz MANTENIDO durante reinicio")
        }
        
        isActive = true
        accelerometerEventCount = 0
        gyroscopeEventCount = 0
        lightSensorEventCount = 0
        
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
        val hasLightSensor = lightSensor != null
        Log.d(TAG, "🔍 Verificando sensores disponibles:")
        Log.d(TAG, "🔍 - Acelerómetro: $hasAccelerometer")
        Log.d(TAG, "🔍 - Giroscopio: $hasGyroscope")
        Log.d(TAG, "🔍 - Sensor de Luz: $hasLightSensor")
        
        if (hasLightSensor) {
            Log.d(TAG, "💡 Sensor de Luz detectado y disponible para el Protocolo de Bolsillo")
            Log.d(TAG, "💡 Umbral de luminosidad configurado: ${POCKET_LUX_THRESHOLD} lux")
        } else {
            Log.w(TAG, "⚠️ Sensor de Luz NO disponible - Protocolo de Bolsillo deshabilitado")
        }
        
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
        
        if (hasLightSensor) {
            lightSensor?.let { sensor ->
                val success = sensorManager?.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI) ?: false
                Log.d(TAG, "💡 Sensor de Luz registrado: $success")
                Log.d(TAG, "💡 Sensor de Luz - Nombre: ${sensor.name}, Vendor: ${sensor.vendor}, Max Range: ${sensor.maximumRange}")
                if (success) {
                    Log.d(TAG, "💡 Sensor de Luz LISTO para Protocolo de Bolsillo continuo")
                } else {
                    Log.e(TAG, "❌ Error al registrar Sensor de Luz - Protocolo de Bolsillo deshabilitado")
                }
            }
        } else {
            Log.e(TAG, "❌ Sensor de Luz no disponible en este dispositivo")
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
            val hasLightSensor = lightSensor != null
            
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
                    
                    lightSensor?.let { sensor ->
                        sensorManager?.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
                        Log.d(TAG, "Sensor de Luz re-registrado")
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
        val hasLightSensor = lightSensor != null
        
        if (!hasAccelerometer || !hasGyroscope) {
            Log.e(TAG, "Sensores no disponibles - Acelerómetro: $hasAccelerometer, Giroscopio: $hasGyroscope")
            return
        }
        
        try {
            // Desregistrar solo acelerómetro y giroscopio para evitar duplicados
            // El sensor de luz DEBE mantenerse activo
            accelerometer?.let { sensor ->
                sensorManager?.unregisterListener(this, sensor)
            }
            gyroscope?.let { sensor ->
                sensorManager?.unregisterListener(this, sensor)
            }
            Log.d(TAG, "Acelerómetro y Giroscopio desregistrados")
            Log.d(TAG, "💡 Sensor de Luz MANTENIDO durante reactivación")
            
            // Registrar nuevamente los listeners de sensores
            accelerometer?.let { sensor ->
                sensorManager?.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
                Log.d(TAG, "Listener de acelerómetro reactivado")
            }
            
            gyroscope?.let { sensor ->
                sensorManager?.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
                Log.d(TAG, "Listener de giroscopio reactivado")
            }
            
            lightSensor?.let { sensor ->
                sensorManager?.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
                Log.d(TAG, "Listener de sensor de luz reactivado")
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
        
        // CRÍTICO: Solo desregistrar acelerómetro y giroscopio
        // El sensor de luz DEBE permanecer activo para el Protocolo de Bolsillo
        accelerometer?.let { sensor ->
            sensorManager?.unregisterListener(this, sensor)
            Log.d(TAG, "Acelerómetro desregistrado")
        }
        
        gyroscope?.let { sensor ->
            sensorManager?.unregisterListener(this, sensor)
            Log.d(TAG, "Giroscopio desregistrado")
        }
        
        // NO desregistrar el sensor de luz - debe permanecer activo
        Log.d(TAG, "💡 Sensor de Luz MANTENIDO ACTIVO para Protocolo de Bolsillo")
        
        // NO liberar wake lock aquí - se liberará en onDestroy()
        // wakeLock?.release()
        
        Log.d(TAG, "Detección de movimiento detenida - Protocolo de Bolsillo permanece activo")
        ServiceEventManager.sendEvent(mapOf(
            "type" to "service_stopped",
            "message" to "Servicio de detección detenido"
        ))
    }
    
    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null) return
        
        // CRÍTICO: El sensor de luz debe funcionar INDEPENDIENTEMENTE del estado isActive
        if (event.sensor.type == Sensor.TYPE_LIGHT) {
            // El sensor de luz siempre debe procesarse para el Protocolo de Bolsillo
            handleLightSensorEvent(event)
            return
        }
        
        // Para otros sensores (acelerómetro y giroscopio), verificar que la detección esté activa
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
        } else if (event.sensor.type == Sensor.TYPE_LIGHT) {
            lightSensorEventCount++
            if (lightSensorEventCount % 50 == 0) { // Log cada 50 eventos para no saturar
                Log.d(TAG, "💡 Sensor de Luz funcionando - Evento #$lightSensorEventCount")
            }
            // Log especial para los primeros 5 eventos
            if (lightSensorEventCount <= 5) {
                Log.d(TAG, "💡 [PRIMEROS EVENTOS] Sensor de Luz - Evento #$lightSensorEventCount, Lux: ${event.values[0]}")
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
    
    /**
     * Maneja eventos del sensor de luz de forma INDEPENDIENTE del estado del servicio
     * CRÍTICO: Esta función debe ejecutarse continuamente para el Protocolo de Bolsillo
     */
    private fun handleLightSensorEvent(event: SensorEvent) {
        val lightValue = event.values[0]
        
        // Log detallado del sensor de luz cada 5 eventos para mejor visibilidad
        if (lightSensorEventCount % 5 == 0) {
            Log.d(TAG, "💡 Sensor de Luz - Lux: ${lightValue}, Protocolo Activo: $isPocketProtocolActive, Evento #$lightSensorEventCount")
        }
        
        // Log cada evento para los primeros 20 eventos para verificar funcionamiento
        if (lightSensorEventCount <= 20) {
            Log.d(TAG, "💡 [INICIO] Sensor de Luz - Lux: ${lightValue}, Evento #$lightSensorEventCount")
        }
        
        // Enviar datos de sensor si está habilitado
        if (showSensorValues) {
            ServiceEventManager.sendEvent(mapOf(
                "type" to "sensor_data",
                "sensorType" to "light",
                "lux" to lightValue,
                "isPocketProtocolActive" to isPocketProtocolActive,
                "eventCount" to lightSensorEventCount
            ))
        }
        
        // Lógica del Protocolo de Bolsillo - SIEMPRE se ejecuta
        handlePocketProtocol(lightValue)
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
        lightSensorEventCount = 0
        
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
            "lightSensorAvailable" to (lightSensor != null),
            "accelerometerEventCount" to accelerometerEventCount,
            "gyroscopeEventCount" to gyroscopeEventCount,
            "lightSensorEventCount" to lightSensorEventCount,
            "wakeLockHeld" to (wakeLock?.isHeld ?: false),
            "isPocketProtocolActive" to isPocketProtocolActive,
            "pocketTimerActive" to (pocketTimer != null)
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
    
    /**
     * Maneja la lógica del Protocolo de Bolsillo basado en el sensor de luz
     * IMPORTANTE: Esta función se ejecuta continuamente y debe permitir reactivación indefinida
     */
    private fun handlePocketProtocol(lightValue: Float) {
        when {
            // ACTIVACIÓN DEL PROTOCOLO: Móvil metido en el bolsillo (oscuridad)
            lightValue < POCKET_LUX_THRESHOLD -> {
                if (!isPocketProtocolActive) {
                    // Cancelar cualquier temporizador activo antes de activar
                    cancelPocketTimer()
                    
                    isPocketProtocolActive = true
                    Log.d(TAG, "📱 PROTOCOLO DE BOLSILLO ACTIVADO - Luz: ${lightValue} lux (umbral: ${POCKET_LUX_THRESHOLD} lux)")
                    Log.d(TAG, "📱 Estado: Móvil detectado en bolsillo - Protocolo ARMADO y listo")
                    
                    ServiceEventManager.sendEvent(mapOf(
                        "type" to "pocket_protocol_activated",
                        "message" to "Protocolo de bolsillo activado",
                        "lightValue" to lightValue
                    ))
                } else {
                    // Protocolo ya activo - mantener estado y log ocasional
                    if (lightSensorEventCount % 30 == 0) {
                        Log.d(TAG, "📱 Protocolo MANTENIDO ACTIVO - Móvil en bolsillo: ${lightValue} lux")
                    }
                }
            }
            
            // EVENTO DESENCADENANTE: Móvil sacado del bolsillo (luz)
            lightValue >= POCKET_LUX_THRESHOLD -> {
                if (isPocketProtocolActive) {
                    // CRÍTICO: Desarmar inmediatamente el protocolo
                    isPocketProtocolActive = false
                    
                    Log.d(TAG, "🚨 EVENTO DESENCADENANTE DETECTADO!")
                    Log.d(TAG, "🚨 Móvil sacado del bolsillo - Luz: ${lightValue} lux (umbral: ${POCKET_LUX_THRESHOLD} lux)")
                    Log.d(TAG, "🚨 Protocolo DESARMADO - Iniciando período de gracia de 5 segundos...")
                    
                    // Iniciar temporizador de 5 segundos
                    startPocketTimer()
                    
                    ServiceEventManager.sendEvent(mapOf(
                        "type" to "pocket_protocol_triggered",
                        "message" to "Móvil sacado del bolsillo - Iniciando período de gracia",
                        "lightValue" to lightValue
                    ))
                } else {
                    // Protocolo no activo - log ocasional del estado normal
                    if (lightSensorEventCount % 30 == 0) {
                        Log.d(TAG, "💡 Protocolo INACTIVO - Móvil fuera del bolsillo: ${lightValue} lux (normal)")
                    }
                }
            }
        }
    }
    
    /**
     * Inicia el temporizador de 5 segundos para el Protocolo de Bolsillo
     */
    private fun startPocketTimer() {
        // Cancelar temporizador existente si hay uno
        cancelPocketTimer()
        
        Log.d(TAG, "⏰ Iniciando temporizador de 5 segundos para Protocolo de Bolsillo")
        
        pocketTimer = object : CountDownTimer(5000, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val secondsRemaining = (millisUntilFinished / 1000).toInt()
                Log.d(TAG, "⏰ Temporizador de bolsillo: ${secondsRemaining} segundos restantes")
                
                ServiceEventManager.sendEvent(mapOf(
                    "type" to "pocket_timer_tick",
                    "secondsRemaining" to secondsRemaining,
                    "message" to "Período de gracia: ${secondsRemaining} segundos")
                )
            }
            
            override fun onFinish() {
                Log.d(TAG, "🚨 TEMPORIZADOR FINALIZADO - Disparando alarma por Protocolo de Bolsillo")
                
                ServiceEventManager.sendEvent(mapOf(
                    "type" to "pocket_timer_finished",
                    "message" to "Período de gracia finalizado - Alarma activada")
                )
                
                // Disparar la alarma principal
                triggerAlarm()
                
                pocketTimer = null
            }
        }
        
        pocketTimer?.start()
        
        ServiceEventManager.sendEvent(mapOf(
            "type" to "pocket_timer_started",
            "message" to "Período de gracia iniciado - 5 segundos")
        )
    }
    
    /**
     * Cancela el temporizador del Protocolo de Bolsillo
     */
    private fun cancelPocketTimer() {
        pocketTimer?.let { timer ->
            timer.cancel()
            pocketTimer = null
            Log.d(TAG, "✅ Temporizador de bolsillo cancelado por desbloqueo del dispositivo")
            
            ServiceEventManager.sendEvent(mapOf(
                "type" to "pocket_timer_cancelled",
                "message" to "Temporizador cancelado - Usuario desbloqueó el dispositivo")
            )
        }
    }
}