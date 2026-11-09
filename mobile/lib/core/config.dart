import 'package:flutter/foundation.dart';

/// Configuración de compilación.
///
/// La URL de la API se define con: flutter run --dart-define=API_URL=http://mi-servidor:8000
/// Si no se define:
///  * en Android se usa http://10.0.2.2:8000 (el equipo anfitrión visto desde el emulador);
///  * en la versión web se usa el mismo servidor desde el que se abrió la página.
/// El usuario puede cambiarla desde la app (Inicio → Servidor).
abstract final class ConfiguracionApp {
  static const _apiUrlCompilada = String.fromEnvironment('API_URL');

  static String get urlPorDefecto {
    if (_apiUrlCompilada.isNotEmpty) return _apiUrlCompilada;
    if (kIsWeb) return Uri.base.origin;
    return 'http://10.0.2.2:8000';
  }

  /// Normaliza lo que escribe el usuario: agrega http:// si falta y quita la barra final.
  /// Devuelve null si el texto no es una dirección válida.
  static String? normalizarUrl(String texto) {
    var url = texto.trim();
    if (url.isEmpty) return null;
    if (!url.startsWith('http://') && !url.startsWith('https://')) url = 'http://$url';
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return null;
    return url;
  }

  static const autor = 'Luis Cajigas';
  static const universidad = 'Universidad Cooperativa de Colombia';
  static const programa = 'Ingeniería de Software';
  static const ciudad = 'San Juan de Pasto';
  static const anio = '2026';
  static const version = '1.1.0';
}
