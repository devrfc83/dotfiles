# Dotfiles

Mis archivos de configuración y preferencias de usuario.

## Licencia

En términos generales, se considera que el contenido de los dotfiles se rige por los términos y condiciones de las licencias de software a las que pertenecen.

## Historia

En 1995, cuando comencé a usar Linux, no era común hacer copias de seguridad de los archivos de configuración. No me preocupé por los respaldos hasta 1998, principalmente porque volver a aplicar mi configuración después de reinstalar el sistema era una tarea tediosa.

Decidí comenzar desde cero y mantener mis archivos de configuración organizados después de obtener mi título de ingeniería en 2024. Entonces descubrí que tenía varios gigabytes de dotfiles. Después de pasar semanas recopilándolos y limpiándolos, inicié este repositorio para reorganizarlo todo.

Para simplificar las cosas, opté por eliminar las configuraciones de software que ya no uso y configurar instalaciones limpias de Linux en mis computadoras personales para aplicar los fragmentos que encontré interesantes y útiles.

## Qué uso

- **nerdfonts** — fuentes con iconos para la terminal y los editores.
- **zsh** — intérprete de comandos.
- **oh-my-zsh** — marco de plugins y temas para zsh.
- **vim** — editor en terminal.
- **vimdiff** — comparación de archivos en terminal (incluido con Vim).
- **chromium** — navegador web predeterminado (DNF; Firefox se desinstala).
- **vscodium** — editor gráfico y visor de diferencias.
- **cursor** — editor gráfico (mismas extensiones que Codium).
- **claude code** — asistente de IA como extensión de VSCodium y Cursor.
- **editorconfig** — reglas de formato compartidas entre editores.
- **tmux** — multiplexor de terminal principal.
- **screen** — multiplexor alternativo (misma idea de atajos que tmux).
- **mc** — gestor de archivos en terminal.
- **php 8.5** y **composer** — scripting en el servidor (paquetes de Fedora).
- **node** — JavaScript (instalado con nvm).
- **rust** — toolchain vía rustup (typst-cli con Cargo).
- **vala** — GTK4, libadwaita y Meson (desarrollo de aplicaciones de escritorio).
- **curl** — cliente HTTP con opciones por defecto en `curl/curlrc`.
- **git** — control de versiones.
- **gh** — CLI oficial de GitHub (repo propio de GitHub CLI).
- **doctl** — CLI oficial de DigitalOcean (DNF).
- **jq** — procesador de JSON en terminal, útil con la salida de `gh` y `doctl` (DNF).
- **docker** — motor de contenedores (repo oficial de Docker CE).
- **podman** — motor de contenedores (DNF).
- **virt-manager** — máquinas virtuales con KVM y libvirt; reemplaza a GNOME Boxes (DNF).
- **ansible** — despliegue de proyectos propios a servidores remotos (paquete `ansible-core` de Fedora).
- **postgresql** — base de datos local con PostGIS y pgRouting.
- **dbeaver** — cliente gráfico para bases de datos. [Descarga desde dbeaver.io.](https://dbeaver.io/)
- **spotify** — reproducción de música en streaming (Flatpak).
- **inkscape** — editor de gráficos vectoriales (DNF).
- **fastfetch** — resumen del sistema al abrir la terminal (DNF).
- **piper** — síntesis de voz neuronal sin conexión, para el saludo matutino (pipx).
- **espeak-ng** — síntesis de voz (texto a voz) en terminal; respaldo si no está Piper (DNF).
- **monitores** — btop (procesos y recursos), glances (resumen del sistema) y cava (visualizador de audio) (DNF).
- **tty-clock** — reloj grande en la terminal (compilado desde el upstream).
- **genact** — generador de actividad falsa en la terminal (Cargo).
- **tetris en la terminal** — bastet (DNF), tetris-tui (Cargo) y tint (fuentes de Debian).
- **retroarch** y **mame** — emulación de NES, SNES, PlayStation, Sega Genesis y arcade con gamepad.
- **utilidades de terminal** — asciiquarium, cbonsai, cmatrix, cowsay, figlet, fortune-mod, lolcat, sl, toilet (DNF).

## Sistema

Estos dotfiles se mantienen y prueban principalmente en **Fedora Linux 44+** (Workstation).

### Fuentes de paquetes

| Origen                         | Para qué sirve                                                      |
| ------------------------------ | ------------------------------------------------------------------- |
| **DNF** (`fedora`, `updates`)  | Casi todo el software base y de terminal                            |
| **RPM Fusion** (free, nonfree) | VLC, codecs y paquetes no incluidos en los repos oficiales          |
| **Repositorio de VSCodium**    | Editor `codium`                                                     |
| **Repositorio de Cursor**      | Editor `cursor`                                                     |
| **Repositorio de GitHub CLI**  | `gh`                                                                |
| **Repositorio de Docker CE**   | `docker-ce`, `docker-ce-cli`, `containerd.io` y plugins             |
| **rustup + Cargo**             | `typst-cli`, `genact` y `tetris-tui` (no están en Fedora)           |
| **nvm**                        | Versiones de Node.js                                                |
| **pipx**                       | `piper-tts` (síntesis de voz para el saludo matutino)               |
| **Git (manual)**               | oh-my-zsh, plugins de zsh, TPM de tmux, Vim, pgFormatter, tty-clock |
| **Fuentes de Debian**          | `tint` (versión y checksum fijados en `scripts/install-tint.sh`)    |
| **Flatpak** (Flathub)          | Vesktop, Spotify                                                    |

Los repositorios `fedora` y `updates` vienen habilitados por defecto; no hace falta EPEL ni Remi. Sí deben añadirse **RPM Fusion** (free y nonfree) antes del bloque DNF de esta guía.

### Instalación automatizada (scripts)

Hay tres scripts para automatizar la instalación, que deben ejecutarse en este orden desde la raíz del repositorio:

```bash
# Fedora 44+
bash scripts/fedora-install.sh
bash scripts/dotfiles-install.sh
bash scripts/extras-install.sh
```

- `fedora-install.sh` habilita RPM Fusion, configura los repositorios de VSCodium, Cursor, GitHub CLI y Docker CE (verificando la huella de sus llaves), instala los paquetes de `packages.txt`, intenta eliminar paquetes no deseados, configura Flathub, deja Podman listo en modo _rootless_ (sección 23), habilita Docker con el usuario en el grupo `docker`, agrega el usuario al grupo `libvirt` (virt-manager sin contraseña) y pone zsh como shell de inicio.
- `dotfiles-install.sh` crea los enlaces del paso 1 (y reconstruye la caché de fuentes por las reglas de `fontconfig/`), incluidos `vim`/`vi`/`vimdiff`/`view` hacia `vimx` (respaldando como `*.bak.<fecha>` los archivos que ya existan), los directorios de trabajo de npm y Vim, las carpetas de juegos en `~/Juegos`, el archivo `~/.config/git/allowed_signers`, deja Chromium como navegador predeterminado (`xdg-settings` y `xdg-mime`), instala las fuentes (con FiraCode Nerd Font) en `~/.local/share/fonts/`, fija FiraCode Nerd Font Mono como fuente monoespaciada del sistema (la que usa Ptyxis), aplica los ajustes de `retroarch/retroarch.cfg` (sección «Emulación»), pone `gnome/background.jpg` como fondo de escritorio y de la pantalla de bloqueo, carga la configuración de las extensiones de GNOME (sección 25) y activa el timer del saludo matutino. Puede ejecutarse varias veces.
- `extras-install.sh` instala lo que no está en `packages.txt`: rustup y nvm con Node.js, oh-my-zsh y los plugins de zsh y tmux, los crates de Cargo (`typst-cli`, `genact`, `tetris-tui`), pgFormatter, tty-clock, tint, el core Genesis Plus GX de RetroArch, las extensiones de VSCodium y Cursor, los plugins de Vim (con la compilación de YouCompleteMe) y Piper con la voz por defecto. Ejecuta los scripts `install-*.sh` correspondientes; si uno falla, sigue con los demás y lo informa al final. También sirve para actualizar.

Después de ejecutarlos quedan pocos pasos manuales: iniciar sesión en `gh` y `doctl`, inicializar PostgreSQL (sección 18) y, si se usa, configurar MiniDLNA y rsyslog (sección «Otros»).

### Instalación base con DNF

#### RPM Fusion (free y nonfree)

Varios paquetes del bloque siguiente (por ejemplo **VLC** con plugins completos) están en [RPM Fusion](https://rpmfusion.org/), no en los repos `fedora` / `updates`. Deben habilitarse **free** y **nonfree** antes de ejecutar la instalación masiva:

```bash
sudo dnf install \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```

Puede comprobarse que los repos quedaron activos con:

```bash
dnf repolist | grep rpmfusion
```

#### Paquetes

La lista completa de paquetes DNF está en [`packages.txt`](packages.txt), agrupada por categoría (terminal, desarrollo, PHP, bases de datos, contenedores, escritorio, multimedia, etc.). Es la única fuente: la usan tanto `scripts/fedora-install.sh` como el comando siguiente. Para agregar o quitar un paquete, debe editarse solo ese archivo.

Deben instalarse de una vez. Antes deben configurarse los repositorios de VSCodium y Cursor (sección 8), porque `codium` y `cursor` están en la lista. El resto de esta guía asume que ya se habilitó RPM Fusion y se ejecutó este bloque:

```bash
grep -vE '^[[:space:]]*(#|$)' packages.txt | xargs sudo dnf install -y --setopt=exclude_from_weak='libretro-*'
```

Tras instalarse las extensiones de GNOME Shell, debe reiniciarse la sesión o recargarse el shell con `Alt`+`F2`, escribiendo `r` y pulsando Enter.

### Paquetes a eliminar

En Fedora Workstation suelen venir preinstalados programas que no se usan en este entorno. Pueden desinstalarse tras el bloque de instalación anterior (o en cualquier momento):

```bash
sudo dnf remove -y firefox firefox-langpacks gnome-boxes gnome-tour libreoffice-core unoconv \
  malcontent-control malcontent-ui-libs
```

| Paquete              | Motivo                                                  |
| -------------------- | ------------------------------------------------------- |
| `firefox`            | Navegador; se usa Chromium (en `packages.txt`)          |
| `firefox-langpacks`  | Traducciones de Firefox; no se necesitan sin Firefox    |
| `gnome-boxes`        | Máquinas virtuales; se usa virt-manager                 |
| `gnome-tour`         | Asistente de bienvenida de GNOME; no se necesita        |
| `libreoffice-core`   | Suite ofimática (núcleo en Fedora); no se utiliza       |
| `unoconv`            | Conversión de documentos vía LibreOffice; no se utiliza |
| `malcontent-control` | Controles parentales de GNOME; no se utilizan           |
| `malcontent-ui-libs` | Bibliotecas de interfaz de malcontent; no se utilizan   |

`dnf` mostrará las dependencias que también se eliminarán (resto de subpaquetes de LibreOffice, etc.). Debe revisarse la lista antes de confirmar si se ejecuta el comando sin `-y`.

Para comprobar que ya no están instalados:

```bash
rpm -q firefox firefox-langpacks gnome-boxes gnome-tour libreoffice-core unoconv \
  malcontent-control malcontent-ui-libs
```

Si el comando devuelve «no está instalado» para todos, la desinstalación fue correcta.

---

## Configuración paso a paso

Deben seguirse estos pasos **en orden** después de clonarse el repositorio y de ejecutarse la instalación DNF anterior. Todos los comandos `ln -sf` asumen que se está en la raíz del repositorio (`cd ~/Proyectos/Dotfiles` o la ruta que se use).

### 1. Enlazar los dotfiles

Lo más simple es ejecutar `bash scripts/dotfiles-install.sh`, que crea todos los enlaces y respalda los archivos existentes. A mano, debe enlazarse cada archivo a su sitio en `$HOME`:

```bash
mkdir -p "$HOME/.config/npm" "$HOME/.local/bin" "$HOME/.config/systemd/user" "$HOME/.config/fontconfig/conf.d" \
  "$HOME/.config/VSCodium/User" "$HOME/.config/Cursor/User"
ln -sf "$PWD/curl/curlrc" "$HOME/.curlrc"
ln -sf "$PWD/codium/settings.json" "$HOME/.config/VSCodium/User/settings.json"
ln -sf "$PWD/codium/cursor-settings.json" "$HOME/.config/Cursor/User/settings.json"
ln -sf "$PWD/editorconfig/editorconfig" "$HOME/.editorconfig"
ln -sf "$PWD/fontconfig/conf.d/50-aptos-display.conf" "$HOME/.config/fontconfig/conf.d/50-aptos-display.conf"
ln -sf "$PWD/gnome/background.jpg" "$HOME/.config/background"
ln -sf "$PWD/git/gitconfig" "$HOME/.gitconfig"
ln -sf "$PWD/git/gitconfig-personal" "$HOME/.gitconfig-personal"
ln -sf "$PWD/git/gitignore" "$HOME/.gitignore"
ln -sf "$PWD/git/gitattributes" "$HOME/.gitattributes"
ln -sf "$PWD/input/dircolors" "$HOME/.dircolors"
ln -sf "$PWD/input/inputrc" "$HOME/.inputrc"
ln -sf "$PWD/screen/screenrc" "$HOME/.screenrc"
ln -sf "$PWD/tmux/tmux.conf" "$HOME/.tmux.conf"
ln -sf "$PWD/tmux/tmux-weather.sh" "$HOME/.local/bin/tmux-weather"
ln -sf "$PWD/vim/vimrc" "$HOME/.vimrc"
ln -sf "$PWD/node/npmrc" "$HOME/.npmrc"
ln -sf "$PWD/zsh/zlogin" "$HOME/.zlogin"
ln -sf "$PWD/zsh/zlogout" "$HOME/.zlogout"
ln -sf "$PWD/zsh/zshenv" "$HOME/.zshenv"
ln -sf "$PWD/zsh/zprofile" "$HOME/.zprofile"
ln -sf "$PWD/zsh/zshrc" "$HOME/.zshrc"
ln -sf "$PWD/zsh/zshoptions" "$HOME/.zshoptions"
ln -sf "$PWD/zsh/zshaliases" "$HOME/.zshaliases"
ln -sf "$PWD/zsh/zshfunctions" "$HOME/.zshfunctions"
ln -sf "$PWD/zsh/scripts/buenos_dias.zsh" "$HOME/.local/bin/buenos-dias"
ln -sf "$PWD/systemd/buenos-dias.service" "$HOME/.config/systemd/user/buenos-dias.service"
ln -sf "$PWD/systemd/buenos-dias.timer" "$HOME/.config/systemd/user/buenos-dias.timer"
ln -sf /usr/bin/vimx "$HOME/.local/bin/vim"
ln -sf /usr/bin/vimx "$HOME/.local/bin/vi"
ln -sf /usr/bin/vimx "$HOME/.local/bin/vimdiff"
ln -sf /usr/bin/vimx "$HOME/.local/bin/view"
```

Debe abrirse una terminal nueva para que los enlaces surtan efecto.

#### npmrc privado (token fuera del repo)

El archivo `node/npmrc` **no** contiene credenciales. Si se necesita autenticar contra npm, debe crearse un archivo privado fuera del repositorio en `~/.config/npm/npmrc-private` (con permisos 0600):

```bash
install -d -m 700 "$HOME/.config/npm"
touch "$HOME/.config/npm/npmrc-private"
chmod 600 "$HOME/.config/npm/npmrc-private"
```

Luego debe añadirse el token (se pega una sola vez; el archivo **no** debe versionarse):

```bash
printf '\n//registry.npmjs.org/:_authToken=%s\n' 'PEGAR_TOKEN_AQUI' >> "$HOME/.config/npm/npmrc-private"
```

En `zsh/zshenv` se genera automáticamente `~/.config/npm/npmrc-effective` combinando `~/.npmrc` (base) + `npmrc-private` (secreto), y se exporta `NPM_CONFIG_USERCONFIG` hacia ese archivo efectivo.

### 2. Nerdfonts

Las fuentes **Nerd Fonts** muestran iconos en la terminal, tmux y Vim. Se usa **FiraCode Nerd Font**, que instala `scripts/dotfiles-install.sh` en `~/.local/share/fonts/` junto con las demás fuentes, en una versión propia (no la del repositorio oficial): las actualizaciones se deciden a mano. Verifica su SHA-256 y, si ya está esa versión, no hace nada.

**Ptyxis** (la terminal de Fedora) usa la fuente monoespaciada del sistema. `scripts/dotfiles-install.sh` la fija en **FiraCode Nerd Font Mono 10** y deja Ptyxis usando esa fuente. A mano:

```bash
gsettings set org.gnome.desktop.interface monospace-font-name 'FiraCode Nerd Font Mono 10'
gsettings set org.gnome.Ptyxis use-system-font true
```

Se usa la variante **Mono** porque Ptyxis (VTE) da a los iconos de Nerd Fonts una sola celda: en la variante normal, los iconos son más anchos y se montan sobre el carácter siguiente. La opción de Ptyxis para caracteres de ancho ambiguo debe quedar en _estrecho_ (`narrow`, el valor por defecto); en _ancho_ también se ensancharían las líneas de cajas de tmux y `eza`, `°`, `±`, etc.

### 3. Zsh, inputrc y dircolors

**Zsh** queda instalado con el bloque DNF. Los archivos de este repositorio configuran el shell y los programas que usan readline:

| Archivo en el repo | Enlace en `$HOME` | Función                                     |
| ------------------ | ----------------- | ------------------------------------------- |
| `input/inputrc`    | `~/.inputrc`      | Edición tipo vi en bash, python, psql, etc. |
| `input/dircolors`  | `~/.dircolors`    | Colores de `ls` / `eza` (paleta Tango)      |
| `zsh/*`            | `~/.zsh*`         | Shell interactivo completo                  |

`scripts/fedora-install.sh` deja zsh como shell de inicio si aún no lo es. A mano:

```bash
chsh -s "$(command -v zsh)"
```

Debe cerrarse sesión y volverse a entrar para que surta efecto.

**Readline en modo vi** (`~/.inputrc`):

- Con `Esc` se pasa a modo comando.
- En modo comando: `h`/`l` (izquierda/derecha), `b`/`w` (palabras), `0`/`$` (inicio/fin de línea).
- Con `↑`/`↓` o `Ctrl-p`/`Ctrl-n` se recorre el historial por prefijo.
- En modo inserción: `Ctrl-a` / `Ctrl-e` — inicio/fin de línea.

Para comprobarlo: debe abrirse `python3`, escribir un comando, pulsarse `Esc` y probarse las teclas anteriores.

### 4. oh-my-zsh

El framework y sus plugins externos (`zsh-completions` y `zsh-syntax-highlighting`) los instala o actualiza `scripts/install-shell-plugins.sh` (lo ejecuta `extras-install.sh`). Los clona con git en `~/.oh-my-zsh` sin usar el instalador oficial, que reemplazaría `~/.zshrc` (un enlace a este repositorio).

Configuración relevante en este repositorio:

- **Tema:** `pygmalion` (`ZSH_THEME` en `zsh/zshenv`).
- **Plugins de omz:** listados en `zsh/zshrc` (git, tmux, vi-mode, postgres, npm, etc.).
- **Actualizaciones:** automáticas cada 15 días (`zstyle ':omz:update'` en `zshenv`); manualmente con `omz update`.

Debe recargarse la shell con `source ~/.zshrc`.

Si **fastfetch** está instalado (bloque DNF), se ejecuta al final de `zsh/zshrc` en cada shell interactiva.

### 5. Zoxide

**Zoxide** se instala con DNF. El hook se activa en `zsh/zshrc` si existe el comando `zoxide`.

Uso habitual:

| Comando            | Acción                                        |
| ------------------ | --------------------------------------------- |
| `z foo`            | Ir al directorio que mejor coincida con `foo` |
| `z foo bar`        | Usar varios términos de búsqueda              |
| `zi foo`           | Elegir destino con `fzf`                      |
| `z -`              | Volver al directorio anterior (como `cd -`)   |
| `zoxide query foo` | Ver el destino sin cambiar de carpeta         |

También se definen alias para `eza`, `fzf`, `bat`, `fd`, `direnv`, `pgcli` y más en `zsh/zshaliases` (solo si el comando correspondiente está instalado).

### 6. Vim

Los directorios de trabajo (`~/.vim/backup`, `swap`, `undodir` y `snippets`) los crea `scripts/dotfiles-install.sh`. El esquema de colores y los plugins (sistema `pack` de Vim) los instala o actualiza:

```bash
bash scripts/install-vim-plugins.sh
```

El script clona en `~/.vim/pack/` lo que falte, actualiza con `git pull` lo que ya existe, compila **YouCompleteMe** cuando hace falta (la primera vez o cuando cambió; con completado de TypeScript si encuentra Node de nvm) y regenera la ayuda (`:help`) de los plugins. Lo ejecuta también `scripts/extras-install.sh`. Las dependencias de compilación (`python3-devel`, `cmake`, `gcc-c++`) están en `packages.txt`.

En el `vimrc` de este repositorio se usa `colorscheme cobalt` (archivo `colors/cobalt.vim` del paquete flazz/vim-colorschemes). La lista de plugins y su uso se documentan en `vim/instrucciones.md`.

El enlace `~/.vimrc` → `vim/vimrc` debe existir desde el paso 1.

**Portapapeles (vimx):** el `vim` de Fedora (`vim-enhanced`) está compilado sin portapapeles (`-clipboard`), así que `set clipboard=unnamedplus` no tendría efecto. Por eso se instala `vim-X11` (bloque DNF), que trae `vimx`: el mismo Vim en terminal, con `+clipboard`. Funciona en GNOME con Wayland (a través de XWayland) y lo copiado sigue disponible al cerrar Vim.

Para usarlo con los nombres de siempre, `scripts/dotfiles-install.sh` crea en `~/.local/bin` (que va primero en el `PATH`) los enlaces `vim`, `vi`, `vimdiff` y `view` hacia `/usr/bin/vimx`. Vim elige el modo según el nombre con que se invoca: `vimdiff` compara archivos y `view` abre en solo lectura. `EDITOR`, `VISUAL` y `core.editor` de git apuntan directamente a `/usr/bin/vimx`.

Para comprobarlo: `vim --version | grep clipboard` debe mostrar `+clipboard`.

**Valores por defecto:** el `vimrc` carga `$VIMRUNTIME/defaults.vim` (Vim no lo hace solo si existe `~/.vimrc`), que aporta `ttimeoutlen` (Esc sin demora), `incsearch`, `wildmenu`, `showcmd` y `filetype plugin indent on`.

**Formato al guardar (ALE):** prettier (CSS, HTML, JS, JSON, SCSS, TS, Vue), pint (PHP), ruff (Python), rustfmt, shfmt y pgFormatter (SQL). prettier y pint se buscan en `node_modules/.bin` y `vendor/bin` de cada proyecto; si un formateador no está instalado, ALE lo omite sin error.

### 7. Vimdiff

**vimdiff** es el modo diff de Vim; no se instala por separado. Sirve para comparar dos o más archivos en terminal:

```bash
vimdiff archivo1 archivo2
# o
vim -d archivo1 archivo2
```

Se usa la misma configuración que `~/.vimrc`.

### 8. VSCodium

VSCodium y Cursor no están en los repos de Fedora; cada uno tiene su repositorio RPM. Los archivos `.repo` están versionados en `etc/yum.repos.d/` y `scripts/fedora-install.sh` los instala, junto con sus llaves GPG, antes del bloque DNF (`codium` y `cursor` están en `packages.txt`). Las llaves solo se importan si su huella coincide con la esperada:

| Repositorio | Llave                                                 | Huella                                               |
| ----------- | ----------------------------------------------------- | ---------------------------------------------------- |
| VSCodium    | Pavlo Rudyi (mantenedor del repo RPM de VSCodium)     | `1302 DE60 2318 89FE 1EBA  CADC 5467 8CF7 5A27 8D9C` |
| Cursor      | Anysphere Inc (empresa de Cursor)                     | `380F F4BC DC34 A4BD 92A3  5653 42A1 772E 62E4 92D6` |

A mano, sin el script:

```bash
sudo rpm --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
sudo rpm --import https://downloads.cursor.com/keys/anysphere.asc
sudo install -m 644 etc/yum.repos.d/vscodium.repo etc/yum.repos.d/cursor.repo /etc/yum.repos.d/
sudo dnf install -y codium cursor
```

En `zsh/zshenv`, `EDITOR` y `VISUAL` apuntan siempre a `vimx` (Vim con portapapeles, sección 6), igual que `core.editor` en `git/gitconfig`. Codium se sigue usando como `difftool` y `mergetool` de git.

**Configuración:** `codium/settings.json` (VSCodium) y `codium/cursor-settings.json` (Cursor) se enlazan en `~/.config/<editor>/User/settings.json` con `scripts/dotfiles-install.sh`; los cambios hechos desde la interfaz de cada editor quedan en el repositorio. Los dos archivos son iguales, salvo que Cursor sigue el tema claro u oscuro de GNOME y VSCodium conserva sus ajustes propios (panel de Claude Code, sin pantalla de inicio):

- **Formato al guardar:** PHP con **Pint** (respeta el `pint.json` del proyecto; sin él, usa el preset de Laravel) y el resto (CSS, HTML, JS/TS, JSON, SCSS, Vue, YAML) con **Prettier**.
- **PHP:** solo Intelephense (se desactiva el soporte integrado del editor, que duplicaba sugerencias).
- **Fuentes:** FiraCode Nerd Font con ligaduras en el editor; FiraCode Nerd Font Mono en la terminal integrada.
- **Reglas de longitud:** columna 132 (80 en Markdown), como en `editorconfig`.
- **Exclusiones:** `vendor/`, `cache/` y `versions/` quedan fuera de las búsquedas y de Ctrl+P, como en el `wildignore` de Vim.
- **Telemetría de Red Hat** desactivada (extensión de XML).

En la terminal integrada no se muestra fastfetch (`zsh/zshrc` lo omite cuando `TERM_PROGRAM=vscode`).

**Extensiones:** la lista está en `codium/extensions.txt` y sirve para los dos editores; una segunda columna limita una extensión a uno solo (Claude Code, GitLens y el soporte de idioma de Intelephense van solo en Codium). `scripts/install-editor-extensions.sh` instala en Codium y en Cursor las que falten (lo ejecuta también `extras-install.sh`); si una falla, sigue con las demás y lo informa al final.

| Extensión                                     | Uso                                     |
| --------------------------------------------- | --------------------------------------- |
| `anthropic.claude-code`                       | Claude Code (solo Codium)               |
| `anessaeah.php-intelephense-language-support` | Soporte de idioma PHP (solo Codium)     |
| `bmewburn.vscode-intelephense-client`         | PHP (Intelephense)                      |
| `dart-code.dart-code`                         | Dart                                    |
| `dart-code.flutter`                           | Flutter                                 |
| `dbaeumer.vscode-eslint`                      | ESLint                                  |
| `doonfrs.livewire-support`                    | Livewire                                |
| `dsznajder.es7-react-js-snippets`             | Snippets React/JS                       |
| `eamodio.gitlens`                             | GitLens (solo Codium)                   |
| `editorconfig.editorconfig`                   | EditorConfig                            |
| `esbenp.prettier-vscode`                      | Formato con Prettier                    |
| `laravel.vscode-laravel`                      | Laravel                                 |
| `mikestead.dotenv`                            | Archivos `.env`                         |
| `mtxr.sqltools`                               | SQLTools                                |
| `mtxr.sqltools-driver-pg`                     | Driver PostgreSQL para SQLTools         |
| `open-southeners.laravel-pint`                | Laravel Pint                            |
| `porifa.laravel-intelephense`                 | Laravel en Intelephense                 |
| `prince781.vala`                              | Vala                                    |
| `redhat.vscode-xml`                           | XML                                     |
| `timsexperiments.vscode-tailwindcss`          | Tailwind CSS                            |

Para comprobar o actualizar las extensiones:

```bash
codium --list-extensions    # o: cursor --list-extensions
codium --update-extensions  # o: cursor --update-extensions
```

### 9. EditorConfig

No se requiere paquete: basta con el enlace `~/.editorconfig` → `editorconfig/editorconfig`. Los editores con soporte EditorConfig leerán las reglas al abrir un proyecto. Vim usa el archivo directamente; Codium y Cursor usan la extensión EditorConfig de la tabla anterior.

### 10. tmux

**tmux** se instala con DNF; la configuración está en `~/.tmux.conf` (prefijo **`C-a`**, paleta Tango).

**TPM** (gestor de plugins de tmux) y los plugins de `tmux.conf` los instala o actualiza `scripts/install-shell-plugins.sh`, sin abrir tmux. Dentro de tmux también puede hacerse a mano: con `C-a I` (mayúscula) se instalan los plugins; con `C-a U` se actualizan.

Plugins configurados: tmux-sensible, tmux-cpu, tmux-battery, tmux-online-status. La barra muestra CPU, RAM, batería, conectividad, clima (wttr.in) y fecha.

**Clima:** la barra llama a `~/.local/bin/tmux-weather` (enlace a `tmux/tmux-weather.sh`, creado por `scripts/dotfiles-install.sh`). El script guarda la respuesta de wttr.in en `~/.cache/tmux-weather/` y solo vuelve a consultar cada 15 minutos (variable `TMUX_WEATHER_TTL`, en segundos), para no ser limitado por el servicio. Sin conexión, muestra el último valor conocido.

**Color verdadero:** `default-terminal` es `tmux-256color` (terminfo incluido en `ncurses-base`) y `terminal-features` activa RGB, de modo que `termguicolors` de Vim funciona dentro de tmux. Las sesiones abiertas antes del cambio deben cerrarse (`tmux kill-server`) para que se aplique.

En tmux no se muestra fastfetch al abrir paneles o ventanas; solo aparece en terminales fuera de tmux.

#### Atajos principales de tmux

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
| Copia   | `C-a [` luego `y`                   | Modo copia; copia al portapapeles (`xclip`)   |
| Otros   | `C-a r`                             | Recargar configuración                        |

El ratón está activado para seleccionar paneles y texto.

**Bloqueo:** tras 10 minutos sin actividad (`lock-after-time`), o con `C-a C-l`, tmux muestra `cmatrix` en azul Tango como protector de pantalla. Cualquier tecla vuelve a la sesión.

### 11. screen

**screen** es opcional; comparte prefijo **`C-a`** y estética Tango con tmux (`screen/screenrc`).

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

No dispone de TPM ni de sincronización de paneles como tmux; la barra muestra CPU, RAM, clima y fecha.

### 12. Midnight Commander (mc)

**mc** se instala con DNF; se usa con su configuración por defecto.

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

### 13. PHP y Composer

PHP 8.5, Composer y sus extensiones (bcmath, curl, fpm, gd, imagick, intl, mbstring, memcached, pcov, pgsql, sodium, sqlite3, xdebug, xml, zip) se instalan con el bloque DNF; están en la sección «PHP y Composer» de `packages.txt`.

En Fedora 44, extensiones como `opcache` suelen incluirse con `php` y `php-common`. Los binarios de Composer en proyectos (`vendor/bin`) se añaden al `PATH` en `zsh/zshenv`.

### 14. Node.js (nvm)

Node no está en DNF; se instala con **nvm**, que instala `scripts/install-runtimes.sh` (lo ejecuta `extras-install.sh`). El script clona nvm con git en la versión fijada en `nvm_version`, en lugar de usar `install.sh`, que agregaría líneas a `~/.zshrc` (un enlace a este repositorio). Si no hay ninguna versión de Node, instala la última y la deja como predeterminada.

Para actualizar Node más adelante:

```bash
nvm install node
nvm alias default node
```

En `zsh/zshrc` se carga nvm en cada shell interactiva.

### 15. Rust

**rustup** (Rust estable) lo instala o actualiza `scripts/install-runtimes.sh`, con `--no-modify-path` para no tocar los perfiles. Los crates `typst-cli`, `genact` y `tetris-tui` los instala después `extras-install.sh` con `cargo install --locked`. La compilación de typst-cli requiere `openssl-devel`, `gcc` y `make`, incluidos en el bloque DNF.

En `zshenv` se añade `~/.cargo/bin` al `PATH` si existe ese directorio.

### 16. curl

El cliente **curl** suele estar ya instalado; las opciones por defecto están en `curl/curlrc` (enlace `~/.curlrc` en el paso 1). No se requiere ningún paso adicional si el enlace ya fue creado.

### 17. Git

**git** y **git-lfs** se instalan con DNF. Los enlaces `~/.gitconfig`, `~/.gitconfig-personal`, `~/.gitignore` y `~/.gitattributes` se crean en el paso 1.

**Pull según el repositorio:**

- En cualquier repositorio, `git pull` solo avanza en _fast-forward_ (`pull.ff = only`). Si las ramas divergieron, falla y debe decidirse a mano entre `git pr` (rebase) y `git m` (merge).
- En repositorios propios, `git/gitconfig-personal` activa el rebase automático (`pull.rebase = merges`). Se carga con `includeIf` cuando algún remoto apunta a `github://` o a `git@github.com:devrfc83/`. Los repos de Sea Dragon (`seadragon://`) no son personales y usan la configuración general.

**Otras opciones globales de `git/gitconfig`:**

| Opción                         | Efecto                                                                    |
| ------------------------------ | ------------------------------------------------------------------------- |
| `rebase.autoStash`             | Guarda los cambios sin commit antes de un rebase y los restaura después   |
| `rebase.updateRefs`            | Mueve también las ramas apiladas encima de la que se rebasa               |
| `rerere.enabled`               | Recuerda cómo se resolvió un conflicto y lo reaplica si vuelve a aparecer |
| `merge.conflictStyle = zdiff3` | Muestra también el texto original (base común) en los conflictos          |
| `diff.algorithm = histogram`   | Diffs más legibles en código con muchas líneas repetidas                  |
| `fetch.prune`                  | Borra las ramas remotas que ya no existen en el servidor                  |
| `push.autoSetupRemote`         | El primer `git push` de una rama nueva crea el upstream sin `-u`          |
| `help.autocorrect = prompt`    | Ante un comando mal escrito, pregunta antes de ejecutar la corrección     |
| `alias.psf`                    | `push --force-with-lease --force-if-includes`: no pisa commits ajenos     |

**Verificación de firmas:** los commits se firman con la llave SSH `~/.ssh/id_ed25519`. Para que `git log --show-signature` pueda verificarlas, `scripts/dotfiles-install.sh` genera `~/.config/git/allowed_signers` (opción `gpg.ssh.allowedSignersFile`) a partir de `~/.ssh/id_ed25519.pub`.

Para comprobar qué archivo define el comportamiento en un repositorio:

```bash
git config --show-origin pull.rebase
```

Las ramas creadas con la configuración anterior (`branch.autosetuprebase = always`) guardan `branch.<rama>.rebase` en `.git/config` y siguen haciendo rebase. Para limpiarlas, debe ejecutarse en cada repositorio:

```bash
git config --get-regexp '^branch\..*\.rebase$' | cut -d' ' -f1 | xargs -rn1 git config --unset
```

`git/gitignore` está preparado para este stack y cubre reglas de **Laravel + Node + Python + Go + Rust + Vala** (además de archivos temporales de editores/sistema). `git/gitattributes` incluye normalización y diffs para varios tipos, incluyendo **Go** (`*.go`), **Rust** (`*.rs`) y **Vala** (`*.vala`, `*.vapi`).

Git LFS debe inicializarse una vez por usuario:

```bash
git lfs install
```

### 18. PostgreSQL

Los paquetes de servidor, PostGIS y pgRouting están en el bloque DNF. **El clúster debe inicializarse** la primera vez:

```bash
sudo postgresql-setup --initdb
sudo systemctl enable --now postgresql
```

La unidad systemd en Fedora es `postgresql`.

**Variables por defecto** (`zsh/zshenv`), solo si no están ya definidas:

| Variable     | Valor         |
| ------------ | ------------- |
| `PGHOST`     | `localhost`   |
| `PGPORT`     | `5432`        |
| `PGUSER`     | `developer`   |
| `PGPASSWORD` | `developer`   |
| `PGDATABASE` | `development` |

Un proyecto puede sobrescribirlas con `.env` o `direnv`.

**Herramientas en zsh** (`zsh/zshfunctions` y alias):

| Comando              | Acción                                        |
| -------------------- | --------------------------------------------- |
| `pgstart` / `pgstop` | Arrancar / parar el servicio                  |
| `pgstatus`           | Consultar el estado del servicio              |
| `pglog`              | Seguir los registros (`journalctl`)           |
| `psqlx`              | Abrir `psql` con las variables `PG*` actuales |
| `pg`                 | Alias de `pgcli` (si está instalado)          |

**pgcli** se instala con DNF.

### 19. pgFormatter (`pg_format`)

[pgFormatter](https://github.com/darold/pgFormatter) formatea SQL y PL/pgSQL. **No está en Fedora**; debe compilarse con Perl (paquetes `perl`, `make` y `gcc` del bloque DNF).

**Instalación o actualización** (siempre la última versión del upstream):

```bash
bash scripts/install-pgformatter.sh
```

Para actualizar a la última versión del upstream, debe ejecutarse `bash scripts/update-pgformatter.sh` (reutiliza el instalador).

El script clona el repositorio en `/tmp`, ejecuta `perl Makefile.PL`, `make` y `sudo make install`, y deja disponible el comando `pg_format`.

En zsh, el alias **`pgfmt`** se activa automáticamente si existe `pg_format`.

### 20. gh (GitHub CLI)

**gh** no está en los repos base de Fedora. Su repositorio oficial está versionado en `etc/yum.repos.d/gh-cli.repo`; `scripts/fedora-install.sh` lo instala e importa su llave (huella `7F38 BBB5 9D06 4DBC B3D8  4D72 5612 B364 6231 3325`; el archivo de GitHub también trae la llave anterior, vencida en septiembre de 2026), y `gh` está en `packages.txt`.

Autenticación (una sola vez por usuario):

```bash
gh auth login
```

Para comprobar el estado de la sesión:

```bash
gh auth status
```

### 21. doctl (DigitalOcean CLI)

**doctl** está disponible directamente en los repos de Fedora (`fedora`/`updates`); se instala con el bloque DNF de este README.

Autenticación (una sola vez por usuario, requiere un token de la API de DigitalOcean):

```bash
doctl auth init
```

Para comprobar el contexto activo:

```bash
doctl account get
```

### 22. Docker

**docker** no está en los repos base de Fedora. Su repositorio oficial está versionado en `etc/yum.repos.d/docker-ce.repo`; `scripts/fedora-install.sh` lo instala e importa su llave (huella `060A 61C5 1B55 8A7F 742B  77AA C52F EB6B 621E 9F35`). Los paquetes (`docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`) están en `packages.txt`, y el script habilita el servicio y agrega el usuario al grupo `docker` para no requerir `sudo` en cada comando.

Debe cerrarse sesión y volverse a entrar para que el nuevo grupo surta efecto. Para comprobar que todo funciona:

```bash
docker run hello-world
```

### 23. Podman

**podman** y **podman-compose** se instalan con el bloque DNF. `scripts/fedora-install.sh` ya ejecuta los pasos de esta sección (subuid/subgid, socket de usuario y _linger_); a mano son los siguientes. En Linux, Podman funciona sin demonio y sin `root` (modo _rootless_); no hace falta `podman machine init`, que solo se usa en macOS y Windows.

Debe comprobarse que el usuario tiene rangos de UID/GID subordinados (Fedora los crea al dar de alta el usuario):

```bash
grep "$USER" /etc/subuid /etc/subgid
```

Si no aparecen, deben asignarse y migrarse los contenedores existentes:

```bash
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER"
podman system migrate
```

Debe habilitarse el socket de usuario (API compatible con Docker, usada por `podman-compose`, editores y otras herramientas):

```bash
systemctl --user enable --now podman.socket
```

Para que los contenedores del usuario sigan en marcha tras cerrar sesión (y arranquen con el sistema):

```bash
sudo loginctl enable-linger "$USER"
```

Para comprobar que todo funciona:

```bash
podman info --format '{{.Host.Security.Rootless}}'
podman run --rm quay.io/podman/hello
```

Docker y Podman pueden convivir en el mismo equipo. **No** debe instalarse `podman-docker` (alias `docker` → `podman`) mientras esté instalado Docker CE, porque ambos paquetes entran en conflicto.

### 24. Ansible

Algunos proyectos propios se despliegan a un servidor remoto mediante **Ansible** controlado con `make`. En la máquina cliente (la que ejecuta `make`) se necesita:

- **Ansible** (`ansible-core` ≥ 2.15), **`make`** y **passlib** de Python (se usa localmente para generar el hash de la contraseña del usuario de despliegue).
- Una llave SSH que pueda acceder al servidor destino como `root` (u otro usuario con sudo) la primera vez.

Los tres paquetes están en el bloque DNF de este README (`ansible-core`, `make`, `python3-passlib`); no requieren pasos adicionales de instalación.

Cada proyecto que use este flujo documenta en su propio repositorio los playbooks, el `Makefile` y las variables específicas de su despliegue.

---

### 25. Extensiones de GNOME

Las extensiones son paquetes de Fedora incluidos en `packages.txt` (Dash to Dock, Just Perfection y AppIndicator, más el gestor `gnome-extensions-app`). Sus valores se guardan en dconf, una base de datos binaria que no se puede enlazar, así que el repositorio guarda un volcado en `gnome/`:

- `gnome/dash-to-dock.dconf` y `gnome/just-perfection.dconf`: los valores de cada extensión (solo los que difieren del valor por defecto).
- `gnome/enabled-extensions.txt`: las extensiones activas, una por línea.

`scripts/dotfiles-install.sh` los carga con `dconf load` y activa esas extensiones; las recién instaladas aparecen al volver a iniciar sesión. Tras cambiar algo en las preferencias de una extensión, o activar o desactivar una, debe volcarse de nuevo y hacerse commit:

```bash
bash scripts/export-gnome-settings.sh
git diff gnome/
```

**Fondo de escritorio:** `gnome/background.jpg` se enlaza como `~/.config/background` (el archivo que crea GNOME al elegir una imagen en Configuración) y `dotfiles-install.sh` lo fija para el tema claro y el oscuro y para la pantalla de bloqueo, con ajuste `zoom`. Si no existe la imagen, no cambia el fondo.

Dash to Dock guarda el monitor preferido por conector (`eDP-1`, la pantalla del portátil); en un equipo sin ese conector usa el monitor principal.

## Otros

### Saludo matutino (buenos_dias)

`zsh/scripts/buenos_dias.zsh` dice en voz alta la fecha, la hora y la temperatura de Talca (actual, mínima y máxima, desde wttr.in). Se enlaza como `~/.local/bin/buenos-dias` y lo ejecuta todos los días a las 08:00 el timer de usuario `systemd/buenos-dias.timer` (si el equipo estaba apagado a esa hora, no saluda después).

La voz es **Piper** (neuronal, sin conexión, mucho menos robótica que espeak-ng). Debe instalarse una vez, junto con una voz en español:

```bash
bash scripts/install-piper.sh                      # voz por defecto: es_MX-claude-high
bash scripts/install-piper.sh es_AR-daniela-high   # u otra voz
```

Voces en español disponibles: `es_MX-claude-high`, `es_MX-ald-medium`, `es_AR-daniela-high`, `es_ES-davefx-medium`, `es_ES-sharvard-medium`. Las voces quedan en `~/.local/share/piper/voces/`. Para usar una distinta de la predeterminada, debe definirse `BUENOS_DIAS_VOZ` (para el timer, en `~/.config/environment.d/buenos-dias.conf`):

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

### Diversión en la terminal

| Comando                  | Acción                                                                 |
| ------------------------ | ---------------------------------------------------------------------- |
| `clima [ciudad]`         | Pronóstico de 3 días de wttr.in en español (por defecto, Talca)        |
| `clima-hoy [ciudad]`     | Tiempo actual y pronóstico de hoy                                      |
| `luna`                   | Fase lunar                                                             |
| `starwars`               | Star Wars episodio IV en ASCII (towel.blinkenlights.nl); `Ctrl-C` sale |
| `mapa`                   | MapSCII: mapa mundial en Braille (flechas, `a`/`z` zoom, `q` sale)     |
| `toilet -f future texto` | Texto grande en ASCII; `--gay` (arcoíris) y `--metal` agregan color    |
| `btop` / `glances`       | Monitores del sistema                                                  |
| `cava`                   | Visualizador de audio (por ejemplo, mientras suena Spotify)            |
| `tty-clock -c -C 4`      | Reloj grande centrado, en azul Tango (`q` sale)                        |
| `genact`                 | Simula actividad (compilaciones, descargas…) para parecer ocupado      |
| `tint`                   | Tetris clásico, con tabla de puntajes                                  |
| `tetris-tui`             | Tetris moderno (pieza fantasma, guardar pieza)                         |
| `bastet`                 | «Bastard Tetris»: elige a propósito la peor pieza posible              |

**tty-clock** no está en Fedora; se compila desde el upstream (requiere `ncurses-devel`, incluido en `packages.txt`). El mismo script sirve para actualizarlo:

```bash
bash scripts/install-tty-clock.sh
```

**tint** tampoco está en Fedora; se compila desde las fuentes de Debian, verificando el checksum del tarball. Como en Debian, el binario es setgid `games` para guardar los puntajes en `/var/games/tint.scores`:

```bash
bash scripts/install-tint.sh
```

**genact** y **tetris-tui** se instalan con Cargo (sección 15); **bastet**, con el bloque DNF.

`clima` acepta ciudades con espacios (`clima Puerto Montt`). Son funciones de `zsh/zshfunctions` (no alias) porque reciben la ciudad como argumento.

### Rsyslog y logrotate

**rsyslog** y **logrotate** se instalan con el bloque DNF. Rsyslog recibe y escribe registros del sistema; logrotate rota y comprime los archivos en `/var/log` según reglas en `/etc/logrotate.d/`.

#### Escuchar en el puerto 514 (UDP y TCP)

Por defecto, rsyslog en Fedora no abre el puerto 514 para tráfico remoto. Debe crearse un fragmento en `/etc/rsyslog.d/` (por ejemplo `listen-514.conf`):

```
module(load="imudp")
input(type="imudp" port="514")

module(load="imtcp")
input(type="imtcp" port="514")
```

Debe reiniciarse el servicio y habilitarse al arranque:

```bash
sudo systemctl enable --now rsyslog
sudo systemctl restart rsyslog
```

Puede comprobarse que escucha en 514 con:

```bash
sudo ss -ulnp | grep ':514'
sudo ss -tlnp | grep ':514'
```

**Firewall (firewalld):** deben abrirse UDP y TCP en el puerto 514 de forma permanente:

```bash
sudo firewall-cmd --permanent --add-port=514/udp
sudo firewall-cmd --permanent --add-port=514/tcp
sudo firewall-cmd --reload
```

Para comprobar las reglas activas:

```bash
sudo firewall-cmd --list-ports
```

Si el host usa SELinux en modo enforcing y rsyslog no enlaza el puerto, puede revisarse el contexto con `ausearch` / `audit2why`; el puerto 514 suele estar ya asociado al tipo `syslogd_port_t`.

Los clientes remotos deben enviar syslog a la IP de este equipo en el puerto **514** (UDP o TCP, según lo que soporte el emisor).

#### Rotación de logs con logrotate

**logrotate** se ejecuta de forma periódica mediante el temporizador systemd `logrotate.timer` (habitualmente una vez al día). La configuración global está en `/etc/logrotate.conf`; cada servicio o familia de logs tiene un fichero en `/etc/logrotate.d/` (por ejemplo `rsyslog`, `nginx`, `httpd`).

Un bloque típico (como en `/etc/logrotate.d/rsyslog`) define la frecuencia, cuántas copias se conservan y si se comprimen:

```
/var/log/messages
/var/log/secure
/var/log/maillog
/var/log/spooler
/var/log/boot.log
/var/log/cron
{
    missingok
    sharedscripts
    postrotate
        /usr/bin/systemctl kill -s HUP rsyslog.service >/dev/null 2>&1 || true
    endscript
}
```

En Fedora, la frecuencia y el número de rotaciones suelen definirse en `/etc/logrotate.conf` (`weekly`, `rotate 4`, `compress`, etc.) y aplicarse a los ficheros listados en cada snippet.

Comandos útiles:

| Comando                                 | Acción                                  |
| --------------------------------------- | --------------------------------------- |
| `sudo logrotate -d /etc/logrotate.conf` | Simular una pasada (modo depuración)    |
| `sudo logrotate -f /etc/logrotate.conf` | Forzar rotación ahora                   |
| `systemctl list-timers logrotate*`      | Ver cuándo se ejecutará el temporizador |

Tras cambiar un fichero en `/etc/logrotate.d/`, no hace falta reiniciar un servicio; la siguiente ejecución de logrotate aplicará las reglas (o puede forzarse con `-f`).

### MiniDLNA

**MiniDLNA** (paquete `minidlna`) expone vídeo, música e imágenes de carpetas locales a clientes DLNA/UPnP (televisores, consolas, VLC, etc.). Se instala con el bloque DNF.

#### Configuración básica

En este repositorio hay un ejemplo en `etc/minidlna.conf` (`friendly_name`, interfaces de red, `media_dir` bajo `/opt/minidlna/`, `inotify`, etc.). Debe copiarse o enlazarse al sistema (requiere permisos de root):

```bash
sudo install -D -m 644 "$PWD/etc/minidlna.conf" /etc/minidlna.conf
```

Las carpetas referenciadas en `media_dir` deben existir y ser **legibles** por el usuario `minidlna` (por ejemplo con ACL):

```bash
sudo install -d -o minidlna -g minidlna -m 755 /opt/minidlna/{Music,Pictures,Videos}
# o, si se usan otras rutas:
# sudo setfacl -R -m u:minidlna:rx /ruta/a/medios
```

Si SELinux está en enforcing y los clientes no ven archivos, puede asignarse un contexto adecuado a esas carpetas (por ejemplo `public_content_t`):

```bash
sudo semanage fcontext -a -t public_content_t '/opt/minidlna(/.*)?'
sudo restorecon -Rv /opt/minidlna
```

#### Servicio systemd

Tras guardar la configuración:

```bash
sudo systemctl enable --now minidlna
sudo systemctl restart minidlna
```

Estado y registros:

```bash
systemctl status minidlna
journalctl -u minidlna -f
```

Puede comprobarse que escucha en el puerto configurado (8200 por defecto):

```bash
sudo ss -tlnp | grep minidlnad
```

#### Firewall (firewalld)

Los clientes DLNA usan **UDP 1900** (SSDP/descubrimiento) y **TCP 8200** (servidor HTTP/media, o el `port=` definido). Si existe el servicio predefinido:

```bash
sudo firewall-cmd --permanent --add-service=minidlna
sudo firewall-cmd --reload
```

Si no está disponible, deben abrirse los puertos explícitamente:

```bash
sudo firewall-cmd --permanent --add-port=1900/udp
sudo firewall-cmd --permanent --add-port=8200/tcp
sudo firewall-cmd --reload
```

#### Reindexar la biblioteca

Con `inotify=yes`, los cambios en disco suelen detectarse solos. Para forzar un escaneo completo de la base de datos:

```bash
sudo systemctl restart minidlna
```

O, si el servicio está en marcha, puede enviarse la señal de reescaneo al demonio:

```bash
sudo killall -USR1 minidlnad
```

#### Comprobación en clientes

En la misma LAN, los reproductores compatibles con DLNA/UPnP deberían listar el servidor por `friendly_name`. En **VLC**: _Ver_ → _Listas de reproducción locales_ → _Red universal plug'n'play_. En un televisor o consola, suele aparecer como servidor de medios en el menú de red.

| Parámetro       | Valor habitual        | Uso                                      |
| --------------- | --------------------- | ---------------------------------------- |
| `friendly_name` | texto libre           | Nombre del servidor en la red            |
| `port`          | `8200`                | Puerto TCP del servidor HTTP/DLNA        |
| `media_dir`     | ruta[,tipo]           | Carpetas publicadas                      |
| `inotify`       | `yes`                 | Actualizar el índice al cambiar archivos |
| `db_dir`        | `/var/cache/minidlna` | Caché del catálogo de medios             |

### Emulación (NES, SNES, PlayStation, Sega Genesis y arcade)

Todo se instala con el bloque DNF (sección «Emulación» de `packages.txt`); no se usa Flathub.

| Sistema                   | Programa                        | Paquete                                          |
| ------------------------- | ------------------------------- | ------------------------------------------------ |
| NES / Famicom             | RetroArch, core Nestopia        | `libretro-nestopia`                              |
| SNES / Super Famicom      | RetroArch, core bsnes           | `libretro-bsnes-mercury`                         |
| PlayStation               | RetroArch, core PCSX ReARMED    | `libretro-pcsx-rearmed`                          |
| Sega Genesis / Mega Drive | RetroArch, core Genesis Plus GX | compilado (`scripts/install-genesis-plus-gx.sh`) |
| Arcade                    | MAME (independiente)            | `mame`                                           |

`retroarch` recomienda (dependencias débiles) muchos otros cores de Fedora: DS, Virtual Boy, Game & Watch, Atari, PlayStation, etc. Para que RetroArch muestre solo los de la tabla, `scripts/fedora-install.sh` instala con `--setopt=exclude_from_weak='libretro-*'`. Si ya están instalados, basta con `sudo dnf remove` de los que sobren: dnf no vuelve a instalar una dependencia débil que se quitó a mano.

**Genesis Plus GX** (Sega Genesis/Mega Drive, Master System, Game Gear y Sega CD) no está en Fedora porque su licencia solo permite el uso no comercial. `scripts/install-genesis-plus-gx.sh` (lo ejecuta `extras-install.sh`) lo compila desde el upstream en un commit fijo y lo deja en `~/.local/lib/libretro/`; para actualizarlo, debe cambiarse el commit del script. RetroArch lee los cores de un solo directorio, así que `scripts/dotfiles-install.sh` arma `~/.config/retroarch/cores/` con enlaces a los del sistema (`/usr/lib64/libretro/`) y a los compilados.

#### Configuración

RetroArch reescribe su `~/.config/retroarch/retroarch.cfg` completo al salir, así que no se enlaza: `retroarch/retroarch.cfg` guarda solo los ajustes propios y `scripts/dotfiles-install.sh` los aplica sobre ese archivo, sin tocar el resto (si RetroArch está abierto, no hace nada):

| Ajuste                                  | Efecto                                                 |
| --------------------------------------- | ------------------------------------------------------ |
| `input_menu_toggle_gamepad_combo = "4"` | **Start + Select** abre el menú durante un juego       |
| `rgui_browser_directory = "~/Juegos"`   | _Cargar contenido_ parte en la carpeta de juegos       |
| `video_fullscreen = "true"`             | Pantalla completa                                      |
| `video_scale_integer = "true"`          | Píxeles de tamaño entero (bordes negros a los lados)   |
| `libretro_directory`                    | Cores del sistema más los compilados                   |
| `joypad_autoconfig_dir`                 | Perfiles de mandos del sistema más los corregidos      |

Los demás ajustes hechos desde el menú de RetroArch se guardan en su propio archivo; para conservar uno en el repositorio, debe agregarse su línea (`clave = "valor"`) a `retroarch/retroarch.cfg`. Los menús están en español (_Settings → User → Language_).

#### Gamepad (GameSir Nova Lite T4)

El mando tiene varios modos de conexión. En Linux, el más fiable es el **receptor USB de 2,4 GHz en modo PC (X-input)**: el kernel lo maneja con el driver `xpad` y lo presenta como «Microsoft X-Box 360 pad», que RetroArch configura solo gracias a los perfiles de `/usr/share/libretro/autoconfig/`. La combinación de botones para cambiar de modo está en el manual del mando.

RetroArch trae un perfil para este modelo (`GameSir Nova Lite.cfg`), pero cruza hombros y gatillos (LT/RT quedan como L/R) y define Start dos veces. `retroarch/autoconfig/udev/GameSir Nova Lite.cfg` es la versión corregida: LB/RB son L/R, LT/RT son L2/R2 y Home abre el menú. RetroArch lee un solo directorio de perfiles, así que `scripts/dotfiles-install.sh` arma `~/.config/retroarch/autoconfig/` con enlaces a los del sistema y, encima, a los del repositorio; los demás mandos siguen configurándose solos.

Por Bluetooth, en modo Switch lo maneja el driver `hid-nintendo`; en ese caso puede que deba asignarse los botones a mano en RetroArch: _Settings → Input → Port 1 Controls → Set All Controls_ (Ajustes → Entrada → Controles del puerto 1 → Asignar todos los controles).

Para comprobar que el sistema reconoce el mando y sus botones, basta un tester de gamepad en Chromium: usa la Gamepad API, que muestra cada control según su función (palancas en los ejes 0–3). Para ver los eventos crudos del kernel:

```bash
sudo evtest    # debe elegirse el dispositivo
```

MAME usa el mismo mando sin configuración adicional; los controles se cambian en su menú (`Tab` → _Input (general)_).

#### ROMs

Los ROMs no vienen incluidos; deben obtenerse de los cartuchos propios. Se guardan en `~/Juegos`, una carpeta por consola (las crea `scripts/dotfiles-install.sh`):

```bash
mkdir -p ~/Juegos/{Nintendo,"Super Nintendo",PlayStation,"Sega Genesis"} ~/.local/share/mame/roms
```

- **RetroArch:** _Load Content_ (Cargar contenido) y elegir el archivo en `~/Juegos/<consola>`; RetroArch propone el core adecuado. _Import Content → Scan Directory_ (Importar contenido → Escanear directorio) sobre `~/Juegos` crea listas de juegos por consola (usa `retroarch-database`).
- **MAME:** busca los juegos en `~/.local/share/mame/roms` (ruta por defecto de `/etc/mame/mame.ini` en Fedora). Los ROMs de MAME deben coincidir con la versión instalada (`mame -version`); se comprueban con `mame -verifyroms`.

| Comando                                                           | Acción                                       |
| ----------------------------------------------------------------- | -------------------------------------------- |
| `retroarch`                                                       | Abrir RetroArch                              |
| `retroarch -L /usr/lib64/libretro/nestopia_libretro.so juego.nes` | Abrir un juego directamente con un core      |
| `mame`                                                            | Abrir MAME con su lista de juegos            |
| `mame juego`                                                      | Abrir un juego de arcade por su nombre corto |

### Flatpak

Algunas aplicaciones de escritorio se instalan con **Flatpak** (fuera de los repos DNF habituales).

**Flatpak y Flathub** (configuración única):

```bash
sudo dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

**Vesktop** (cliente de Discord con Vencord):

```bash
flatpak install flathub dev.vencord.Vesktop
```

Puede iniciarse desde el menú de aplicaciones o con:

```bash
flatpak run dev.vencord.Vesktop
```

**Spotify** (música en streaming):

```bash
flatpak install flathub com.spotify.Client
```

Puede iniciarse desde el menú de aplicaciones o con:

```bash
flatpak run com.spotify.Client
```

---

## Advertencia

Este repositorio es público como una forma de no perder el acceso a mis propios archivos de configuración y preferencias de usuario, no con fines colaborativos, ya que no tengo intención de mantener un historial ni garantizar la consistencia de este repositorio a lo largo del tiempo.

- Deben leerse los archivos antes de usarlos.
- Pueden extraerse fragmentos para adaptarlos a dotfiles propios.
- No debe usarse este repositorio en otras computadoras.
- No debe hacerse fork de este repositorio a menos que se sepa cómo usarlo.

## Problemas / Pull Requests

Si se usa este repositorio o parte de él y se encuentra que algo no funciona correctamente, puede abrirse un issue en este repositorio de GitHub. No es necesario abrir un pull request.
