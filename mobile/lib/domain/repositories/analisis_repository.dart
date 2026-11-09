import '../entities/estado_servidor.dart';
import '../entities/imagen_capturada.dart';
import '../entities/resultado_analisis.dart';

/// Contrato para analizar fotos. Las pantallas solo conocen esta interfaz, nunca HTTP ni TensorFlow.
abstract interface class AnalisisRepository {
  /// true si el análisis se hace en un servidor (API); false si se hace dentro del teléfono.
  bool get usaServidor;

  /// Analiza la foto (en el teléfono o en el servicio de análisis).
  ///
  /// Lanza una AnalisisException con un mensaje en español si algo falla.
  Future<ResultadoAnalisis> analizar(ImagenCapturada imagen);

  /// Consulta si el servicio está disponible y si funciona en modo demostración.
  Future<EstadoServidor> consultarEstado();
}
