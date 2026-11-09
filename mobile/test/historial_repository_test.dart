import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mandidog/data/repositories/historial_repository_local.dart';
import 'package:mandidog/domain/entities/nivel_riesgo.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'soporte.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('guarda un análisis y lo vuelve a leer con todos sus datos', () async {
    final repositorio = HistorialRepositoryLocal(prefs);
    final original = resultadoDePrueba(
      id: 'a1',
      nivel: NivelRiesgo.rojo,
      probabilidad: 0.87,
      imagen: Uint8List.fromList([1, 2, 3, 4]),
    );

    await repositorio.guardar(original);
    final leidos = await HistorialRepositoryLocal(prefs).obtenerTodos();

    expect(leidos, hasLength(1));
    final leido = leidos.single;
    expect(leido.id, 'a1');
    expect(leido.nivel, NivelRiesgo.rojo);
    expect(leido.probabilidad, closeTo(0.87, 1e-9));
    expect(leido.recomendacion, original.recomendacion);
    expect(leido.aviso, original.aviso);
    expect(leido.versionModelo, 'demo-sin-entrenar');
    expect(leido.modoDemo, isTrue);
    expect(leido.fecha, original.fecha);
    expect(leido.imagen, [1, 2, 3, 4]);
  });

  test('devuelve los análisis del más reciente al más antiguo', () async {
    final repositorio = HistorialRepositoryLocal(prefs);
    await repositorio.guardar(resultadoDePrueba(id: 'viejo', fecha: DateTime(2026, 1, 1)));
    await repositorio.guardar(resultadoDePrueba(id: 'nuevo', fecha: DateTime(2026, 5, 1)));
    await repositorio.guardar(resultadoDePrueba(id: 'medio', fecha: DateTime(2026, 3, 1)));

    final ids = (await repositorio.obtenerTodos()).map((r) => r.id).toList();

    expect(ids, ['nuevo', 'medio', 'viejo']);
  });

  test('guarda una miniatura en lugar de la foto original', () async {
    final repositorio = HistorialRepositoryLocal(
      prefs,
      reducirImagen: (original) async => Uint8List.fromList([9, 9]),
    );

    final guardado = await repositorio.guardar(resultadoDePrueba(id: 'x', imagen: Uint8List(5000)));

    expect(guardado.imagen, [9, 9]);
    expect((await repositorio.obtenerTodos()).single.imagen, [9, 9]);
  });

  test('si la miniatura no se puede crear, guarda el análisis sin foto', () async {
    final repositorio = HistorialRepositoryLocal(prefs, reducirImagen: (_) async => null);

    final guardado = await repositorio.guardar(resultadoDePrueba(id: 'y', imagen: Uint8List(10)));

    expect(guardado.imagen, isNull);
    expect(await repositorio.obtenerTodos(), hasLength(1));
  });

  test('conserva como máximo el número de registros configurado', () async {
    final repositorio = HistorialRepositoryLocal(prefs, maximoRegistros: 3);
    for (var i = 1; i <= 5; i++) {
      await repositorio.guardar(resultadoDePrueba(id: '$i', fecha: DateTime(2026, 1, i)));
    }

    final ids = (await repositorio.obtenerTodos()).map((r) => r.id).toList();

    expect(ids, ['5', '4', '3']);
  });

  test('borrar el historial elimina todos los registros', () async {
    final repositorio = HistorialRepositoryLocal(prefs);
    await repositorio.guardar(resultadoDePrueba(id: '1'));
    await repositorio.guardar(resultadoDePrueba(id: '2'));

    await repositorio.borrarTodo();

    expect(await repositorio.obtenerTodos(), isEmpty);
  });

  test('un historial vacío o dañado no rompe la app', () async {
    expect(await HistorialRepositoryLocal(prefs).obtenerTodos(), isEmpty);

    await prefs.setString(HistorialRepositoryLocal.clave, '{esto no es json');
    expect(await HistorialRepositoryLocal(prefs).obtenerTodos(), isEmpty);
  });
}
