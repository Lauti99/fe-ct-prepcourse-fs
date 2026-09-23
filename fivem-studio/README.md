# 🎬 Studio — servidor de FiveM para cinemáticas y fotos

Servidor de FiveM hecho desde cero, sin frameworks (ni ESX ni QBCore), pensado como **estudio de grabación**:
cámara libre, rutas de cámara cinemáticas, modo foto, control total del clima y la hora, y actores
(personajes, vehículos y props) para montar escenas.

## Qué incluye (v0.1)

| Módulo | Qué hace |
|---|---|
| **Freecam** | Cámara libre con velocidad, FOV, roll (inclinación) y profundidad de campo (DOF). |
| **Cinemática** | Guarda keyframes de cámara y los reproduce con una curva suave (Catmull-Rom). Duración por tramo, suavizado, bucle, cuenta atrás, bandas de cine y grabación automática en el Rockstar Editor. |
| **Escenas** | Guarda y carga rutas de cámara en el servidor (`data/scenes.json`). Las comparte todo el equipo. |
| **Foto** | Oculta el HUD y el personaje; bandas 2.39:1, cuadrícula de tercios, filtros de color (timecycle) y cámara lenta. |
| **Mundo** | Clima, hora, congelar el tiempo, apagón, viento y densidad de tráfico y peatones (ciudad vacía). Se sincroniza con todos. |
| **Actores** | Coloca personajes, vehículos o props donde apunta la cámara. Clonar tu personaje, animaciones, fijar y borrar. |
| **Panel** | Interfaz (NUI) con pestañas. Se abre con `F5`. |

## Instalación paso a paso (Windows)

1. **Descarga FXServer**: entra a <https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/>,
   baja el último artifact *recommended* y descomprímelo en `C:\FXServer\server`.
2. **Descarga los recursos base**:
   ```
   git clone https://github.com/citizenfx/cfx-server-data C:\FXServer\server-data
   ```
3. **Copia este estudio**: copia la carpeta `resources/[studio]` a `C:\FXServer\server-data\resources\`.
4. **Configura**: copia `server.cfg.example` a `C:\FXServer\server-data\server.cfg` y pega tu clave en
   `sv_licenseKey`. La clave se crea gratis en <https://portal.cfx.re>.
5. **Arranca**:
   ```
   cd C:\FXServer\server-data
   C:\FXServer\server\FXServer.exe +exec server.cfg
   ```
6. En FiveM pulsa `F8` y escribe `connect localhost`.

> Con **txAdmin** (se abre solo si ejecutas `FXServer.exe` sin argumentos) también funciona: elige la
> plantilla *CFX Default*, copia `[studio]` a `resources` y añade `ensure studio` al `server.cfg`.

En Linux es lo mismo, con el artifact de `build_proot_linux` y `bash run.sh +exec server.cfg`.

## Controles

| Tecla | Acción |
|---|---|
| `F5` | Abrir / cerrar el panel |
| `F6` | Activar / desactivar la freecam |
| `K` | Añadir keyframe en la posición de la cámara |
| `F7` | Reproducir / parar la cinemática |
| `Retroceso` | Cortar la cinemática |
| `W A S D` | Mover la cámara |
| `Espacio` / `E` · `Ctrl` / `Q` | Subir · bajar |
| `Shift` · `Alt` | Rápido · lento |
| `RePág` / `AvPág` | Subir / bajar la velocidad base |
| Rueda del mouse | Zoom (FOV) |
| `Z` / `C` · `X` | Inclinar (roll) · reiniciar roll |

Las teclas se pueden cambiar en *Ajustes → Asignación de teclas → FiveM*.

## Cómo grabar una cinemática

1. `F6` para la freecam y colócate en el primer plano.
2. `K` para guardar el keyframe. Mueve la cámara y pulsa `K` otra vez para cada punto de la ruta.
3. En `F5 → Cinemática`, ajusta la duración de cada tramo (segundos hasta el siguiente punto).
4. Pulsa **▶ Reproducir**. Empieza tras la cuenta atrás; mientras tanto, pon a grabar OBS o activa
   *Grabar clip* para usar el Rockstar Editor.
5. Si te gusta la ruta, ponle un nombre y **Guárdala** para usarla otro día.

## Estructura

```
fivem-studio/
├── server.cfg.example
└── resources/[studio]/studio/
    ├── fxmanifest.lua
    ├── config.lua          ← spawn, velocidades, filtros, climas, animaciones, modelos
    ├── shared/utils.lua    ← matemáticas (interpolación, direcciones)
    ├── client/
    │   ├── main.lua        ← permisos, aparición, helpers
    │   ├── freecam.lua     ← cámara libre
    │   ├── cinematic.lua   ← keyframes y reproducción
    │   ├── visual.lua      ← modo foto (HUD, bandas, filtros, cámara lenta)
    │   ├── world.lua       ← aplica clima y hora sincronizados
    │   ├── actors.lua      ← personajes, vehículos y props
    │   └── ui.lua          ← panel, comandos y teclas
    ├── server/
    │   ├── main.lua        ← permisos (ACE)
    │   ├── world.lua       ← estado del mundo (GlobalState)
    │   └── scenes.lua      ← guardado de escenas
    ├── html/               ← panel NUI
    └── data/scenes.json
```

## Próximos pasos (roadmap)

- [ ] Guardar actores y mundo junto con la escena (escena completa, no solo la cámara)
- [ ] Mover y rotar actores con un gizmo
- [ ] Cámara que sigue o apunta a un actor o vehículo (tracking / look-at)
- [ ] Varias cámaras por escena y cortes entre ellas
- [ ] Iluminación: focos colocables (DrawLightWithRange / DrawSpotLight)
- [ ] Editor de ropa y apariencia para los personajes
- [ ] Coches en movimiento sobre una ruta grabada
- [ ] Capturas desde el panel con `screenshot-basic`
