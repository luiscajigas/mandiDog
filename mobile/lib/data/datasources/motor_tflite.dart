// En Android se usa TensorFlow Lite; en la web (sin dart:ffi) no hay motor nativo.
export 'motor_tflite_web.dart' if (dart.library.ffi) 'motor_tflite_nativo.dart';
