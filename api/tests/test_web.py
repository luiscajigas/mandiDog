from fastapi.testclient import TestClient

from app.config import Settings
from app.main import crear_app


def test_sirve_la_version_web_sin_tapar_la_api(tmp_path):
    web = tmp_path / "web"
    web.mkdir()
    (web / "index.html").write_text("<title>MandiDog IA</title>", encoding="utf-8")
    cliente = TestClient(crear_app(Settings(MODEL_PATH=str(tmp_path / "no.keras"), WEB_DIR=str(web))))

    pagina = cliente.get("/")
    assert pagina.status_code == 200
    assert "MandiDog IA" in pagina.text

    assert cliente.get("/health").json()["estado"] == "ok"


def test_sin_web_dir_la_raiz_no_existe(cliente):
    assert cliente.get("/").status_code == 404
