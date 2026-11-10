"""Validación cruzada estratificada por foto original (k pliegues) del modelo de MandiDog IA.

Con pocos datos, un único conjunto de prueba tiene muy pocas fotos y sus métricas cambian mucho según
qué fotos caigan en él. Aquí cada foto original se evalúa exactamente una vez, con un modelo que no la
vio durante el entrenamiento, y se informan las métricas globales y su variación entre pliegues.

Además:
  * muestra cómo se reparte cada clase real en el semáforo con los umbrales actuales;
  * sugiere umbrales: amarillo = el mayor umbral que mantiene la sensibilidad objetivo
    (casi ningún perro con signos queda en VERDE) y rojo = el menor umbral que alcanza la
    especificidad objetivo (casi ningún perro sin signos queda en ROJO).

Uso:
    python validacion_cruzada.py --data data --pliegues 5
"""

from __future__ import annotations

import argparse
import csv
import json
from datetime import datetime, timezone
from pathlib import Path

import numpy as np

from train import (
    CLASES,
    ajustar_modelo,
    calcular_metricas,
    crear_dataset,
    fijar_semillas,
    grupo_de,
    listar_imagenes,
)


def argumentos() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validación cruzada del modelo de MandiDog IA")
    parser.add_argument("--data", type=Path, default=Path("data"))
    parser.add_argument("--pliegues", type=int, default=5)
    parser.add_argument("--salida", type=Path, default=Path("metrics_cv.json"))
    parser.add_argument("--predicciones", type=Path, default=Path("predicciones_cv.csv"))
    parser.add_argument("--epocas-base", type=int, default=15)
    parser.add_argument("--epocas-ajuste", type=int, default=15)
    parser.add_argument("--lote", type=int, default=16)
    parser.add_argument("--capas-ajuste", type=int, default=30)
    parser.add_argument("--validacion", type=float, default=0.15)
    parser.add_argument("--semilla", type=int, default=42)
    parser.add_argument("--umbral-amarillo", type=float, default=0.30)
    parser.add_argument("--umbral-rojo", type=float, default=0.60)
    parser.add_argument("--sensibilidad-objetivo", type=float, default=0.90)
    parser.add_argument("--especificidad-objetivo", type=float, default=0.90)
    return parser.parse_args()


def agrupar(rutas, etiquetas) -> dict[tuple[int, str], list[str]]:
    grupos: dict[tuple[int, str], list[str]] = {}
    for ruta, etiqueta in zip(rutas, etiquetas):
        grupos.setdefault((int(etiqueta), grupo_de(ruta)), []).append(ruta)
    return grupos


def asignar_pliegues(claves, pliegues: int, generador) -> dict:
    """Reparte las fotos originales de cada clase en k pliegues de tamaño parecido."""
    asignacion = {}
    for clase in sorted({c for c, _ in claves}):
        de_clase = sorted(k for k in claves if k[0] == clase)
        orden = generador.permutation(len(de_clase))
        for posicion, indice in enumerate(orden):
            asignacion[de_clase[indice]] = posicion % pliegues
    return asignacion


def expandir(claves, grupos, una_por_foto: bool):
    rutas, etiquetas = [], []
    for clave in claves:
        imagenes = sorted(grupos[clave])
        if una_por_foto:
            imagenes = imagenes[:1]
        rutas += imagenes
        etiquetas += [clave[0]] * len(imagenes)
    return rutas, etiquetas


def area_bajo_curva(y_real: np.ndarray, y_prob: np.ndarray) -> float:
    """AUC ROC por el método de rangos (probabilidad de que un positivo puntúe más que un negativo)."""
    positivos = y_prob[y_real == 1]
    negativos = y_prob[y_real == 0]
    if len(positivos) == 0 or len(negativos) == 0:
        return float("nan")
    mayores = (positivos[:, None] > negativos[None, :]).sum()
    empates = (positivos[:, None] == negativos[None, :]).sum()
    return round(float((mayores + 0.5 * empates) / (len(positivos) * len(negativos))), 4)


def semaforo(y_real, y_prob, amarillo: float, rojo: float) -> dict:
    tabla = {}
    for indice, clase in enumerate(CLASES):
        p = y_prob[y_real == indice]
        tabla[clase] = {
            "VERDE": int(np.sum(p < amarillo)),
            "AMARILLO": int(np.sum((p >= amarillo) & (p < rojo))),
            "ROJO": int(np.sum(p >= rojo)),
        }
    return tabla


def sugerir_umbrales(y_real, y_prob, sens_obj: float, esp_obj: float, por_defecto: tuple[float, float]) -> dict:
    candidatos = np.round(np.arange(0.05, 0.96, 0.01), 2)
    positivos = y_prob[y_real == 1]
    negativos = y_prob[y_real == 0]
    con_sensibilidad = [u for u in candidatos if np.mean(positivos >= u) >= sens_obj]
    con_especificidad = [u for u in candidatos if np.mean(negativos < u) >= esp_obj]
    amarillo = float(max(con_sensibilidad)) if con_sensibilidad else por_defecto[0]
    rojo = float(min(con_especificidad)) if con_especificidad else por_defecto[1]
    valido = amarillo < rojo
    return {
        "umbral_amarillo": amarillo if valido else por_defecto[0],
        "umbral_rojo": rojo if valido else por_defecto[1],
        "criterio": f"amarillo: sensibilidad >= {sens_obj}; rojo: especificidad >= {esp_obj}",
        "aplicado": valido,
        "nota": None if valido else "Los objetivos se cruzan con estos datos; se conservan los umbrales por defecto.",
    }


def validar(args: argparse.Namespace) -> dict:
    fijar_semillas(args.semilla)
    generador = np.random.default_rng(args.semilla)
    print("Leyendo imágenes...")
    rutas, etiquetas = listar_imagenes(args.data)
    grupos = agrupar(rutas, etiquetas)
    asignacion = asignar_pliegues(list(grupos), args.pliegues, generador)

    filas, exactitudes = [], []
    for pliegue in range(args.pliegues):
        prueba = [k for k, p in asignacion.items() if p == pliegue]
        resto = [k for k, p in asignacion.items() if p != pliegue]
        validacion = []
        for clase in sorted({c for c, _ in resto}):
            de_clase = sorted(k for k in resto if k[0] == clase)
            orden = generador.permutation(len(de_clase))
            n_val = max(1, int(round(len(de_clase) * args.validacion)))
            validacion += [de_clase[i] for i in orden[:n_val]]
        entrenamiento = [k for k in resto if k not in validacion]

        print(f"\n=== Pliegue {pliegue + 1}/{args.pliegues}: {len(entrenamiento)} fotos de entrenamiento, "
              f"{len(validacion)} de validación, {len(prueba)} de prueba ===")
        modelo = ajustar_modelo(expandir(entrenamiento, grupos, False), expandir(validacion, grupos, True), args, detalle=0)
        rutas_prueba, etiquetas_prueba = expandir(prueba, grupos, True)
        y_prob = modelo.predict(crear_dataset(rutas_prueba, etiquetas_prueba, args.lote, False, args.semilla), verbose=0).reshape(-1)
        y_real = np.array(etiquetas_prueba)
        exactitud = float(np.mean((y_prob >= 0.5).astype(int) == y_real))
        exactitudes.append(exactitud)
        print(f"Exactitud del pliegue: {exactitud:.3f}")
        for ruta, real, prob in zip(rutas_prueba, y_real, y_prob):
            filas.append({"pliegue": pliegue + 1, "foto": grupo_de(ruta), "clase_real": CLASES[real],
                          "probabilidad_con_signos": round(float(prob), 4)})

    y_real = np.array([CLASES.index(f["clase_real"]) for f in filas])
    y_prob = np.array([f["probabilidad_con_signos"] for f in filas])
    resultado = {
        "metodo": f"Validación cruzada estratificada por foto original, {args.pliegues} pliegues",
        "fotos_evaluadas": int(len(filas)),
        "metricas_umbral_0_5": calcular_metricas(y_real, y_prob),
        "auc_roc": area_bajo_curva(y_real, y_prob),
        "exactitud_por_pliegue": [round(e, 4) for e in exactitudes],
        "exactitud_media": round(float(np.mean(exactitudes)), 4),
        "exactitud_desviacion": round(float(np.std(exactitudes)), 4),
        "semaforo_umbrales_actuales": {
            "umbrales": [args.umbral_amarillo, args.umbral_rojo],
            "reparto": semaforo(y_real, y_prob, args.umbral_amarillo, args.umbral_rojo),
        },
        "umbrales_sugeridos": sugerir_umbrales(
            y_real, y_prob, args.sensibilidad_objetivo, args.especificidad_objetivo,
            (args.umbral_amarillo, args.umbral_rojo),
        ),
        "fecha": datetime.now(timezone.utc).isoformat(),
    }
    sugeridos = resultado["umbrales_sugeridos"]
    resultado["semaforo_umbrales_sugeridos"] = semaforo(
        y_real, y_prob, sugeridos["umbral_amarillo"], sugeridos["umbral_rojo"]
    )

    args.salida.write_text(json.dumps(resultado, indent=2, ensure_ascii=False), encoding="utf-8")
    with args.predicciones.open("w", newline="", encoding="utf-8") as f:
        escritor = csv.DictWriter(f, fieldnames=list(filas[0]))
        escritor.writeheader()
        escritor.writerows(filas)
    print(json.dumps(resultado, indent=2, ensure_ascii=False))
    print(f"\nResultados: {args.salida} y {args.predicciones}")
    return resultado


def main() -> None:
    validar(argumentos())


if __name__ == "__main__":
    main()
