import '../entities/estado_servidor.dart';
import '../entities/imagen_capturada.dart';
import '../entities/resultado_analisis.dart';

/// Contrato para analizar fotos. Las pantallas solo conocen esta interfaz, nunca HTTP.
abstract interface class AnalisisRepository {
  /// Envía la foto al servicio de análisis.
  ///
  /// Lanza una AnalisisException con un mensaje en español si algo falla.
  Future<ResultadoAnalisis> analizar(ImagenCapturada imagen);

  /// Consulta si el servicio está disponible y si funciona en modo demostración.
  Future<EstadoServidor> consultarEstado();
}
