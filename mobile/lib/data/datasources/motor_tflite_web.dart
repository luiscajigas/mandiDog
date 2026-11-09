import 'package:flutter/services.dart';

import 'motor_inferencia.dart';

/// La versión web no ejecuta el modelo: analiza las fotos a través de la API.
Future<MotorInferencia?> cargarMotorTflite(AssetBundle bundle, InfoModelo info) async => null;
