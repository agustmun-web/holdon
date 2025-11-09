# Sistema de Geofencing con Notificaciones de Seguridad

## Resumen del Sistema

Este sistema implementa un geofencing completo con notificaciones diferenciadas según el nivel de riesgo de los hotspots. Funciona en segundo plano (headless tasks) incluso cuando la aplicación está cerrada.

## Configuración de Hotspots

### Hotspots ALTA (Rojo) - Notificaciones Críticas
1. **Edificio Guardia Civil**
   - Latitud: 40.93599
   - Longitud: -4.11286
   - Radio: 183.72 metros
   - Nivel: ALTA

2. **Claret**
   - Latitud: 40.94649
   - Longitud: -4.11220
   - Radio: 116.55 metros
   - Nivel: ALTA

### Hotspots MODERADA (Ámbar) - Notificaciones de Precaución
1. **Hermanitas de los pobres**
   - Latitud: 40.94204
   - Longitud: -4.10901
   - Radio: 148.69 metros
   - Nivel: MODERADA

2. **Camino IE**
   - Latitud: 40.95093
   - Longitud: -4.11616
   - Radio: 75.40 metros
   - Nivel: MODERADA

## Mensajes de Notificación

### Para Hotspots ALTA (Rojo)
- **Título**: "Alerta, estás en una zona de alta peligrosidad."
- **Cuerpo**: "Activa el sistema para estar a salvo"
- **Características**:
  - Importancia máxima
  - Notificación persistente
  - Sonido de alarma
  - Visible en pantalla bloqueada
  - Botón de acción "Activar Sistema"

### Para Hotspots MODERADA (Ámbar)
- **Título**: "Alerta, zona de peligrosidad moderada."
- **Cuerpo**: "Activa el sistema para estar a salvo"
- **Características**:
  - Importancia alta
  - Notificación cancelable
  - Sonido de notificación
  - Visible en pantalla bloqueada
  - Botón de acción "Activar Sistema"

## Arquitectura del Sistema

### 1. GeofenceService (`lib/services/geofence_service.dart`)
- Configuración de hotspots con metadatos
- Inicialización del servicio de geofencing
- Manejo de notificaciones locales
- Callbacks para eventos de geofencing

### 2. Background Task (`lib/background/geofence_background_task.dart`)
- Función headless para ejecución en segundo plano
- Lógica condicional basada en metadatos
- Inicialización independiente de notificaciones
- Procesamiento de eventos de entrada

### 3. Metadatos de Geofencing
- Cada región de geofencing almacena el nivel de riesgo en `region.data`
- Los metadatos se consultan en el callback para determinar el tipo de notificación
- Permite escalabilidad para futuros niveles de riesgo

## Funcionamiento en Segundo Plano

1. **Inicialización**: El sistema se configura al iniciar la aplicación
2. **Monitoreo**: Las regiones de geofencing se monitorean continuamente
3. **Detección**: Al entrar a un hotspot, se activa el callback de segundo plano
4. **Procesamiento**: Se lee el nivel de riesgo de los metadatos
5. **Notificación**: Se envía la notificación apropiada según el nivel
6. **Persistencia**: Funciona aunque la aplicación esté cerrada

## Características Técnicas

- **Headless Tasks**: Funciona sin interfaz de usuario
- **Metadatos**: Almacenamiento del nivel de riesgo en cada región
- **Notificaciones Locales**: Sistema completo de notificaciones
- **Cross-Platform**: Compatible con Android e iOS
- **Escalable**: Fácil adición de nuevos hotspots y niveles

## Logs de Debug

El sistema incluye logs detallados para debugging:
- `🔄 [BACKGROUND]` - Eventos de geofencing
- `🚨 [BACKGROUND]` - Alertas de alta peligrosidad
- `⚠️ [BACKGROUND]` - Alertas de peligrosidad moderada
- `✅ [BACKGROUND]` - Confirmaciones de éxito
- `❌ [BACKGROUND]` - Errores y excepciones

## Próximos Pasos

1. Pruebas en dispositivos reales
2. Optimización de batería
3. Integración con sistema de seguridad
4. Configuración de permisos de ubicación
5. Personalización de mensajes por usuario




