import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Guarda las fotos analizadas en la carpeta privada de la app para que el historial
/// pueda mostrarlas aunque el sistema limpie la caché.
class AlmacenImagenes {
  static const _carpeta = 'analisis';

  Future<Directory> _directorio() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, _carpeta));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String?> persistir(String rutaOriginal, String id) async {
    try {
      final origen = File(rutaOriginal);
      if (!await origen.exists()) return null;
      final destino = p.join((await _directorio()).path, '$id${p.extension(rutaOriginal).toLowerCase()}');
      if (p.equals(origen.path, destino)) return destino;
      await origen.copy(destino);
      return destino;
    } on Object {
      return null;
    }
  }

  Future<void> borrar(List<String> rutas) async {
    for (final ruta in rutas) {
      try {
        final archivo = File(ruta);
        if (await archivo.exists()) await archivo.delete();
      } on Object {
        // Si no se puede borrar una foto, se continúa con las demás.
      }
    }
  }
}
