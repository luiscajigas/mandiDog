import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/navegacion/rutas.dart';
import '../../core/theme/colores.dart';
import '../../domain/entities/resultado_analisis.dart';
import '../../domain/repositories/historial_repository.dart';
import '../widgets/semaforo.dart';
import '../widgets/tarjeta.dart';
import 'captura_screen.dart';
import 'resultado_screen.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  late Future<List<ResultadoAnalisis>> _registros;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _registros = context.read<HistorialRepository>().obtenerTodos();
  }

  Future<void> _confirmarBorrado() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_rounded, color: ColoresMandiDog.rojo),
        title: const Text('¿Borrar el historial?'),
        content: const Text('Se eliminarán todos los análisis guardados en este teléfono. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(contexto, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ColoresMandiDog.rojo, minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    await context.read<HistorialRepository>().borrarTodo();
    if (!mounted) return;
    setState(_cargar);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Historial borrado')));
  }

  Future<void> _abrir(ResultadoAnalisis resultado) async {
    await Navigator.of(context).push(rutaAnimada(ResultadoScreen(resultado: resultado, desdeHistorial: true)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ResultadoAnalisis>>(
      future: _registros,
      builder: (context, snapshot) {
        final registros = snapshot.data ?? const [];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Historial'),
            actions: [
              if (registros.isNotEmpty)
                IconButton(
                  tooltip: 'Borrar historial',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _confirmarBorrado,
                ),
            ],
          ),
          body: switch (snapshot.connectionState) {
            ConnectionState.done when registros.isEmpty => const _HistorialVacio(),
            ConnectionState.done => ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                itemCount: registros.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _ElementoHistorial(
                  resultado: registros[i],
                  onTap: () => _abrir(registros[i]),
                ).animate().fadeIn(delay: (40 * i.clamp(0, 10)).ms, duration: 300.ms).slideX(begin: 0.05),
              ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        );
      },
    );
  }
}

class _ElementoHistorial extends StatelessWidget {
  const _ElementoHistorial({required this.resultado, required this.onTap});

  final ResultadoAnalisis resultado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final fecha = DateFormat("d MMM y · h:mm a", 'es').format(resultado.fecha);
    final ruta = resultado.imagenPath;
    final respaldo = Container(
      width: 64,
      height: 64,
      color: colorDeNivel(resultado.nivel).withValues(alpha: 0.15),
      child: Icon(Icons.pets_rounded, color: colorDeNivel(resultado.nivel)),
    );

    return Tarjeta(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ruta == null
                ? respaldo
                : Image.file(
                    File(ruta),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    cacheWidth: 192,
                    errorBuilder: (_, _, _) => respaldo,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resultado.nivel.titulo, style: textos.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(fecha, style: textos.bodySmall),
                const SizedBox(height: 6),
                ChipNivel(nivel: resultado.nivel),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _HistorialVacio extends StatelessWidget {
  const _HistorialVacio();

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(Icons.history_rounded, size: 52, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text('Aún no hay análisis', style: textos.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Cuando analices una foto, el resultado se guardará aquí, solo en este teléfono.',
              textAlign: TextAlign.center,
              style: textos.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushReplacement(rutaAnimada(const CapturaScreen())),
              icon: const Icon(Icons.photo_camera_rounded),
              label: const Text('Analizar a mi perro'),
            ),
          ],
        ),
      ),
    );
  }
}
