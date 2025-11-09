/// Configuración para Google Maps
class GoogleMapsConfig {
  /// API Key para Google Maps
  /// NOTA: Esta es una API key de ejemplo. En producción, debes:
  /// 1. Crear tu propia API key en Google Cloud Console
  /// 2. Configurar restricciones de aplicación
  /// 3. Usar variables de entorno o archivos de configuración seguros
  static const String apiKey = 'AIzaSyBvOkBw8Q8Q8Q8Q8Q8Q8Q8Q8Q8Q8Q8Q8Q8';
  
  /// Verifica si la API key está configurada correctamente
  static bool get isConfigured {
    return apiKey.isNotEmpty && 
           apiKey != 'your_api_key_here' && 
           apiKey.length > 20;
  }
  
  /// Obtiene instrucciones para configurar la API key
  static String get setupInstructions => '''
Para configurar Google Maps correctamente:

1. Ve a Google Cloud Console (https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Habilita la API de Maps SDK for Android
4. Ve a "Credenciales" y crea una nueva API key
5. Configura restricciones de aplicación:
   - Tipo: Aplicaciones Android
   - Nombre del paquete: com.holdon.holdon
   - Huella digital SHA-1: (obtén con keytool)
6. Reemplaza la API key en:
   - android/app/src/main/AndroidManifest.xml
   - lib/config/google_maps_config.dart

Para obtener la huella digital SHA-1:
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
''';
}







