import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/preferencias_repository.dart';

class PreferenciasRepositoryLocal implements PreferenciasRepository {
  PreferenciasRepositoryLocal(this._prefs);

  static const claveBienvenida = 'bienvenida_vista';
  static const claveTemaOscuro = 'tema_oscuro';
  static const claveUrlServidor = 'url_servidor';

  final SharedPreferences _prefs;

  @override
  bool get bienvenidaVista => _prefs.getBool(claveBienvenida) ?? false;

  @override
  Future<void> marcarBienvenidaVista() => _prefs.setBool(claveBienvenida, true);

  @override
  bool get temaOscuro => _prefs.getBool(claveTemaOscuro) ?? false;

  @override
  Future<void> guardarTemaOscuro(bool valor) => _prefs.setBool(claveTemaOscuro, valor);

  @override
  String? get urlServidor {
    final url = _prefs.getString(claveUrlServidor);
    return (url == null || url.trim().isEmpty) ? null : url;
  }

  @override
  Future<void> guardarUrlServidor(String? url) async {
    if (url == null || url.trim().isEmpty) {
      await _prefs.remove(claveUrlServidor);
    } else {
      await _prefs.setString(claveUrlServidor, url.trim());
    }
  }
}
