import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/navegacion/rutas.dart';
import '../../core/theme/colores.dart';
import '../../domain/errores.dart';
import '../../domain/repositories/analisis_repository.dart';
import '../../domain/repositories/historial_repository.dart';
import '../widgets/vista_error.dart';
import 'resultado_screen.dart';

/// Envía la foto al repositorio mientras muestra una animación con mensajes.
class AnalizandoScreen extends StatefulWidget {
  const AnalizandoScreen({super.key, required this.imagenPath});

  final String imagenPath;

  @override
  State<AnalizandoScreen> createState() => _AnalizandoScreenState();
}

class _AnalizandoScreenState extends State<AnalizandoScreen> with SingleTickerProviderStateMixin {
  static const _mensajes = [
    'Revisando encías…',
    'Buscando sarro…',
    'Observando la mandíbula…',
    'Comparando con miles de patrones…',
    'Preparando tu resultado…',
  ];

  late final AnimationController _pulso;
  Timer? _temporizador;
  int _indiceMensaje = 0;
  String? _error;
  bool _errorDeConexion = false;

  @override
  void initState() {
    super.initState();
    _pulso = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _analizar();
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _pulso.dispose();
    super.dispose();
  }

  void _iniciarAnimacion() {
    _pulso.repeat(reverse: true);
    _temporizador?.cancel();
    _temporizador = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (mounted) setState(() => _indiceMensaje = (_indiceMensaje + 1) % _mensajes.length);
    });
  }

  void _detenerAnimacion() {
    _temporizador?.cancel();
    _pulso.stop();
  }

  Future<void> _analizar() async {
    setState(() {
      _error = null;
      _indiceMensaje = 0;
    });
    _iniciarAnimacion();

    final analisis = context.read<AnalisisRepository>();
    final historial = context.read<HistorialRepository>();
    final inicio = DateTime.now();

    try {
      final resultado = await analisis.analizar(widget.imagenPath);
      final guardado = await historial.guardar(resultado).catchError((_) => resultado);

      // Mantiene la animación un momento para que la transición no sea brusca.
      final transcurrido = DateTime.now().difference(inicio);
      const minimo = Duration(milliseconds: 1800);
      if (transcurrido < minimo) await Future<void>.delayed(minimo - transcurrido);

      if (!mounted) return;
      _detenerAnimacion();
      Navigator.of(context).pushReplacement(rutaAnimada(ResultadoScreen(resultado: guardado)));
    } on AnalisisException catch (e) {
      _mostrarError(e.mensaje, conexion: e is SinConexionException);
    } on Object {
      _mostrarError(const SinConexionException().mensaje, conexion: true);
    }
  }

  void _mostrarError(String mensaje, {required bool conexion}) {
    if (!mounted) return;
    _detenerAnimacion();
    setState(() {
      _error = mensaje;
      _errorDeConexion = conexion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analizando')),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _error == null
              ? _vistaCarga(context)
              : Center(
                  child: SingleChildScrollView(
                    child: VistaError(
                      mensaje: _error!,
                      icono: _errorDeConexion ? Icons.wifi_off_rounded : Icons.image_not_supported_rounded,
                      onReintentar: _analizar,
                      onVolver: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _vistaCarga(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Center(
      key: const ValueKey('carga'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulso,
                    builder: (_, _) {
                      final t = Curves.easeInOut.transform(_pulso.value);
                      return Container(
                        width: 180 + 40 * t,
                        height: 180 + 40 * t,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColoresMandiDog.coral.withValues(alpha: 0.10 + 0.10 * (1 - t)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(
                    width: 176,
                    height: 176,
                    child: CircularProgressIndicator(strokeWidth: 5, color: ColoresMandiDog.coral),
                  ),
                  ClipOval(
                    child: Image.file(
                      File(widget.imagenPath),
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 150,
                        height: 150,
                        color: ColoresMandiDog.petroleo,
                        child: const Icon(Icons.pets_rounded, color: Colors.white, size: 64),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (hijo, animacion) => FadeTransition(
                opacity: animacion,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(animacion),
                  child: hijo,
                ),
              ),
              child: Text(
                _mensajes[_indiceMensaje],
                key: ValueKey(_indiceMensaje),
                style: textos.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Esto puede tardar unos segundos.',
              style: textos.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
