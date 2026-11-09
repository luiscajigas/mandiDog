import 'package:flutter/material.dart';

import '../../core/theme/colores.dart';
import '../../domain/entities/nivel_riesgo.dart';

/// Semáforo horizontal: enciende la luz del nivel indicado y atenúa las demás.
class Semaforo extends StatelessWidget {
  const Semaforo({super.key, required this.nivel, this.tamanoLuz = 64});

  final NivelRiesgo nivel;
  final double tamanoLuz;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Semáforo de riesgo: ${nivel.titulo}',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: tamanoLuz * 0.3, vertical: tamanoLuz * 0.25),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2A30),
          borderRadius: BorderRadius.circular(tamanoLuz),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final luz in NivelRiesgo.values) ...[
              _Luz(color: colorDeNivel(luz), encendida: luz == nivel, tamano: tamanoLuz),
              if (luz != NivelRiesgo.values.last) SizedBox(width: tamanoLuz * 0.28),
            ],
          ],
        ),
      ),
    );
  }
}

class _Luz extends StatelessWidget {
  const _Luz({required this.color, required this.encendida, required this.tamano});

  final Color color;
  final bool encendida;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      width: encendida ? tamano : tamano * 0.78,
      height: encendida ? tamano : tamano * 0.78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: encendida ? color : color.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: encendida ? 0.5 : 0.08), width: 2),
        boxShadow: encendida
            ? [BoxShadow(color: color.withValues(alpha: 0.75), blurRadius: tamano * 0.5, spreadRadius: 2)]
            : const [],
      ),
    );
  }
}

/// Chip con el color del nivel, usado en el historial.
class ChipNivel extends StatelessWidget {
  const ChipNivel({super.key, required this.nivel});

  final NivelRiesgo nivel;

  @override
  Widget build(BuildContext context) {
    final color = colorDeNivel(nivel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconoDeNivel(nivel), size: 15, color: colorTextoSobreNivel(nivel)),
          const SizedBox(width: 5),
          Text(
            nivel.etiqueta,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorTextoSobreNivel(nivel),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
