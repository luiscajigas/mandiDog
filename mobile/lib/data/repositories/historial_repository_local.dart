import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/resultado_analisis.dart';
import '../../domain/repositories/historial_repository.dart';

/// Copia la foto a un lugar permanente y devuelve la nueva ruta.
typedef PersistirImagen = Future<String?> Function(String rutaOriginal, String id);

/// Borra las fotos guardadas del historial.
typedef BorrarImagenes = Future<void> Function(List<String> rutas);

/// Historial guardado en el dispositivo como una lista JSON dentro de SharedPreferences.
class HistorialRepositoryLocal implements HistorialRepository {
  HistorialRepositoryLocal(
    this._prefs, {
    this._persistirImagen,
    this._borrarImagenes,
    this.maximoRegistros = 100,
  });

  static const clave = 'historial_analisis_v1';

  final SharedPreferences _prefs;
  final PersistirImagen? _persistirImagen;
  final BorrarImagenes? _borrarImagenes;
  final int maximoRegistros;

  @override
  Future<List<ResultadoAnalisis>> obtenerTodos() async {
    final texto = _prefs.getString(clave);
    if (texto == null || texto.isEmpty) return [];
    try {
      final lista = jsonDecode(texto) as List<dynamic>;
      final resultados = <ResultadoAnalisis>[];
      for (final elemento in lista) {
        try {
          resultados.add(ResultadoAnalisis.fromJson(elemento as Map<String, dynamic>));
        } on Object {
          // Un registro dañado no debe impedir leer los demás.
        }
      }
      resultados.sort((a, b) => b.fecha.compareTo(a.fecha));
      return resultados;
    } on Object {
      return [];
    }
  }

  @override
  Future<ResultadoAnalisis> guardar(ResultadoAnalisis resultado) async {
    var aGuardar = resultado;
    final ruta = resultado.imagenPath;
    if (ruta != null && _persistirImagen != null) {
      final definitiva = await _persistirImagen(ruta, resultado.id);
      if (definitiva != null) aGuardar = resultado.copyWith(imagenPath: definitiva);
    }

    final actuales = await obtenerTodos();
    final lista = [aGuardar, ...actuales.where((r) => r.id != aGuardar.id)].take(maximoRegistros);
    await _prefs.setString(clave, jsonEncode(lista.map((r) => r.toJson()).toList()));
    return aGuardar;
  }

  @override
  Future<void> borrarTodo() async {
    final actuales = await obtenerTodos();
    final rutas = actuales.map((r) => r.imagenPath).whereType<String>().toList();
    await _prefs.remove(clave);
    if (_borrarImagenes != null && rutas.isNotEmpty) await _borrarImagenes(rutas);
  }
}
