/// Nivel de riesgo que devuelve la API a partir de la probabilidad del modelo.
enum NivelRiesgo {
  verde('VERDE', 'Sin signos aparentes', 'Riesgo bajo'),
  amarillo('AMARILLO', 'Posibles signos leves', 'Riesgo medio'),
  rojo('ROJO', 'Requiere atención', 'Riesgo alto');

  const NivelRiesgo(this.codigo, this.titulo, this.etiqueta);

  /// Valor tal como lo envía la API.
  final String codigo;

  /// Texto principal que se muestra al usuario.
  final String titulo;

  /// Etiqueta corta para chips e historial.
  final String etiqueta;

  static NivelRiesgo desdeCodigo(String codigo) {
    final normalizado = codigo.trim().toUpperCase();
    return NivelRiesgo.values.firstWhere(
      (nivel) => nivel.codigo == normalizado,
      orElse: () => throw FormatException('Nivel de riesgo desconocido: $codigo'),
    );
  }
}
