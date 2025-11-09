# Configuración de Google Maps para HoldOn

## ⚠️ IMPORTANTE: Configurar API Key

La aplicación necesita una API key válida de Google Maps para funcionar correctamente.

## Pasos para configurar la API key:

### 1. Crear proyecto en Google Cloud Console
1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Habilita la **Maps SDK for Android**

### 2. Crear API Key
1. Ve a "Credenciales" en el menú lateral
2. Haz clic en "Crear credenciales" > "Clave de API"
3. Copia la API key generada

### 3. Configurar restricciones de seguridad
1. Edita la API key creada
2. En "Restricciones de aplicación", selecciona "Aplicaciones Android"
3. Agrega:
   - **Nombre del paquete**: `com.holdon.holdon`
   - **Huella digital SHA-1**: (ver instrucciones abajo)

### 4. Obtener huella digital SHA-1

#### Para debug (desarrollo):
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### Para release (producción):
```bash
keytool -list -v -keystore path/to/your/release-key.keystore -alias your-key-alias
```

### 5. Actualizar la API key en el proyecto

#### En AndroidManifest.xml:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_AQUI" />
```

#### En lib/config/google_maps_config.dart:
```dart
static const String apiKey = 'TU_API_KEY_AQUI';
```

## Verificación

Después de configurar la API key:
1. Ejecuta `flutter clean`
2. Ejecuta `flutter run`
3. La aplicación debería cargar el mapa sin errores

## Solución de problemas

### Error: "API key not found"
- Verifica que la API key esté en AndroidManifest.xml
- Asegúrate de que la API key sea válida
- Verifica que Maps SDK for Android esté habilitada

### Error: "This API project is not authorized"
- Verifica las restricciones de la API key
- Asegúrate de que el nombre del paquete coincida
- Verifica que la huella digital SHA-1 sea correcta

### Mapa no se carga
- Verifica la conexión a internet
- Revisa los logs de la consola para errores específicos
- Asegúrate de que la API key tenga permisos de Maps SDK

## Seguridad

⚠️ **NUNCA** subas tu API key real a repositorios públicos. Usa:
- Variables de entorno
- Archivos de configuración locales
- Servicios de gestión de secretos

Para desarrollo, puedes usar la API key de ejemplo temporalmente, pero recuerda cambiarla antes de producción.







