"""Servicio de aplicación: traduce la salida del modelo en un nivel de riesgo y una recomendación."""

from datetime import datetime, timezone

from app.domain.modelos import AVISO_LEGAL, RECOMENDACIONES, NivelRiesgo, ResultadoAnalisis
from app.domain.ports import InferencePort


class AnalisisService:
    def __init__(self, motor: InferencePort, umbral_amarillo: float = 0.30, umbral_rojo: float = 0.60) -> None:
        if not 0.0 <= umbral_amarillo < umbral_rojo <= 1.0:
            raise ValueError("Los umbrales deben cumplir 0 <= amarillo < rojo <= 1")
        self._motor = motor
        self._umbral_amarillo = umbral_amarillo
        self._umbral_rojo = umbral_rojo

    def clasificar_nivel(self, probabilidad: float) -> NivelRiesgo:
        """VERDE por debajo del umbral amarillo, ROJO a partir del umbral rojo y AMARILLO entre ambos."""
        if probabilidad < self._umbral_amarillo:
            return NivelRiesgo.VERDE
        if probabilidad < self._umbral_rojo:
            return NivelRiesgo.AMARILLO
        return NivelRiesgo.ROJO

    @staticmethod
    def recomendacion_para(nivel: NivelRiesgo) -> str:
        return RECOMENDACIONES[nivel]

    def analizar(self, image_bytes: bytes) -> ResultadoAnalisis:
        inferencia = self._motor.predict(image_bytes)
        nivel = self.clasificar_nivel(inferencia.probabilidad)
        return ResultadoAnalisis(
            probabilidad=round(inferencia.probabilidad, 4),
            nivel=nivel,
            recomendacion=self.recomendacion_para(nivel),
            aviso=AVISO_LEGAL,
            version_modelo=inferencia.version_modelo,
            modo_demo=self._motor.modo_demo,
            fecha=datetime.now(timezone.utc),
        )
