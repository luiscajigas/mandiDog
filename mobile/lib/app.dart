import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/tema.dart';
import 'presentation/screens/bienvenida_screen.dart';
import 'presentation/screens/inicio_screen.dart';
import 'presentation/state/controlador_tema.dart';

class MandiDogApp extends StatelessWidget {
  const MandiDogApp({super.key, required this.mostrarBienvenida});

  final bool mostrarBienvenida;

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<ControladorTema>();
    return MaterialApp(
      title: 'MandiDog IA',
      debugShowCheckedModeBanner: false,
      theme: temaClaro(),
      darkTheme: temaOscuro(),
      themeMode: tema.modo,
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: mostrarBienvenida ? const BienvenidaScreen() : const InicioScreen(),
    );
  }
}
