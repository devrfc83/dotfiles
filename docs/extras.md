# Extras

Saludo matutino, diversión en la terminal y emulación.

[← Volver al índice](README.md)

## Saludo matutino (buenos_dias)

`zsh/scripts/buenos_dias.zsh` dice en voz alta la fecha, la hora y la
temperatura de `CURRENT_LOCATION` (actual, mínima y máxima, desde wttr.in; ver
«Ubicación para el clima»). Se enlaza como `~/.local/bin/buenos-dias` y lo
ejecuta todos los días a las 08:00 el timer de usuario
`systemd/buenos-dias.timer` (si el equipo estaba apagado a esa hora, no saluda
después). Antes espera hasta 30 segundos a que haya red (`nm-online`); si no la
hay, saluda sin la temperatura.

La voz es **Piper** (neuronal, sin conexión, mucho menos robótica que
espeak-ng). Debe instalarse una vez, junto con una voz en español:

```bash
bash scripts/install-piper.sh                      # voz por defecto: es_MX-claude-high
bash scripts/install-piper.sh es_AR-daniela-high   # u otra voz
```

Voces en español disponibles: `es_MX-claude-high`, `es_MX-ald-medium`,
`es_AR-daniela-high`, `es_ES-davefx-medium`, `es_ES-sharvard-medium`. Las voces
quedan en `~/.local/share/piper/voces/`. Para usar una distinta de la
predeterminada, debe definirse `BUENOS_DIAS_VOZ` (para el timer, en
`~/.config/environment.d/buenos-dias.conf`):

```bash
mkdir -p ~/.config/environment.d
echo 'BUENOS_DIAS_VOZ=es_AR-daniela-high' > ~/.config/environment.d/buenos-dias.conf
```

Si Piper o la voz no están instalados, el saludo usa **espeak-ng**.

Comandos útiles:

| Comando                                            | Acción                   |
| -------------------------------------------------- | ------------------------ |
| `buenos-dias`                                      | Escuchar el saludo ahora |
| `systemctl --user list-timers buenos-dias`         | Ver la próxima ejecución |
| `systemctl --user disable --now buenos-dias.timer` | Desactivar el saludo     |
| `journalctl --user -u buenos-dias`                 | Ver los registros        |

## Diversión en la terminal

| Comando                  | Acción                                                                       |
| ------------------------ | ---------------------------------------------------------------------------- |
| `clima [ciudad]`         | Pronóstico de 3 días de wttr.in en español (por defecto, `CURRENT_LOCATION`) |
| `clima-hoy [ciudad]`     | Tiempo actual y pronóstico de hoy                                            |
| `luna`                   | Fase lunar                                                                   |
| `starwars`               | Star Wars episodio IV en ASCII (towel.blinkenlights.nl); `Ctrl-C` sale       |
| `mapa`                   | MapSCII: mapa mundial en Braille (flechas, `a`/`z` zoom, `q` sale)           |
| `toilet -f future texto` | Texto grande en ASCII; `--gay` (arcoíris) y `--metal` agregan color          |
| `btop` / `glances`       | Monitores del sistema                                                        |
| `cava`                   | Visualizador de audio (por ejemplo, mientras suena Spotify)                  |
| `tty-clock -c -C 4`      | Reloj grande centrado, en azul (morado con Dracula; `q` sale)                |
| `genact`                 | Simula actividad (compilaciones, descargas…) para parecer ocupado            |
| `tint`                   | Tetris clásico, con tabla de puntajes                                        |
| `tetris-tui`             | Tetris moderno (pieza fantasma, guardar pieza)                               |
| `bastet`                 | «Bastard Tetris»: elige a propósito la peor pieza posible                    |

**tty-clock** no está en Fedora; se compila desde el upstream en un commit fijo
(requiere `ncurses-devel`, incluido en `packages.txt`). Si ya está compilado en
ese commit, no hace nada; para actualizarlo, debe cambiarse `commit` en el
script:

```bash
bash scripts/install-tty-clock.sh
```

**tint** tampoco está en Fedora; se compila desde las fuentes de Debian,
verificando el checksum del tarball. Como en Debian, el binario es setgid
`games` para guardar los puntajes en `/var/games/tint.scores`:

```bash
bash scripts/install-tint.sh
```

**genact** y **tetris-tui** se instalan con Cargo ([Rust](desarrollo.md#rust));
**bastet**, con
el bloque DNF.

`clima` acepta ciudades con espacios (`clima Puerto Montt`). Son funciones de
`zsh/zshfunctions` (no alias) porque reciben la ciudad como argumento.

## Emulación (NES, SNES, PlayStation, Sega Genesis y arcade)

Todo se instala con el bloque DNF (sección «Emulación» de `packages.txt`); no se
usa Flathub.

| Sistema                   | Programa                        | Paquete                                          |
| ------------------------- | ------------------------------- | ------------------------------------------------ |
| NES / Famicom             | RetroArch, core Nestopia        | `libretro-nestopia`                              |
| SNES / Super Famicom      | RetroArch, core bsnes           | `libretro-bsnes-mercury`                         |
| PlayStation               | RetroArch, core PCSX ReARMED    | `libretro-pcsx-rearmed`                          |
| Sega Genesis / Mega Drive | RetroArch, core Genesis Plus GX | compilado (`scripts/install-genesis-plus-gx.sh`) |
| Arcade                    | MAME (independiente)            | `mame`                                           |

`retroarch` recomienda (dependencias débiles) muchos otros cores de Fedora: DS,
Virtual Boy, Game & Watch, Atari, PlayStation, etc. Para que RetroArch muestre
solo los de la tabla, `scripts/fedora-install.sh` instala con
`--setopt=exclude_from_weak='libretro-*'`. Si ya están instalados, basta con
`sudo dnf remove` de los que sobren: dnf no vuelve a instalar una dependencia
débil que se quitó a mano.

**BIOS de PlayStation:** PCSX ReARMED usa
`~/.config/retroarch/system/scph5501.bin`, que no puede redistribuirse.
`scripts/dotfiles-install.sh` lo copia desde Nextcloud
(`Respaldos/scph5501.bin`; [Archivos privados desde
Nextcloud](instalacion.md#archivos-privados-desde-nextcloud)) y
verifica su SHA-256; si ya está bien, no hace nada.

**Genesis Plus GX** (Sega Genesis/Mega Drive, Master System, Game Gear y Sega
CD) no está en Fedora porque su licencia solo permite el uso no comercial.
`scripts/install-genesis-plus-gx.sh` (lo ejecuta `extras-install.sh`) lo compila
desde el upstream en un commit fijo y lo deja en `~/.local/lib/libretro/`; para
actualizarlo, debe cambiarse el commit del script. RetroArch lee los cores de un
solo directorio, así que `scripts/dotfiles-install.sh` arma
`~/.config/retroarch/cores/` con enlaces a los del sistema
(`/usr/lib64/libretro/`) y a los compilados.

### Configuración

RetroArch reescribe su `~/.config/retroarch/retroarch.cfg` completo al salir,
así que no se enlaza: `retroarch/retroarch.cfg` guarda solo los ajustes propios
y `scripts/dotfiles-install.sh` los aplica sobre ese archivo, sin tocar el resto
(si RetroArch está abierto, no hace nada):

| Ajuste                                  | Efecto                                                 |
| --------------------------------------- | ------------------------------------------------------ |
| `input_menu_toggle_gamepad_combo = "4"` | **Start + Select** abre el menú durante un juego       |
| `rgui_browser_directory = "~/Juegos"`   | _Cargar contenido_ parte en la carpeta de juegos       |
| `video_fullscreen = "true"`             | Pantalla completa                                      |
| `video_scale_integer = "true"`          | Píxeles de tamaño entero (bordes negros a los lados)   |
| `libretro_directory`                    | Cores del sistema más los compilados                   |
| `joypad_autoconfig_dir`                 | Perfiles de mandos del sistema más los corregidos      |

Los demás ajustes hechos desde el menú de RetroArch se guardan en su propio
archivo; para conservar uno en el repositorio, debe agregarse su línea
(`clave = "valor"`) a `retroarch/retroarch.cfg`. Los menús están en español
(_Settings → User → Language_).

### Gamepad (GameSir Nova Lite T4)

El mando tiene varios modos de conexión. En Linux, el más fiable es el
**receptor USB de 2,4 GHz en modo PC (X-input)**: el kernel lo maneja con el
driver `xpad` y lo presenta como «Microsoft X-Box 360 pad», que RetroArch
configura solo gracias a los perfiles de `/usr/share/libretro/autoconfig/`. La
combinación de botones para cambiar de modo está en el manual del mando.

RetroArch trae un perfil para este modelo (`GameSir Nova Lite.cfg`), pero cruza
hombros y gatillos (LT/RT quedan como L/R) y define Start dos veces.
`retroarch/autoconfig/udev/GameSir Nova Lite.cfg` es la versión corregida: LB/RB
son L/R, LT/RT son L2/R2 y Home abre el menú. RetroArch lee un solo directorio
de perfiles, así que `scripts/dotfiles-install.sh` arma
`~/.config/retroarch/autoconfig/` con enlaces a los del sistema y, encima, a los
del repositorio; los demás mandos siguen configurándose solos.

Por Bluetooth, en modo Switch lo maneja el driver `hid-nintendo`; en ese caso
puede que deba asignarse los botones a mano en RetroArch: _Settings → Input →
Port 1 Controls → Set All Controls_ (Ajustes → Entrada → Controles del puerto 1
→ Asignar todos los controles).

Para comprobar que el sistema reconoce el mando y sus botones, basta un tester
de gamepad en Chromium: usa la Gamepad API, que muestra cada control según su
función (palancas en los ejes 0–3). Para ver los eventos crudos del kernel:

```bash
sudo evtest    # debe elegirse el dispositivo
```

MAME usa el mismo mando sin configuración adicional; los controles se cambian en
su menú (`Tab` → _Input (general)_).

### ROMs

Los ROMs no vienen incluidos; deben obtenerse de los cartuchos propios. Se
guardan en `~/Juegos`, una carpeta por consola (las crea
`scripts/dotfiles-install.sh`):

```bash
mkdir -p ~/Juegos/{Nintendo,"Super Nintendo",PlayStation,"Sega Genesis"} ~/.local/share/mame/roms
```

- **RetroArch:** _Load Content_ (Cargar contenido) y elegir el archivo en
  `~/Juegos/<consola>`; RetroArch propone el core adecuado. _Import Content →
  Scan Directory_ (Importar contenido → Escanear directorio) sobre `~/Juegos`
  crea listas de juegos por consola (usa `retroarch-database`).
- **MAME:** busca los juegos en `~/.local/share/mame/roms` (ruta por defecto de
  `/etc/mame/mame.ini` en Fedora). Los ROMs de MAME deben coincidir con la
  versión instalada (`mame -version`); se comprueban con `mame -verifyroms`.

| Comando                                                           | Acción                                       |
| ----------------------------------------------------------------- | -------------------------------------------- |
| `retroarch`                                                       | Abrir RetroArch                              |
| `retroarch -L /usr/lib64/libretro/nestopia_libretro.so juego.nes` | Abrir un juego directamente con un core      |
| `mame`                                                            | Abrir MAME con su lista de juegos            |
| `mame juego`                                                      | Abrir un juego de arcade por su nombre corto |
