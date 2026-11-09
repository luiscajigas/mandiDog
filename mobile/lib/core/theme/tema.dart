import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colores.dart';

const radioTarjeta = 20.0;

ThemeData temaClaro() => _construir(Brightness.light);

ThemeData temaOscuro() => _construir(Brightness.dark);

ThemeData _construir(Brightness brillo) {
  final oscuro = brillo == Brightness.dark;
  final esquema = ColorScheme.fromSeed(
    seedColor: ColoresMandiDog.petroleo,
    brightness: brillo,
    primary: oscuro ? const Color(0xFF7FC4D4) : ColoresMandiDog.petroleo,
    onPrimary: oscuro ? ColoresMandiDog.fondoOscuro : Colors.white,
    secondary: ColoresMandiDog.coral,
    onSecondary: Colors.white,
    surface: oscuro ? ColoresMandiDog.superficieOscura : Colors.white,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: esquema, brightness: brillo);
  final texto = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
    bodyColor: oscuro ? const Color(0xFFE6EEF0) : ColoresMandiDog.tinta,
    displayColor: oscuro ? Colors.white : ColoresMandiDog.tinta,
  );
  final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radioTarjeta));

  return base.copyWith(
    scaffoldBackgroundColor: oscuro ? ColoresMandiDog.fondoOscuro : ColoresMandiDog.crema,
    textTheme: texto,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      foregroundColor: oscuro ? Colors.white : ColoresMandiDog.petroleo,
      titleTextStyle: texto.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: oscuro ? Colors.white : ColoresMandiDog.petroleo,
      ),
    ),
    cardTheme: CardThemeData(
      color: esquema.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: forma,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: texto.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: esquema.primary.withValues(alpha: 0.5), width: 1.5),
        textStyle: texto.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      labelStyle: texto.labelMedium,
    ),
    dialogTheme: DialogThemeData(shape: forma),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}

/// Sombra suave usada en las tarjetas.
List<BoxShadow> sombraSuave(BuildContext context) {
  final oscuro = Theme.of(context).brightness == Brightness.dark;
  return [
    BoxShadow(
      color: (oscuro ? Colors.black : ColoresMandiDog.petroleo).withValues(alpha: oscuro ? 0.35 : 0.08),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}
