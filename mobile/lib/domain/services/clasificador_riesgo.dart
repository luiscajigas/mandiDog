import '../entities/nivel_riesgo.dart';

/// Traduce la probabilidad del modelo en un nivel del semáforo y una recomendación.
///
/// Usa las mismas reglas que la API: VERDE por debajo del umbral amarillo,
/// ROJO a partir del umbral rojo y AMARILLO entre ambos.
class ClasificadorRiesgo {
  const ClasificadorRiesgo({this.umbralAmarillo = 0.30, this.umbralRojo = 0.60})
      : assert(0 <= umbralAmarillo && umbralAmarillo < umbralRojo && umbralRojo <= 1);

  final double umbralAmarillo;
  final double umbralRojo;

  static const recomendaciones = {
    NivelRiesgo.verde: 'No se observan signos aparentes. Mantén las revisiones veterinarias periódicas.',
    NivelRiesgo.amarillo: 'Se observan posibles signos leves. Programa una revisión con tu veterinario.',
    NivelRiesgo.rojo: 'Se observan signos que requieren atención. Consulta a un veterinario lo antes posible.',
  };

  /// Devuelve true si los umbrales son coherentes (0 <= amarillo < rojo <= 1).
  static bool umbralesValidos(double amarillo, double rojo) => 0 <= amarillo && amarillo < rojo && rojo <= 1;

  NivelRiesgo clasificar(double probabilidad) {
    if (probabilidad < umbralAmarillo) return NivelRiesgo.verde;
    if (probabilidad < umbralRojo) return NivelRiesgo.amarillo;
    return NivelRiesgo.rojo;
  }

  String recomendacionPara(NivelRiesgo nivel) => recomendaciones[nivel]!;
}
