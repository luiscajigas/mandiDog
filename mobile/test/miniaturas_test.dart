import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mandidog/data/datasources/miniaturas.dart';

Future<Uint8List> _pngDePrueba(int ancho, int alto) async {
  final grabadora = ui.PictureRecorder();
  ui.Canvas(grabadora).drawRect(
    ui.Rect.fromLTWH(0, 0, ancho.toDouble(), alto.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFC62828),
  );
  final imagen = await grabadora.endRecording().toImage(ancho, alto);
  final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
  return datos!.buffer.asUint8List();
}

void main() {
  testWidgets('reduce la foto a 200 px de ancho conservando la proporción', (tester) async {
    await tester.runAsync(() async {
      final original = await _pngDePrueba(800, 600);

      final miniatura = await crearMiniatura(original);

      expect(miniatura, isNotNull);
      final codec = await ui.instantiateImageCodec(miniatura!);
      final cuadro = await codec.getNextFrame();
      expect(cuadro.image.width, 200);
      expect(cuadro.image.height, 150);
    });
  });

  testWidgets('devuelve null si los bytes no son una imagen', (tester) async {
    await tester.runAsync(() async {
      expect(await crearMiniatura(Uint8List.fromList([1, 2, 3])), isNull);
    });
  });
}
