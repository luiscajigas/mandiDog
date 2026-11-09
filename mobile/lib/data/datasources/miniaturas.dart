import 'dart:typed_data';
import 'dart:ui' as ui;

/// Reduce una foto a una miniatura PNG para guardarla en el historial.
///
/// Usa el decodificador de imágenes de Flutter, por lo que funciona igual en Android y en web.
/// Devuelve null si la imagen no se puede decodificar.
Future<Uint8List?> crearMiniatura(Uint8List bytes, {int ancho = 200}) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: ancho);
    final cuadro = await codec.getNextFrame();
    final datos = await cuadro.image.toByteData(format: ui.ImageByteFormat.png);
    cuadro.image.dispose();
    codec.dispose();
    return datos?.buffer.asUint8List();
  } on Object {
    return null;
  }
}
