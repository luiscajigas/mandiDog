/// Errores que la capa de datos entrega a la presentación con mensajes listos para mostrar.
sealed class AnalisisException implements Exception {
  const AnalisisException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// No hubo respuesta del servidor (sin red, servidor apagado o tiempo agotado).
class SinConexionException extends AnalisisException {
  const SinConexionException()
      : super('No pudimos conectar con el servidor. Revisa tu conexión e inténtalo de nuevo');
}

/// El servidor rechazó la imagen (por ejemplo, formato o tamaño no válidos).
class ImagenRechazadaException extends AnalisisException {
  const ImagenRechazadaException(super.mensaje);
}

/// El servidor respondió con un error inesperado.
class ErrorServidorException extends AnalisisException {
  const ErrorServidorException([
    super.mensaje = 'El servidor tuvo un problema al analizar la foto. Inténtalo de nuevo en unos minutos.',
  ]);
}
