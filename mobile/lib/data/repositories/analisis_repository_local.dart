import '../../domain/entities/estado_servidor.dart';
import '../../domain/entities/imagen_capturada.dart';
import '../../domain/entities/resultado_analisis.dart';
import '../../domain/errores.dart';
import '../../domain/repositories/analisis_repository.dart';
import '../../domain/services/clasificador_riesgo.dart';
import '../datasources/motor_inferencia.dart';

/// Analiza las fotos dentro del teléfono, sin servidor ni conexión a internet.
class AnalisisRepositoryLocal implements AnalisisRepository {
  AnalisisRepositoryLocal(this._motor, {this._clasificador = const ClasificadorRiesgo()});

  final MotorInferencia _motor;
  final ClasificadorRiesgo _clasificador;

  @override
  bool get usaServidor => false;

  @override
  Future<ResultadoAnalisis> analizar(ImagenCapturada imagen) async {
    final double probabilidad;
    try {
      probabilidad = await _motor.predecir(imagen.bytes);
    } on AnalisisException {
      rethrow;
    } on Object {
      throw const ErrorAnalisisLocalException();
    }

    final nivel = _clasificador.clasificar(probabilidad);
    final fecha = DateTime.now();
    return ResultadoAnalisis(
      id: fecha.microsecondsSinceEpoch.toString(),
      probabilidad: (probabilidad * 10000).round() / 10000,
      nivel: nivel,
      recomendacion: _clasificador.recomendacionPara(nivel),
      aviso: avisoLegal,
      versionModelo: _motor.version,
      modoDemo: _motor.modoDemo,
      fecha: fecha,
      imagen: imagen.bytes,
    );
  }

  @override
  Future<EstadoServidor> consultarEstado() async =>
      EstadoServidor(disponible: true, modoDemo: _motor.modoDemo, versionModelo: _motor.version);
}
