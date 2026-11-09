import 'package:flutter/material.dart';

import '../../core/theme/colores.dart';
import '../../core/theme/tema.dart';
import '../../domain/entities/resultado_analisis.dart';

/// Tarjeta destacada con el aviso de que el resultado no es un diagnóstico.
class AvisoLegal extends StatelessWidget {
  const AvisoLegal({super.key, this.texto = avisoLegal, this.compacto = false});

  final String texto;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compacto ? 14 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radioTarjeta),
        color: ColoresMandiDog.coral.withValues(alpha: oscuro ? 0.18 : 0.09),
        border: Border.all(color: ColoresMandiDog.coral.withValues(alpha: 0.55), width: 1.4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.health_and_safety_rounded, color: ColoresMandiDog.coral),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
