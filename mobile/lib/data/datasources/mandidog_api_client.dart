import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../domain/entities/imagen_capturada.dart';
import '../../domain/errores.dart';

/// Devuelve la URL base vigente (puede cambiar si el usuario configura otro servidor).
typedef ProveedorUrl = String Function();

/// Cliente de bajo nivel para la API de MandiDog IA. Solo lo usa la capa de datos.
class MandiDogApiClient {
  MandiDogApiClient({
    required this._cliente,
    required this._urlBase,
    this.tiempoAnalisis = const Duration(seconds: 45),
    this.tiempoEstado = const Duration(seconds: 6),
  });

  final http.Client _cliente;
  final ProveedorUrl _urlBase;
  final Duration tiempoAnalisis;
  final Duration tiempoEstado;

  Uri _resolver(String ruta) {
    final base = _urlBase();
    final uri = Uri.tryParse(base.endsWith('/') ? base : '$base/');
    if (uri == null || uri.host.isEmpty || !uri.isScheme('http') && !uri.isScheme('https')) {
      throw const SinConexionException();
    }
    return uri.resolve(ruta);
  }

  Future<Map<String, dynamic>> health() async {
    final respuesta = await _ejecutar(() => _cliente.get(_resolver('health')), tiempoEstado);
    return _decodificar(respuesta);
  }

  Future<Map<String, dynamic>> analizar(ImagenCapturada imagen) async {
    if (imagen.bytes.isEmpty) {
      throw const ImagenRechazadaException('La foto está vacía. Tómala o selecciónala de nuevo.');
    }

    final respuesta = await _ejecutar(() async {
      final solicitud = http.MultipartRequest('POST', _resolver('v1/analisis'))
        ..files.add(http.MultipartFile.fromBytes(
          'imagen',
          imagen.bytes,
          filename: imagen.nombreNormalizado,
          contentType: MediaType.parse(imagen.tipoMime),
        ));
      final enviada = await _cliente.send(solicitud);
      return http.Response.fromStream(enviada);
    }, tiempoAnalisis);
    return _decodificar(respuesta);
  }

  Future<http.Response> _ejecutar(Future<http.Response> Function() accion, Duration limite) async {
    try {
      return await accion().timeout(limite);
    } on TimeoutException {
      throw const SinConexionException();
    } on http.ClientException {
      throw const SinConexionException();
    } on FormatException {
      // URL del servidor mal escrita.
      throw const SinConexionException();
    } on Exception {
      // Errores de red propios de cada plataforma (por ejemplo, SocketException en Android).
      throw const SinConexionException();
    }
  }

  Map<String, dynamic> _decodificar(http.Response respuesta) {
    Map<String, dynamic>? cuerpo;
    try {
      final decodificado = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (decodificado is Map<String, dynamic>) cuerpo = decodificado;
    } on FormatException {
      cuerpo = null;
    }

    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300 && cuerpo != null) {
      return cuerpo;
    }
    final detalle = cuerpo?['detalle'];
    if (respuesta.statusCode == 422 || respuesta.statusCode == 413) {
      throw ImagenRechazadaException(
        detalle is String ? detalle : 'La foto no es válida. Usa una imagen JPG o PNG de máximo 10 MB.',
      );
    }
    throw const ErrorServidorException();
  }
}
