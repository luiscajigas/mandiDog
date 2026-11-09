"""Endpoints HTTP de MandiDog IA."""

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.concurrency import run_in_threadpool

from app.api.dependencies import obtener_configuracion, obtener_motor, obtener_servicio
from app.api.schemas import AnalisisRespuesta, ErrorRespuesta, HealthRespuesta
from app.config import Settings
from app.domain.errores import ImagenInvalidaError
from app.domain.ports import InferencePort
from app.services.analisis_service import AnalisisService
from app.services.validacion_imagen import validar_imagen

router = APIRouter()


@router.get("/health", response_model=HealthRespuesta, tags=["estado"])
def health(motor: InferencePort = Depends(obtener_motor)) -> HealthRespuesta:
    return HealthRespuesta(estado="ok", version_modelo=motor.version_modelo, modo_demo=motor.modo_demo)


@router.post(
    "/v1/analisis",
    response_model=AnalisisRespuesta,
    responses={422: {"model": ErrorRespuesta, "description": "Imagen inválida"}},
    tags=["análisis"],
)
async def analizar(
    imagen: UploadFile = File(..., description="Foto de la boca del perro (JPG o PNG, máximo 10 MB)"),
    servicio: AnalisisService = Depends(obtener_servicio),
    settings: Settings = Depends(obtener_configuracion),
) -> AnalisisRespuesta:
    contenido = await imagen.read(settings.max_tamano_bytes + 1)
    try:
        validar_imagen(contenido, imagen.content_type, settings.max_tamano_bytes)
    except ImagenInvalidaError as error:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(error)) from error

    resultado = await run_in_threadpool(servicio.analizar, contenido)
    return AnalisisRespuesta.desde_dominio(resultado)
