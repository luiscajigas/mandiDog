import 'package:flutter/material.dart';

import '../../core/theme/colores.dart';

/// Logo vectorial: una pata dentro de un círculo con degradado y un anillo coral.
class LogoMandiDog extends StatelessWidget {
  const LogoMandiDog({super.key, this.tamano = 120});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo de MandiDog IA',
      child: Container(
        width: tamano,
        height: tamano,
        padding: EdgeInsets.all(tamano * 0.045),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ColoresMandiDog.coral, width: tamano * 0.035),
          boxShadow: [
            BoxShadow(
              color: ColoresMandiDog.petroleo.withValues(alpha: 0.25),
              blurRadius: tamano * 0.25,
              offset: Offset(0, tamano * 0.08),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ColoresMandiDog.petroleoClaro, ColoresMandiDog.petroleo],
            ),
          ),
          child: Center(
            child: Icon(Icons.pets_rounded, size: tamano * 0.48, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
