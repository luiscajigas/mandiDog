import 'package:flutter_test/flutter_test.dart';
import 'package:mandidog/presentation/screens/bienvenida_screen.dart';
import 'package:mandidog/presentation/screens/inicio_screen.dart';
import 'package:mandidog/presentation/widgets/logo_mandidog.dart';

import 'soporte.dart';

void main() {
  setUpAll(prepararPruebas);

  testWidgets('la pantalla de bienvenida se construye con su contenido', (tester) async {
    await tester.pumpWidget(envolver(const BienvenidaScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(LogoMandiDog), findsOneWidget);
    expect(find.text('MandiDog IA'), findsOneWidget);
    expect(find.text('Cuida la boca de tu perro a tiempo'), findsOneWidget);
    expect(find.textContaining('no es un diagnóstico'), findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);
  });

  testWidgets('al pulsar Comenzar se guarda la preferencia y se abre el inicio', (tester) async {
    final preferencias = PreferenciasFalsas();
    await tester.pumpWidget(envolver(const BienvenidaScreen(), preferencias: preferencias));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();

    expect(preferencias.bienvenidaVista, isTrue);
    expect(find.byType(InicioScreen), findsOneWidget);
    expect(find.text('Analizar a mi perro'), findsOneWidget);
    expect(find.text('Modo demostración'), findsOneWidget);
  });
}
