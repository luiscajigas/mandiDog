"""Organiza el dataset "dog dental" (Roboflow Universe, v4 "tartar divided into stages") en las dos clases del modelo.

El dataset es de detección de objetos y marca el sarro por etapas (tartar_1 a tartar_4). Cada foto recibe
la etapa más alta que tenga anotada (0 si solo se anotaron dientes, sin sarro) y se clasifica así:

  sin_signos  etapa menor que --corte  (por defecto: sin sarro o sarro leve, etapa 1)
  con_signos  etapa igual o mayor que --corte  (por defecto: etapas 2, 3 y 4)

Las fotos marcadas con sarro pero sin etapa se excluyen porque no se pueden ubicar con seguridad.
Roboflow guarda tres copias aumentadas de cada foto de entrenamiento ("<original>.rf.<hash>.jpg");
train.py las agrupa por foto original para que nunca queden repartidas entre entrenamiento y prueba.

Uso:
    python preparar_roboflow.py --origen data/roboflow_v4 --destino data
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import shutil
from collections import Counter, defaultdict
from pathlib import Path

SUBCONJUNTOS = ("train", "valid", "test")
PATRON_ETAPA = re.compile(r"tartar_(\d)")


def argumentos() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Prepara el dataset de Roboflow para train.py")
    parser.add_argument("--origen", type=Path, default=Path("data/roboflow_v4"), help="Carpeta del ZIP COCO descomprimido")
    parser.add_argument("--destino", type=Path, default=Path("data"))
    parser.add_argument("--corte", type=int, default=2, help="Etapa de sarro a partir de la cual la foto es con_signos")
    return parser.parse_args()


def grupo_de(nombre_archivo: str) -> str:
    """Nombre de la foto original: Roboflow agrega '.rf.<hash>' a cada copia."""
    return nombre_archivo.split(".rf.")[0]


def etapa_de(clases: set[str]) -> int | None:
    """Etapa más alta anotada; 0 si no hay sarro; None si hay sarro sin etapa."""
    etapas = [int(m.group(1)) for c in clases if (m := PATRON_ETAPA.fullmatch(c))]
    if etapas:
        return max(etapas)
    if "tartar" in clases:
        return None
    return 0


def leer_anotaciones(origen: Path) -> list[dict]:
    registros = []
    for subconjunto in SUBCONJUNTOS:
        archivo = origen / subconjunto / "_annotations.coco.json"
        if not archivo.is_file():
            continue
        datos = json.loads(archivo.read_text(encoding="utf-8"))
        categorias = {c["id"]: c["name"] for c in datos["categories"]}
        clases_por_imagen = defaultdict(set)
        for anotacion in datos["annotations"]:
            clases_por_imagen[anotacion["image_id"]].add(categorias[anotacion["category_id"]])
        for imagen in datos["images"]:
            registros.append(
                {
                    "ruta": origen / subconjunto / imagen["file_name"],
                    "archivo": imagen["file_name"],
                    "grupo": grupo_de(imagen["file_name"]),
                    "etapa": etapa_de(clases_por_imagen[imagen["id"]]),
                    "subconjunto_roboflow": subconjunto,
                }
            )
    if not registros:
        raise SystemExit(f"No se encontraron anotaciones COCO en {origen}")
    return registros


def preparar(origen: Path, destino: Path, corte: int) -> Counter:
    registros = leer_anotaciones(origen)
    for clase in ("sin_signos", "con_signos"):
        carpeta = destino / clase
        if carpeta.exists():
            shutil.rmtree(carpeta)
        carpeta.mkdir(parents=True)

    fotos = Counter()
    filas = []
    for r in registros:
        if r["etapa"] is None:
            clase = "excluida"
        else:
            clase = "con_signos" if r["etapa"] >= corte else "sin_signos"
            shutil.copy2(r["ruta"], destino / clase / r["archivo"])
        fotos[(clase, r["grupo"])] += 1
        filas.append({**r, "ruta": str(r["ruta"]), "clase": clase})

    with (destino / "manifiesto.csv").open("w", newline="", encoding="utf-8") as f:
        escritor = csv.DictWriter(f, fieldnames=["archivo", "grupo", "etapa", "clase", "subconjunto_roboflow", "ruta"])
        escritor.writeheader()
        escritor.writerows(filas)

    originales = Counter(clase for clase, _ in fotos)
    imagenes = Counter(f["clase"] for f in filas)
    for clase in ("sin_signos", "con_signos", "excluida"):
        print(f"  {clase}: {originales[clase]} fotos originales ({imagenes[clase]} imágenes con las copias)")
    print(f"Manifiesto: {destino / 'manifiesto.csv'}")
    return originales


def main() -> None:
    args = argumentos()
    print(f"Corte: etapa {args.corte} o mayor = con_signos")
    preparar(args.origen, args.destino, args.corte)


if __name__ == "__main__":
    main()
