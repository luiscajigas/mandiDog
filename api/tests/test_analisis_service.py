import pytest

from app.config import Settings
from app.domain.modelos import RECOMENDACIONES, NivelRiesgo
from app.domain.ports import InferencePort, ResultadoInferencia
from app.services.analisis_service import AnalisisService


class MotorFijo(InferencePort):
    def __init__(self, probabilidad: float) -> None:
        self._probabilidad = probabilidad

    @property
    def version_modelo(self) -> str:
        return "prueba"

    def predict(self, image_bytes: bytes) -> ResultadoInferencia:
        return ResultadoInferencia(self._probabilidad, "prueba")


@pytest.mark.parametrize(
    ("probabilidad", "esperado"),
    [
        (0.0, NivelRiesgo.VERDE),
        (0.29, NivelRiesgo.VERDE),
        (0.30, NivelRiesgo.AMARILLO),
        (0.45, NivelRiesgo.AMARILLO),
        (0.5999, NivelRiesgo.AMARILLO),
        (0.60, NivelRiesgo.ROJO),
        (1.0, NivelRiesgo.ROJO),
    ],
)
def test_umbrales_por_defecto(probabilidad, esperado):
    servicio = AnalisisService(MotorFijo(probabilidad), 0.30, 0.60)

    assert servicio.clasificar_nivel(probabilidad) is esperado


def test_umbrales_personalizados():
    servicio = AnalisisService(MotorFijo(0.5), umbral_amarillo=0.5, umbral_rojo=0.8)

    assert servicio.clasificar_nivel(0.49) is NivelRiesgo.VERDE
    assert servicio.clasificar_nivel(0.5) is NivelRiesgo.AMARILLO
    assert servicio.clasificar_nivel(0.8) is NivelRiesgo.ROJO


@pytest.mark.parametrize("nivel", list(NivelRiesgo))
def test_cada_nivel_tiene_su_recomendacion(nivel):
    probabilidad = {NivelRiesgo.VERDE: 0.1, NivelRiesgo.AMARILLO: 0.4, NivelRiesgo.ROJO: 0.9}[nivel]
    resultado = AnalisisService(MotorFijo(probabilidad)).analizar(b"imagen")

    assert resultado.nivel is nivel
    assert resultado.recomendacion == RECOMENDACIONES[nivel]
    assert resultado.modo_demo is False


def test_umbrales_invertidos_son_rechazados():
    with pytest.raises(ValueError):
        AnalisisService(MotorFijo(0.1), umbral_amarillo=0.7, umbral_rojo=0.3)


def test_umbrales_leidos_desde_variables_de_entorno(monkeypatch):
    monkeypatch.setenv("UMBRAL_AMARILLO", "0.2")
    monkeypatch.setenv("UMBRAL_ROJO", "0.9")
    settings = Settings(_env_file=None)

    assert settings.umbral_amarillo == 0.2
    assert settings.umbral_rojo == 0.9
