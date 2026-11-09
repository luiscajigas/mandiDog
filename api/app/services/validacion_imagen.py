"""Validación de las imágenes recibidas antes de enviarlas al modelo."""

import io

from PIL import Image, UnidentifiedImageError

from app.domain.errores import ImagenInvalidaError

FORMATOS_PERMITIDOS = {"JPEG", "PNG"}
TIPOS_MIME_PERMITIDOS = {"image/jpeg", "image/jpg", "image/png", "application/octet-stream", ""}


def validar_imagen(contenido: bytes, tipo_mime: str | None, max_bytes: int) -> None:
    """Comprueba que el archivo sea un JPG o PNG legible y que no supere el tamaño máximo.

    Lanza ImagenInvalidaError con un mensaje en español si algo falla.
    """
    if not contenido:
        raise ImagenInvalidaError("El archivo está vacío. Selecciona una foto de la boca de tu perro.")

    if len(contenido) > max_bytes:
        limite_mb = max_bytes // (1024 * 1024)
        raise ImagenInvalidaError(f"La imagen supera el tamaño máximo permitido de {limite_mb} MB.")

    if (tipo_mime or "").lower() not in TIPOS_MIME_PERMITIDOS:
        raise ImagenInvalidaError("Formato no permitido. Solo se aceptan imágenes JPG o PNG.")

    try:
        with Image.open(io.BytesIO(contenido)) as imagen:
            formato = imagen.format
            imagen.verify()
    except (UnidentifiedImageError, OSError, SyntaxError) as error:
        raise ImagenInvalidaError(
            "El archivo no es una imagen válida o está dañado. Solo se aceptan imágenes JPG o PNG."
        ) from error

    if formato not in FORMATOS_PERMITIDOS:
        raise ImagenInvalidaError("Formato no permitido. Solo se aceptan imágenes JPG o PNG.")
