/// Configuración de compilación.
///
/// La URL de la API se define con: flutter run --dart-define=API_URL=http://mi-servidor:8000
/// Por defecto apunta al equipo anfitrión visto desde el emulador de Android.
abstract final class ConfiguracionApp {
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');

  static const autor = 'Luis Cajigas';
  static const universidad = 'Universidad Cooperativa de Colombia';
  static const programa = 'Ingeniería de Software';
  static const ciudad = 'San Juan de Pasto';
  static const anio = '2026';
  static const version = '1.0.0';
}
