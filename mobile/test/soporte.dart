import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mandidog/core/theme/tema.dart';
import 'package:mandidog/domain/entities/estado_servidor.dart';
import 'package:mandidog/domain/entities/imagen_capturada.dart';
import 'package:mandidog/domain/entities/nivel_riesgo.dart';
import 'package:mandidog/domain/entities/resultado_analisis.dart';
import 'package:mandidog/domain/repositories/analisis_repository.dart';
import 'package:mandidog/domain/repositories/historial_repository.dart';
import 'package:mandidog/domain/repositories/preferencias_repository.dart';
import 'package:mandidog/presentation/state/controlador_tema.dart';
import 'package:provider/provider.dart';

Future<void> prepararPruebas() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await initializeDateFormatting('es');
}

class PreferenciasFalsas implements PreferenciasRepository {
  bool _bienvenida = false;
  bool _oscuro = false;

  @override
  bool get bienvenidaVista => _bienvenida;

  @override
  Future<void> marcarBienvenidaVista() async => _bienvenida = true;

  @override
  bool get temaOscuro => _oscuro;

  @override
  Future<void> guardarTemaOscuro(bool valor) async => _oscuro = valor;

  String? _url;

  @override
  String? get urlServidor => _url;

  @override
  Future<void> guardarUrlServidor(String? url) async => _url = url;
}

class AnalisisFalso implements AnalisisRepository {
  AnalisisFalso({this.estado = const EstadoServidor(disponible: true, modoDemo: true, versionModelo: 'demo')});

  final EstadoServidor estado;

  @override
  Future<ResultadoAnalisis> analizar(ImagenCapturada imagen) async => resultadoDePrueba(imagen: imagen.bytes);

  @override
  Future<EstadoServidor> consultarEstado() async => estado;
}

class HistorialEnMemoria implements HistorialRepository {
  final List<ResultadoAnalisis> registros = [];

  @override
  Future<void> borrarTodo() async => registros.clear();

  @override
  Future<ResultadoAnalisis> guardar(ResultadoAnalisis resultado) async {
    registros.insert(0, resultado);
    return resultado;
  }

  @override
  Future<List<ResultadoAnalisis>> obtenerTodos() async => List.of(registros);
}

ResultadoAnalisis resultadoDePrueba({
  String id = '1',
  NivelRiesgo nivel = NivelRiesgo.amarillo,
  double probabilidad = 0.42,
  bool modoDemo = true,
  DateTime? fecha,
  Uint8List? imagen,
}) {
  return ResultadoAnalisis(
    id: id,
    probabilidad: probabilidad,
    nivel: nivel,
    recomendacion: 'Se observan posibles signos leves. Programa una revisión con tu veterinario.',
    aviso: avisoLegal,
    versionModelo: 'demo-sin-entrenar',
    modoDemo: modoDemo,
    fecha: fecha ?? DateTime(2026, 3, 14, 10, 30),
    imagen: imagen,
  );
}

/// Monta una pantalla con los repositorios falsos registrados.
Widget envolver(
  Widget pantalla, {
  PreferenciasRepository? preferencias,
  AnalisisRepository? analisis,
  HistorialRepository? historial,
}) {
  final prefs = preferencias ?? PreferenciasFalsas();
  return MultiProvider(
    providers: [
      Provider<PreferenciasRepository>.value(value: prefs),
      Provider<AnalisisRepository>.value(value: analisis ?? AnalisisFalso()),
      Provider<HistorialRepository>.value(value: historial ?? HistorialEnMemoria()),
      ChangeNotifierProvider(create: (_) => ControladorTema(prefs)),
    ],
    // Sin Poppins: las pruebas no evalúan tipografía y así no dependen de cargar fuentes.
    child: MaterialApp(theme: temaClaro(poppins: false), home: pantalla),
  );
}
