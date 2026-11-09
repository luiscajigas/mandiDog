import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandidog/data/datasources/motor_inferencia.dart';
import 'package:mandidog/data/datasources/preprocesamiento.dart';
import 'package:mandidog/data/repositories/analisis_repository_local.dart';
import 'package:mandidog/domain/entities/imagen_capturada.dart';
import 'package:mandidog/domain/entities/nivel_riesgo.dart';
import 'package:mandidog/domain/errores.dart';
import 'package:mandidog/domain/services/clasificador_riesgo.dart';

class _MotorFijo implements MotorInferencia {
  _MotorFijo(this.probabilidad, {this.error});

  final double probabilidad;
  final Object? error;

  @override
  String get version => 'mandidog_v1';

  @override
  bool get modoDemo => false;

  @override
  Future<double> predecir(Uint8List bytes) async {
    if (error != null) throw error!;
    return probabilidad;
  }

  @override
  void cerrar() {}
}

class _BundleDePrueba extends CachingAssetBundle {
  _BundleDePrueba(this.archivos);

  final Map<String, String> archivos;

  @override
  Future<ByteData> load(String key) async {
    final texto = archivos[key];
    if (texto == null) throw StateError('No existe $key');
    return ByteData.sublistView(Uint8List.fromList(texto.codeUnits));
  }
}

ImagenCapturada _imagen() => ImagenCapturada(bytes: Uint8List.fromList([0xFF, 0xD8, 1, 2, 3]), nombre: 'foto.jpg');

void main() {
  group('ClasificadorRiesgo', () {
    const clasificador = ClasificadorRiesgo();

    test('aplica los mismos umbrales que la API (0,30 y 0,60)', () {
      expect(clasificador.clasificar(0.0), NivelRiesgo.verde);
      expect(clasificador.clasificar(0.2999), NivelRiesgo.verde);
      expect(clasificador.clasificar(0.30), NivelRiesgo.amarillo);
      expect(clasificador.clasificar(0.5999), NivelRiesgo.amarillo);
      expect(clasificador.clasificar(0.60), NivelRiesgo.rojo);
      expect(clasificador.clasificar(1.0), NivelRiesgo.rojo);
    });

    test('tiene una recomendación para cada nivel', () {
      for (final nivel in NivelRiesgo.values) {
        expect(clasificador.recomendacionPara(nivel), isNotEmpty);
      }
    });
  });

  group('MotorDemo', () {
    test('la misma foto da siempre la misma probabilidad, entre 0 y 1', () async {
      const motor = MotorDemo();
      final bytes = Uint8List.fromList(List.generate(500, (i) => i % 256));
      final primera = await motor.predecir(bytes);
      expect(await motor.predecir(bytes), primera);
      expect(primera, inInclusiveRange(0.0, 1.0));
      expect(motor.modoDemo, isTrue);
    });

    test('coincide con el adaptador de demostración de la API', () async {
      // sha256("mandidog") empieza por 0x1b5e…; la API calcula el mismo valor.
      final valor = await const MotorDemo().predecir(Uint8List.fromList('mandidog'.codeUnits));
      expect(valor, closeTo(0.1069, 0.0001));
    });
  });

  group('InfoModelo', () {
    test('lee la versión y los umbrales de modelo.json', () async {
      final info = await InfoModelo.leer(_BundleDePrueba({
        InfoModelo.rutaInfo: '{"version": "mandidog_v2", "umbral_amarillo": 0.25, "umbral_rojo": 0.7}',
      }));
      expect(info.version, 'mandidog_v2');
      expect(info.clasificador.umbralAmarillo, 0.25);
      expect(info.clasificador.umbralRojo, 0.7);
    });

    test('usa los valores por defecto si falta el archivo o los umbrales no son coherentes', () async {
      final sinArchivo = await InfoModelo.leer(_BundleDePrueba({}));
      expect(sinArchivo.clasificador.umbralAmarillo, 0.30);

      final incoherente = await InfoModelo.leer(_BundleDePrueba({
        InfoModelo.rutaInfo: '{"umbral_amarillo": 0.8, "umbral_rojo": 0.4}',
      }));
      expect(incoherente.clasificador.umbralAmarillo, 0.30);
      expect(incoherente.clasificador.umbralRojo, 0.60);
    });
  });

  group('AnalisisRepositoryLocal', () {
    test('convierte la probabilidad del modelo en un resultado completo', () async {
      final repositorio = AnalisisRepositoryLocal(_MotorFijo(0.71234));
      final resultado = await repositorio.analizar(_imagen());

      expect(repositorio.usaServidor, isFalse);
      expect(resultado.probabilidad, 0.7123);
      expect(resultado.nivel, NivelRiesgo.rojo);
      expect(resultado.recomendacion, ClasificadorRiesgo.recomendaciones[NivelRiesgo.rojo]);
      expect(resultado.versionModelo, 'mandidog_v1');
      expect(resultado.modoDemo, isFalse);
      expect(resultado.imagen, isNotNull);
    });

    test('respeta los umbrales del modelo', () async {
      final repositorio = AnalisisRepositoryLocal(
        _MotorFijo(0.5),
        clasificador: const ClasificadorRiesgo(umbralAmarillo: 0.2, umbralRojo: 0.45),
      );
      expect((await repositorio.analizar(_imagen())).nivel, NivelRiesgo.rojo);
    });

    test('el estado indica que el análisis está disponible sin servidor', () async {
      final estado = await AnalisisRepositoryLocal(const MotorDemo()).consultarEstado();
      expect(estado.disponible, isTrue);
      expect(estado.modoDemo, isTrue);
    });

    test('mantiene los errores con mensaje y traduce los inesperados', () async {
      const rechazo = ImagenRechazadaException('No pudimos leer la foto.');
      expect(
        () => AnalisisRepositoryLocal(_MotorFijo(0, error: rechazo)).analizar(_imagen()),
        throwsA(same(rechazo)),
      );
      expect(
        () => AnalisisRepositoryLocal(_MotorFijo(0, error: StateError('falla nativa'))).analizar(_imagen()),
        throwsA(isA<ErrorAnalisisLocalException>()),
      );
    });
  });

  group('Preprocesamiento', () {
    test('normaliza RGBA a RGB entre 0 y 1 descartando el canal alfa', () {
      final salida = rgbaANormalizado(Uint8List.fromList([255, 0, 51, 128, 0, 255, 102, 7]));
      expect(salida, hasLength(6));
      expect(salida[0], 1.0);
      expect(salida[1], 0.0);
      expect(salida[2], closeTo(0.2, 1e-6));
      expect(salida[4], 1.0);
      expect(salida[5], closeTo(0.4, 1e-6));
    });

    testWidgets('reduce cualquier foto a 224 x 224 píxeles', (tester) async {
      await tester.runAsync(() async {
        final grabadora = ui.PictureRecorder();
        ui.Canvas(grabadora).drawRect(
          const ui.Rect.fromLTWH(0, 0, 640, 480),
          ui.Paint()..color = const ui.Color(0xFFC62828),
        );
        final imagen = await grabadora.endRecording().toImage(640, 480);
        final png = (await imagen.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();

        final rgba = await decodificarRgba(png);
        expect(rgba, hasLength(ladoEntrada * ladoEntrada * 4));
        final tensor = rgbaANormalizado(rgba!);
        expect(tensor, hasLength(ladoEntrada * ladoEntrada * 3));
        expect(tensor[0], closeTo(0xC6 / 255, 0.02));

        expect(await decodificarRgba(Uint8List.fromList([1, 2, 3])), isNull);
      });
    });
  });
}
