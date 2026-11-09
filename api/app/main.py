"""Composition root de la API.

Es el único lugar donde se instancian los adaptadores de infraestructura. Los demás módulos
reciben sus dependencias mediante Depends.
"""

import logging
from pathlib import Path

from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from app.api.routes import router
from app.config import Settings, obtener_settings
from app.domain.ports import InferencePort
from app.infrastructure.demo_adapter import DemoInferenceAdapter
from app.infrastructure.tensorflow_adapter import TensorFlowInferenceAdapter
from app.services.analisis_service import AnalisisService

logger = logging.getLogger("mandidog")


def construir_motor(settings: Settings) -> InferencePort:
    """Usa el modelo entrenado si existe; si no, recurre al adaptador de demostración."""
    if Path(settings.model_path).is_file():
        logger.info("Cargando modelo desde %s", settings.model_path)
        return TensorFlowInferenceAdapter(settings.model_path)
    logger.warning("No existe el modelo en %s. Se usará el modo demostración.", settings.model_path)
    return DemoInferenceAdapter()


def crear_app(settings: Settings | None = None, motor: InferencePort | None = None) -> FastAPI:
    settings = settings or obtener_settings()
    motor = motor or construir_motor(settings)

    app = FastAPI(
        title="MandiDog IA",
        description=(
            "API de apoyo a la detección temprana de anomalías mandibulares en perros. "
            "Los resultados son orientativos y no reemplazan el diagnóstico de un médico veterinario."
        ),
        version="1.0.0",
    )

    app.state.settings = settings
    app.state.motor = motor
    app.state.servicio = AnalisisService(motor, settings.umbral_amarillo, settings.umbral_rojo)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.lista_cors,
        allow_methods=["GET", "POST", "OPTIONS"],
        allow_headers=["*"],
    )

    @app.exception_handler(HTTPException)
    async def _manejar_http(_: Request, exc: HTTPException) -> JSONResponse:
        return JSONResponse(status_code=exc.status_code, content={"detalle": exc.detail})

    @app.exception_handler(RequestValidationError)
    async def _manejar_validacion(_: Request, exc: RequestValidationError) -> JSONResponse:
        falta_imagen = any("imagen" in [str(p) for p in error.get("loc", ())] for error in exc.errors())
        mensaje = (
            "Debes enviar una foto en el campo 'imagen' (JPG o PNG, máximo 10 MB)."
            if falta_imagen
            else "La solicitud no es válida. Revisa los datos enviados."
        )
        return JSONResponse(status_code=422, content={"detalle": mensaje})

    app.include_router(router)

    # Versión web de la app (opcional). Se monta al final para no tapar los endpoints de la API.
    if settings.web_dir:
        carpeta_web = Path(settings.web_dir)
        if (carpeta_web / "index.html").is_file():
            app.mount("/", StaticFiles(directory=carpeta_web, html=True), name="web")
            logger.info("Sirviendo la versión web desde %s", carpeta_web)
        else:
            logger.warning("WEB_DIR=%s no contiene index.html; no se servirá la versión web.", carpeta_web)

    return app


app = crear_app()
