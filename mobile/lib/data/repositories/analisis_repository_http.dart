import '../../domain/entities/estado_servidor.dart';
import '../../domain/entities/imagen_capturada.dart';
import '../../domain/entities/resultado_analisis.dart';
import '../../domain/errores.dart';
import '../../domain/repositories/analisis_repository.dart';
import '../datasources/mandidog_api_client.dart';

/// Implementación del repositorio de análisis que usa la API REST.
class AnalisisRepositoryHttp implements AnalisisRepository {
  AnalisisRepositoryHttp(this._api);

  final MandiDogApiClient _api;

  @override
  bool get usaServidor => true;

  @override
  Future<ResultadoAnalisis> analizar(ImagenCapturada imagen) async {
    final json = await _api.analizar(imagen);
    try {
      return ResultadoAnalisis.fromJson(
        json,
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        imagen: imagen.bytes,
      );
    } on Object {
      throw const ErrorServidorException('La respuesta del servidor no tiene el formato esperado.');
    }
  }

  @override
  Future<EstadoServidor> consultarEstado() async {
    try {
      final json = await _api.health();
      return EstadoServidor(
        disponible: json['estado'] == 'ok',
        modoDemo: json['modo_demo'] as bool? ?? false,
        versionModelo: json['version_modelo'] as String?,
      );
    } on AnalisisException {
      return const EstadoServidor.noDisponible();
    }
  }
}
