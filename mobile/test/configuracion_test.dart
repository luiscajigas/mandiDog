import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mandidog/core/config.dart';
import 'package:mandidog/domain/entities/imagen_capturada.dart';

void main() {
  group('ConfiguracionApp.normalizarUrl', () {
    test('agrega http:// y quita la barra final', () {
      expect(ConfiguracionApp.normalizarUrl(' 192.168.1.7:8000/ '), 'http://192.168.1.7:8000');
    });

    test('respeta https', () {
      expect(ConfiguracionApp.normalizarUrl('https://mandidog.ejemplo.co'), 'https://mandidog.ejemplo.co');
    });

    test('rechaza textos vacíos o sin servidor', () {
      expect(ConfiguracionApp.normalizarUrl(''), isNull);
      expect(ConfiguracionApp.normalizarUrl('http://'), isNull);
    });
  });

  group('ImagenCapturada', () {
    test('reconoce un PNG por su firma', () {
      final png = ImagenCapturada(bytes: Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D]), nombre: 'image');
      expect(png.tipoMime, 'image/png');
      expect(png.nombreNormalizado, 'image.png');
    });

    test('trata el resto como JPG y corrige la extensión', () {
      final jpg = ImagenCapturada(bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]), nombre: 'IMG_0001.HEIC');
      expect(jpg.tipoMime, 'image/jpeg');
      expect(jpg.nombreNormalizado, 'IMG_0001.jpg');
    });
  });
}
