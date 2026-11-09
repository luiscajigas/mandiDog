import 'package:flutter/material.dart';

import '../../core/theme/colores.dart';

/// Superpone a la cámara un recuadro redondeado con esquinas resaltadas para guiar la foto.
class MarcoEncuadre extends StatelessWidget {
  const MarcoEncuadre({super.key, this.texto = 'Centra la boca de tu perro dentro del marco'});

  final String texto;

  /// Calcula el rectángulo del marco dentro del área disponible.
  static Rect rectanguloPara(Size tamano) {
    final ancho = tamano.width * 0.82;
    final alto = (ancho * 0.85).clamp(0.0, tamano.height * 0.55);
    final centro = Offset(tamano.width / 2, tamano.height * 0.45);
    return Rect.fromCenter(center: centro, width: ancho, height: alto);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final tamano = Size(restricciones.maxWidth, restricciones.maxHeight);
        final marco = rectanguloPara(tamano);
        return Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _PintorMarco(marco))),
            Positioned(
              left: 24,
              right: 24,
              top: marco.bottom + 18,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    texto,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PintorMarco extends CustomPainter {
  _PintorMarco(this.marco);

  final Rect marco;
  static const _radio = 28.0;
  static const _largoEsquina = 38.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(marco, const Radius.circular(_radio));

    // Oscurece todo lo que queda fuera del marco.
    final fuera = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(fuera, Paint()..color = Colors.black.withValues(alpha: 0.45));

    // Borde fino del recuadro.
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.7),
    );

    // Esquinas resaltadas.
    final esquinas = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = ColoresMandiDog.coral;

    final l = marco.left, t = marco.top, r = marco.right, b = marco.bottom;
    const c = _largoEsquina, k = _radio;
    final arco = Rect.fromLTWH(0, 0, k * 2, k * 2);

    canvas.drawPath(
      Path()
        ..moveTo(l, t + k + c)
        ..lineTo(l, t + k)
        ..arcTo(arco.shift(Offset(l, t)), 3.1416, 1.5708, false)
        ..lineTo(l + k + c, t),
      esquinas,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r - k - c, t)
        ..lineTo(r - k, t)
        ..arcTo(arco.shift(Offset(r - 2 * k, t)), -1.5708, 1.5708, false)
        ..lineTo(r, t + k + c),
      esquinas,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r, b - k - c)
        ..lineTo(r, b - k)
        ..arcTo(arco.shift(Offset(r - 2 * k, b - 2 * k)), 0, 1.5708, false)
        ..lineTo(r - k - c, b),
      esquinas,
    );
    canvas.drawPath(
      Path()
        ..moveTo(l + k + c, b)
        ..lineTo(l + k, b)
        ..arcTo(arco.shift(Offset(l, b - 2 * k)), 1.5708, 1.5708, false)
        ..lineTo(l, b - k - c),
      esquinas,
    );
  }

  @override
  bool shouldRepaint(_PintorMarco anterior) => anterior.marco != marco;
}
