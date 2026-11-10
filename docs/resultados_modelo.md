# Resultados del modelo (versión mandidog_v1)

Este documento resume cómo se entrenó y evaluó el modelo que incluye la app a partir de la versión 1.3.0.
Los números se pueden reproducir con los scripts de `ml/` (ver al final).

> **Alcance.** El modelo se entrenó con 62 fotos públicas. Los resultados demuestran que el sistema funciona
> de principio a fin, pero **no tienen validez clínica**: el conjunto es pequeño, proviene de una sola fuente y
> no fue revisado por un médico veterinario del proyecto. El resultado de la app es orientativo y no reemplaza
> el diagnóstico de un médico veterinario.

## 1. Datos

| Aspecto | Detalle |
|---------|---------|
| Fuente | [dog dental — Roboflow Universe](https://universe.roboflow.com/moriahai/dog-dental), versión 4 "tartar divided into stages" (formato COCO) |
| Licencia | CC BY 4.0. Atribución: "dog dental" por *moriahai*, publicado en Roboflow Universe |
| Fotos originales | 63 (Roboflow las entrega como 137 imágenes porque incluye 3 copias aumentadas de cada foto de entrenamiento) |
| Anotación original | Detección de objetos: dientes (`teeth`) y sarro por etapas (`tartar_1` a `tartar_4`) |
| Preprocesamiento de Roboflow | Orientación automática y redimensionado a 640×640 |

### Conversión a dos clases

Cada foto recibe la etapa de sarro más alta que tenga anotada (0 si solo tiene dientes sin sarro).
El corte se hizo en la etapa 2:

| Etapa | Fotos | Clase |
|-------|-------|-------|
| Sin sarro | 15 | `sin_signos` |
| Etapa 1 (leve) | 13 | `sin_signos` |
| Etapa 2 | 6 | `con_signos` |
| Etapa 3 | 12 | `con_signos` |
| Etapa 4 | 16 | `con_signos` |
| Sarro sin etapa | 1 | Excluida (no se puede ubicar) |

Resultado: **28 fotos `sin_signos` y 34 `con_signos`** (62 en total). El sarro leve (etapa 1) se agrupó con
"sin signos" porque no requiere atención inmediata y así las clases quedan equilibradas. Este criterio es una
decisión del proyecto y debe validarlo un médico veterinario; el corte se cambia con
`python preparar_roboflow.py --corte N`.

### Prevención de fuga de datos

Las copias aumentadas de una foto son casi iguales al original. Si una copia queda en entrenamiento y otra en
prueba, la métrica sale inflada. Por eso todas las divisiones se hacen **por foto original**, no por imagen, y
en validación y prueba se usa una sola imagen por foto.

## 2. Modelo

- MobileNetV2 preentrenada en ImageNet, entrada 224×224 RGB, y un clasificador binario (salida sigmoide =
  probabilidad de `con_signos`).
- Entrenamiento en dos fases: base congelada (tasa 1e-3) y ajuste fino de las últimas 30 capas (tasa 1e-5).
- Aumento de datos (rotación, volteo, brillo y contraste), pesos por clase y parada temprana.
- Exportado a TensorFlow Lite (9,2 MB) para ejecutarse en el teléfono. La diferencia frente al modelo Keras es
  menor que 0,00001. En la app, la probabilidad difiere como máximo 0,004 de la que calcula la API por el método
  de redimensionado de la imagen.

## 3. Evaluación

### Validación cruzada (métrica principal)

Con tan pocas fotos, un único conjunto de prueba (9 fotos) da cifras muy inestables. Por eso la métrica principal
es una **validación cruzada estratificada de 5 pliegues por foto original**: cada una de las 62 fotos se evalúa
una vez, con un modelo que no la vio durante el entrenamiento.

| Métrica (umbral 0,5) | Valor |
|----------------------|-------|
| Exactitud | **0,871** (54 de 62) |
| Sensibilidad (detecta los casos con signos) | 0,882 (30 de 34) |
| Especificidad (reconoce los casos sin signos) | 0,857 (24 de 28) |
| Precisión | 0,882 |
| F1 | 0,882 |
| AUC ROC | 0,929 |
| Exactitud por pliegue | 0,846 · 0,923 · 0,846 · 0,833 · 0,909 (media 0,872 ± 0,037) |

Matriz de confusión (filas = clase real, columnas = predicción):

|                 | Predice sin signos | Predice con signos |
|-----------------|-------------------:|-------------------:|
| **Sin signos**  | 24 | 4 |
| **Con signos**  | 4  | 30 |

### Reparto en el semáforo (umbrales 0,30 y 0,60)

| Clase real | VERDE | AMARILLO | ROJO |
|------------|------:|---------:|-----:|
| Sin signos (28) | 20 | 5 | 3 |
| Con signos (34) | 1 | 5 | 28 |

Solo 1 de 34 perros con signos quedó en VERDE: el 97 % recibió al menos la recomendación de revisión. El script
sugirió umbrales de 0,43 y 0,80, pero con ellos 3 perros con signos quedarían en VERDE. En una herramienta de
detección temprana es más grave no avisar que enviar a revisión a un perro sano, así que se mantienen **0,30 y
0,60** (en `mobile/assets/modelo/modelo.json` y en la configuración de la API).

### Conjunto de prueba del modelo publicado

El modelo que incluye la app se entrenó con 44 fotos (más 9 de validación) y se probó con 9 fotos que nunca vio:
exactitud 0,667 (6 de 9), sensibilidad 0,6 y especificidad 0,75. Con 9 fotos, una sola foto mal clasificada
cambia la exactitud en 11 puntos, por eso se reporta como referencia y no como métrica principal.

## 4. Limitaciones

- **Pocas fotos y una sola fuente.** 62 fotos no representan la variedad de razas, edades, iluminación y cámaras
  de uso real.
- **Etiquetas no clínicas.** Las etapas de sarro vienen del autor del dataset; el corte en dos clases no fue
  validado por un médico veterinario.
- **Solo sarro.** El dataset no incluye otras anomalías mandibulares (fracturas, masas, maloclusiones), aunque son
  parte del objetivo del proyecto.
- **Fotos de primer plano.** Las imágenes muestran los dientes de cerca. Fotos tomadas de lejos o de otra parte
  del cuerpo pueden dar resultados sin sentido, porque el modelo no sabe reconocer cuándo la foto no es de una boca.

## 5. Trabajo futuro

1. Ampliar el dataset con fotos locales tomadas con consentimiento y etiquetadas por médicos veterinarios.
2. Validar el corte entre clases y los umbrales del semáforo con especialistas.
3. Incluir otras anomalías mandibulares y una clase "foto no válida".
4. Probar la app con propietarios y veterinarios para medir su utilidad.

## 6. Cómo reproducir

```bash
cd ml
# Descomprimir el ZIP COCO de Roboflow en data/roboflow_v4
python preparar_roboflow.py --origen data/roboflow_v4 --destino data
python train.py --data data --salida models/mandidog_v1.keras    # también exporta el modelo a la app
python validacion_cruzada.py --data data --pliegues 5             # metrics_cv.json y predicciones_cv.csv
```

Semilla 42; TensorFlow 2.18 (CPU). Los resultados pueden variar ligeramente entre equipos.
