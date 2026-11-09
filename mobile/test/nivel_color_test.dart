import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandidog/core/theme/colores.dart';
import 'package:mandidog/domain/entities/nivel_riesgo.dart';

void main() {
  group('colorDeNivel', () {
    test('VERDE se pinta de #2E7D32', () {
      expect(colorDeNivel(NivelRiesgo.verde), const Color(0xFF2E7D32));
    });

    test('AMARILLO se pinta de #F9A825', () {
      expect(colorDeNivel(NivelRiesgo.amarillo), const Color(0xFFF9A825));
    });

    test('ROJO se pinta de #C62828', () {
      expect(colorDeNivel(NivelRiesgo.rojo), const Color(0xFFC62828));
    });

    test('cada nivel tiene un color distinto', () {
      final colores = NivelRiesgo.values.map(colorDeNivel).toSet();
      expect(colores, hasLength(NivelRiesgo.values.length));
    });
  });

  group('NivelRiesgo.desdeCodigo', () {
    test('interpreta los códigos que envía la API', () {
      expect(NivelRiesgo.desdeCodigo('VERDE'), NivelRiesgo.verde);
      expect(NivelRiesgo.desdeCodigo('amarillo'), NivelRiesgo.amarillo);
      expect(NivelRiesgo.desdeCodigo(' ROJO '), NivelRiesgo.rojo);
    });

    test('rechaza códigos desconocidos', () {
      expect(() => NivelRiesgo.desdeCodigo('AZUL'), throwsFormatException);
    });
  });
}
