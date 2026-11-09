import 'nivel_riesgo.dart';

/// Resultado de un análisis, tal como lo usa la app (y como se guarda en el historial).
class ResultadoAnalisis {
  const ResultadoAnalisis({
    required this.id,
    required this.probabilidad,
    required this.nivel,
    required this.recomendacion,
    required this.aviso,
    required this.versionModelo,
    required this.modoDemo,
    required this.fecha,
    this.imagenPath,
  });

  final String id;

  /// Probabilidad (0 a 1) de que existan signos visibles de patología mandibular.
  final double probabilidad;
  final NivelRiesgo nivel;
  final String recomendacion;
  final String aviso;
  final String versionModelo;
  final bool modoDemo;
  final DateTime fecha;

  /// Ruta local de la foto analizada.
  final String? imagenPath;

  /// Confianza del modelo en la clase que predijo (con o sin signos), entre 0 y 1.
  double get confianza => probabilidad >= 0.5 ? probabilidad : 1 - probabilidad;

  ResultadoAnalisis copyWith({String? imagenPath}) {
    return ResultadoAnalisis(
      id: id,
      probabilidad: probabilidad,
      nivel: nivel,
      recomendacion: recomendacion,
      aviso: aviso,
      versionModelo: versionModelo,
      modoDemo: modoDemo,
      fecha: fecha,
      imagenPath: imagenPath ?? this.imagenPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'probabilidad': probabilidad,
        'nivel': nivel.codigo,
        'recomendacion': recomendacion,
        'aviso': aviso,
        'version_modelo': versionModelo,
        'modo_demo': modoDemo,
        'fecha': fecha.toIso8601String(),
        'imagen_path': imagenPath,
      };

  factory ResultadoAnalisis.fromJson(Map<String, dynamic> json, {String? id, String? imagenPath}) {
    final fecha = DateTime.tryParse(json['fecha'] as String? ?? '')?.toLocal() ?? DateTime.now();
    return ResultadoAnalisis(
      id: id ?? json['id'] as String? ?? fecha.microsecondsSinceEpoch.toString(),
      probabilidad: (json['probabilidad'] as num).toDouble().clamp(0.0, 1.0),
      nivel: NivelRiesgo.desdeCodigo(json['nivel'] as String),
      recomendacion: json['recomendacion'] as String? ?? '',
      aviso: json['aviso'] as String? ?? avisoLegal,
      versionModelo: json['version_modelo'] as String? ?? 'desconocida',
      modoDemo: json['modo_demo'] as bool? ?? false,
      fecha: fecha,
      imagenPath: imagenPath ?? json['imagen_path'] as String?,
    );
  }
}

/// Aviso que acompaña siempre a cualquier resultado.
const avisoLegal = 'Este resultado es orientativo y no reemplaza el diagnóstico de un médico veterinario.';
