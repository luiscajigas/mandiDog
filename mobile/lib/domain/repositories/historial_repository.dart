import '../entities/resultado_analisis.dart';

/// Historial de análisis guardado en el dispositivo.
abstract interface class HistorialRepository {
  /// Devuelve los análisis del más reciente al más antiguo.
  Future<List<ResultadoAnalisis>> obtenerTodos();

  /// Guarda un análisis y devuelve la versión almacenada (con la ruta definitiva de la foto).
  Future<ResultadoAnalisis> guardar(ResultadoAnalisis resultado);

  Future<void> borrarTodo();
}
