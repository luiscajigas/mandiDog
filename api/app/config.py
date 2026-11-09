"""Configuración de la API leída desde variables de entorno o archivo .env."""

from functools import lru_cache

from pydantic import Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Parámetros configurables del servicio."""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    model_path: str = Field(default="models/mandidog_v1.keras", alias="MODEL_PATH")
    umbral_amarillo: float = Field(default=0.30, ge=0.0, le=1.0, alias="UMBRAL_AMARILLO")
    umbral_rojo: float = Field(default=0.60, ge=0.0, le=1.0, alias="UMBRAL_ROJO")
    max_tamano_mb: int = Field(default=10, gt=0, alias="MAX_TAMANO_MB")
    cors_origins: str = Field(default="*", alias="CORS_ORIGINS")

    @model_validator(mode="after")
    def _validar_umbrales(self) -> "Settings":
        if self.umbral_amarillo >= self.umbral_rojo:
            raise ValueError("UMBRAL_AMARILLO debe ser menor que UMBRAL_ROJO")
        return self

    @property
    def max_tamano_bytes(self) -> int:
        return self.max_tamano_mb * 1024 * 1024

    @property
    def lista_cors(self) -> list[str]:
        return [origen.strip() for origen in self.cors_origins.split(",") if origen.strip()]


@lru_cache
def obtener_settings() -> Settings:
    return Settings()
