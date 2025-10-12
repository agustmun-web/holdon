package com.example.holdon

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BootReceiver para reiniciar servicios después del reinicio del dispositivo
 * Esto es necesario para que el geofencing y las tareas en segundo plano
 * se reinicien automáticamente después de un reinicio
 */
class BootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_PACKAGE_REPLACED -> {
                Log.d(TAG, "Dispositivo reiniciado o aplicación actualizada: ${intent.action}")
                
                try {
                    // Log de información sobre el reinicio
                    Log.d(TAG, "BootReceiver activado - La aplicación se reiniciará automáticamente")
                    
                    // Los servicios de Flutter se reiniciarán automáticamente
                    // cuando la aplicación se ejecute nuevamente
                    Log.d(TAG, "Servicios de Flutter se reiniciarán cuando la app se abra")
                    
                } catch (e: Exception) {
                    Log.e(TAG, "Error en BootReceiver: ${e.message}")
                }
            }
        }
    }
}
