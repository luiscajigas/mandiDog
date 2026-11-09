/// Estado del servidor según el endpoint /health.
class EstadoServidor {
  const EstadoServidor({required this.disponible, this.modoDemo = false, this.versionModelo});

  const EstadoServidor.noDisponible() : this(disponible: false);

  final bool disponible;
  final bool modoDemo;
  final String? versionModelo;
}
