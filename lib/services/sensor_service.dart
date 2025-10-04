import 'package:sensors_plus/sensors_plus.dart';

// Este es un ejemplo simple, normalmente usarías un Stream
// para escuchar continuamente los cambios del sensor.
void startSensorReading() {
  // Escucha las lecturas del acelerómetro
  accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
      .listen((AccelerometerEvent event) {
    // Muestra las coordenadas (x, y, z) en la consola (Logcat en Android Studio)
    print('Acelerómetro: x=${event.x.toStringAsFixed(2)}, y=${event.y.toStringAsFixed(2)}, z=${event.z.toStringAsFixed(2)}');
  });
}