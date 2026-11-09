import 'package:flutter/material.dart';

import '../../domain/repositories/preferencias_repository.dart';

/// Guarda y notifica la preferencia de tema claro u oscuro.
class ControladorTema extends ChangeNotifier {
  ControladorTema(this._preferencias) : _oscuro = _preferencias.temaOscuro;

  final PreferenciasRepository _preferencias;
  bool _oscuro;

  bool get oscuro => _oscuro;
  ThemeMode get modo => _oscuro ? ThemeMode.dark : ThemeMode.light;

  Future<void> alternar() async {
    _oscuro = !_oscuro;
    notifyListeners();
    await _preferencias.guardarTemaOscuro(_oscuro);
  }
}
