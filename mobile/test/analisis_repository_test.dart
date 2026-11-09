// Usa SocketException de dart:io para simular la caída de la red; solo corre en la VM.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mandidog/data/datasources/mandidog_api_client.dart';
import 'package:mandidog/data/repositories/analisis_repository_http.dart';
import 'package:mandidog/domain/entities/imagen_capturada.dart';
import 'package:mandidog/domain/entities/nivel_riesgo.dart';
import 'package:mandidog/domain/errores.dart';

void main() {
  final foto = ImagenCapturada(bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]), nombre: 'boca.jpg');

  AnalisisRepositoryHttp repositorioCon(MockClientHandler manejador, {String url = 'http://servidor:8000'}) {
    final api = MandiDogApiClient(cliente: MockClient(manejador), urlBase: () => url);
    return AnalisisRepositoryHttp(api);
  }

  http.Response json(Object cuerpo, int codigo) => http.Response.bytes(
        utf8.encode(jsonEncode(cuerpo)),
        codigo,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  test('convierte la respuesta de la API en un resultado', () async {
    late http.BaseRequest recibida;
    final repositorio = repositorioCon((solicitud) async {
      recibida = solicitud;
      return json({
        'probabilidad': 0.73,
        'nivel': 'ROJO',
        'recomendacion': 'Consulta a un veterinario lo antes posible.',
        'aviso': 'Este resultado es orientativo y no reemplaza el diagnóstico de un médico veterinario.',
        'version_modelo': 'mandidog_v1',
        'modo_demo': false,
        'fecha': '2026-03-14T15:30:00Z',
      }, 200);
    });

    final resultado = await repositorio.analizar(foto);

    expect(recibida.method, 'POST');
    expect(recibida.url.toString(), 'http://servidor:8000/v1/analisis');
    expect(resultado.nivel, NivelRiesgo.rojo);
    expect(resultado.probabilidad, 0.73);
    expect(resultado.modoDemo, isFalse);
    expect(resultado.imagen, foto.bytes);
  });

  test('un 422 se traduce en ImagenRechazadaException con el mensaje del servidor', () async {
    final repositorio = repositorioCon((_) async => json({'detalle': 'Solo se aceptan imágenes JPG o PNG.'}, 422));

    expect(
      () => repositorio.analizar(foto),
      throwsA(isA<ImagenRechazadaException>().having((e) => e.mensaje, 'mensaje', contains('JPG o PNG'))),
    );
  });

  test('si el servidor no responde se lanza SinConexionException', () async {
    final repositorio = repositorioCon((_) async => throw const SocketException('sin red'));

    expect(
      () => repositorio.analizar(foto),
      throwsA(isA<SinConexionException>().having(
        (e) => e.mensaje,
        'mensaje',
        'No pudimos conectar con el servidor. Revisa tu conexión e inténtalo de nuevo',
      )),
    );
  });

  test('usa la dirección de servidor vigente en cada petición', () async {
    final urls = <String>[];
    var actual = 'http://10.0.2.2:8000';
    final api = MandiDogApiClient(
      cliente: MockClient((solicitud) async {
        urls.add(solicitud.url.toString());
        return json({'estado': 'ok', 'version_modelo': 'v', 'modo_demo': false}, 200);
      }),
      urlBase: () => actual,
    );
    final repositorio = AnalisisRepositoryHttp(api);

    await repositorio.consultarEstado();
    actual = 'http://192.168.1.7:8000/';
    await repositorio.consultarEstado();

    expect(urls, ['http://10.0.2.2:8000/health', 'http://192.168.1.7:8000/health']);
  });

  test('una dirección de servidor mal escrita se informa como falta de conexión', () async {
    final repositorio = repositorioCon((_) async => json({}, 200), url: 'http://');

    expect(() => repositorio.analizar(foto), throwsA(isA<SinConexionException>()));
  });

  test('consultarEstado informa el modo demostración', () async {
    final repositorio = repositorioCon(
      (_) async => json({'estado': 'ok', 'version_modelo': 'demo-sin-entrenar', 'modo_demo': true}, 200),
    );

    final estado = await repositorio.consultarEstado();

    expect(estado.disponible, isTrue);
    expect(estado.modoDemo, isTrue);
  });

  test('consultarEstado devuelve no disponible si falla la conexión', () async {
    final repositorio = repositorioCon((_) async => throw http.ClientException('caído'));

    expect((await repositorio.consultarEstado()).disponible, isFalse);
  });
}
