"""Verifica que el adaptador real carga un modelo Keras y devuelve una probabilidad válida."""

import pytest

tf = pytest.importorskip("tensorflow")

from fastapi.testclient import TestClient  # noqa: E402

from app.config import Settings  # noqa: E402
from app.infrastructure.tensorflow_adapter import TensorFlowInferenceAdapter  # noqa: E402
from app.main import crear_app  # noqa: E402


@pytest.fixture(scope="module")
def ruta_modelo(tmp_path_factory):
    entrada = tf.keras.Input(shape=(224, 224, 3))
    x = tf.keras.layers.GlobalAveragePooling2D()(entrada)
    salida = tf.keras.layers.Dense(1, activation="sigmoid")(x)
    modelo = tf.keras.Model(entrada, salida)
    ruta = tmp_path_factory.mktemp("modelo") / "mandidog_prueba.keras"
    modelo.save(ruta)
    return ruta


def test_adaptador_tensorflow_predice(ruta_modelo, jpg_bytes):
    adaptador = TensorFlowInferenceAdapter(str(ruta_modelo))
    resultado = adaptador.predict(jpg_bytes)

    assert 0.0 <= resultado.probabilidad <= 1.0
    assert resultado.version_modelo == "mandidog_prueba"
    assert adaptador.modo_demo is False


def test_app_usa_adaptador_tensorflow_si_existe_el_modelo(ruta_modelo, png_bytes):
    cliente = TestClient(crear_app(Settings(MODEL_PATH=str(ruta_modelo))))

    assert cliente.get("/health").json()["modo_demo"] is False
    respuesta = cliente.post("/v1/analisis", files={"imagen": ("b.png", png_bytes, "image/png")})
    assert respuesta.status_code == 200
    assert respuesta.json()["modo_demo"] is False
