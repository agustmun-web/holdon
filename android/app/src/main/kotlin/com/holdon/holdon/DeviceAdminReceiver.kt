package com.holdon.holdon

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent

class DeviceAdminReceiver : DeviceAdminReceiver() {
    
    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        // Device admin permission granted
    }
    
    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        // Device admin permission revoked
    }
    
    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        return "HoldOn needs device admin permission to protect your device from theft. Disabling this permission will prevent the app from locking the screen during theft detection."
    }
}

