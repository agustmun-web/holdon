# Configuración Android para Geofencing y Headless Tasks

## Permisos Requeridos

### 1. Permisos de Ubicación
```xml
<!-- Permisos básicos de ubicación -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### 2. Permisos para Headless Tasks
```xml
<!-- Permisos para ejecución en segundo plano -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
<uses-permission android:name="android.permission.DISABLE_KEYGUARD" />
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
```

### 3. Permisos de Servicios
```xml
<!-- Permisos para Foreground Services -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

## Configuración de Servicios

### 1. Servicio de Geofencing
```xml
<service
    android:name="com.fluttercandies.geofencing_api.GeofencingService"
    android:enabled="true"
    android:exported="false" />
```

### 2. Boot Receiver
```xml
<receiver
    android:name=".BootReceiver"
    android:enabled="true"
    android:exported="true">
    <intent-filter android:priority="1000">
        <action android:name="android.intent.action.BOOT_COMPLETED" />
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
        <action android:name="android.intent.action.PACKAGE_REPLACED" />
        <data android:scheme="package" />
    </intent-filter>
</receiver>
```

**Nota**: El BootReceiver está configurado para registrar eventos de reinicio. Los servicios de Flutter se reiniciarán automáticamente cuando la aplicación se ejecute nuevamente.

## Verificación de Permisos

### En el Código Dart
```dart
// Verificar permisos de ubicación
final locationAlwaysStatus = await Permission.locationAlways.status;
final notificationStatus = await Permission.notification.status;

if (locationAlwaysStatus.isGranted) {
    // Permiso "Siempre" otorgado - Geofencing funcionará
} else {
    // Solicitar permiso "Siempre"
    await Permission.locationAlways.request();
}
```

## Configuración de Battery Optimization

### Para Dispositivos Android 6.0+
1. El usuario debe otorgar permiso de ubicación "Siempre"
2. Deshabilitar optimización de batería para la aplicación
3. Permitir que la aplicación se ejecute en segundo plano

### Código para Solicitar Deshabilitar Optimización
```dart
// Solicitar deshabilitar optimización de batería
await Permission.ignoreBatteryOptimizations.request();
```

## Configuración de Notificaciones

### Canales de Notificación
1. **high_danger_alerts**: Para hotspots de ALTA peligrosidad
2. **moderate_danger_alerts**: Para hotspots de MODERADA peligrosidad

### Configuración de Importancia
- **ALTA**: `Importance.max` - Crítica
- **MODERADA**: `Importance.high` - Alta

## Testing en Dispositivos Reales

### 1. Verificar Permisos
```bash
# Verificar permisos otorgados
adb shell dumpsys package com.example.holdon | grep permission
```

### 2. Verificar Servicios Activos
```bash
# Verificar servicios en ejecución
adb shell dumpsys activity services | grep holdon
```

### 3. Logs de Debug
```bash
# Ver logs de la aplicación
adb logcat | grep HoldOn
```

## Solución de Problemas Comunes

### 1. Geofencing No Funciona
- Verificar que el permiso "Ubicación Siempre" esté otorgado
- Verificar que la optimización de batería esté deshabilitada
- Verificar que el GPS esté habilitado

### 2. Notificaciones No Aparecen
- Verificar permisos de notificación
- Verificar configuración de canales de notificación
- Verificar que las notificaciones no estén deshabilitadas por el usuario

### 3. Headless Tasks No Ejecutan
- Verificar que el BootReceiver esté registrado
- Verificar permisos de RECEIVE_BOOT_COMPLETED
- Verificar que la aplicación no esté en lista de "Aplicaciones en reposo"

## Configuración de Producción

### 1. ProGuard/R8
Agregar reglas para mantener clases de geofencing:
```proguard
-keep class com.fluttercandies.geofencing_api.** { *; }
-keep class com.example.holdon.BootReceiver { *; }
```

### 2. Verificación de Versión
- Android API 21+ (Android 5.0)
- Flutter 3.0+
- Dart 3.0+

### 3. Testing
- Probar en dispositivos Android reales
- Probar con aplicación cerrada
- Probar después de reinicio del dispositivo
- Probar con diferentes niveles de batería
