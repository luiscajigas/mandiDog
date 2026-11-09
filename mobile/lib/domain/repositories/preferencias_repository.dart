/// Preferencias simples del usuario.
abstract interface class PreferenciasRepository {
  bool get bienvenidaVista;
  Future<void> marcarBienvenidaVista();

  bool get temaOscuro;
  Future<void> guardarTemaOscuro(bool valor);
}
