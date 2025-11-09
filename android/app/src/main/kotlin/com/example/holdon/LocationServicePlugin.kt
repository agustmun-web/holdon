package com.example.holdon

import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Plugin para comunicación entre Flutter y el servicio de ubicación nativo
 */
class LocationServicePlugin : FlutterPlugin, MethodCallHandler {
    
    companion object {
        private const val TAG = "LocationServicePlugin"
        private const val CHANNEL_NAME = "holdon/location_service"
    }
    
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var locationService: LocationForegroundService? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        
        Log.d(TAG, "LocationServicePlugin attached to engine")
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startLocationService" -> {
                startLocationService(result)
            }
            "stopLocationService" -> {
                stopLocationService(result)
            }
            "isLocationServiceRunning" -> {
                isLocationServiceRunning(result)
            }
            "requestLocationUpdate" -> {
                requestLocationUpdate(result)
            }
            "getLastKnownLocation" -> {
                getLastKnownLocation(result)
            }
            "getServiceStatus" -> {
                getServiceStatus(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun startLocationService(result: Result) {
        try {
            Log.d(TAG, "Starting location service from Flutter")
            
            val intent = Intent(context, LocationForegroundService::class.java).apply {
                action = LocationForegroundService.ACTION_START_SERVICE
            }
            
            context.startForegroundService(intent)
            
            result.success(true)
            Log.d(TAG, "Location service started successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error starting location service: ${e.message}")
            result.error("START_SERVICE_ERROR", e.message, null)
        }
    }

    private fun stopLocationService(result: Result) {
        try {
            Log.d(TAG, "Stopping location service from Flutter")
            
            val intent = Intent(context, LocationForegroundService::class.java).apply {
                action = LocationForegroundService.ACTION_STOP_SERVICE
            }
            
            context.startService(intent)
            
            result.success(true)
            Log.d(TAG, "Location service stopped successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping location service: ${e.message}")
            result.error("STOP_SERVICE_ERROR", e.message, null)
        }
    }

    private fun isLocationServiceRunning(result: Result) {
        try {
            // Verificar si el servicio está ejecutándose
            val isRunning = LocationServiceManager.isServiceRunning(context)
            
            Log.d(TAG, "Location service running status: $isRunning")
            result.success(isRunning)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error checking service status: ${e.message}")
            result.error("CHECK_SERVICE_ERROR", e.message, null)
        }
    }

    private fun requestLocationUpdate(result: Result) {
        try {
            Log.d(TAG, "Requesting location update from Flutter")
            
            val intent = Intent(context, LocationForegroundService::class.java).apply {
                action = LocationForegroundService.ACTION_UPDATE_LOCATION
            }
            
            context.startService(intent)
            
            result.success(true)
            Log.d(TAG, "Location update requested successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error requesting location update: ${e.message}")
            result.error("UPDATE_LOCATION_ERROR", e.message, null)
        }
    }

    private fun getLastKnownLocation(result: Result) {
        try {
            val location = LocationServiceManager.getLastKnownLocation(context)
            
            if (location != null) {
                val locationData = mapOf(
                    "latitude" to location.latitude,
                    "longitude" to location.longitude,
                    "accuracy" to location.accuracy,
                    "time" to location.time,
                    "altitude" to (location.altitude ?: 0.0),
                    "speed" to (location.speed ?: 0.0f)
                )
                
                Log.d(TAG, "Last known location: ${location.latitude}, ${location.longitude}")
                result.success(locationData)
            } else {
                Log.d(TAG, "No last known location available")
                result.success(null)
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error getting last known location: ${e.message}")
            result.error("GET_LOCATION_ERROR", e.message, null)
        }
    }

    private fun getServiceStatus(result: Result) {
        try {
            val status = LocationServiceManager.getServiceStatus(context)
            Log.d(TAG, "Service status: $status")
            result.success(status)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error getting service status: ${e.message}")
            result.error("GET_STATUS_ERROR", e.message, null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        Log.d(TAG, "LocationServicePlugin detached from engine")
    }
}

/**
 * Manager para gestionar el estado del servicio de ubicación
 */
object LocationServiceManager {
    private const val TAG = "LocationServiceManager"
    
    fun isServiceRunning(context: Context): Boolean {
        return try {
            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
            val runningServices = activityManager.getRunningServices(Integer.MAX_VALUE)
            
            runningServices.any { serviceInfo ->
                serviceInfo.service.className == LocationForegroundService::class.java.name
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking if service is running: ${e.message}")
            false
        }
    }
    
    fun getLastKnownLocation(context: Context): android.location.Location? {
        return try {
            // Intentar obtener la ubicación del servicio si está disponible
            // En una implementación real, esto se comunicaría con el servicio
            null
        } catch (e: Exception) {
            Log.e(TAG, "Error getting last known location: ${e.message}")
            null
        }
    }
    
    fun getServiceStatus(context: Context): Map<String, Any> {
        return mapOf(
            "isRunning" to isServiceRunning(context),
            "lastKnownLocation" to (getLastKnownLocation(context) ?: ""),
            "timestamp" to System.currentTimeMillis()
        )
    }
}
