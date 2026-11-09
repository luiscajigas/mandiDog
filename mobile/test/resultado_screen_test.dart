import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandidog/domain/entities/nivel_riesgo.dart';
import 'package:mandidog/domain/entities/resultado_analisis.dart';
import 'package:mandidog/presentation/screens/resultado_screen.dart';
import 'package:mandidog/presentation/widgets/semaforo.dart';

import 'soporte.dart';

/// La pantalla es una lista desplazable: se baja hasta el elemento como haría el usuario.
Future<void> bajarHasta(WidgetTester tester, Finder elemento) async {
  await tester.scrollUntilVisible(elemento, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(prepararPruebas);

  testWidgets('muestra el semáforo, el aviso y la franja de modo demostración', (tester) async {
    final resultado = resultadoDePrueba(nivel: NivelRiesgo.amarillo, modoDemo: true);
    await tester.pumpWidget(envolver(ResultadoScreen(resultado: resultado)));
    await tester.pumpAndSettle();

    expect(find.text('Modo demostración: el modelo aún no está entrenado'), findsOneWidget);
    expect(find.byType(Semaforo), findsOneWidget);
    expect(find.text('NIVEL AMARILLO'), findsOneWidget);

    await bajarHasta(tester, find.text(resultado.recomendacion));
    expect(find.text(resultado.recomendacion), findsOneWidget);

    await bajarHasta(tester, find.text(avisoLegal));
    expect(find.text(avisoLegal), findsOneWidget);
  });

  testWidgets('sin modo demostración no aparece la franja', (tester) async {
    await tester.pumpWidget(envolver(ResultadoScreen(resultado: resultadoDePrueba(modoDemo: false))));
    await tester.pumpAndSettle();

    expect(find.textContaining('Modo demostración'), findsNothing);
    await bajarHasta(tester, find.text(avisoLegal));
    expect(find.text(avisoLegal), findsOneWidget);
  });
}
