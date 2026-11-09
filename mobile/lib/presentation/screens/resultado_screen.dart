import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/navegacion/rutas.dart';
import '../../core/theme/colores.dart';
import '../../domain/entities/resultado_analisis.dart';
import '../widgets/aviso_legal.dart';
import '../widgets/semaforo.dart';
import '../widgets/tarjeta.dart';
import 'captura_screen.dart';
import 'historial_screen.dart';

class ResultadoScreen extends StatelessWidget {
  const ResultadoScreen({super.key, required this.resultado, this.desdeHistorial = false});

  final ResultadoAnalisis resultado;
  final bool desdeHistorial;

  void _nuevoAnalisis(BuildContext context) {
    final navegador = Navigator.of(context);
    navegador.popUntil((ruta) => ruta.isFirst);
    navegador.push(rutaAnimada(const CapturaScreen()));
  }

  void _verHistorial(BuildContext context) {
    final navegador = Navigator.of(context);
    if (desdeHistorial) {
      navegador.pop();
      return;
    }
    navegador.popUntil((ruta) => ruta.isFirst);
    navegador.push(rutaAnimada(const HistorialScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final color = colorDeNivel(resultado.nivel);
    final fecha = DateFormat("d 'de' MMMM 'de' y, h:mm a", 'es').format(resultado.fecha);
    final porcentaje = NumberFormat.percentPattern('es').format(resultado.confianza);
    final probabilidad = NumberFormat.percentPattern('es').format(resultado.probabilidad);

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          if (resultado.modoDemo) ...[
            const _FranjaDemo(),
            const SizedBox(height: 16),
          ],
          Tarjeta(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Column(
              children: [
                Semaforo(nivel: resultado.nivel)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack, duration: 600.ms),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(30)),
                  child: Text(
                    'NIVEL ${resultado.nivel.codigo}',
                    style: textos.labelLarge?.copyWith(
                      color: colorTextoSobreNivel(resultado.nivel),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 12),
                Text(
                  resultado.nivel.titulo,
                  textAlign: TextAlign.center,
                  style: textos.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: color),
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2),
                const SizedBox(height: 20),
                _BarraConfianza(valor: resultado.confianza, color: color, texto: porcentaje),
                const SizedBox(height: 8),
                Text(
                  'Probabilidad estimada de signos visibles: $probabilidad',
                  textAlign: TextAlign.center,
                  style: textos.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Tarjeta(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.medical_services_rounded, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recomendación', style: textos.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(resultado.recomendacion, style: textos.bodyLarge?.copyWith(height: 1.45)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),
          AvisoLegal(texto: resultado.aviso.isEmpty ? avisoLegal : resultado.aviso)
              .animate()
              .fadeIn(delay: 500.ms),
          const SizedBox(height: 16),
          Tarjeta(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _Miniatura(bytes: resultado.imagen, tamano: 92),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Foto analizada', style: textos.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      _Dato(icono: Icons.calendar_today_rounded, texto: fecha),
                      const SizedBox(height: 4),
                      _Dato(icono: Icons.memory_rounded, texto: 'Modelo: ${resultado.versionModelo}'),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _nuevoAnalisis(context),
            icon: const Icon(Icons.photo_camera_rounded),
            label: const Text('Nuevo análisis'),
            style: FilledButton.styleFrom(backgroundColor: ColoresMandiDog.coral),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _verHistorial(context),
            icon: const Icon(Icons.history_rounded),
            label: const Text('Ver historial'),
          ),
        ],
      ),
    );
  }
}

class _FranjaDemo extends StatelessWidget {
  const _FranjaDemo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColoresMandiDog.amarillo.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColoresMandiDog.amarillo),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_rounded, color: Color(0xFF8A5A00)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Modo demostración: el modelo aún no está entrenado',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraConfianza extends StatelessWidget {
  const _BarraConfianza({required this.valor, required this.color, required this.texto});

  final double valor;
  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      children: [
        Row(
          children: [
            Text('Confianza del análisis', style: textos.bodyMedium),
            const Spacer(),
            Text(texto, style: textos.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: valor),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 12,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 15, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Expanded(child: Text(texto, style: Theme.of(context).textTheme.bodySmall)),
      ],
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.bytes, required this.tamano});

  final Uint8List? bytes;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final respaldo = Container(
      width: tamano,
      height: tamano,
      color: ColoresMandiDog.petroleo.withValues(alpha: 0.12),
      child: const Icon(Icons.pets_rounded, color: ColoresMandiDog.petroleo),
    );
    if (bytes == null) return respaldo;
    return Image.memory(
      bytes!,
      width: tamano,
      height: tamano,
      fit: BoxFit.cover,
      cacheWidth: (tamano * 3).round(),
      errorBuilder: (_, _, _) => respaldo,
    );
  }
}
