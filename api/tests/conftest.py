import io

import pytest
from fastapi.testclient import TestClient
from PIL import Image

from app.config import Settings
from app.main import crear_app


def _imagen_bytes(formato: str, color=(180, 90, 90)) -> bytes:
    buffer = io.BytesIO()
    Image.new("RGB", (64, 48), color).save(buffer, format=formato)
    return buffer.getvalue()


@pytest.fixture
def settings_demo(tmp_path) -> Settings:
    return Settings(MODEL_PATH=str(tmp_path / "no_existe.keras"))


@pytest.fixture
def cliente(settings_demo) -> TestClient:
    return TestClient(crear_app(settings_demo))


@pytest.fixture
def jpg_bytes() -> bytes:
    return _imagen_bytes("JPEG")


@pytest.fixture
def png_bytes() -> bytes:
    return _imagen_bytes("PNG", color=(20, 120, 200))
