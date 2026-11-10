"""Entrenamiento del clasificador binario de MandiDog IA.

Transfer learning con MobileNetV2 preentrenada en ImageNet, en dos fases:
  1. Base congelada: solo se entrenan las capas de clasificación.
  2. Ajuste fino: se descongelan las últimas capas de la base con una tasa de aprendizaje baja.

Entrada:  data/con_signos/  y  data/sin_signos/  (solo imágenes de perros)
Salida:   models/mandidog_v1.keras  y  metrics.json
          ../mobile/assets/modelo/mandidog.tflite  y  modelo.json  (para que la app analice sin servidor)

Uso:
    python train.py --data data --salida models/mandidog_v1.keras
"""

from __future__ import annotations

import argparse
import json
import random
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import tensorflow as tf

TAMANO_IMAGEN = (224, 224)
CLASES = ["sin_signos", "con_signos"]  # índice 1 = "con signos": la salida sigmoide es su probabilidad
EXTENSIONES = {".jpg", ".jpeg", ".png"}


def argumentos() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Entrena el modelo de MandiDog IA")
    parser.add_argument("--data", type=Path, default=Path("data"), help="Carpeta con con_signos/ y sin_signos/")
    parser.add_argument("--salida", type=Path, default=Path("models/mandidog_v1.keras"))
    parser.add_argument("--metricas", type=Path, default=Path("metrics.json"))
    parser.add_argument("--epocas-base", type=int, default=15)
    parser.add_argument("--epocas-ajuste", type=int, default=15)
    parser.add_argument("--lote", type=int, default=16)
    parser.add_argument("--capas-ajuste", type=int, default=30, help="Capas finales de la base a descongelar")
    parser.add_argument("--prueba", type=float, default=0.15, help="Proporción del conjunto de prueba")
    parser.add_argument("--validacion", type=float, default=0.15, help="Proporción del conjunto de validación")
    parser.add_argument("--semilla", type=int, default=42)
    parser.add_argument("--sin-app", action="store_true", help="No exportar el modelo TensorFlow Lite para la app")
    return parser.parse_args()


def fijar_semillas(semilla: int) -> None:
    random.seed(semilla)
    np.random.seed(semilla)
    tf.random.set_seed(semilla)


def listar_imagenes(carpeta_datos: Path) -> tuple[list[str], list[int]]:
    rutas, etiquetas = [], []
    for indice, clase in enumerate(CLASES):
        carpeta = carpeta_datos / clase
        if not carpeta.is_dir():
            raise SystemExit(f"No existe la carpeta {carpeta}. Revise ml/README.md para preparar los datos.")
        archivos = sorted(p for p in carpeta.rglob("*") if p.suffix.lower() in EXTENSIONES)
        if not archivos:
            raise SystemExit(f"La carpeta {carpeta} no contiene imágenes JPG o PNG.")
        rutas += [str(p) for p in archivos]
        etiquetas += [indice] * len(archivos)
        print(f"  {clase}: {len(archivos)} imágenes")
    return rutas, etiquetas


def grupo_de(ruta: str) -> str:
    """Foto original a la que pertenece una imagen.

    Roboflow guarda copias aumentadas como '<original>.rf.<hash>.jpg'; todas pertenecen al mismo grupo.
    """
    return Path(ruta).name.split(".rf.")[0]


def dividir_estratificado(rutas, etiquetas, prop_prueba, prop_val, semilla):
    """Divide en entrenamiento, validación y prueba conservando la proporción de cada clase.

    Se divide por foto original (grupo), no por imagen: las copias de una misma foto nunca quedan
    repartidas entre entrenamiento y prueba. En validación y prueba se usa una sola imagen por foto
    original, para que las métricas cuenten fotos distintas.
    """
    generador = np.random.default_rng(semilla)
    conjuntos = {"entrenamiento": ([], []), "validacion": ([], []), "prueba": ([], [])}

    grupos: dict[tuple[int, str], list[str]] = {}
    for ruta, etiqueta in zip(rutas, etiquetas):
        grupos.setdefault((int(etiqueta), grupo_de(ruta)), []).append(ruta)

    for clase in sorted({clase for clase, _ in grupos}):
        claves = sorted(clave for clave in grupos if clave[0] == clase)
        orden = generador.permutation(len(claves))
        claves = [claves[i] for i in orden]
        n_prueba = max(1, int(round(len(claves) * prop_prueba)))
        n_val = max(1, int(round(len(claves) * prop_val)))
        cortes = {
            "prueba": claves[:n_prueba],
            "validacion": claves[n_prueba : n_prueba + n_val],
            "entrenamiento": claves[n_prueba + n_val :],
        }
        for nombre, seleccion in cortes.items():
            for clave in seleccion:
                imagenes = sorted(grupos[clave])
                if nombre != "entrenamiento":
                    imagenes = imagenes[:1]
                conjuntos[nombre][0].extend(imagenes)
                conjuntos[nombre][1].extend([clase] * len(imagenes))
    return conjuntos


def cargar_imagen(ruta: tf.Tensor, etiqueta: tf.Tensor):
    """Lee, decodifica y normaliza a [0, 1]. Debe coincidir con el preprocesamiento de la API."""
    contenido = tf.io.read_file(ruta)
    imagen = tf.io.decode_image(contenido, channels=3, expand_animations=False)
    imagen = tf.image.resize(imagen, TAMANO_IMAGEN, method="bilinear")
    imagen = tf.cast(imagen, tf.float32) / 255.0
    return imagen, tf.cast(etiqueta, tf.float32)


def crear_dataset(rutas, etiquetas, lote: int, mezclar: bool, semilla: int) -> tf.data.Dataset:
    ds = tf.data.Dataset.from_tensor_slices((rutas, etiquetas))
    if mezclar:
        ds = ds.shuffle(len(rutas), seed=semilla, reshuffle_each_iteration=True)
    ds = ds.map(cargar_imagen, num_parallel_calls=tf.data.AUTOTUNE)
    return ds.batch(lote).prefetch(tf.data.AUTOTUNE)


def construir_modelo() -> tuple[tf.keras.Model, tf.keras.Model]:
    aumento = tf.keras.Sequential(
        [
            tf.keras.layers.RandomRotation(0.08),
            tf.keras.layers.RandomFlip("horizontal"),
            tf.keras.layers.RandomBrightness(0.2, value_range=(0.0, 1.0)),
            tf.keras.layers.RandomContrast(0.2),
        ],
        name="aumento_datos",
    )
    base = tf.keras.applications.MobileNetV2(
        input_shape=TAMANO_IMAGEN + (3,), include_top=False, weights="imagenet"
    )
    base.trainable = False

    entrada = tf.keras.Input(shape=TAMANO_IMAGEN + (3,), name="imagen")
    x = aumento(entrada)
    x = tf.keras.layers.Rescaling(2.0, offset=-1.0, name="escala_mobilenet")(x)  # [0,1] -> [-1,1]
    x = base(x, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(0.3)(x)
    x = tf.keras.layers.Dense(64, activation="relu")(x)
    x = tf.keras.layers.Dropout(0.2)(x)
    salida = tf.keras.layers.Dense(1, activation="sigmoid", name="prob_con_signos")(x)
    return tf.keras.Model(entrada, salida, name="mandidog"), base


def compilar(modelo: tf.keras.Model, tasa: float) -> None:
    modelo.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=tasa),
        loss="binary_crossentropy",
        metrics=["accuracy", tf.keras.metrics.AUC(name="auc")],
    )


def pesos_de_clase(etiquetas: list[int]) -> dict[int, float]:
    total = len(etiquetas)
    conteo = np.bincount(etiquetas, minlength=2)
    return {i: total / (2.0 * max(1, conteo[i])) for i in range(2)}


def calcular_metricas(y_real: np.ndarray, y_prob: np.ndarray, umbral: float = 0.5) -> dict:
    y_pred = (y_prob >= umbral).astype(int)
    vp = int(np.sum((y_pred == 1) & (y_real == 1)))
    vn = int(np.sum((y_pred == 0) & (y_real == 0)))
    fp = int(np.sum((y_pred == 1) & (y_real == 0)))
    fn = int(np.sum((y_pred == 0) & (y_real == 1)))

    def dividir(a, b):
        return round(a / b, 4) if b else 0.0

    precision = dividir(vp, vp + fp)
    sensibilidad = dividir(vp, vp + fn)
    return {
        "umbral": umbral,
        "muestras_prueba": int(len(y_real)),
        "exactitud": dividir(vp + vn, len(y_real)),
        "precision": precision,
        "sensibilidad": sensibilidad,
        "especificidad": dividir(vn, vn + fp),
        "f1": dividir(2 * precision * sensibilidad, precision + sensibilidad),
        "matriz_confusion": {
            "orden": "filas = clase real, columnas = clase predicha, [sin_signos, con_signos]",
            "valores": [[vn, fp], [fn, vp]],
        },
    }


def ajustar_modelo(entrenamiento, validacion, args: argparse.Namespace, detalle: int = 1) -> tf.keras.Model:
    """Entrena un modelo nuevo en dos fases (base congelada y ajuste fino) y lo devuelve."""
    ds_entrenamiento = crear_dataset(*entrenamiento, args.lote, True, args.semilla)
    ds_validacion = crear_dataset(*validacion, args.lote, False, args.semilla)

    modelo, base = construir_modelo()
    pesos = pesos_de_clase(entrenamiento[1])
    parada = tf.keras.callbacks.EarlyStopping(monitor="val_loss", patience=5, restore_best_weights=True)

    print("\nFase 1: base congelada")
    compilar(modelo, 1e-3)
    modelo.fit(ds_entrenamiento, validation_data=ds_validacion, epochs=args.epocas_base,
               class_weight=pesos, callbacks=[parada], verbose=detalle)

    print(f"Fase 2: ajuste fino de las últimas {args.capas_ajuste} capas")
    base.trainable = True
    for capa in base.layers[: -args.capas_ajuste]:
        capa.trainable = False
    for capa in base.layers:
        if isinstance(capa, tf.keras.layers.BatchNormalization):
            capa.trainable = False  # mantiene estables las estadísticas de ImageNet
    compilar(modelo, 1e-5)
    modelo.fit(ds_entrenamiento, validation_data=ds_validacion, epochs=args.epocas_ajuste,
               class_weight=pesos, callbacks=[parada], verbose=detalle)
    return modelo


def entrenar(args: argparse.Namespace) -> dict:
    """Ejecuta todo el proceso y devuelve las métricas sobre el conjunto de prueba."""
    fijar_semillas(args.semilla)

    print("Leyendo imágenes...")
    rutas, etiquetas = listar_imagenes(args.data)
    conjuntos = dividir_estratificado(rutas, etiquetas, args.prueba, args.validacion, args.semilla)
    for nombre, (r, _) in conjuntos.items():
        print(f"  {nombre}: {len(r)} imágenes de {len({grupo_de(x) for x in r})} fotos originales")

    modelo = ajustar_modelo(conjuntos["entrenamiento"], conjuntos["validacion"], args)
    ds_prueba = crear_dataset(*conjuntos["prueba"], args.lote, False, args.semilla)

    print("\nEvaluando en el conjunto de prueba...")
    y_prob = modelo.predict(ds_prueba, verbose=0).reshape(-1)
    y_real = np.array(conjuntos["prueba"][1])
    metricas = calcular_metricas(y_real, y_prob)
    metricas.update(
        {
            "modelo": args.salida.stem,
            "arquitectura": "MobileNetV2 (ImageNet) + clasificador binario",
            "clases": CLASES,
            "fecha": datetime.now(timezone.utc).isoformat(),
            "tamano_conjuntos": {k: len(v[0]) for k, v in conjuntos.items()},
            "fotos_originales": {k: len({grupo_de(x) for x in v[0]}) for k, v in conjuntos.items()},
        }
    )

    args.salida.parent.mkdir(parents=True, exist_ok=True)
    modelo.save(args.salida)
    args.metricas.parent.mkdir(parents=True, exist_ok=True)
    args.metricas.write_text(json.dumps(metricas, indent=2, ensure_ascii=False), encoding="utf-8")

    print(json.dumps(metricas, indent=2, ensure_ascii=False))
    print(f"\nModelo guardado en {args.salida}")
    print(f"Métricas guardadas en {args.metricas}")

    if not getattr(args, "sin_app", False):
        from exportar_tflite import DESTINO_APP, exportar

        print("\nExportando el modelo para la app (TensorFlow Lite)...")
        exportar(args.salida, DESTINO_APP, umbral_amarillo=0.30, umbral_rojo=0.60)
    return metricas


def main() -> None:
    entrenar(argumentos())


if __name__ == "__main__":
    main()
