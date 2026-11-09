import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/resultado_analisis.dart';
import '../../domain/repositories/historial_repository.dart';

/// Convierte la foto original en una miniatura para guardarla.
typedef ReducirImagen = Future<Uint8List?> Function(Uint8List original);

/// Historial guardado en el dispositivo como una lista JSON dentro de SharedPreferences
/// (en el navegador, SharedPreferences usa el almacenamiento local de la página).
class HistorialRepositoryLocal implements HistorialRepository {
  HistorialRepositoryLocal(
    this._prefs, {
    this._reducirImagen,
    this.maximoRegistros = 30,
  });

  static const clave = 'historial_analisis_v2';

  final SharedPreferences _prefs;
  final ReducirImagen? _reducirImagen;
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
    final imagen = resultado.imagen;
    final reducir = _reducirImagen;
    if (imagen != null && reducir != null) {
      final miniatura = await reducir(imagen);
      aGuardar = miniatura == null ? resultado.copyWith(quitarImagen: true) : resultado.copyWith(imagen: miniatura);
    }

    final actuales = await obtenerTodos();
    var lista = [aGuardar, ...actuales.where((r) => r.id != aGuardar.id)].take(maximoRegistros).toList();

    // Si el almacenamiento se llena (por ejemplo, el límite del navegador), se descartan los más antiguos.
    while (true) {
      try {
        await _prefs.setString(clave, jsonEncode(lista.map((r) => r.toJson()).toList()));
        return aGuardar;
      } on Object {
        if (lista.length <= 1) return aGuardar;
        lista = lista.take(lista.length ~/ 2).toList();
      }
    }
  }

  @override
  Future<void> borrarTodo() => _prefs.remove(clave);
}
