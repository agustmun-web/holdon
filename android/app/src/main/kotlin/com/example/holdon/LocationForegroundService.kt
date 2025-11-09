package com.example.holdon

import android.app.*
import android.content.Context
import android.content.Intent
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import java.util.concurrent.TimeUnit

/**
 * Servicio de Primer Plano personalizado para mantener el geofencing activo
 * incluso cuando la aplicación está cerrada o en segundo plano
 */
class LocationForegroundService : Service(), LocationListener {
    
    companion object {
        private const val TAG = "LocationForegroundService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "location_foreground_channel"
        private const val CHANNEL_NAME = "Ubicación en Tiempo Real"
        private const val CHANNEL_DESCRIPTION = "Monitoreo continuo de ubicación para geofencing"
        
        // Acciones
        const val ACTION_START_SERVICE = "START_LOCATION_SERVICE"
        const val ACTION_STOP_SERVICE = "STOP_LOCATION_SERVICE"
        const val ACTION_UPDATE_LOCATION = "UPDATE_LOCATION"
        
        // Parámetros
        private const val LOCATION_INTERVAL = 5000L // 5 segundos
        private const val LOCATION_FASTEST_INTERVAL = 2000L // 2 segundos
        private const val LOCATION_DISTANCE = 5f // 5 metros
    }
    
    private lateinit var locationManager: LocationManager
    private val binder = LocationBinder()
    private var isServiceRunning = false
    private var lastKnownLocation: Location? = null
    
    inner class LocationBinder : Binder() {
        fun getService(): LocationForegroundService = this@LocationForegroundService
    }
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Servicio de ubicación creado")
        
        initializeLocationServices()
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_SERVICE -> {
                startForegroundLocationService()
            }
            ACTION_STOP_SERVICE -> {
                stopForegroundLocationService()
            }
            ACTION_UPDATE_LOCATION -> {
                requestLocationUpdate()
            }
        }
        return START_STICKY // Reiniciar automáticamente si es terminado
    }
    
    override fun onBind(intent: Intent?): IBinder = binder
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Servicio de ubicación destruido")
        stopLocationUpdates()
        isServiceRunning = false
    }
    
    /**
     * Inicializa los servicios de ubicación
     */
    private fun initializeLocationServices() {
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        Log.d(TAG, "Servicios de ubicación inicializados")
    }
    
    /**
     * Crea el canal de notificación
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = CHANNEL_DESCRIPTION
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
                setSound(null, null)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * Inicia el servicio en primer plano
     */
    private fun startForegroundLocationService() {
        if (isServiceRunning) {
            Log.d(TAG, "Servicio ya está ejecutándose")
            return
        }
        
        Log.d(TAG, "Iniciando servicio de ubicación en primer plano")
        
        // Crear notificación persistente
        val notification = createForegroundNotification()
        
        // Iniciar en primer plano
        startForeground(NOTIFICATION_ID, notification)
        
        // Iniciar actualizaciones de ubicación
        startLocationUpdates()
        
        isServiceRunning = true
        Log.d(TAG, "Servicio de ubicación iniciado correctamente")
    }
    
    /**
     * Detiene el servicio en primer plano
     */
    private fun stopForegroundLocationService() {
        Log.d(TAG, "Deteniendo servicio de ubicación")
        
        stopLocationUpdates()
        stopForeground(true)
        stopSelf()
        
        isServiceRunning = false
    }
    
    /**
     * Crea la notificación persistente para el servicio en primer plano
     */
    private fun createForegroundNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("HoldOn - Monitoreo Activo")
            .setContentText("Geofencing funcionando en segundo plano")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
    
    /**
     * Inicia las actualizaciones de ubicación
     */
    private fun startLocationUpdates() {
        try {
            // Verificar permisos de ubicación
            if (!hasLocationPermission()) {
                Log.e(TAG, "No se tienen permisos de ubicación")
                return
            }
            
            // Iniciar con LocationManager nativo
            locationManager.requestLocationUpdates(
                LocationManager.GPS_PROVIDER,
                LOCATION_INTERVAL,
                LOCATION_DISTANCE,
                this,
                Looper.getMainLooper()
            )
            
            locationManager.requestLocationUpdates(
                LocationManager.NETWORK_PROVIDER,
                LOCATION_INTERVAL,
                LOCATION_DISTANCE,
                this,
                Looper.getMainLooper()
            )
            
            Log.d(TAG, "Actualizaciones de ubicación iniciadas")
            
        } catch (e: SecurityException) {
            Log.e(TAG, "Error de seguridad al iniciar ubicación: ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "Error al iniciar actualizaciones de ubicación: ${e.message}")
        }
    }
    
    /**
     * Detiene las actualizaciones de ubicación
     */
    private fun stopLocationUpdates() {
        try {
            locationManager.removeUpdates(this)
            Log.d(TAG, "Actualizaciones de ubicación detenidas")
        } catch (e: Exception) {
            Log.e(TAG, "Error al detener actualizaciones de ubicación: ${e.message}")
        }
    }
    
    /**
     * Solicita una actualización de ubicación inmediata
     */
    private fun requestLocationUpdate() {
        try {
            if (!hasLocationPermission()) {
                Log.e(TAG, "No se tienen permisos de ubicación")
                return
            }
            
            // Obtener última ubicación conocida
            val gpsLocation = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            val networkLocation = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
            
            val location = gpsLocation ?: networkLocation
            location?.let {
                lastKnownLocation = it
                onLocationChanged(it)
                Log.d(TAG, "Ubicación actual solicitada: ${it.latitude}, ${it.longitude}")
            }
            
        } catch (e: SecurityException) {
            Log.e(TAG, "Error de seguridad al solicitar ubicación: ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "Error al solicitar ubicación: ${e.message}")
        }
    }
    
    /**
     * Verifica si se tienen permisos de ubicación
     */
    private fun hasLocationPermission(): Boolean {
        return checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) == 
               android.content.pm.PackageManager.PERMISSION_GRANTED ||
               checkSelfPermission(android.Manifest.permission.ACCESS_COARSE_LOCATION) == 
               android.content.pm.PackageManager.PERMISSION_GRANTED
    }
    
    /**
     * Callback cuando cambia la ubicación
     */
    override fun onLocationChanged(location: Location) {
        // Aquí puedes agregar lógica adicional para procesar la ubicación
        // Por ejemplo, verificar geofences manualmente o enviar datos a Flutter
        Log.d(TAG, "Nueva ubicación: ${location.latitude}, ${location.longitude}")
    }
    
    /**
     * Obtiene la última ubicación conocida
     */
    fun getLastKnownLocation(): Location? = lastKnownLocation
    
    /**
     * Verifica si el servicio está ejecutándose
     */
    fun isRunning(): Boolean = isServiceRunning
}

