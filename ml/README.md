# Entrenamiento del modelo de MandiDog IA

Esta carpeta contiene el script de entrenamiento del clasificador binario que usa la API:

| Clase        | Significado                                               | Etiqueta |
|--------------|-----------------------------------------------------------|----------|
| `sin_signos` | Sin signos visibles de patología mandibular u oral        | 0        |
| `con_signos` | Con signos visibles (sarro severo, gingivitis, masas, etc.) | 1        |

La salida del modelo es la **probabilidad de la clase `con_signos`**. La API la traduce a VERDE, AMARILLO o ROJO con los umbrales configurados.

## Archivos

| Archivo              | Descripción                                                        |
|----------------------|--------------------------------------------------------------------|
| `preparar_roboflow.py` | Organiza el dataset "dog dental" de Roboflow (COCO) en `con_signos/` y `sin_signos/` |
| `train.py`           | Entrenamiento local con TensorFlow/Keras                           |
| `validacion_cruzada.py` | Validación cruzada por foto original, reparto en el semáforo y umbrales sugeridos |
| `exportar_tflite.py` | Convierte el modelo a TensorFlow Lite para la app                  |
| `train_colab.ipynb`  | Versión equivalente para Google Colab (con GPU gratuita)           |
| `requirements.txt`   | Dependencias del entrenamiento                                      |

## Método

1. **Transfer learning** con MobileNetV2 preentrenada en ImageNet (entrada 224×224 RGB).
2. **Fase 1:** base congelada; solo se entrenan las capas finales (`GlobalAveragePooling` → `Dropout` → `Dense(64)` → `Dense(1, sigmoid)`), tasa de aprendizaje 1e-3.
3. **Fase 2 (ajuste fino):** se descongelan las últimas 30 capas de la base (las capas `BatchNormalization` siguen congeladas) y se reentrena con tasa de aprendizaje 1e-5.
4. **Aumento de datos** dentro del modelo (solo activo durante el entrenamiento): rotación, volteo horizontal, brillo y contraste.
5. **División estratificada** 70 % entrenamiento, 15 % validación y 15 % prueba. El conjunto de prueba no se usa en ningún momento del entrenamiento.
6. **Pesos por clase** para compensar el desbalance y parada temprana sobre la pérdida de validación.

El preprocesamiento (redimensionar a 224×224 y dividir los píxeles entre 255) es el mismo que aplica `api/app/infrastructure/tensorflow_adapter.py`; el modelo convierte internamente el rango [0, 1] al rango [-1, 1] que espera MobileNetV2.

## Los datos NO se versionan

Las carpetas `ml/data/` y `ml/models/` están en `.gitignore`. Las imágenes no se suben al repositorio por tamaño, por licencias y por la privacidad de los propietarios. Cada persona que quiera entrenar debe preparar los datos localmente con esta estructura:

```
ml/
└── data/
    ├── con_signos/   *.jpg | *.png
    └── sin_signos/   *.jpg | *.png
```

Use **solo imágenes de la boca de perros**. Elimine duplicados y fotos borrosas o en las que no se vea la boca.

### Fuente 1: dataset público "dog dental" (Roboflow Universe)

Es el dataset con el que se entrenó el modelo incluido en la app (resultados en [docs/resultados_modelo.md](../docs/resultados_modelo.md)).

1. Cree una cuenta gratuita en <https://roboflow.com> y abra el dataset: <https://universe.roboflow.com/moriahai/dog-dental>.
2. Elija la versión **v4 "tartar divided into stages"** → **Download Dataset** → formato **COCO JSON** → *Download zip to computer*.
3. Descomprima el ZIP en `ml/data/roboflow_v4/` y organice las fotos en las dos clases:

   ```bash
   python preparar_roboflow.py --origen data/roboflow_v4 --destino data
   ```

   El dataset marca el sarro por etapas (1 a 4). Las fotos sin sarro o con sarro leve (etapa 1) van a `sin_signos`
   y las de etapas 2 a 4 a `con_signos` (`--corte` cambia ese límite). La foto con sarro sin etapa se excluye.
   El script deja un `data/manifiesto.csv` con la etapa y la clase de cada imagen.

Roboflow incluye tres copias aumentadas de cada foto de entrenamiento (`<original>.rf.<hash>.jpg`). `train.py` y
`validacion_cruzada.py` agrupan esas copias por foto original para que nunca queden repartidas entre entrenamiento
y prueba.

También puede descargarlo desde Python con su clave de API:

```python
from roboflow import Roboflow

rf = Roboflow(api_key="SU_CLAVE")
proyecto = rf.workspace("moriahai").project("dog-dental")
dataset = proyecto.version(1).download("folder")   # o "coco" si el proyecto es de detección
```

Ajuste el número de versión al que aparezca en la página del proyecto.

### Fuente 2: fotos locales tomadas con consentimiento

Para ampliar el dataset se pueden agregar fotos de perros tomadas en clínicas veterinarias o por propietarios de Pasto y la región, siempre que:

- El propietario firme un **consentimiento informado** que autorice el uso de las fotos con fines académicos.
- Un **médico veterinario** asigne la etiqueta (`con_signos` o `sin_signos`).
- Se eliminen los metadatos de ubicación (EXIF/GPS) y no aparezcan personas ni datos que identifiquen al propietario.
- Se registre cada foto en una hoja de control (archivo, fecha, etiqueta, veterinario que la etiquetó, consentimiento).

### Tabla de fuentes y atribución

| Fuente | Imágenes | Licencia | Atribución |
|--------|----------|----------|------------|
| [dog dental — Roboflow Universe](https://universe.roboflow.com/moriahai/dog-dental) | 63 | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) | "dog dental" por *moriahai*, publicado en Roboflow Universe. Usado bajo licencia CC BY 4.0. |
| Fotos locales con consentimiento | Variable | Uso académico autorizado por cada propietario (no se redistribuyen) | Propietarios participantes y médicos veterinarios colaboradores |

> Con solo 63 imágenes públicas el modelo es un **prototipo**: las métricas tendrán una varianza alta y no permiten conclusiones clínicas. Para una evaluación seria se necesitan cientos de imágenes etiquetadas por especialistas.

## Entrenamiento local

Requiere Python 3.11 (TensorFlow aún no publica paquetes para versiones más nuevas).

```bash
cd ml
python -m venv .venv
.venv\Scripts\activate          # Linux/macOS: source .venv/bin/activate
pip install -r requirements.txt
python train.py --data data --salida models/mandidog_v1.keras --metricas metrics.json
```

Parámetros útiles: `--epocas-base 15`, `--epocas-ajuste 15`, `--lote 16`, `--capas-ajuste 30`, `--prueba 0.15`, `--validacion 0.15`, `--semilla 42`.
Al terminar, el script también exporta el modelo para la app (ver más abajo); `--sin-app` lo omite.

## Entrenamiento en Google Colab

1. Abra `train_colab.ipynb` en <https://colab.research.google.com> (Archivo → Subir cuaderno).
2. Active la GPU: Entorno de ejecución → Cambiar tipo de entorno → GPU.
3. Suba a Google Drive una carpeta `mandidog/data` con `con_signos/` y `sin_signos/`.
4. Ejecute todas las celdas. Al final se descargan `mandidog_v1.keras`, `metrics.json`, `mandidog.tflite` y `modelo.json`.

## Salidas

- `models/mandidog_v1.keras`: modelo listo para la API.
- `../mobile/assets/modelo/mandidog.tflite` y `modelo.json`: el mismo modelo en TensorFlow Lite, para que la app analice las fotos dentro del teléfono.
- `metrics.json`: métricas sobre el conjunto de prueba: exactitud, precisión, sensibilidad, especificidad, F1 y matriz de confusión.

## Usar el modelo en la app (sin servidor)

La app de Android ejecuta el modelo en el propio teléfono, sin internet ni computador encendido.
`train.py` deja los archivos en `mobile/assets/modelo/` automáticamente. Para exportar un modelo ya entrenado:

```bash
python exportar_tflite.py --modelo models/mandidog_v1.keras
python exportar_tflite.py --modelo models/mandidog_v1.keras --umbral-amarillo 0.25 --umbral-rojo 0.55
```

- `mandidog.tflite`: entrada (1, 224, 224, 3) en RGB normalizado entre 0 y 1, igual que en la API; salida: probabilidad de "con signos".
- `modelo.json`: versión del modelo y umbrales del semáforo. Se pueden ajustar sin volver a entrenar.
- `--cuantizar` reduce el archivo a la cuarta parte (unos 2,5 MB) a cambio de una pequeña variación en la probabilidad.

El script compara el modelo convertido con el original y muestra la diferencia máxima.
Después se suben los dos archivos al repositorio: GitHub Actions compila el APK con el modelo incluido.
Si la carpeta no tiene un modelo, la app funciona en modo demostración.

## Validación cruzada

Con pocos datos, el conjunto de prueba de `train.py` tiene muy pocas fotos. `validacion_cruzada.py` entrena k
modelos (5 por defecto) y evalúa cada foto original una vez con un modelo que no la vio:

```bash
python validacion_cruzada.py --data data --pliegues 5
```

Genera `metrics_cv.json` (métricas globales, AUC, exactitud por pliegue, reparto de cada clase en el semáforo y
umbrales sugeridos) y `predicciones_cv.csv` (probabilidad de cada foto). Los umbrales sugeridos buscan que casi
ningún perro con signos quede en VERDE (`--sensibilidad-objetivo`) y casi ninguno sin signos en ROJO
(`--especificidad-objetivo`); conviene revisarlos antes de cambiar `modelo.json`.

## Usar el modelo en la API

Copie el modelo a `api/models/mandidog_v1.keras` (o ajuste `MODEL_PATH` en `api/.env`) y reinicie la API. El endpoint `/health` dejará de mostrar `"modo_demo": true`.

## Aviso

El modelo es una herramienta de apoyo para propietarios. Sus resultados son orientativos y no reemplazan el diagnóstico de un médico veterinario.
