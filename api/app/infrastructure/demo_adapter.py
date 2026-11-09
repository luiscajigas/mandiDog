"""Adaptador de demostración: se usa solo cuando no existe un modelo entrenado."""

import hashlib

from app.domain.ports import InferencePort, ResultadoInferencia


class DemoInferenceAdapter(InferencePort):
    """Simula una inferencia determinista a partir del contenido de la imagen.

    La misma imagen produce siempre la misma probabilidad. No tiene valor clínico.
    """

    VERSION = "demo-sin-entrenar"

    @property
    def version_modelo(self) -> str:
        return self.VERSION

    @property
    def modo_demo(self) -> bool:
        return True

    def predict(self, image_bytes: bytes) -> ResultadoInferencia:
        resumen = hashlib.sha256(image_bytes).digest()
        valor = int.from_bytes(resumen[:8], "big") / float(2**64 - 1)
        return ResultadoInferencia(probabilidad=round(valor, 4), version_modelo=self.VERSION)
