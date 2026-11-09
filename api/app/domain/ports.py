"""Puertos del dominio: contratos que deben cumplir los adaptadores de infraestructura."""

from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass(frozen=True)
class ResultadoInferencia:
    """Salida cruda del modelo para una imagen."""

    probabilidad: float
    """Probabilidad (0 a 1) de que la imagen presente signos visibles de patología mandibular."""

    version_modelo: str

    def __post_init__(self) -> None:
        if not 0.0 <= self.probabilidad <= 1.0:
            raise ValueError("La probabilidad debe estar entre 0 y 1")


class InferencePort(ABC):
    """Puerto de inferencia: cualquier motor de clasificación debe implementarlo."""

    @property
    @abstractmethod
    def version_modelo(self) -> str:
        """Identificador de la versión del modelo cargado."""

    @property
    def modo_demo(self) -> bool:
        """Indica si el motor es un simulador sin modelo entrenado."""
        return False

    @abstractmethod
    def predict(self, image_bytes: bytes) -> ResultadoInferencia:
        """Clasifica la imagen y devuelve la probabilidad de la clase "con signos"."""
