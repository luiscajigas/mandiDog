import io

from fastapi.testclient import TestClient
from PIL import Image

from app.config import Settings
from app.domain.modelos import AVISO_LEGAL
from app.main import crear_app

NIVELES_VALIDOS = {"VERDE", "AMARILLO", "ROJO"}


def test_analisis_con_jpg_valido_devuelve_nivel_valido(cliente, jpg_bytes):
    respuesta = cliente.post("/v1/analisis", files={"imagen": ("boca.jpg", jpg_bytes, "image/jpeg")})

    assert respuesta.status_code == 200
    cuerpo = respuesta.json()
    assert cuerpo["nivel"] in NIVELES_VALIDOS
    assert 0.0 <= cuerpo["probabilidad"] <= 1.0
    assert cuerpo["aviso"] == AVISO_LEGAL
    assert cuerpo["modo_demo"] is True
    assert cuerpo["version_modelo"] == "demo-sin-entrenar"
    assert cuerpo["recomendacion"]
    assert cuerpo["fecha"]


def test_analisis_con_png_valido_devuelve_nivel_valido(cliente, png_bytes):
    respuesta = cliente.post("/v1/analisis", files={"imagen": ("boca.png", png_bytes, "image/png")})

    assert respuesta.status_code == 200
    assert respuesta.json()["nivel"] in NIVELES_VALIDOS


def test_modo_demo_es_determinista(cliente, jpg_bytes):
    archivos = {"imagen": ("boca.jpg", jpg_bytes, "image/jpeg")}
    primera = cliente.post("/v1/analisis", files=archivos).json()
    segunda = cliente.post("/v1/analisis", files=archivos).json()

    assert primera["probabilidad"] == segunda["probabilidad"]


def test_archivo_que_no_es_imagen_devuelve_422(cliente):
    archivos = {"imagen": ("notas.txt", b"hola, no soy una foto", "text/plain")}
    respuesta = cliente.post("/v1/analisis", files=archivos)

    assert respuesta.status_code == 422
    assert "JPG o PNG" in respuesta.json()["detalle"]


def test_bytes_corruptos_con_extension_jpg_devuelven_422(cliente):
    archivos = {"imagen": ("falsa.jpg", b"\xff\xd8basura", "image/jpeg")}
    respuesta = cliente.post("/v1/analisis", files=archivos)

    assert respuesta.status_code == 422
    assert "no es una imagen válida" in respuesta.json()["detalle"]


def test_formato_no_permitido_devuelve_422(cliente):
    buffer = io.BytesIO()
    Image.new("RGB", (10, 10)).save(buffer, format="GIF")
    archivos = {"imagen": ("perro.gif", buffer.getvalue(), "application/octet-stream")}
    respuesta = cliente.post("/v1/analisis", files=archivos)

    assert respuesta.status_code == 422
    assert "JPG o PNG" in respuesta.json()["detalle"]


def test_imagen_demasiado_grande_devuelve_422(tmp_path, jpg_bytes):
    settings = Settings(MODEL_PATH=str(tmp_path / "no.keras"), MAX_TAMANO_MB=1)
    cliente = TestClient(crear_app(settings))
    grande = jpg_bytes + b"\x00" * (1024 * 1024 + 1)

    respuesta = cliente.post("/v1/analisis", files={"imagen": ("grande.jpg", grande, "image/jpeg")})

    assert respuesta.status_code == 422
    assert "tamaño máximo" in respuesta.json()["detalle"]


def test_sin_campo_imagen_devuelve_422_en_espanol(cliente):
    respuesta = cliente.post("/v1/analisis")

    assert respuesta.status_code == 422
    assert "imagen" in respuesta.json()["detalle"]
