# TensorFlow Lite: el código nativo usa estas clases por reflexión; no se deben eliminar.
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**
