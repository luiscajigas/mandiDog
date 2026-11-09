import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/navegacion/rutas.dart';
import '../../core/theme/colores.dart';
import '../../domain/repositories/preferencias_repository.dart';
import '../widgets/aviso_legal.dart';
import '../widgets/logo_mandidog.dart';
import 'inicio_screen.dart';

class BienvenidaScreen extends StatelessWidget {
  const BienvenidaScreen({super.key});

  Future<void> _comenzar(BuildContext context) async {
    final navegador = Navigator.of(context);
    await context.read<PreferenciasRepository>().marcarBienvenidaVista();
    navegador.pushReplacement(rutaAnimada(const InicioScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: oscuro
                ? const [ColoresMandiDog.superficieOscura, ColoresMandiDog.fondoOscuro]
                : [ColoresMandiDog.petroleo.withValues(alpha: 0.10), ColoresMandiDog.crema],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, restricciones) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: restricciones.maxHeight - 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 24),
                    Column(
                      children: [
                        const LogoMandiDog(tamano: 150)
                            .animate()
                            .scale(begin: const Offset(0.7, 0.7), duration: 650.ms, curve: Curves.easeOutBack)
                            .fadeIn(duration: 400.ms),
                        const SizedBox(height: 32),
                        Text(
                          'MandiDog IA',
                          style: textos.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: oscuro ? Colors.white : ColoresMandiDog.petroleo,
                          ),
                        ).animate().fadeIn(delay: 200.ms, duration: 450.ms).slideY(begin: 0.3),
                        const SizedBox(height: 8),
                        Text(
                          'Cuida la boca de tu perro a tiempo',
                          textAlign: TextAlign.center,
                          style: textos.titleMedium?.copyWith(color: ColoresMandiDog.coral, fontWeight: FontWeight.w500),
                        ).animate().fadeIn(delay: 350.ms, duration: 450.ms).slideY(begin: 0.3),
                        const SizedBox(height: 20),
                        Text(
                          'Toma una foto de la boca de tu perro y recibe una orientación inmediata '
                          'sobre posibles signos de anomalías mandibulares.',
                          textAlign: TextAlign.center,
                          style: textos.bodyLarge?.copyWith(height: 1.5),
                        ).animate().fadeIn(delay: 500.ms, duration: 450.ms),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Column(
                      children: [
                        const AvisoLegal(
                          texto: 'MandiDog IA no es un diagnóstico. Sus resultados son orientativos y no '
                              'reemplazan la valoración de un médico veterinario.',
                        ).animate().fadeIn(delay: 650.ms, duration: 450.ms),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => _comenzar(context),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Comenzar'),
                          style: FilledButton.styleFrom(backgroundColor: ColoresMandiDog.coral),
                        ).animate().fadeIn(delay: 800.ms, duration: 450.ms).slideY(begin: 0.4),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
