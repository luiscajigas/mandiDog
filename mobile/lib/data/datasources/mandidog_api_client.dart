import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../domain/errores.dart';

/// Cliente de bajo nivel para la API de MandiDog IA. Solo lo usa la capa de datos.
class MandiDogApiClient {
  MandiDogApiClient({
    required this._cliente,
    required String urlBase,
    this.tiempoAnalisis = const Duration(seconds: 45),
    this.tiempoEstado = const Duration(seconds: 6),
  }) : _urlBase = Uri.parse(urlBase.endsWith('/') ? urlBase : '$urlBase/');

  final http.Client _cliente;
  final Uri _urlBase;
  final Duration tiempoAnalisis;
  final Duration tiempoEstado;

  Uri get urlBase => _urlBase;

  Future<Map<String, dynamic>> health() async {
    final respuesta = await _ejecutar(() => _cliente.get(_urlBase.resolve('health')), tiempoEstado);
    return _decodificar(respuesta);
  }

  Future<Map<String, dynamic>> analizar(String imagenPath) async {
    final archivo = File(imagenPath);
    if (!await archivo.exists()) {
      throw const ImagenRechazadaException('No encontramos la foto. Tómala o selecciónala de nuevo.');
    }

    final solicitud = http.MultipartRequest('POST', _urlBase.resolve('v1/analisis'))
      ..files.add(await http.MultipartFile.fromPath(
        'imagen',
        imagenPath,
        contentType: _tipoMime(imagenPath),
      ));

    final respuesta = await _ejecutar(() async {
      final enviada = await _cliente.send(solicitud);
      return http.Response.fromStream(enviada);
    }, tiempoAnalisis);
    return _decodificar(respuesta);
  }

  MediaType _tipoMime(String ruta) {
    final extension = ruta.toLowerCase();
    return extension.endsWith('.png') ? MediaType('image', 'png') : MediaType('image', 'jpeg');
  }

  Future<http.Response> _ejecutar(Future<http.Response> Function() accion, Duration limite) async {
    try {
      return await accion().timeout(limite);
    } on TimeoutException {
      throw const SinConexionException();
    } on SocketException {
      throw const SinConexionException();
    } on http.ClientException {
      throw const SinConexionException();
    } on HandshakeException {
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
