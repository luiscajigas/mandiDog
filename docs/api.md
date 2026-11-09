# API de MandiDog IA

URL base de desarrollo: `http://localhost:8000` (desde el emulador de Android: `http://10.0.2.2:8000`).

Documentación interactiva generada por FastAPI: `GET /docs` (Swagger UI) y `GET /redoc`.

Todas las respuestas son JSON en UTF-8. Los errores devuelven un objeto con el campo `detalle` y un mensaje en español.

---

## `GET /health`

Indica si el servicio está activo, qué modelo tiene cargado y si funciona en modo demostración.

### Ejemplo

```bash
curl http://localhost:8000/health
```

### Respuesta `200 OK`

```json
{
  "estado": "ok",
  "version_modelo": "demo-sin-entrenar",
  "modo_demo": true
}
```

| Campo            | Tipo    | Descripción                                                                 |
|------------------|---------|-----------------------------------------------------------------------------|
| `estado`         | string  | Siempre `"ok"` si el servicio responde                                      |
| `version_modelo` | string  | Nombre del archivo del modelo (por ejemplo `mandidog_v1`) o `demo-sin-entrenar` |
| `modo_demo`      | boolean | `true` si no hay modelo entrenado y se usa el adaptador de demostración     |

---

## `POST /v1/analisis`

Analiza la foto de la boca de un perro.

- **Tipo de contenido:** `multipart/form-data`
- **Campo:** `imagen` (archivo JPG o PNG, máximo 10 MB)

### Ejemplo con curl

```bash
curl -X POST http://localhost:8000/v1/analisis \
     -F "imagen=@boca_de_max.jpg;type=image/jpeg"
```

### Ejemplo con Python

```python
import httpx

with open("boca_de_max.jpg", "rb") as foto:
    respuesta = httpx.post(
        "http://localhost:8000/v1/analisis",
        files={"imagen": ("boca_de_max.jpg", foto, "image/jpeg")},
    )
print(respuesta.json())
```

### Respuesta `200 OK`

```json
{
  "probabilidad": 0.4213,
  "nivel": "AMARILLO",
  "recomendacion": "Se observan posibles signos leves. Programa una revisión con tu veterinario.",
  "aviso": "Este resultado es orientativo y no reemplaza el diagnóstico de un médico veterinario.",
  "version_modelo": "mandidog_v1",
  "modo_demo": false,
  "fecha": "2026-03-14T15:30:12.345678Z"
}
```

| Campo            | Tipo    | Descripción                                                          |
|------------------|---------|----------------------------------------------------------------------|
| `probabilidad`   | number  | Probabilidad (0 a 1) de la clase "con signos visibles"               |
| `nivel`          | string  | `VERDE`, `AMARILLO` o `ROJO`                                         |
| `recomendacion`  | string  | Recomendación asociada al nivel                                      |
| `aviso`          | string  | Aviso legal; se devuelve siempre                                     |
| `version_modelo` | string  | Modelo que generó el resultado                                       |
| `modo_demo`      | boolean | `true` si el resultado proviene del adaptador de demostración        |
| `fecha`          | string  | Fecha y hora del análisis en ISO 8601 (UTC)                          |

### Reglas de clasificación

Con los umbrales por defecto (`UMBRAL_AMARILLO=0.30`, `UMBRAL_ROJO=0.60`):

| Probabilidad       | Nivel      | Recomendación                                                                 |
|--------------------|------------|-------------------------------------------------------------------------------|
| `p < 0.30`         | `VERDE`    | No se observan signos aparentes. Mantén las revisiones veterinarias periódicas. |
| `0.30 ≤ p < 0.60`  | `AMARILLO` | Se observan posibles signos leves. Programa una revisión con tu veterinario.  |
| `p ≥ 0.60`         | `ROJO`     | Se observan signos que requieren atención. Consulta a un veterinario lo antes posible. |

### Errores `422 Unprocessable Entity`

| Situación                              | `detalle`                                                                                  |
|----------------------------------------|--------------------------------------------------------------------------------------------|
| No se envió el campo `imagen`          | Debes enviar una foto en el campo 'imagen' (JPG o PNG, máximo 10 MB).                      |
| Archivo vacío                          | El archivo está vacío. Selecciona una foto de la boca de tu perro.                         |
| Más de 10 MB                           | La imagen supera el tamaño máximo permitido de 10 MB.                                      |
| Tipo distinto de JPG o PNG             | Formato no permitido. Solo se aceptan imágenes JPG o PNG.                                  |
| Archivo dañado o que no es una imagen  | El archivo no es una imagen válida o está dañado. Solo se aceptan imágenes JPG o PNG.      |

Ejemplo:

```bash
curl -X POST http://localhost:8000/v1/analisis -F "imagen=@notas.txt;type=text/plain"
```

```json
{ "detalle": "Formato no permitido. Solo se aceptan imágenes JPG o PNG." }
```

---

## Configuración

Ver [api/README.md](../api/README.md#variables-de-entorno) para las variables de entorno (`MODEL_PATH`, `UMBRAL_AMARILLO`, `UMBRAL_ROJO`, `MAX_TAMANO_MB`, `CORS_ORIGINS`).
