package com.example.holdon

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    
    companion object {
        private const val TAG = "MainActivity"
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Registrar el plugin de servicio de ubicación
        flutterEngine.plugins.add(LocationServicePlugin())
        Log.d(TAG, "LocationServicePlugin registrado")
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d(TAG, "MainActivity created")
    }
    
    override fun onResume() {
        super.onResume()
        Log.d(TAG, "MainActivity resumed - Asegurando que el servicio esté activo")
        
        // Asegurar que el servicio de ubicación esté ejecutándose
        ensureLocationServiceRunning()
    }
    
    override fun onPause() {
        super.onPause()
        Log.d(TAG, "MainActivity paused - Servicio continúa en segundo plano")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "MainActivity destroyed - Servicio persiste")
    }
    
    
    /**
     * Asegura que el servicio de ubicación esté ejecutándose
     */
    private fun ensureLocationServiceRunning() {
        try {
            if (!LocationServiceManager.isServiceRunning(this)) {
                Log.d(TAG, "Iniciando servicio de ubicación desde MainActivity")
                
                val intent = Intent(this, LocationForegroundService::class.java).apply {
                    action = LocationForegroundService.ACTION_START_SERVICE
                }
                
                startForegroundService(intent)
            } else {
                Log.d(TAG, "Servicio de ubicación ya está ejecutándose")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error asegurando servicio de ubicación: ${e.message}")
        }
    }
}
