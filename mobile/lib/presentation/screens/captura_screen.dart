import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/navegacion/rutas.dart';
import '../../core/theme/colores.dart';
import '../../domain/entities/imagen_capturada.dart';
import '../widgets/marco_encuadre.dart';
import 'analizando_screen.dart';

/// En el navegador la cámara se abre con la app nativa del teléfono (no requiere HTTPS).
enum _EstadoCamara { iniciando, lista, sinCamara, permisoDenegado, web }

/// Captura de la foto: vista previa con marco de encuadre, galería y confirmación.
class CapturaScreen extends StatefulWidget {
  const CapturaScreen({super.key});

  @override
  State<CapturaScreen> createState() => _CapturaScreenState();
}

class _CapturaScreenState extends State<CapturaScreen> with WidgetsBindingObserver {
  final _selector = ImagePicker();
  CameraController? _camara;
  _EstadoCamara _estado = kIsWeb ? _EstadoCamara.web : _EstadoCamara.iniciando;
  ImagenCapturada? _foto;
  bool _ocupado = false;
  FlashMode _flash = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb) _iniciarCamara();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camara?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    final camara = _camara;
    if (camara == null || !camara.value.isInitialized) return;
    if (estado == AppLifecycleState.inactive) {
      _camara = null;
      camara.dispose();
      if (mounted) setState(() => _estado = _EstadoCamara.iniciando);
    } else if (estado == AppLifecycleState.resumed && _foto == null) {
      _iniciarCamara();
    }
  }

  Future<void> _iniciarCamara() async {
    if (kIsWeb) return;
    setState(() => _estado = _EstadoCamara.iniciando);
    try {
      final camaras = await availableCameras();
      if (camaras.isEmpty) {
        if (mounted) setState(() => _estado = _EstadoCamara.sinCamara);
        return;
      }
      final trasera = camaras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => camaras.first,
      );
      final controlador = CameraController(
        trasera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controlador.initialize();
      await controlador.setFlashMode(_flash).catchError((_) {});
      if (!mounted) {
        await controlador.dispose();
        return;
      }
      await _camara?.dispose();
      setState(() {
        _camara = controlador;
        _estado = _EstadoCamara.lista;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      final denegado = e.code.contains('Access') || e.code.contains('Permission');
      setState(() => _estado = denegado ? _EstadoCamara.permisoDenegado : _EstadoCamara.sinCamara);
    } on Object {
      if (mounted) setState(() => _estado = _EstadoCamara.sinCamara);
    }
  }

  Future<void> _tomarFoto() async {
    if (kIsWeb) return _elegir(ImageSource.camera);
    final camara = _camara;
    if (camara == null || !camara.value.isInitialized || camara.value.isTakingPicture || _ocupado) return;
    setState(() => _ocupado = true);
    try {
      final archivo = await camara.takePicture();
      final foto = ImagenCapturada(bytes: await archivo.readAsBytes(), nombre: archivo.name);
      if (mounted) setState(() => _foto = foto);
    } on Object {
      _mostrarMensaje('No pudimos tomar la foto. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _elegir(ImageSource origen) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      final archivo = await _selector.pickImage(
        source: origen,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (archivo != null) {
        final foto = ImagenCapturada(bytes: await archivo.readAsBytes(), nombre: archivo.name);
        if (mounted) setState(() => _foto = foto);
      }
    } on Object {
      _mostrarMensaje(origen == ImageSource.camera
          ? 'No pudimos abrir la cámara. Revisa los permisos del navegador o elige una foto de la galería.'
          : 'No pudimos abrir la galería. Revisa los permisos de la app.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _alternarFlash() async {
    final siguiente = _flash == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await _camara?.setFlashMode(siguiente);
      setState(() => _flash = siguiente);
    } on Object {
      _mostrarMensaje('Esta cámara no tiene linterna.');
    }
  }

  void _repetir() {
    setState(() => _foto = null);
    if (_camara == null && !kIsWeb) _iniciarCamara();
  }

  void _analizar() {
    final foto = _foto;
    if (foto == null) return;
    Navigator.of(context).pushReplacement(rutaAnimada(AnalizandoScreen(imagen: foto)));
  }

  void _mostrarMensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  bool get _puedeDisparar => _estado == _EstadoCamara.lista || _estado == _EstadoCamara.web;

  @override
  Widget build(BuildContext context) {
    final foto = _foto;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text(foto == null ? 'Toma la foto' : 'Revisa la foto', style: const TextStyle(color: Colors.white)),
        actions: [
          if (foto == null && _estado == _EstadoCamara.lista)
            IconButton(
              tooltip: _flash == FlashMode.off ? 'Encender linterna' : 'Apagar linterna',
              icon: Icon(_flash == FlashMode.off ? Icons.flash_off_rounded : Icons.flash_on_rounded),
              onPressed: _alternarFlash,
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: foto == null ? _vistaCamara() : _vistaConfirmacion(foto),
      ),
    );
  }

  Widget _vistaCamara() {
    return Column(
      key: const ValueKey('camara'),
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _previsualizacion(),
              if (_estado == _EstadoCamara.lista || _estado == _EstadoCamara.web) const MarcoEncuadre(),
            ],
          ),
        ),
        _barraControles(),
      ],
    );
  }

  Widget _previsualizacion() {
    final camara = _camara;
    switch (_estado) {
      case _EstadoCamara.iniciando:
        return const Center(child: CircularProgressIndicator(color: Colors.white));
      case _EstadoCamara.web:
        return const _FondoGuiaWeb();
      case _EstadoCamara.sinCamara:
      case _EstadoCamara.permisoDenegado:
        return _AvisoCamara(
          permisoDenegado: _estado == _EstadoCamara.permisoDenegado,
          onReintentar: _iniciarCamara,
          onGaleria: () => _elegir(ImageSource.gallery),
        );
      case _EstadoCamara.lista:
        if (camara == null || !camara.value.isInitialized) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        final tamano = camara.value.previewSize;
        if (tamano == null) return CameraPreview(camara);
        return ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(width: tamano.height, height: tamano.width, child: CameraPreview(camara)),
          ),
        );
    }
  }

  Widget _barraControles() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 22),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _BotonRedondo(
              icono: Icons.photo_library_rounded,
              etiqueta: 'Galería',
              onPressed: _ocupado ? null : () => _elegir(ImageSource.gallery),
            ),
            Semantics(
              button: true,
              label: 'Tomar foto',
              child: GestureDetector(
                onTap: _puedeDisparar ? _tomarFoto : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 82,
                  height: 82,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _puedeDisparar ? (_ocupado ? Colors.white54 : ColoresMandiDog.coral) : Colors.white24,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 32),
                  ),
                ),
              ),
            ),
            if (kIsWeb)
              const SizedBox(width: 56)
            else
              _BotonRedondo(
                icono: Icons.refresh_rounded,
                etiqueta: 'Reiniciar',
                onPressed: _ocupado ? null : _iniciarCamara,
              ),
          ],
        ),
      ),
    );
  }

  Widget _vistaConfirmacion(ImagenCapturada foto) {
    final textos = Theme.of(context).textTheme;
    return SafeArea(
      key: ObjectKey(foto),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 64, 20, 20),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.memory(
                  foto.bytes,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No pudimos mostrar la foto. Si viene de un iPhone, intenta tomarla de nuevo desde la app.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.96, 0.96)),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Se ve bien la boca de tu perro? Asegúrate de que la foto esté enfocada y con buena luz.',
              textAlign: TextAlign.center,
              style: textos.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54, width: 1.5),
                    ),
                    onPressed: _repetir,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Repetir'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: ColoresMandiDog.coral),
                    onPressed: _analizar,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Analizar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Fondo de la versión web: explica cómo encuadrar antes de abrir la cámara del teléfono.
class _FondoGuiaWeb extends StatelessWidget {
  const _FondoGuiaWeb();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final marco = MarcoEncuadre.rectanguloPara(Size(restricciones.maxWidth, restricciones.maxHeight));
        return Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [ColoresMandiDog.petroleo, Color(0xFF07262E)],
                  ),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: marco.deflate(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pets_rounded, color: Colors.white54, size: 56),
                  const SizedBox(height: 12),
                  Text(
                    'Pulsa el botón para abrir la cámara.\nLevanta suavemente el labio para que se vean las encías y los dientes.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BotonRedondo extends StatelessWidget {
  const _BotonRedondo({required this.icono, required this.etiqueta, required this.onPressed});

  final IconData icono;
  final String etiqueta;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: onPressed,
          iconSize: 26,
          style: IconButton.styleFrom(backgroundColor: Colors.white12, foregroundColor: Colors.white),
          icon: Icon(icono),
          tooltip: etiqueta,
        ),
        const SizedBox(height: 4),
        Text(etiqueta, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _AvisoCamara extends StatelessWidget {
  const _AvisoCamara({required this.permisoDenegado, required this.onReintentar, required this.onGaleria});

  final bool permisoDenegado;
  final VoidCallback onReintentar;
  final VoidCallback onGaleria;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_rounded, color: Colors.white70, size: 64),
            const SizedBox(height: 16),
            Text(
              permisoDenegado ? 'Necesitamos permiso para usar la cámara' : 'No pudimos acceder a la cámara',
              textAlign: TextAlign.center,
              style: textos.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              permisoDenegado
                  ? 'Concede el permiso desde los ajustes del teléfono o elige una foto de la galería.'
                  : 'Puedes intentarlo de nuevo o elegir una foto de la galería.',
              textAlign: TextAlign.center,
              style: textos.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: ColoresMandiDog.coral),
              onPressed: onGaleria,
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('Elegir de la galería'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('Reintentar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
