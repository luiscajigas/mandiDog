import 'package:flutter_test/flutter_test.dart';
import 'package:mandidog/domain/entities/nivel_riesgo.dart';
import 'package:mandidog/domain/entities/resultado_analisis.dart';
import 'package:mandidog/presentation/screens/resultado_screen.dart';
import 'package:mandidog/presentation/widgets/semaforo.dart';

import 'soporte.dart';

void main() {
  setUpAll(prepararPruebas);

  testWidgets('muestra el semáforo, el aviso y la franja de modo demostración', (tester) async {
    final resultado = resultadoDePrueba(nivel: NivelRiesgo.amarillo, modoDemo: true);
    await tester.pumpWidget(envolver(ResultadoScreen(resultado: resultado)));
    await tester.pumpAndSettle();

    expect(find.byType(Semaforo), findsOneWidget);
    expect(find.text('NIVEL AMARILLO'), findsOneWidget);
    expect(find.text(avisoLegal), findsOneWidget);
    expect(find.text('Modo demostración: el modelo aún no está entrenado'), findsOneWidget);
    expect(find.text(resultado.recomendacion), findsOneWidget);
  });

  testWidgets('sin modo demostración no aparece la franja', (tester) async {
    await tester.pumpWidget(envolver(ResultadoScreen(resultado: resultadoDePrueba(modoDemo: false))));
    await tester.pumpAndSettle();

    expect(find.textContaining('Modo demostración'), findsNothing);
    expect(find.text(avisoLegal), findsOneWidget);
  });
}
