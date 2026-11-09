import 'package:flutter/material.dart';

/// Ruta con transición de desvanecido y desplazamiento suave hacia arriba.
Route<T> rutaAnimada<T>(Widget pantalla) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) => pantalla,
    transitionsBuilder: (_, animacion, _, hijo) {
      final curva = CurvedAnimation(parent: animacion, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curva,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(curva),
          child: hijo,
        ),
      );
    },
  );
}
