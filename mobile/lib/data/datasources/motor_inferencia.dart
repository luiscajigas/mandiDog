import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../../domain/services/clasificador_riesgo.dart';

/// Motor que calcula, dentro del teléfono, la probabilidad de signos visibles de patología mandibular.
abstract interface class MotorInferencia {
  String get version;

  /// true cuando no hay un modelo entrenado y el resultado es solo una simulación.
  bool get modoDemo;

  /// Probabilidad (0 a 1) de la clase "con signos".
  Future<double> predecir(Uint8List bytes);

  /// Libera los recursos nativos del motor.
  void cerrar();
}

/// Motor de demostración: se usa solo cuando la app no incluye un modelo entrenado.
///
/// Igual que el adaptador de demostración de la API, deriva la probabilidad del hash
/// SHA-256 de la foto: la misma imagen da siempre el mismo valor. No tiene valor clínico.
class MotorDemo implements MotorInferencia {
  const MotorDemo();

  @override
  String get version => 'demo-sin-entrenar';

  @override
  bool get modoDemo => true;

  @override
  Future<double> predecir(Uint8List bytes) async {
    final resumen = sha256.convert(bytes).bytes;
    // Se acumula en double para que el cálculo sea igual en Android y en la web.
    var valor = 0.0;
    for (final byte in resumen.take(8)) {
      valor = valor * 256 + byte;
    }
    final probabilidad = valor / 18446744073709551615.0; // 2^64 - 1
    return (probabilidad * 10000).round() / 10000;
  }

  @override
  void cerrar() {}
}

/// Datos del modelo incluidos junto al archivo .tflite (assets/modelo/modelo.json).
class InfoModelo {
  const InfoModelo({this.version = 'mandidog', this.clasificador = const ClasificadorRiesgo()});

  static const rutaInfo = 'assets/modelo/modelo.json';
  static const rutaModelo = 'assets/modelo/mandidog.tflite';

  final String version;
  final ClasificadorRiesgo clasificador;

  factory InfoModelo.fromJson(Map<String, dynamic> json) {
    final amarillo = (json['umbral_amarillo'] as num?)?.toDouble() ?? 0.30;
    final rojo = (json['umbral_rojo'] as num?)?.toDouble() ?? 0.60;
    return InfoModelo(
      version: json['version'] as String? ?? 'mandidog',
      clasificador: ClasificadorRiesgo.umbralesValidos(amarillo, rojo)
          ? ClasificadorRiesgo(umbralAmarillo: amarillo, umbralRojo: rojo)
          : const ClasificadorRiesgo(),
    );
  }

  /// Lee modelo.json; si no existe o no es válido, usa los valores por defecto.
  static Future<InfoModelo> leer(AssetBundle bundle) async {
    try {
      final texto = await bundle.loadString(rutaInfo, cache: false);
      return InfoModelo.fromJson(jsonDecode(texto) as Map<String, dynamic>);
    } on Object {
      return const InfoModelo();
    }
  }
}
