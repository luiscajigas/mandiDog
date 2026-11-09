"""Entidades y valores del dominio de análisis."""

from dataclasses import dataclass
from datetime import datetime
from enum import Enum

AVISO_LEGAL = "Este resultado es orientativo y no reemplaza el diagnóstico de un médico veterinario."


class NivelRiesgo(str, Enum):
    VERDE = "VERDE"
    AMARILLO = "AMARILLO"
    ROJO = "ROJO"


RECOMENDACIONES: dict[NivelRiesgo, str] = {
    NivelRiesgo.VERDE: "No se observan signos aparentes. Mantén las revisiones veterinarias periódicas.",
    NivelRiesgo.AMARILLO: "Se observan posibles signos leves. Programa una revisión con tu veterinario.",
    NivelRiesgo.ROJO: "Se observan signos que requieren atención. Consulta a un veterinario lo antes posible.",
}


@dataclass(frozen=True)
class ResultadoAnalisis:
    probabilidad: float
    nivel: NivelRiesgo
    recomendacion: str
    aviso: str
    version_modelo: str
    modo_demo: bool
    fecha: datetime
