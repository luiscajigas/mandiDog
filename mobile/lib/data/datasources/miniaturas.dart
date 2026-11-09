import 'dart:typed_data';
import 'dart:ui' as ui;

/// Reduce una foto a una miniatura PNG para guardarla en el historial.
///
/// Decodifica la imagen completa y la dibuja escalada en un lienzo. Así la proporción se conserva
/// igual en Android y en web (el escalado del decodificador no se comporta igual en todas las
/// plataformas). Devuelve null si la imagen no se puede decodificar.
Future<Uint8List?> crearMiniatura(Uint8List bytes, {int ancho = 200}) async {
  ui.Image? original;
  ui.Image? reducida;
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    original = (await codec.getNextFrame()).image;
    codec.dispose();

    final escala = original.width > ancho ? ancho / original.width : 1.0;
    final w = (original.width * escala).round().clamp(1, original.width);
    final h = (original.height * escala).round().clamp(1, original.height);

    final grabadora = ui.PictureRecorder();
    ui.Canvas(grabadora).drawImageRect(
      original,
      ui.Rect.fromLTWH(0, 0, original.width.toDouble(), original.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    reducida = await grabadora.endRecording().toImage(w, h);
    final datos = await reducida.toByteData(format: ui.ImageByteFormat.png);
    return datos?.buffer.asUint8List();
  } on Object {
    return null;
  } finally {
    original?.dispose();
    reducida?.dispose();
  }
}
