"""Proveedores de dependencias. No crean adaptadores: leen los que registró main.py."""

from fastapi import Request

from app.config import Settings
from app.domain.ports import InferencePort
from app.services.analisis_service import AnalisisService


def obtener_configuracion(request: Request) -> Settings:
    return request.app.state.settings


def obtener_motor(request: Request) -> InferencePort:
    return request.app.state.motor


def obtener_servicio(request: Request) -> AnalisisService:
    return request.app.state.servicio
