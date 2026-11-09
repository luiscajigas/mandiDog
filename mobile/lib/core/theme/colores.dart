import 'package:flutter/material.dart';

import '../../domain/entities/nivel_riesgo.dart';

/// Paleta de MandiDog IA.
abstract final class ColoresMandiDog {
  static const petroleo = Color(0xFF0F4C5C);
  static const petroleoClaro = Color(0xFF1F6F82);
  static const coral = Color(0xFFE36414);
  static const crema = Color(0xFFFAF7F2);
  static const tinta = Color(0xFF1B2A30);

  static const verde = Color(0xFF2E7D32);
  static const amarillo = Color(0xFFF9A825);
  static const rojo = Color(0xFFC62828);

  static const fondoOscuro = Color(0xFF0E1A1F);
  static const superficieOscura = Color(0xFF16262D);
}

/// Color asociado a cada nivel de riesgo del semáforo.
Color colorDeNivel(NivelRiesgo nivel) => switch (nivel) {
      NivelRiesgo.verde => ColoresMandiDog.verde,
      NivelRiesgo.amarillo => ColoresMandiDog.amarillo,
      NivelRiesgo.rojo => ColoresMandiDog.rojo,
    };

/// Ícono asociado a cada nivel.
IconData iconoDeNivel(NivelRiesgo nivel) => switch (nivel) {
      NivelRiesgo.verde => Icons.check_circle_rounded,
      NivelRiesgo.amarillo => Icons.error_rounded,
      NivelRiesgo.rojo => Icons.warning_rounded,
    };

/// Color de texto legible sobre el color del nivel.
Color colorTextoSobreNivel(NivelRiesgo nivel) =>
    nivel == NivelRiesgo.amarillo ? ColoresMandiDog.tinta : Colors.white;
