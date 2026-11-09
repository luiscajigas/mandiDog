import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/navegacion/rutas.dart';
import '../../core/theme/colores.dart';
import '../../domain/entities/estado_servidor.dart';
import '../../domain/repositories/analisis_repository.dart';
import '../state/controlador_tema.dart';
import '../widgets/logo_mandidog.dart';
import '../widgets/tarjeta.dart';
import 'acerca_de_screen.dart';
import 'captura_screen.dart';
import 'historial_screen.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  late Future<EstadoServidor> _estado;

  @override
  void initState() {
    super.initState();
    _estado = context.read<AnalisisRepository>().consultarEstado();
  }

  Future<void> _actualizarEstado() async {
    final consulta = context.read<AnalisisRepository>().consultarEstado();
    setState(() => _estado = consulta);
    await consulta;
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final tema = context.watch<ControladorTema>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const LogoMandiDog(tamano: 34),
            const SizedBox(width: 10),
            const Text('MandiDog IA'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: tema.oscuro ? 'Usar tema claro' : 'Usar tema oscuro',
            icon: Icon(tema.oscuro ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: tema.alternar,
          ),
          IconButton(
            tooltip: 'Acerca de',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => Navigator.of(context).push(rutaAnimada(const AcercaDeScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _actualizarEstado,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text('¡Hola!', style: textos.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('¿Cómo está la boca de tu perro hoy?', style: textos.bodyLarge),
            const SizedBox(height: 14),
            _IndicadorServidor(estado: _estado, onReintentar: _actualizarEstado),
            const SizedBox(height: 20),
            const _TarjetaAnalizar(),
            const SizedBox(height: 16),
            Tarjeta(
              onTap: () => Navigator.of(context).push(rutaAnimada(const HistorialScreen())),
              child: Row(
                children: [
                  _IconoCirculo(icono: Icons.history_rounded, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Historial', style: textos.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        Text('Consulta tus análisis anteriores', style: textos.bodyMedium),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.15),
            const SizedBox(height: 16),
            const _TarjetaConsejos().animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.15),
          ],
        ),
      ),
    );
  }
}

class _TarjetaAnalizar extends StatelessWidget {
  const _TarjetaAnalizar();

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Tarjeta(
      padding: const EdgeInsets.all(24),
      gradiente: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [ColoresMandiDog.petroleoClaro, ColoresMandiDog.petroleo],
      ),
      onTap: () => Navigator.of(context).push(rutaAnimada(const CapturaScreen())),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analizar a mi perro',
                  style: textos.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toma una foto de su boca y obtén una orientación en segundos.',
                  style: textos.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: ColoresMandiDog.coral,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Empezar',
                        style: textos.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.14)),
            child: const Icon(Icons.pets_rounded, size: 46, color: Colors.white),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15);
  }
}

class _IndicadorServidor extends StatelessWidget {
  const _IndicadorServidor({required this.estado, required this.onReintentar});

  final Future<EstadoServidor> estado;
  final Future<void> Function() onReintentar;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EstadoServidor>(
      future: estado,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Wrap(children: [
            _Etiqueta(icono: Icons.sync_rounded, texto: 'Conectando con el servidor…', color: Colors.blueGrey),
          ]);
        }
        final datos = snapshot.data ?? const EstadoServidor.noDisponible();
        if (!datos.disponible) {
          return Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _Etiqueta(icono: Icons.cloud_off_rounded, texto: 'Servidor no disponible', color: ColoresMandiDog.rojo),
              TextButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const _Etiqueta(icono: Icons.cloud_done_rounded, texto: 'Servidor conectado', color: ColoresMandiDog.verde),
            if (datos.modoDemo)
              const _Etiqueta(icono: Icons.science_rounded, texto: 'Modo demostración', color: ColoresMandiDog.coral),
          ],
        );
      },
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.icono, required this.texto, required this.color});

  final IconData icono;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 6),
          Text(texto, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _IconoCirculo extends StatelessWidget {
  const _IconoCirculo({required this.icono, required this.color});

  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.12)),
      child: Icon(icono, color: color),
    );
  }
}

class _TarjetaConsejos extends StatefulWidget {
  const _TarjetaConsejos();

  @override
  State<_TarjetaConsejos> createState() => _TarjetaConsejosState();
}

class _TarjetaConsejosState extends State<_TarjetaConsejos> {
  static const _consejos = [
    (Icons.brush_rounded, 'Cepilla sus dientes', 'Usa cepillo y pasta para perros entre 3 y 7 veces por semana.'),
    (Icons.search_rounded, 'Revisa su boca', 'Busca encías inflamadas, sarro, mal aliento o bultos cada semana.'),
    (Icons.restaurant_rounded, 'Cuida su alimentación', 'Prefiere croquetas y premios dentales aprobados por tu veterinario.'),
    (Icons.local_hospital_rounded, 'Visita al veterinario', 'Programa una revisión oral al menos una vez al año.'),
    (Icons.warning_amber_rounded, 'Atiende las señales', 'Si le cuesta comer, babea mucho o tiene la cara hinchada, consulta pronto.'),
  ];

  final _controlador = PageController(viewportFraction: 1);
  int _pagina = 0;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final primario = Theme.of(context).colorScheme.primary;

    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded, color: ColoresMandiDog.coral),
              const SizedBox(width: 8),
              Text('Consejos de salud oral', style: textos.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: PageView.builder(
              controller: _controlador,
              itemCount: _consejos.length,
              onPageChanged: (i) => setState(() => _pagina = i),
              itemBuilder: (context, i) {
                final (icono, titulo, texto) = _consejos[i];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IconoCirculo(icono: icono, color: primario),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(titulo, style: textos.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(texto, style: textos.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _consejos.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _pagina ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _pagina ? ColoresMandiDog.coral : primario.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
