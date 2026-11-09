import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/theme/colores.dart';
import '../widgets/aviso_legal.dart';
import '../widgets/logo_mandidog.dart';
import '../widgets/tarjeta.dart';

class AcercaDeScreen extends StatelessWidget {
  const AcercaDeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final titulo = textos.titleMedium?.copyWith(fontWeight: FontWeight.w600);

    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Center(child: LogoMandiDog(tamano: 96)),
          const SizedBox(height: 16),
          Text('MandiDog IA', textAlign: TextAlign.center, style: textos.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          Text('Versión ${ConfiguracionApp.version}', textAlign: TextAlign.center, style: textos.bodySmall),
          const SizedBox(height: 20),
          Tarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Qué es MandiDog IA?', style: titulo),
                const SizedBox(height: 8),
                Text(
                  'Es una plataforma móvil de apoyo a la detección temprana de anomalías mandibulares '
                  'en perros mediante visión por computador. A partir de una foto de la boca, un modelo '
                  'de red neuronal convolucional estima si hay signos visibles de patología y te orienta '
                  'sobre cuándo acudir al veterinario.',
                  style: textos.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Tarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Cómo funciona?', style: titulo),
                const SizedBox(height: 14),
                const _Paso(numero: 1, icono: Icons.photo_camera_rounded, titulo: 'Foto', texto: 'Tomas o eliges una foto de la boca de tu perro.'),
                const _Paso(numero: 2, icono: Icons.cloud_upload_rounded, titulo: 'API', texto: 'La app envía la foto de forma segura al servidor.'),
                const _Paso(numero: 3, icono: Icons.memory_rounded, titulo: 'Modelo', texto: 'Una red neuronal analiza la imagen y calcula una probabilidad.'),
                const _Paso(numero: 4, icono: Icons.traffic_rounded, titulo: 'Semáforo', texto: 'Recibes un nivel verde, amarillo o rojo con una recomendación.', ultimo: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AvisoLegal(
            texto: 'MandiDog IA no realiza diagnósticos. Sus resultados son orientativos y no reemplazan '
                'el diagnóstico de un médico veterinario. Ante cualquier duda, consulta a un profesional.',
          ),
          const SizedBox(height: 16),
          Tarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Proyecto de grado', style: titulo),
                const SizedBox(height: 10),
                const _Linea(icono: Icons.person_rounded, texto: 'Autor: ${ConfiguracionApp.autor}'),
                const _Linea(icono: Icons.school_rounded, texto: ConfiguracionApp.universidad),
                const _Linea(icono: Icons.code_rounded, texto: ConfiguracionApp.programa),
                const _Linea(
                  icono: Icons.location_on_rounded,
                  texto: '${ConfiguracionApp.ciudad}, ${ConfiguracionApp.anio}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  const _Paso({required this.numero, required this.icono, required this.titulo, required this.texto, this.ultimo = false});

  final int numero;
  final IconData icono;
  final String titulo;
  final String texto;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: ColoresMandiDog.coral),
                child: Icon(icono, color: Colors.white, size: 20),
              ),
              if (!ultimo)
                Expanded(child: Container(width: 2, color: ColoresMandiDog.coral.withValues(alpha: 0.3))),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: ultimo ? 0 : 16, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$numero. $titulo', style: textos.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(texto, style: textos.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Linea extends StatelessWidget {
  const _Linea({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icono, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
