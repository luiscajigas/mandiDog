import 'dart:typed_data';
import 'dart:ui' as ui;

/// Lado de la imagen que espera el modelo (MobileNetV2, 224 x 224).
const ladoEntrada = 224;

/// Decodifica la foto y la reduce a 224 x 224 píxeles RGBA con el decodificador nativo del teléfono.
///
/// Igual que en el entrenamiento y en la API, la imagen se ajusta al cuadrado sin recortar.
/// El decodificador respeta la orientación EXIF de la foto. Devuelve null si no es una imagen.
Future<Uint8List?> decodificarRgba(Uint8List bytes, {int lado = ladoEntrada}) async {
  ui.Codec? codec;
  ui.Image? imagen;
  try {
    codec = await ui.instantiateImageCodec(bytes, targetWidth: lado, targetHeight: lado);
    imagen = (await codec.getNextFrame()).image;
    final datos = await imagen.toByteData(format: ui.ImageByteFormat.rawRgba);
    return datos?.buffer.asUint8List();
  } on Object {
    return null;
  } finally {
    imagen?.dispose();
    codec?.dispose();
  }
}

/// Convierte píxeles RGBA (0 a 255) en el tensor RGB normalizado entre 0 y 1 que usa el modelo.
Float32List rgbaANormalizado(Uint8List rgba) {
  final pixeles = rgba.length ~/ 4;
  final salida = Float32List(pixeles * 3);
  for (var i = 0; i < pixeles; i++) {
    salida[i * 3] = rgba[i * 4] / 255.0;
    salida[i * 3 + 1] = rgba[i * 4 + 1] / 255.0;
    salida[i * 3 + 2] = rgba[i * 4 + 2] / 255.0;
  }
  return salida;
}
