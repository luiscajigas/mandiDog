"""Esquemas de entrada y salida de la API."""

from datetime import datetime

from pydantic import BaseModel, Field

from app.domain.modelos import NivelRiesgo, ResultadoAnalisis


class AnalisisRespuesta(BaseModel):
    probabilidad: float = Field(..., ge=0.0, le=1.0, examples=[0.42])
    nivel: NivelRiesgo = Field(..., examples=["AMARILLO"])
    recomendacion: str
    aviso: str
    version_modelo: str = Field(..., examples=["mandidog_v1"])
    modo_demo: bool
    fecha: datetime

    @classmethod
    def desde_dominio(cls, resultado: ResultadoAnalisis) -> "AnalisisRespuesta":
        return cls(
            probabilidad=resultado.probabilidad,
            nivel=resultado.nivel,
            recomendacion=resultado.recomendacion,
            aviso=resultado.aviso,
            version_modelo=resultado.version_modelo,
            modo_demo=resultado.modo_demo,
            fecha=resultado.fecha,
        )


class HealthRespuesta(BaseModel):
    estado: str = Field(..., examples=["ok"])
    version_modelo: str
    modo_demo: bool


class ErrorRespuesta(BaseModel):
    detalle: str
