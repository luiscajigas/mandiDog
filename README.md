# MandiDog IA

**Plataforma móvil de apoyo a la detección temprana de anomalías mandibulares en perros mediante visión por computador.**

Proyecto de grado — Ingeniería de Software, Universidad Cooperativa de Colombia, San Juan de Pasto, 2026.

> ⚠️ **Aviso:** MandiDog IA no realiza diagnósticos. Este resultado es orientativo y no reemplaza el diagnóstico de un médico veterinario.

## Descripción

El propietario de un perro toma o carga una foto de la boca del animal desde la app. Una red neuronal convolucional la analiza (clasificación binaria: *con signos visibles* o *sin signos visibles* de patología mandibular) y la app muestra un nivel de riesgo.

En **Android el análisis se hace dentro del teléfono** (TensorFlow Lite): no necesita internet, servidor ni computador encendido, y la foto no sale del dispositivo. La **versión web** (para iPhone) envía la foto a la API, que ejecuta el mismo modelo.

| Nivel | Probabilidad de signos | Recomendación |
|-------|------------------------|---------------|
| 🟢 **VERDE** | menor que 0.30 | No se observan signos aparentes. Mantén las revisiones veterinarias periódicas. |
| 🟡 **AMARILLO** | entre 0.30 y 0.60 | Se observan posibles signos leves. Programa una revisión con tu veterinario. |
| 🔴 **ROJO** | 0.60 o más | Se observan signos que requieren atención. Consulta a un veterinario lo antes posible. |

Los umbrales se configuran en la API (`UMBRAL_AMARILLO`, `UMBRAL_ROJO`) y, para el análisis en el teléfono, en `mobile/assets/modelo/modelo.json`.

## Estructura del repositorio

```
mobile/   App Flutter (Android)
api/      API FastAPI (Python 3.11)
ml/       Scripts de entrenamiento del modelo
docs/     Documentación (arquitectura y API)
```

## Arquitectura

- **Dos motores de análisis intercambiables.** En Android, `AnalisisRepositoryLocal` ejecuta el modelo TensorFlow Lite en el teléfono, sin conexión. En la web, `AnalisisRepositoryHttp` envía la foto a la API (FastAPI), que valida la imagen y ejecuta el modelo. Ambos aplican los mismos umbrales y recomendaciones.
- **La API es un monolito modular con puertos y adaptadores.** El dominio define el puerto `InferencePort`; los adaptadores `TensorFlowInferenceAdapter` (modelo real) y `DemoInferenceAdapter` (sin modelo) lo implementan. `app/main.py` es el único lugar donde se instancian y se inyectan con `Depends`.
- **La app usa capas presentation / domain / data con el patrón repositorio.** Las pantallas solo conocen `AnalisisRepository` e `HistorialRepository`; `main.dart` crea las implementaciones y las registra con Provider.
- **Sin estado en el servidor.** El historial se guarda solo en el teléfono.

```
            Android (sin conexión)
┌──────────────┐   ┌──────────────────────────┐
│  App Flutter │──►│ Modelo TensorFlow Lite   │◄──────────────┐
│  (APK)       │   │ assets/modelo/*.tflite   │               │ ml/exportar_tflite.py
└──────┬───────┘   └──────────────────────────┘               │
       │ historial local (SharedPreferences)          ┌───────┴──────────────┐
       ▼                                              │ ml/train.py          │
  Teléfono del propietario                            │ MobileNetV2 binario  │◄── Dataset (no versionado)
                                                      └───────┬──────────────┘
            Web / iPhone                                      │ .keras
┌──────────────┐  POST /v1/analisis   ┌─────────────────────┐ ▼ ┌──────────────┐
│  App web     │ ───────────────────► │ API FastAPI         │──►│ Modelo Keras │
│  (Safari)    │ ◄─────────────────── │ InferencePort       │   └──────────────┘
└──────────────┘   nivel + aviso      └─────────────────────┘
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
flutter run                                                     # análisis dentro del teléfono (sin servidor)
flutter run --dart-define=ANALISIS_EN_SERVIDOR=true --dart-define=API_URL=http://192.168.1.50:8000   # usar la API
```

El modelo que usa la app está en `mobile/assets/modelo/` (`mandidog.tflite` y `modelo.json`); se genera con `ml/train.py` o `ml/exportar_tflite.py`. Si la carpeta no tiene modelo, la app funciona en **modo demostración**.

- Análisis estático: `flutter analyze`
- Pruebas: `flutter test`

Cuando la app usa la API (versión web o `ANALISIS_EN_SERVIDOR=true`), la dirección del servidor se puede cambiar desde **Inicio → ícono de servidor**.

### Instalar el APK sin Android Studio

Cada vez que se suben cambios a `main` o `develop`, GitHub Actions ejecuta las pruebas y compila el APK. Para descargarlo:

1. En GitHub, abra la pestaña **Actions** → flujo **App Android (APK) y web** → la ejecución más reciente.
2. Descargue el artefacto **mandidog-apk** (un .zip con `app-release.apk`).
3. Copie el APK al teléfono Android, ábralo y permita instalar apps de origen desconocido.
4. Abra MandiDog IA y analice una foto. No necesita internet ni un computador encendido.

#### Versiones publicadas (Releases)

Para un enlace de descarga directo, sin cuenta de GitHub, se publica una versión con una etiqueta:

```bash
git tag -a v1.1.0 -m "MandiDog IA 1.1.0"
git push origin v1.1.0
```

GitHub Actions prueba y compila el APK y lo adjunta a una Release en la pestaña **Releases** del repositorio
(archivo `MandiDog-IA-v1.1.0.apk`). La última versión siempre queda en
`https://github.com/luiscajigas/mandiDog/releases/latest`.

### Versión web (iPhone o cualquier navegador)

La misma app se compila para web y la API puede servirla. Así se puede usar desde un iPhone sin instalar nada:

```bash
cd mobile
flutter build web --release

cd ../api
set WEB_DIR=../mobile/build/web                 # Linux/macOS: export WEB_DIR=../mobile/build/web
uvicorn app.main:app --host 0.0.0.0 --port 8080
```

En el iPhone, conectado a la **misma red Wi-Fi**, abra Safari en `http://IP-DEL-COMPUTADOR:8080` y, si quiere, use **Compartir → Agregar a pantalla de inicio**. En la versión web, el botón de la cámara abre la cámara del teléfono y el marco de encuadre se muestra como guía.

Si el teléfono no carga la página, permita en el firewall de Windows las conexiones entrantes al puerto 8080 en redes privadas.

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

- Análisis dentro del teléfono con TensorFlow Lite, sin internet ni servidor.
- Versión web de la misma app, usable desde el navegador de un iPhone.
- Compilación automática del APK y pruebas en GitHub Actions.
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
