"""Adaptador de inferencia basado en un modelo Keras entrenado con TensorFlow."""

import io
from pathlib import Path

import numpy as np
from PIL import Image, ImageOps

from app.domain.ports import InferencePort, ResultadoInferencia

TAMANO_ENTRADA = (224, 224)


def preprocesar_imagen(image_bytes: bytes) -> np.ndarray:
    """Convierte los bytes en un tensor (1, 224, 224, 3) con canales RGB normalizados entre 0 y 1."""
    with Image.open(io.BytesIO(image_bytes)) as imagen:
        imagen = ImageOps.exif_transpose(imagen).convert("RGB")
        imagen = imagen.resize(TAMANO_ENTRADA, Image.Resampling.BILINEAR)
        arreglo = np.asarray(imagen, dtype=np.float32) / 255.0
    return np.expand_dims(arreglo, axis=0)


class TensorFlowInferenceAdapter(InferencePort):
    """Carga el modelo Keras una sola vez y lo reutiliza en cada predicción.

    El modelo debe tener una salida sigmoide cuyo valor es la probabilidad de la clase "con signos".
    """

    def __init__(self, model_path: str) -> None:
        ruta = Path(model_path)
        if not ruta.is_file():
            raise FileNotFoundError(f"No se encontró el modelo en {ruta}")

        import tensorflow as tf  # importación diferida: TensorFlow tarda en cargar

        self._modelo = tf.keras.models.load_model(ruta, compile=False)
        self._version = ruta.stem

    @property
    def version_modelo(self) -> str:
        return self._version

    def predict(self, image_bytes: bytes) -> ResultadoInferencia:
        tensor = preprocesar_imagen(image_bytes)
        salida = self._modelo(tensor, training=False)
        probabilidad = float(np.clip(np.asarray(salida).reshape(-1)[0], 0.0, 1.0))
        return ResultadoInferencia(probabilidad=probabilidad, version_modelo=self._version)
