# App móvil de MandiDog IA (Flutter)

Aplicación Android que permite al propietario fotografiar la boca de su perro, enviarla a la API de análisis y ver el resultado como un semáforo (VERDE, AMARILLO o ROJO).

## Requisitos

- Flutter 3.47 o superior (canal stable)
- Android SDK con un emulador o un teléfono Android con depuración USB
- La API de MandiDog IA en ejecución (ver [../api/README.md](../api/README.md))

## Ejecución

```bash
cd mobile
flutter pub get

# Emulador de Android (la API corre en el mismo equipo, puerto 8000)
flutter run

# Teléfono físico en la misma red Wi-Fi que el equipo con la API
flutter run --dart-define=API_URL=http://192.168.1.50:8000
```

Por defecto la app usa `http://10.0.2.2:8000`, la dirección con la que el emulador de Android ve al equipo anfitrión.

## Pruebas y análisis estático

```bash
flutter analyze
flutter test
```

## Arquitectura

```
lib/
├── main.dart            # composition root: crea el cliente HTTP y registra los repositorios con Provider
├── app.dart             # MaterialApp, temas claro/oscuro y localización en español
├── core/                # configuración, tema, colores y transiciones
├── domain/              # entidades, errores e interfaces de repositorio
├── data/                # cliente de la API e implementaciones de los repositorios
└── presentation/        # pantallas, widgets y estado de la interfaz
```

Las pantallas nunca llaman a `http` directamente: usan `AnalisisRepository`, `HistorialRepository` y `PreferenciasRepository`.

## Pantallas

1. **Bienvenida** (solo la primera vez)
2. **Inicio**: analizar, historial, consejos e indicador del estado del servidor
3. **Captura**: cámara con marco de encuadre, galería y confirmación de la foto
4. **Analizando**: animación mientras responde la API
5. **Resultado**: semáforo, confianza, recomendación, aviso, foto, fecha y versión del modelo
6. **Historial**: análisis guardados solo en el teléfono
7. **Acerca de**

## Fuentes

La tipografía Poppins se incluye en `assets/google_fonts/` bajo la licencia SIL Open Font License (`OFL.txt`).
