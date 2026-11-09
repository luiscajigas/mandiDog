"""Convierte el modelo entrenado (.keras) a TensorFlow Lite para que la app lo ejecute en el teléfono.

Genera dos archivos en la carpeta de destino (por defecto, los assets de la app):
  mandidog.tflite  el modelo, con la misma entrada (1, 224, 224, 3) normalizada entre 0 y 1
  modelo.json      versión del modelo y umbrales del semáforo

Uso:
    python exportar_tflite.py --modelo models/mandidog_v1.keras
    python exportar_tflite.py --modelo models/mandidog_v1.keras --umbral-amarillo 0.25 --umbral-rojo 0.55

Después se vuelve a compilar el APK (o se sube el cambio a GitHub para que lo compile Actions).
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import tensorflow as tf

TAMANO_ENTRADA = (224, 224)
DESTINO_APP = Path(__file__).resolve().parent.parent / "mobile" / "assets" / "modelo"


def argumentos() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Exporta el modelo de MandiDog IA a TensorFlow Lite")
    parser.add_argument("--modelo", type=Path, default=Path("models/mandidog_v1.keras"))
    parser.add_argument("--destino", type=Path, default=DESTINO_APP)
    parser.add_argument("--umbral-amarillo", type=float, default=0.30)
    parser.add_argument("--umbral-rojo", type=float, default=0.60)
    parser.add_argument(
        "--cuantizar",
        action="store_true",
        help="Reduce el tamaño del modelo a la cuarta parte (puede variar levemente la probabilidad)",
    )
    return parser.parse_args()


def convertir(modelo: tf.keras.Model, cuantizar: bool = False) -> bytes:
    """Convierte el modelo en modo inferencia: las capas de aumento de datos quedan desactivadas."""

    @tf.function(input_signature=[tf.TensorSpec((1, *TAMANO_ENTRADA, 3), tf.float32, name="imagen")])
    def inferir(imagen):
        return modelo(imagen, training=False)

    convertidor = tf.lite.TFLiteConverter.from_concrete_functions([inferir.get_concrete_function()], modelo)
    if cuantizar:
        convertidor.optimizations = [tf.lite.Optimize.DEFAULT]
    return convertidor.convert()


def verificar(modelo: tf.keras.Model, tflite: bytes, muestras: int = 4) -> float:
    """Compara el modelo original con el convertido sobre imágenes aleatorias; devuelve la diferencia máxima."""
    interprete = tf.lite.Interpreter(model_content=tflite)
    interprete.allocate_tensors()
    entrada = interprete.get_input_details()[0]
    salida = interprete.get_output_details()[0]
    generador = np.random.default_rng(0)
    diferencia = 0.0
    for _ in range(muestras):
        imagen = generador.random((1, *TAMANO_ENTRADA, 3), dtype=np.float32)
        esperado = float(np.asarray(modelo(imagen, training=False)).reshape(-1)[0])
        interprete.set_tensor(entrada["index"], imagen)
        interprete.invoke()
        obtenido = float(interprete.get_tensor(salida["index"]).reshape(-1)[0])
        diferencia = max(diferencia, abs(esperado - obtenido))
    return diferencia


def exportar(ruta_modelo: Path, destino: Path, umbral_amarillo: float, umbral_rojo: float,
             cuantizar: bool = False) -> dict:
    if not 0.0 <= umbral_amarillo < umbral_rojo <= 1.0:
        raise ValueError("Los umbrales deben cumplir 0 <= amarillo < rojo <= 1")

    modelo = tf.keras.models.load_model(ruta_modelo, compile=False)
    tflite = convertir(modelo, cuantizar)
    diferencia = verificar(modelo, tflite)

    destino.mkdir(parents=True, exist_ok=True)
    (destino / "mandidog.tflite").write_bytes(tflite)
    info = {
        "version": ruta_modelo.stem,
        "umbral_amarillo": umbral_amarillo,
        "umbral_rojo": umbral_rojo,
        "cuantizado": cuantizar,
        "fecha": datetime.now(timezone.utc).isoformat(),
    }
    (destino / "modelo.json").write_text(json.dumps(info, indent=2, ensure_ascii=False), encoding="utf-8")

    print(f"Modelo TensorFlow Lite: {destino / 'mandidog.tflite'} ({len(tflite) / 1e6:.1f} MB)")
    print(f"Diferencia máxima frente al modelo original: {diferencia:.5f}")
    return {**info, "diferencia_maxima": diferencia}


def main() -> None:
    args = argumentos()
    exportar(args.modelo, args.destino, args.umbral_amarillo, args.umbral_rojo, args.cuantizar)


if __name__ == "__main__":
    main()
