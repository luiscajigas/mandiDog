import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config.dart';
import 'data/datasources/mandidog_api_client.dart';
import 'data/datasources/miniaturas.dart';
import 'data/repositories/analisis_repository_http.dart';
import 'data/repositories/historial_repository_local.dart';
import 'data/repositories/preferencias_repository_local.dart';
import 'domain/repositories/analisis_repository.dart';
import 'domain/repositories/historial_repository.dart';
import 'domain/repositories/preferencias_repository.dart';
import 'presentation/state/controlador_tema.dart';

/// Composition root: crea las dependencias concretas y las registra con Provider.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initializeDateFormatting('es');

  // Las fuentes Poppins se incluyen en los assets; no se descargan en tiempo de ejecución.
  GoogleFonts.config.allowRuntimeFetching = false;

  final prefs = await SharedPreferences.getInstance();
  final PreferenciasRepository preferencias = PreferenciasRepositoryLocal(prefs);

  // La URL se consulta en cada petición para respetar el servidor que elija el usuario.
  final api = MandiDogApiClient(
    cliente: http.Client(),
    urlBase: () => preferencias.urlServidor ?? ConfiguracionApp.urlPorDefecto,
  );

  final AnalisisRepository analisis = AnalisisRepositoryHttp(api);
  final HistorialRepository historial = HistorialRepositoryLocal(prefs, reducirImagen: crearMiniatura);

  runApp(
    MultiProvider(
      providers: [
        Provider<PreferenciasRepository>.value(value: preferencias),
        Provider<AnalisisRepository>.value(value: analisis),
        Provider<HistorialRepository>.value(value: historial),
        ChangeNotifierProvider(create: (_) => ControladorTema(preferencias)),
      ],
      child: MandiDogApp(mostrarBienvenida: !preferencias.bienvenidaVista),
    ),
  );
}
