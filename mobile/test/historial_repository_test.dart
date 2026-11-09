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
    final original = resultadoDePrueba(id: 'a1', nivel: NivelRiesgo.rojo, probabilidad: 0.87, imagenPath: '/tmp/foto.jpg');

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
    expect(leido.imagenPath, '/tmp/foto.jpg');
  });

  test('devuelve los análisis del más reciente al más antiguo', () async {
    final repositorio = HistorialRepositoryLocal(prefs);
    await repositorio.guardar(resultadoDePrueba(id: 'viejo', fecha: DateTime(2026, 1, 1)));
    await repositorio.guardar(resultadoDePrueba(id: 'nuevo', fecha: DateTime(2026, 5, 1)));
    await repositorio.guardar(resultadoDePrueba(id: 'medio', fecha: DateTime(2026, 3, 1)));

    final ids = (await repositorio.obtenerTodos()).map((r) => r.id).toList();

    expect(ids, ['nuevo', 'medio', 'viejo']);
  });

  test('usa la ruta definitiva de la foto al guardar', () async {
    final repositorio = HistorialRepositoryLocal(
      prefs,
      persistirImagen: (ruta, id) async => '/documentos/analisis/$id.jpg',
    );

    final guardado = await repositorio.guardar(resultadoDePrueba(id: 'x', imagenPath: '/cache/temporal.jpg'));

    expect(guardado.imagenPath, '/documentos/analisis/x.jpg');
    expect((await repositorio.obtenerTodos()).single.imagenPath, '/documentos/analisis/x.jpg');
  });

  test('borrar el historial elimina los registros y sus fotos', () async {
    final borradas = <String>[];
    final repositorio = HistorialRepositoryLocal(prefs, borrarImagenes: (rutas) async => borradas.addAll(rutas));
    await repositorio.guardar(resultadoDePrueba(id: '1', imagenPath: '/a.jpg'));
    await repositorio.guardar(resultadoDePrueba(id: '2', imagenPath: '/b.jpg'));

    await repositorio.borrarTodo();

    expect(await repositorio.obtenerTodos(), isEmpty);
    expect(borradas, unorderedEquals(['/a.jpg', '/b.jpg']));
  });

  test('un historial vacío o dañado no rompe la app', () async {
    expect(await HistorialRepositoryLocal(prefs).obtenerTodos(), isEmpty);

    await prefs.setString(HistorialRepositoryLocal.clave, '{esto no es json');
    expect(await HistorialRepositoryLocal(prefs).obtenerTodos(), isEmpty);
  });
}
