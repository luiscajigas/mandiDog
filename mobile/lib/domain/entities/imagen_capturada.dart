import 'dart:typed_data';

/// Foto tomada con la cámara o elegida de la galería, lista para enviar al análisis.
///
/// Se maneja en memoria (bytes) para que funcione igual en Android y en el navegador.
class ImagenCapturada {
  const ImagenCapturada({required this.bytes, required this.nombre});

  final Uint8List bytes;
  final String nombre;

  bool get esPng =>
      bytes.length >= 4 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47;

  String get tipoMime => esPng ? 'image/png' : 'image/jpeg';

  /// Nombre con una extensión coherente con el contenido real del archivo.
  String get nombreNormalizado {
    final base = nombre.contains('.') ? nombre.substring(0, nombre.lastIndexOf('.')) : nombre;
    final limpio = base.trim().isEmpty ? 'foto' : base.trim();
    return '$limpio.${esPng ? 'png' : 'jpg'}';
  }
}
