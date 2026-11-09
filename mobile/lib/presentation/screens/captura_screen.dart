import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/navegacion/rutas.dart';
import '../../core/theme/colores.dart';
import '../widgets/marco_encuadre.dart';
import 'analizando_screen.dart';

enum _EstadoCamara { iniciando, lista, sinCamara, permisoDenegado }

/// Captura de la foto: vista previa con marco de encuadre, galería y confirmación.
class CapturaScreen extends StatefulWidget {
  const CapturaScreen({super.key});

  @override
  State<CapturaScreen> createState() => _CapturaScreenState();
}

class _CapturaScreenState extends State<CapturaScreen> with WidgetsBindingObserver {
  final _selector = ImagePicker();
  CameraController? _camara;
  _EstadoCamara _estado = _EstadoCamara.iniciando;
  String? _fotoPath;
  bool _ocupado = false;
  FlashMode _flash = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _iniciarCamara();
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
    } else if (estado == AppLifecycleState.resumed && _fotoPath == null) {
      _iniciarCamara();
    }
  }

  Future<void> _iniciarCamara() async {
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
    final camara = _camara;
    if (camara == null || !camara.value.isInitialized || camara.value.isTakingPicture || _ocupado) return;
    setState(() => _ocupado = true);
    try {
      final foto = await camara.takePicture();
      if (mounted) setState(() => _fotoPath = foto.path);
    } on Object {
      _mostrarMensaje('No pudimos tomar la foto. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _elegirDeGaleria() async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      final foto = await _selector.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (foto != null && mounted) setState(() => _fotoPath = foto.path);
    } on Object {
      _mostrarMensaje('No pudimos abrir la galería. Revisa los permisos de la app.');
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
    setState(() => _fotoPath = null);
    if (_camara == null) _iniciarCamara();
  }

  void _analizar() {
    final ruta = _fotoPath;
    if (ruta == null) return;
    Navigator.of(context).pushReplacement(rutaAnimada(AnalizandoScreen(imagenPath: ruta)));
  }

  void _mostrarMensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text(_fotoPath == null ? 'Toma la foto' : 'Revisa la foto',
            style: const TextStyle(color: Colors.white)),
        actions: [
          if (_fotoPath == null && _estado == _EstadoCamara.lista)
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
        child: _fotoPath == null ? _vistaCamara() : _vistaConfirmacion(_fotoPath!),
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
              if (_estado == _EstadoCamara.lista) const MarcoEncuadre(),
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
      case _EstadoCamara.sinCamara:
      case _EstadoCamara.permisoDenegado:
        return _AvisoCamara(
          permisoDenegado: _estado == _EstadoCamara.permisoDenegado,
          onReintentar: _iniciarCamara,
          onGaleria: _elegirDeGaleria,
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
              onPressed: _ocupado ? null : _elegirDeGaleria,
            ),
            Semantics(
              button: true,
              label: 'Tomar foto',
              child: GestureDetector(
                onTap: _estado == _EstadoCamara.lista ? _tomarFoto : null,
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
                      color: _estado == _EstadoCamara.lista
                          ? (_ocupado ? Colors.white54 : ColoresMandiDog.coral)
                          : Colors.white24,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 32),
                  ),
                ),
              ),
            ),
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

  Widget _vistaConfirmacion(String ruta) {
    final textos = Theme.of(context).textTheme;
    return SafeArea(
      key: ValueKey(ruta),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 64, 20, 20),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(ruta),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Text('No pudimos mostrar la foto', style: TextStyle(color: Colors.white)),
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
