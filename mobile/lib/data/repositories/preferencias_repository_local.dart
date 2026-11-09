import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/preferencias_repository.dart';

class PreferenciasRepositoryLocal implements PreferenciasRepository {
  PreferenciasRepositoryLocal(this._prefs);

  static const claveBienvenida = 'bienvenida_vista';
  static const claveTemaOscuro = 'tema_oscuro';

  final SharedPreferences _prefs;

  @override
  bool get bienvenidaVista => _prefs.getBool(claveBienvenida) ?? false;

  @override
  Future<void> marcarBienvenidaVista() => _prefs.setBool(claveBienvenida, true);

  @override
  bool get temaOscuro => _prefs.getBool(claveTemaOscuro) ?? false;

  @override
  Future<void> guardarTemaOscuro(bool valor) => _prefs.setBool(claveTemaOscuro, valor);
}
