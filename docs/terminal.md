# Terminal

Fuentes, zsh, oh-my-zsh, zoxide, tmux, screen, mc, curl y el clima.

[← Volver al índice](README.md)

## Nerdfonts

Las fuentes **Nerd Fonts** muestran iconos en la terminal, tmux y Vim. Se usa
**FiraCode Nerd Font**, que `scripts/dotfiles-install.sh` copia en
`~/.local/share/fonts/` junto con las demás fuentes desde Nextcloud
(`Respaldos/Fonts/`; [Archivos privados desde
Nextcloud](instalacion.md#archivos-privados-desde-nextcloud)), en una
versión propia (no la del repositorio oficial): las actualizaciones se deciden a
mano, subiendo la fuente nueva a esa carpeta.

**Ptyxis** (la terminal de Fedora) usa la fuente monoespaciada del sistema.
`scripts/dotfiles-install.sh` la fija en **FiraCode Nerd Font Mono 10**, deja
Ptyxis usando esa fuente y pone la paleta **Dracula** (incluida en Ptyxis) en su
perfil por defecto; si Ptyxis nunca se abrió, crea ese perfil. A mano (la paleta
también puede elegirse en las preferencias del perfil):

```bash
gsettings set org.gnome.desktop.interface monospace-font-name 'FiraCode Nerd Font Mono 10'
gsettings set org.gnome.Ptyxis use-system-font true
perfil="$(gsettings get org.gnome.Ptyxis default-profile-uuid | tr -d "'")"
gsettings set "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${perfil}/" palette dracula
```

Se usa la variante **Mono** porque Ptyxis (VTE) da a los iconos de Nerd Fonts
una sola celda: en la variante normal, los iconos son más anchos y se montan
sobre el carácter siguiente. La opción de Ptyxis para caracteres de ancho
ambiguo debe quedar en _estrecho_ (`narrow`, el valor por defecto); en _ancho_
también se ensancharían las líneas de cajas de tmux y `eza`, `°`, `±`, etc.

## Paleta Dracula

Todo usa la paleta [Dracula](https://draculatheme.com): la terminal, tmux,
screen,
git, fzf, `ls`, bat, btop, pgcli, pspg, mc, Vim, VSCodium y Cursor, y en GNOME
los iconos (Tela-dracula) y el color de acento (morado). Los colores están
definidos una sola vez, en `scripts/lib/dracula.palette`, y `scripts/lint.sh`
comprueba que los archivos con colores propios (`tmux/tmux.conf`,
`screen/screenrc`, `git/gitconfig`, `zsh/zshenv`, `input/dircolors` y
`pgcli/config`) solo usen esos.

| Programa          | Cómo toma Dracula                                                    |
| ----------------- | -------------------------------------------------------------------- |
| Ptyxis            | Paleta `dracula`, incluida; la fija `dotfiles-install.sh`             |
| screen, psql, zsh | Colores ANSI: los toman de la paleta de la terminal                  |
| tmux              | Colores propios de la barra (`tmux/tmux.conf`)                       |
| git               | Colores propios (`git/gitconfig`)                                    |
| `ls`, eza, fd     | `input/dircolors` (24 bits)                                          |
| fzf               | Colores oficiales de Dracula en `FZF_DEFAULT_OPTS` (`zsh/zshenv`)    |
| bat               | Tema `Dracula`, incluido (`BAT_THEME`, en `zsh/zshenv`)              |
| btop              | Tema `dracula`, incluido (`btop/btop.conf`)                          |
| pgcli             | Estilo `dracula` de Pygments y colores propios (`pgcli/config`)      |
| pspg              | Estilo 24, incluido (`postgresql/psqlrc`)                            |
| mc                | Skin oficial, `mc/skins/dracula.ini` (`MC_SKIN`, en `zsh/zshenv`)     |
| Vim               | `dracula/vim`, también para airline (`vim/vimrc`)                    |
| VSCodium y Cursor | Extensión `dracula-theme.theme-dracula` (`codium/`)                  |

**btop** reescribe su archivo de configuración entero al salir, así que no se
enlaza: `dotfiles-install.sh` aplica las claves de `btop/btop.conf` sobre
`~/.config/btop/btop.conf`, como con RetroArch. **pgcli** combina
`~/.config/pgcli/config` (enlace a `pgcli/config`, solo con lo propio) con su
configuración por defecto.

## Zsh, inputrc y dircolors

**Zsh** queda instalado con el bloque DNF. Los archivos de este repositorio
configuran el shell y los programas que usan readline:

| Archivo en el repo | Enlace en `$HOME` | Función                                     |
| ------------------ | ----------------- | ------------------------------------------- |
| `input/inputrc`    | `~/.inputrc`      | Edición tipo vi en bash, python, psql, etc. |
| `input/dircolors`  | `~/.dircolors`    | Colores de `ls` / `eza` (paleta Dracula)    |
| `zsh/*`            | `~/.zsh*`         | Shell interactivo completo                  |

`scripts/fedora-install.sh` deja zsh como shell de inicio si aún no lo es. A
mano:

```bash
chsh -s "$(command -v zsh)"
```

Debe cerrarse sesión y volverse a entrar para que surta efecto.

**Readline en modo vi** (`~/.inputrc`):

- Con `Esc` se pasa a modo comando.
- En modo comando: `h`/`l` (izquierda/derecha), `b`/`w` (palabras), `0`/`$`
  (inicio/fin de línea).
- Con `↑`/`↓` o `Ctrl-p`/`Ctrl-n` se recorre el historial por prefijo.
- En modo inserción: `Ctrl-a` / `Ctrl-e` — inicio/fin de línea.

Para comprobarlo: debe abrirse `python3`, escribir un comando, pulsarse `Esc` y
probarse las teclas anteriores.

## oh-my-zsh

El framework y sus plugins externos (`zsh-completions` y
`zsh-syntax-highlighting`) los instala o actualiza
`scripts/install-shell-plugins.sh` (lo ejecuta `extras-install.sh`). Los clona
con git en `~/.oh-my-zsh` sin usar el instalador oficial, que reemplazaría
`~/.zshrc` (un enlace a este repositorio).

Configuración relevante en este repositorio:

- **Tema:** `pygmalion` (`ZSH_THEME` en `zsh/zshrc`). Las variables de
  oh-my-zsh y del historial van en `zshrc` sin exportar, para que no las herede
  cada programa.
- **Plugins de omz:** listados en `zsh/zshrc` (git, tmux, vi-mode, postgres,
  npm, etc.).
- **Agente SSH:** no se usa el plugin `ssh-agent`. El agente es el de GNOME
  (`gcr-ssh-agent`), que la sesión exporta en `SSH_AUTH_SOCK` y comparten las
  terminales, tmux y los editores.
- **Actualizaciones:** no son automáticas (`zstyle ':omz:update' mode disabled`
  en `zshrc`): las hace `scripts/dotfiles-update.sh`; a mano, con `omz update`.

Debe recargarse la shell con `source ~/.zshrc`.

Si **fastfetch** está instalado (bloque DNF), se ejecuta al final de `zsh/zshrc`
en cada shell interactiva.

## Zoxide

**Zoxide** se instala con DNF. El hook se activa en `zsh/zshrc` si existe el
comando `zoxide`.

Uso habitual:

| Comando            | Acción                                        |
| ------------------ | --------------------------------------------- |
| `z foo`            | Ir al directorio que mejor coincida con `foo` |
| `z foo bar`        | Usar varios términos de búsqueda              |
| `zi foo`           | Elegir destino con `fzf`                      |
| `z -`              | Volver al directorio anterior (como `cd -`)   |
| `zoxide query foo` | Ver el destino sin cambiar de carpeta         |

También se definen alias para `eza`, `fzf`, `bat`, `fd`, `direnv`, `pgcli`,
`android` y más en `zsh/zshaliases` (solo si el comando correspondiente está
instalado). Entre ellos, las variantes de `ls` de `common-aliases` (`lt`, `lr`,
`lS`, `lart`, `lrt`, `lsr`, `lsn`, `ldot`), corregidas para `eza`, y alias de
sufijo: escribir el nombre de un vídeo o un audio lo abre en Showtime o en
Decibels, los reproductores de Fedora.

Entre las funciones de `zsh/zshfunctions`, `ggg <texto>` busca en el directorio
actual sin distinguir mayúsculas: con **ripgrep** (`rg`, bloque DNF) omite lo
que ignora `.gitignore` (`node_modules`, `vendor`, `target`...); si no está, usa
`grep -ri`.

## tmux

**tmux** se instala con DNF; la configuración está en `~/.tmux.conf` (prefijo
**`C-a`**, paleta Dracula).

**TPM** (gestor de plugins de tmux) y los plugins de `tmux.conf` los instala o
actualiza `scripts/install-shell-plugins.sh`, sin abrir tmux. Dentro de tmux
también puede hacerse a mano: con `C-a I` (mayúscula) se instalan los plugins;
con `C-a U` se actualizan.

Plugins configurados: tmux-sensible, tmux-cpu, tmux-battery, tmux-online-status.
La barra muestra CPU, RAM, batería, conectividad, clima (wttr.in) y fecha.

**Clima:** la barra llama a `~/.local/bin/tmux-weather` (enlace a
`tmux/tmux-weather.sh`, creado por `scripts/dotfiles-install.sh`). El script
guarda la respuesta de wttr.in en `~/.cache/tmux-weather/` y solo vuelve a
consultar cada 15 minutos (variable `TMUX_WEATHER_TTL`, en segundos), para no
ser limitado por el servicio. Sin conexión, muestra el último valor conocido. La
ubicación es `CURRENT_LOCATION` ([Ubicación para el
clima](#ubicación-para-el-clima)).

**Color verdadero:** `default-terminal` es `tmux-256color` (terminfo incluido en
`ncurses-base`) y `terminal-features` activa RGB, de modo que `termguicolors` de
Vim funciona dentro de tmux. Las sesiones abiertas antes del cambio deben
cerrarse (`tmux kill-server`) para que se aplique.

En tmux no se muestra fastfetch al abrir paneles o ventanas; solo aparece en
terminales fuera de tmux.

### Atajos principales de tmux

| Ámbito  | Comando                             | Acción                                        |
| ------- | ----------------------------------- | --------------------------------------------- |
| Sesión  | `tmux` / `tmux new -s nombre`       | Nueva sesión                                  |
| Sesión  | `tmux ls` / `tmux attach -t nombre` | Listar / conectar                             |
| Sesión  | `C-a s`                             | Elegir sesión (`choose-session`)              |
| Sesión  | `C-a d`                             | Desconectar                                   |
| Ventana | `C-a c`                             | Nueva ventana                                 |
| Ventana | `C-a K`                             | Cerrar ventana                                |
| Ventana | `C-a n` / `C-a p`                   | Siguiente / anterior                          |
| Panel   | `C-a \|` / `C-a -`                  | Dividir vertical / horizontal (misma carpeta) |
| Panel   | `C-a h/j/k/l`                       | Moverse entre paneles                         |
| Panel   | `C-a S`                             | Alternar sincronización de paneles (on/off)   |
| Copia   | `C-a [` luego `y`                   | Modo copia; copia al portapapeles             |
| Otros   | `C-a r`                             | Recargar configuración                        |

El ratón está activado para seleccionar paneles y texto.

**Portapapeles:** el modo copia de tmux y el de screen usan
`~/.local/bin/clipboard-copy` (enlace a `tmux/clipboard-copy.sh`), que copia con
`wl-copy` (paquete `wl-clipboard`) si hay sesión Wayland (`$WAYLAND_DISPLAY`) y
con `xclip` en X11. tmux actualiza `WAYLAND_DISPLAY` al reconectarse a una
sesión. También sirve en la terminal: `comando | clipboard-copy`.

**Bloqueo:** tras 10 minutos sin actividad (`lock-after-time`), o con `C-a C-l`,
tmux muestra `cmatrix` en azul (morado con la paleta Dracula) como protector de
pantalla. Cualquier tecla
vuelve a la sesión.

## screen

**screen** es opcional; comparte prefijo **`C-a`** y estética Dracula con tmux
(`screen/screenrc`).

| Comando                           | Acción                       |
| --------------------------------- | ---------------------------- |
| `screen` / `screen -S nombre`     | Nueva sesión                 |
| `screen -ls` / `screen -r nombre` | Listar / reconectar          |
| `C-a d`                           | Desconectar                  |
| `C-a c`                           | Nueva ventana                |
| `C-a \|` / `C-a -`                | Regiones en columnas / filas |
| `C-a h/j/k/l`                     | Cambiar de región            |
| `C-a [` luego `y`                 | Copiar al portapapeles       |
| `C-a r`                           | Recargar `~/.screenrc`       |

En el modo copia, `Espacio` marca el inicio y `y` el final de la selección, que
se copia al portapapeles con `clipboard-copy` (como en tmux), a través de
`~/.screen-exchange`.

No dispone de TPM ni de sincronización de paneles como tmux; la barra muestra
CPU, RAM, clima y fecha.

## Midnight Commander (mc)

**mc** se instala con DNF; se usa con su configuración por defecto, salvo el
skin [Dracula](#paleta-dracula) (`mc/skins/dracula.ini`, que activa `MC_SKIN`).

Debe ejecutarse `mc` en la terminal.

| Tecla   | Acción                   |
| ------- | ------------------------ |
| F1      | Ayuda                    |
| F2      | Menú de usuario          |
| F3 / F4 | Ver / editar (`$EDITOR`) |
| F5      | Copiar                   |
| F6      | Mover o renombrar        |
| F7      | Crear carpeta            |
| F8      | Eliminar                 |
| F9      | Menú superior            |
| F10     | Salir                    |
| Tab     | Cambiar panel            |

## curl

El cliente **curl** suele estar ya instalado; las opciones por defecto están en
`curl/curlrc` (enlace `~/.curlrc`; ver [Enlazar los
dotfiles](instalacion.md#enlazar-los-dotfiles)). No se requiere ningún paso
adicional si el enlace ya fue creado.

## Ubicación para el clima

`CURRENT_LOCATION` (en `zsh/zshenv`, por defecto `Talca`) es la ubicación que
usan la barra de tmux y de screen (`tmux-weather`), las funciones `clima` y
`clima-hoy` y el saludo matutino. zsh carga `zshenv` también en scripts, así que
el timer del saludo la ve. Puede ser cualquier lugar que entienda wttr.in
(`San Fernando`, `Puerto Montt`); si se define vacía, wttr.in deduce la
ubicación por la IP. Para cambiarla sin editar el repositorio (por ejemplo, de
viaje), basta con definirla antes de zsh, en `~/.config/environment.d/`:

```bash
echo 'CURRENT_LOCATION=Valparaíso' > ~/.config/environment.d/ubicacion.conf   # se aplica al volver a iniciar sesión
```

La barra de tmux toma la variable al iniciar el servidor de tmux.
