# Arquitectura de MandiDog IA

Este documento describe la arquitectura del prototipo con el modelo C4 (Contexto, Contenedores, Componentes y Código), en texto.

## Decisiones principales

- **Inferencia en el dispositivo, con la API como alternativa.** En Android el modelo se ejecuta en el teléfono con TensorFlow Lite: la app funciona sin internet ni servidor y la foto no sale del dispositivo. La versión web no puede ejecutar el modelo nativo, así que envía la foto a la API (cliente-servidor), que ejecuta el mismo modelo en Keras. Ambos caminos implementan el mismo contrato `AnalisisRepository` y aplican los mismos umbrales.
- **La API es un monolito modular.** Un solo servicio desplegable, organizado internamente en capas con **puertos y adaptadores** (arquitectura hexagonal). El dominio no depende de FastAPI ni de TensorFlow.
- **Sin estado en el servidor.** La API no guarda fotos ni resultados. El historial vive solo en el teléfono del propietario.
- **Modo demostración.** Si no existe un modelo entrenado, la API sigue funcionando con un adaptador determinista y lo indica con `modo_demo: true`, para poder probar el flujo completo antes de tener datos suficientes.

---

## Nivel 1: Contexto del sistema

**Personas**

- **Propietario del perro.** Toma o carga una foto de la boca de su perro y recibe una orientación (VERDE, AMARILLO o ROJO) con una recomendación.
- **Médico veterinario** (externo). Realiza el diagnóstico definitivo. La app siempre recuerda que el resultado no reemplaza su valoración.
- **Desarrollador / investigador.** Entrena el modelo con imágenes etiquetadas y lo publica en la API.

**Sistema:** MandiDog IA.

**Sistemas externos:** Roboflow Universe y fotos locales con consentimiento (solo como fuente de datos para el entrenamiento, fuera de línea).

**Relaciones**

- El propietario usa la app móvil de MandiDog IA → recibe una orientación y es remitido al veterinario cuando corresponde.
- El desarrollador entrena el modelo con los datos → lo despliega en la API.

---

## Nivel 2: Contenedores

| Contenedor | Tecnología | Responsabilidad |
|------------|------------|-----------------|
| **App móvil** | Flutter (Dart), Android y web | Captura con marco de encuadre, análisis en el teléfono (TensorFlow Lite) o envío a la API, presentación del semáforo, historial local. El mismo código se compila como APK y como aplicación web para iPhone |
| **Modelo en el teléfono** | TensorFlow Lite (`flutter_litert`, LiteRT) | `assets/modelo/mandidog.tflite` y `modelo.json` (versión y umbrales), generados con `ml/exportar_tflite.py` |
| **Almacenamiento local** | SharedPreferences (JSON; en web, almacenamiento local del navegador) | Historial de análisis con una miniatura de cada foto, solo en el dispositivo |
| **API de análisis** | Python 3.11, FastAPI, Uvicorn, Docker | Validar la imagen, ejecutar la inferencia, traducir la probabilidad a nivel de riesgo |
| **Modelo** | Archivo Keras (`mandidog_v1.keras`) | Red convolucional MobileNetV2 con clasificador binario |
| **Pipeline de entrenamiento** | TensorFlow/Keras (`ml/train.py`, Colab) | Producir el modelo y sus métricas a partir de las carpetas de datos |

**Comunicación**

- La API puede servir también la versión web compilada (`WEB_DIR`), de modo que el navegador carga la app y llama a la API desde el mismo origen.
- App → API (solo versión web o `ANALISIS_EN_SERVIDOR=true`): HTTP/JSON. `GET /health` para el indicador de estado y `POST /v1/analisis` (multipart) para analizar.
- API → Modelo: carga del archivo en memoria al iniciar.
- Entrenamiento → Modelo: genera el archivo que luego se copia en `api/models/` (o se monta como volumen en Docker).

---

## Nivel 3: Componentes

### API (`api/app`)

```
             ┌──────────────────────────── main.py (composition root) ───────────────────────────┐
             │ crea Settings, elige el adaptador (TensorFlow o Demo), crea AnalisisService         │
             └──────────────┬───────────────────────────────────────────────┬────────────────────┘
                            │ inyecta (Depends)                             │
   HTTP ──► api/routes.py ──┴──► services/analisis_service.py ──► domain/ports.InferencePort
            api/schemas.py       services/validacion_imagen.py              ▲           ▲
                                                                            │implementa │implementa
                                              infrastructure/tensorflow_adapter.py  infrastructure/demo_adapter.py
```

| Componente | Capa | Descripción |
|------------|------|-------------|
| `domain/ports.py` | Dominio | `InferencePort` (puerto) y `ResultadoInferencia` (probabilidad, versión del modelo) |
| `domain/modelos.py` | Dominio | `NivelRiesgo`, recomendaciones y aviso legal |
| `services/analisis_service.py` | Aplicación | Traduce la probabilidad a VERDE/AMARILLO/ROJO con umbrales configurables |
| `services/validacion_imagen.py` | Aplicación | Acepta solo JPG o PNG legibles de máximo 10 MB |
| `infrastructure/tensorflow_adapter.py` | Infraestructura | Carga el modelo Keras, redimensiona a 224×224, normaliza RGB y predice |
| `infrastructure/demo_adapter.py` | Infraestructura | Probabilidad determinista a partir del hash de la imagen; `modo_demo = true` |
| `api/routes.py`, `api/schemas.py` | Presentación | Endpoints, validación de entrada y formato de las respuestas |
| `main.py` | Composición | Único lugar que instancia adaptadores; configura CORS y manejadores de error |

Cambiar de motor de inferencia (por ejemplo, a TensorFlow Lite u ONNX) solo requiere un nuevo adaptador que implemente `InferencePort` y registrarlo en `main.py`.

### App móvil (`mobile/lib`)

| Capa | Carpeta | Contenido |
|------|---------|-----------|
| Presentación | `presentation/` | Pantallas (bienvenida, inicio, captura, analizando, resultado, historial, acerca de), widgets (semáforo, marco de encuadre, aviso legal) y el controlador de tema |
| Dominio | `domain/` | Entidades (`ResultadoAnalisis`, `NivelRiesgo`, `EstadoServidor`), el servicio `ClasificadorRiesgo` (umbrales y recomendaciones), errores y las interfaces `AnalisisRepository`, `HistorialRepository`, `PreferenciasRepository` |
| Datos | `data/` | `AnalisisRepositoryLocal` con `MotorTflite` o `MotorDemo` (análisis en el teléfono), `MandiDogApiClient` y `AnalisisRepositoryHttp` (API), `HistorialRepositoryLocal` (SharedPreferences), `PreferenciasRepositoryLocal` |
| Composición | `main.dart` | Elige el motor de análisis (TensorFlow Lite en Android, API en la web), carga el modelo o usa el modo demostración, y registra los repositorios con Provider |

Las pantallas nunca usan `http` directamente: obtienen los repositorios con `context.read<...>()`. Esto permite probarlas con repositorios falsos.

**Flujo principal**

1. `CapturaScreen` toma la foto (paquete `camera`) o la elige de la galería (`image_picker`).
2. `AnalizandoScreen` llama a `AnalisisRepository.analizar()` y luego a `HistorialRepository.guardar()`.
3. `ResultadoScreen` muestra el semáforo, la confianza, la recomendación, el aviso, la foto, la fecha y la versión del modelo.
4. Si falla la conexión se muestra: "No pudimos conectar con el servidor. Revisa tu conexión e inténtalo de nuevo", con el botón **Reintentar**.

---

## Nivel 4: Código

Los detalles de clases y funciones están en el código fuente y sus pruebas:

- API: `api/app/**` y `api/tests/**` (pytest).
- App: `mobile/lib/**` y `mobile/test/**` (flutter test).
- Entrenamiento: `ml/train.py`.

---

## Atributos de calidad

| Atributo | Cómo se aborda |
|----------|----------------|
| Mantenibilidad | Puertos y adaptadores en la API; capas presentation/domain/data con repositorios en la app |
| Facilidad de prueba | Inyección de dependencias en ambos lados; pruebas automáticas con adaptadores y repositorios falsos |
| Privacidad | En Android la foto se analiza en el teléfono y no se envía a ningún servidor; la API tampoco guarda fotos; el historial solo existe en el teléfono |
| Robustez | Validación de imágenes, mensajes de error en español, la app nunca se cierra ante errores de red |
| Portabilidad | API en contenedor Docker; app para Android y web; URL de la API configurable con `--dart-define` o desde la app |
| Integración continua | GitHub Actions ejecuta pytest, flutter analyze y flutter test, y compila el APK |

## Fuera del alcance del prototipo (queda como diseño)

- Cuentas de usuario y autenticación.
- Base de datos en el servidor y sincronización del historial.
- Registro de mascotas y seguimiento por animal.
- Panel de administración para veterinarios.
- Publicación en Google Play.
- Inferencia en el dispositivo (TensorFlow Lite) para uso sin conexión.
