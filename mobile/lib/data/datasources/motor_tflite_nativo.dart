import 'package:flutter/services.dart';
import 'package:flutter_litert/flutter_litert.dart';

import '../../domain/errores.dart';
import 'motor_inferencia.dart';
import 'preprocesamiento.dart';

/// Carga el modelo TensorFlow Lite incluido en la app.
///
/// Devuelve null si la app no trae un modelo entrenado o si no se pudo abrir.
Future<MotorInferencia?> cargarMotorTflite(AssetBundle bundle, InfoModelo info) async {
  try {
    final datos = await bundle.load(InfoModelo.rutaModelo);
    final interprete = Interpreter.fromBuffer(
      datos.buffer.asUint8List(datos.offsetInBytes, datos.lengthInBytes),
      options: InterpreterOptions()..threads = 2,
    );
    return MotorTflite(interprete, version: info.version);
  } on Object {
    return null;
  }
}

/// Ejecuta la red MobileNetV2 entrenada dentro del teléfono, sin conexión.
class MotorTflite implements MotorInferencia {
  MotorTflite(this._interprete, {required this.version});

  final Interpreter _interprete;

  @override
  final String version;

  @override
  bool get modoDemo => false;

  @override
  Future<double> predecir(Uint8List bytes) async {
    final rgba = await decodificarRgba(bytes);
    if (rgba == null) {
      throw const ImagenRechazadaException('No pudimos leer la foto. Prueba con otra imagen JPG o PNG.');
    }
    final entrada = rgbaANormalizado(rgba);
    final salida = [
      [0.0],
    ];
    _interprete.run(entrada.buffer.asUint8List(), salida);
    return salida[0][0].clamp(0.0, 1.0);
  }

  @override
  void cerrar() => _interprete.close();
}
