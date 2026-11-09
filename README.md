# MandiDog IA

**Plataforma móvil de apoyo a la detección temprana de anomalías mandibulares en perros mediante visión por computador.**

Proyecto de grado — Ingeniería de Software, Universidad Cooperativa de Colombia, San Juan de Pasto, 2026.

> ⚠️ **Aviso:** MandiDog IA no realiza diagnósticos. Este resultado es orientativo y no reemplaza el diagnóstico de un médico veterinario.

## Descripción

El propietario de un perro toma o carga una foto de la boca del animal desde la app. La app la envía a una API, que la analiza con una red neuronal convolucional (clasificación binaria: *con signos visibles* o *sin signos visibles* de patología mandibular) y devuelve un nivel de riesgo:

| Nivel | Probabilidad de signos | Recomendación |
|-------|------------------------|---------------|
| 🟢 **VERDE** | menor que 0.30 | No se observan signos aparentes. Mantén las revisiones veterinarias periódicas. |
| 🟡 **AMARILLO** | entre 0.30 y 0.60 | Se observan posibles signos leves. Programa una revisión con tu veterinario. |
| 🔴 **ROJO** | 0.60 o más | Se observan signos que requieren atención. Consulta a un veterinario lo antes posible. |

Los umbrales se configuran en la API.

## Estructura del repositorio

```
mobile/   App Flutter (Android)
api/      API FastAPI (Python 3.11)
ml/       Scripts de entrenamiento del modelo
docs/     Documentación (arquitectura y API)
```

## Arquitectura

- **Cliente-servidor.** La app (Flutter) captura la foto y muestra el resultado; la API (FastAPI) valida la imagen y ejecuta el modelo.
- **La API es un monolito modular con puertos y adaptadores.** El dominio define el puerto `InferencePort`; los adaptadores `TensorFlowInferenceAdapter` (modelo real) y `DemoInferenceAdapter` (sin modelo) lo implementan. `app/main.py` es el único lugar donde se instancian y se inyectan con `Depends`.
- **La app usa capas presentation / domain / data con el patrón repositorio.** Las pantallas solo conocen `AnalisisRepository` e `HistorialRepository`; `main.dart` crea las implementaciones y las registra con Provider.
- **Sin estado en el servidor.** El historial se guarda solo en el teléfono.

```
┌──────────────┐  POST /v1/analisis   ┌───────────────────────────┐        ┌──────────────────────┐
│  App Flutter │ ───────────────────► │ API FastAPI               │ ─────► │ Modelo Keras         │
│  (Android)   │ ◄─────────────────── │ servicio + InferencePort  │        │ MobileNetV2 binario  │
└──────┬───────┘   nivel + aviso      └───────────────────────────┘        └──────────────────────┘
       │ historial local (SharedPreferences)                                     ▲
       ▼                                                                         │ ml/train.py
  Teléfono del propietario                                                Dataset (no versionado)
```

Más detalle en [docs/arquitectura.md](docs/arquitectura.md) y [docs/api.md](docs/api.md).

## Ejecutar la API

Requiere Python 3.11.

```bash
cd api
python -m venv .venv
.venv\Scripts\activate              # Linux/macOS: source .venv/bin/activate
pip install -r requirements.txt
copy .env.example .env              # Linux/macOS: cp .env.example .env
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

- Salud del servicio: <http://localhost:8000/health>
- Documentación interactiva: <http://localhost:8000/docs>
- Pruebas: `pytest`

Si no existe `api/models/mandidog_v1.keras`, la API arranca en **modo demostración** (`"modo_demo": true`): responde con una probabilidad determinista sin valor clínico para poder probar todo el flujo.

### Con Docker

```bash
cd api
docker build -t mandidog-api .
docker run --rm -p 8000:8000 -v "%cd%/models:/srv/models" mandidog-api       # Windows (cmd)
docker run --rm -p 8000:8000 -v "$(pwd)/models:/srv/models" mandidog-api     # Linux/macOS
```

## Ejecutar la app

Requiere Flutter 3.47+ y un emulador o teléfono Android.

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:8000         # emulador de Android
flutter run --dart-define=API_URL=http://192.168.1.50:8000     # teléfono en la misma red (IP del equipo con la API)
```

- Análisis estático: `flutter analyze`
- Pruebas: `flutter test`

## Entrenar el modelo

Los datos **no** se versionan. Prepare `ml/data/con_signos/` y `ml/data/sin_signos/` siguiendo [ml/README.md](ml/README.md) (dataset público *dog dental* de Roboflow Universe, CC BY 4.0, y fotos locales con consentimiento).

```bash
cd ml
pip install -r requirements.txt
python train.py --data data --salida models/mandidog_v1.keras --metricas metrics.json
```

Después copie `ml/models/mandidog_v1.keras` a `api/models/` y reinicie la API. También puede entrenar en Google Colab con `ml/train_colab.ipynb`.

El script produce `metrics.json` con exactitud, precisión, sensibilidad, especificidad, F1 y matriz de confusión sobre un conjunto de prueba separado.

## Alcance del prototipo

**Incluye**

- App Android con bienvenida, inicio, captura con marco de encuadre, análisis, resultado con semáforo, historial local, acerca de y tema oscuro.
- API con validación de imágenes, inferencia con TensorFlow, modo demostración, Docker y pruebas automáticas.
- Pipeline de entrenamiento reproducible (script y notebook) con métricas de evaluación.

**Queda como diseño (no implementado en el prototipo)**

- Cuentas de usuario y autenticación.
- Base de datos en el servidor y sincronización del historial.
- Registro y seguimiento de mascotas.
- Panel de administración para veterinarios.
- Publicación en Google Play.
- Inferencia en el dispositivo sin conexión (TensorFlow Lite).

## Aviso

MandiDog IA es una herramienta de apoyo para propietarios. Este resultado es orientativo y no reemplaza el diagnóstico de un médico veterinario. Ante cualquier signo de dolor, inflamación, sangrado o dificultad para comer, consulte a un profesional.

## Licencia

Código bajo licencia [MIT](LICENSE). La tipografía Poppins se distribuye bajo la SIL Open Font License. Los datos de entrenamiento conservan sus propias licencias (ver [ml/README.md](ml/README.md)).
