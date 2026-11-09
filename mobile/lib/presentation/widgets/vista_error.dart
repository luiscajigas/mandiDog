import 'package:flutter/material.dart';

import '../../core/theme/colores.dart';

/// Mensaje de error amable con botón para reintentar.
class VistaError extends StatelessWidget {
  const VistaError({
    super.key,
    required this.mensaje,
    required this.onReintentar,
    this.onVolver,
    this.icono = Icons.wifi_off_rounded,
  });

  final String mensaje;
  final VoidCallback onReintentar;
  final VoidCallback? onVolver;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColoresMandiDog.coral.withValues(alpha: 0.12),
            ),
            child: Icon(icono, size: 46, color: ColoresMandiDog.coral),
          ),
          const SizedBox(height: 24),
          Text('Algo salió mal', style: textos.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(mensaje, textAlign: TextAlign.center, style: textos.bodyLarge),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onReintentar,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
          if (onVolver != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onVolver,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Volver'),
            ),
          ],
        ],
      ),
    );
  }
}
