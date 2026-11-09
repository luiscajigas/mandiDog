import 'package:flutter/material.dart';

import '../../core/theme/tema.dart';

/// Tarjeta con bordes de 20 px y sombra suave.
class Tarjeta extends StatelessWidget {
  const Tarjeta({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.gradiente,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradiente;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(radioTarjeta);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radio,
        color: gradiente == null ? (color ?? Theme.of(context).colorScheme.surface) : null,
        gradient: gradiente,
        boxShadow: sombraSuave(context),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radio,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
