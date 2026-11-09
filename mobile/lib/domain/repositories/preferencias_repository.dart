/// Preferencias simples del usuario.
abstract interface class PreferenciasRepository {
  bool get bienvenidaVista;
  Future<void> marcarBienvenidaVista();

  bool get temaOscuro;
  Future<void> guardarTemaOscuro(bool valor);

  /// Dirección del servidor elegida por el usuario, o null para usar la predeterminada.
  String? get urlServidor;
  Future<void> guardarUrlServidor(String? url);
}
