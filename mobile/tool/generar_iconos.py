"""Genera los íconos de MandiDog IA (web y Android) a partir de un dibujo vectorial simple.

Uso (requiere Pillow):
    python tool/generar_iconos.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

PETROLEO = (15, 76, 92)
PETROLEO_CLARO = (31, 111, 130)
CORAL = (227, 100, 20)
BLANCO = (255, 255, 255)
BASE = 1024
RAIZ = Path(__file__).resolve().parent.parent


def degradado(tamano: int) -> Image.Image:
    """Degradado diagonal de petróleo claro a petróleo."""
    img = Image.new("RGB", (tamano, tamano))
    pixeles = img.load()
    for y in range(tamano):
        for x in range(tamano):
            t = (x + y) / (2 * (tamano - 1))
            pixeles[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(PETROLEO_CLARO, PETROLEO))
    return img


def dibujar_pata(dibujo: ImageDraw.ImageDraw, cx: float, cy: float, escala: float) -> None:
    """Dibuja una pata blanca centrada en (cx, cy). escala = ancho aproximado de la pata."""
    s = escala

    def elipse(x, y, ancho, alto):
        dibujo.ellipse((cx + x - ancho / 2, cy + y - alto / 2, cx + x + ancho / 2, cy + y + alto / 2), fill=BLANCO)

    elipse(0, 0.18 * s, 0.52 * s, 0.44 * s)  # almohadilla principal
    elipse(-0.36 * s, -0.12 * s, 0.2 * s, 0.27 * s)
    elipse(-0.13 * s, -0.33 * s, 0.2 * s, 0.27 * s)
    elipse(0.13 * s, -0.33 * s, 0.2 * s, 0.27 * s)
    elipse(0.36 * s, -0.12 * s, 0.2 * s, 0.27 * s)


def icono_redondo() -> Image.Image:
    """Círculo con anillo coral y pata, sobre fondo transparente."""
    lienzo = Image.new("RGBA", (BASE, BASE), (0, 0, 0, 0))
    mascara = Image.new("L", (BASE, BASE), 0)
    ImageDraw.Draw(mascara).ellipse((0, 0, BASE - 1, BASE - 1), fill=255)
    anillo = Image.new("RGBA", (BASE, BASE), CORAL + (255,))
    lienzo.paste(anillo, (0, 0), mascara)

    interior = int(BASE * 0.86)
    margen = (BASE - interior) // 2
    mascara_int = Image.new("L", (interior, interior), 0)
    ImageDraw.Draw(mascara_int).ellipse((0, 0, interior - 1, interior - 1), fill=255)
    lienzo.paste(degradado(interior), (margen, margen), mascara_int)

    dibujar_pata(ImageDraw.Draw(lienzo), BASE / 2, BASE / 2, BASE * 0.52)
    return lienzo


def icono_maskable() -> Image.Image:
    """Ícono a sangre completa (el sistema recorta la forma); la pata queda en la zona segura."""
    lienzo = degradado(BASE).convert("RGBA")
    dibujar_pata(ImageDraw.Draw(lienzo), BASE / 2, BASE / 2, BASE * 0.42)
    return lienzo


def guardar(img: Image.Image, ruta: Path, lado: int) -> None:
    ruta.parent.mkdir(parents=True, exist_ok=True)
    img.resize((lado, lado), Image.Resampling.LANCZOS).save(ruta, optimize=True)
    print("generado", ruta.relative_to(RAIZ))


def main() -> None:
    redondo = icono_redondo()
    maskable = icono_maskable()

    web = RAIZ / "web"
    guardar(redondo, web / "favicon.png", 64)
    guardar(redondo, web / "icons" / "Icon-192.png", 192)
    guardar(redondo, web / "icons" / "Icon-512.png", 512)
    guardar(maskable, web / "icons" / "Icon-maskable-192.png", 192)
    guardar(maskable, web / "icons" / "Icon-maskable-512.png", 512)
    guardar(maskable.convert("RGB"), web / "icons" / "apple-touch-icon.png", 180)

    res = RAIZ / "android" / "app" / "src" / "main" / "res"
    for carpeta, lado in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        guardar(redondo, res / f"mipmap-{carpeta}" / "ic_launcher.png", lado)


if __name__ == "__main__":
    main()
