# API de MandiDog IA

Servicio FastAPI que recibe la foto de la boca de un perro, la clasifica con una red neuronal convolucional y devuelve un nivel de riesgo (VERDE, AMARILLO o ROJO).

## Estructura

```
app/
├── main.py                      # composition root: crea adaptadores y los inyecta
├── config.py                    # configuración (variables de entorno / .env)
├── api/                         # capa HTTP: rutas, esquemas y dependencias
├── domain/                      # puertos, entidades y errores (sin dependencias externas)
├── services/                    # casos de uso: análisis y validación de imágenes
└── infrastructure/              # adaptadores: TensorFlow y demostración
tests/                           # pruebas con pytest
```

## Ejecución local (Python 3.11)

```bash
cd api
python -m venv .venv
.venv\Scripts\activate          # Windows  (en Linux/macOS: source .venv/bin/activate)
pip install -r requirements.txt
copy .env.example .env          # en Linux/macOS: cp .env.example .env
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Documentación interactiva: http://localhost:8000/docs

Si el archivo indicado en `MODEL_PATH` no existe, la API arranca en **modo demostración**: responde con `"modo_demo": true` y una probabilidad determinista que no tiene valor clínico.

## Docker

```bash
cd api
docker build -t mandidog-api .
docker run --rm -p 8000:8000 -v "%cd%/models:/srv/models" mandidog-api
```

En Linux/macOS use `-v "$(pwd)/models:/srv/models"`.

## Pruebas

```bash
cd api
pytest
```

## Variables de entorno

| Variable          | Valor por defecto           | Descripción                                     |
|-------------------|-----------------------------|-------------------------------------------------|
| `MODEL_PATH`      | `models/mandidog_v1.keras`  | Ruta del modelo Keras entrenado                  |
| `UMBRAL_AMARILLO` | `0.30`                      | Probabilidad mínima para el nivel AMARILLO       |
| `UMBRAL_ROJO`     | `0.60`                      | Probabilidad mínima para el nivel ROJO           |
| `MAX_TAMANO_MB`   | `10`                        | Tamaño máximo de la imagen                       |
| `CORS_ORIGINS`    | `*`                         | Orígenes permitidos, separados por coma          |
| `WEB_DIR`         | (vacío)                     | Carpeta de la versión web compilada; si se define, se sirve en `/` |

Los endpoints se describen en [docs/api.md](../docs/api.md).
