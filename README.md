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
- **postgresql** — base de datos local con PostGIS y pgRouting.
- **dbeaver** — cliente gráfico para bases de datos. [Descarga desde dbeaver.io.](https://dbeaver.io/)
- **spotify** — reproducción de música en streaming (Flatpak).
- **fastfetch** — resumen del sistema al abrir la terminal (DNF).
- **espeak-ng** — síntesis de voz (texto a voz) en terminal (DNF).
- **utilidades de terminal** — asciiquarium, cbonsai, cmatrix, cowsay, figlet, fortune-mod, lolcat, sl, toilet (DNF).

## Sistema

Estos dotfiles se mantienen y prueban principalmente en **Fedora Linux 44+** (Workstation).

### Fuentes de paquetes

| Origen                         | Para qué sirve                                                       |
| ------------------------------ | -------------------------------------------------------------------- |
| **DNF** (`fedora`, `updates`)  | Casi todo el software base y de terminal                             |
| **RPM Fusion** (free, nonfree) | VLC, codecs y paquetes no incluidos en los repos oficiales           |
| **Repositorio de VSCodium**    | Editor `codium`                                                      |
| **Repositorio de Cursor**      | Editor `cursor`                                                      |
| **Repositorio de GitHub CLI**  | `gh`                                                                  |
| **Repositorio de Docker CE**   | `docker-ce`, `docker-ce-cli`, `containerd.io` y plugins              |
| **rustup + Cargo**             | `typst-cli` (no está en los repos de Fedora)                         |
| **nvm**                        | Versiones de Node.js                                                 |
| **Git (manual)**               | oh-my-zsh, plugins de zsh, TPM de tmux, esquemas de Vim, pgFormatter |
| **Flatpak** (Flathub)          | Vesktop, Spotify                                                     |

Los repositorios `fedora` y `updates` vienen habilitados por defecto; no hace falta EPEL ni Remi. Sí deben añadirse **RPM Fusion** (free y nonfree) antes del bloque DNF de esta guía.

### Instalación automatizada (scripts)

Hay un script para automatizar la instalación base:

```bash
# Fedora 44+
bash scripts/fedora-install.sh
```

El script instala paquetes base, intenta eliminar paquetes no deseados y configura Flathub.
Después de ejecutarlo, deben seguirse igualmente los pasos de enlaces y configuración de este README.

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

Deben instalarse de una vez los paquetes que Fedora y RPM Fusion proveen. El resto de esta guía asume que ya se ejecutaron los repos anteriores y el siguiente bloque:

```bash
sudo dnf install -y \
  7zip \
  asciiquarium \
  autoconf \
  automake \
  bat \
  bzip2 \
  cbonsai \
  cmatrix \
  cowsay \
  direnv \
  doctl \
  espeak-ng \
  eza \
  fastfetch \
  fd-find \
  figlet \
  fortune-mod \
  fzf \
  gcc \
  git \
  git-lfs \
  gnome-extensions-app \
  gnome-shell-extension-dash-to-dock \
  gnome-shell-extension-just-perfection \
  gzip \
  gtk4-devel \
  jq \
  logrotate \
  lolcat \
  make \
  mc \
  minidlna \
  memcached \
  meson \
  most \
  ncompress \
  ninja-build \
  perl \
  postgresql \
  postgresql-contrib \
  postgresql-plperl \
  postgresql-plpython3 \
  postgresql-server \
  postgis \
  pgcli \
  pgrouting \
  postfix \
  python3 \
  python3-pip \
  python3-virtualenv \
  rsyslog \
  screen \
  ShellCheck \
  shfmt \
  sl \
  sqlite \
  tar \
  tmux \
  toilet \
  unrar \
  unzip \
  vala \
  valkey \
  vim \
  vlc \
  vlc-libs \
  vlc-plugins-all \
  wget \
  xclip \
  xz \
  zoxide \
  zsh \
  zstd
```

Tras instalarse las extensiones de GNOME Shell, debe reiniciarse la sesión o recargarse el shell con `Alt`+`F2`, escribiendo `r` y pulsando Enter.

### Paquetes a eliminar

En Fedora Workstation suelen venir preinstalados programas que no se usan en este entorno. Pueden desinstalarse tras el bloque de instalación anterior (o en cualquier momento):

```bash
sudo dnf remove -y gnome-tour libreoffice-core unoconv \
  malcontent-control malcontent-ui-libs
```

| Paquete              | Motivo                                                  |
| -------------------- | ------------------------------------------------------- |
| `gnome-tour`         | Asistente de bienvenida de GNOME; no se necesita        |
| `libreoffice-core`   | Suite ofimática (núcleo en Fedora); no se utiliza       |
| `unoconv`            | Conversión de documentos vía LibreOffice; no se utiliza |
| `malcontent-control` | Controles parentales de GNOME; no se utilizan           |
| `malcontent-ui-libs` | Bibliotecas de interfaz de malcontent; no se utilizan   |

`dnf` mostrará las dependencias que también se eliminarán (resto de subpaquetes de LibreOffice, etc.). Debe revisarse la lista antes de confirmar si se ejecuta el comando sin `-y`.

Para comprobar que ya no están instalados:

```bash
rpm -q gnome-tour libreoffice-core unoconv \
  malcontent-control malcontent-ui-libs
```

Si el comando devuelve «no está instalado» para todos, la desinstalación fue correcta.

---

## Configuración paso a paso

Deben seguirse estos pasos **en orden** después de clonarse el repositorio y de ejecutarse la instalación DNF anterior. Todos los comandos `ln -sf` asumen que se está en la raíz del repositorio (`cd ~/Proyectos/Dotfiles` o la ruta que se use).

### 1. Enlazar los dotfiles

Debe enlazarse cada archivo a su sitio en `$HOME`:

```bash
mkdir -p "$HOME/.config/npm"
ln -sf "$PWD/curl/curlrc" "$HOME/.curlrc"
ln -sf "$PWD/editorconfig/editorconfig" "$HOME/.editorconfig"
ln -sf "$PWD/git/gitconfig" "$HOME/.gitconfig"
ln -sf "$PWD/git/gitignore" "$HOME/.gitignore"
ln -sf "$PWD/git/gitattributes" "$HOME/.gitattributes"
ln -sf "$PWD/input/dircolors" "$HOME/.dircolors"
ln -sf "$PWD/input/inputrc" "$HOME/.inputrc"
ln -sf "$PWD/screen/screenrc" "$HOME/.screenrc"
ln -sf "$PWD/tmux/tmux.conf" "$HOME/.tmux.conf"
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

Las fuentes **Nerdfonts** muestran iconos en la terminal, tmux y Vim.

1. Debe descargarse la variante deseada desde [nerdfonts.com](https://www.nerdfonts.com/font-downloads) (por ejemplo **Meslo** o **FiraCode**).
2. Deben descomprimirse los `.ttf` o `.otf` en `~/.local/share/fonts/` (debe crearse la carpeta si no existe).
3. Debe actualizarse la caché de fuentes:

```bash
fc-cache -fv ~/.local/share/fonts
```

4. En GNOME Terminal (o la terminal que se use), debe elegirse esa fuente en las preferencias.

### 3. Zsh, inputrc y dircolors

**Zsh** queda instalado con el bloque DNF. Los archivos de este repositorio configuran el shell y los programas que usan readline:

| Archivo en el repo | Enlace en `$HOME` | Función                                     |
| ------------------ | ----------------- | ------------------------------------------- |
| `input/inputrc`    | `~/.inputrc`      | Edición tipo vi en bash, python, psql, etc. |
| `input/dircolors`  | `~/.dircolors`    | Colores de `ls` / `eza` (paleta Tango)      |
| `zsh/*`            | `~/.zsh*`         | Shell interactivo completo                  |

Debe establecerse zsh como shell de inicio si aún no lo es:

```bash
chsh -s "$(command -v zsh)"
```

Debe cerrarse sesión y volverse a entrar (o abrirse una terminal nueva).

**Readline en modo vi** (`~/.inputrc`):

- Con `Esc` se pasa a modo comando.
- En modo comando: `h`/`l` (izquierda/derecha), `b`/`w` (palabras), `0`/`$` (inicio/fin de línea).
- Con `↑`/`↓` o `Ctrl-p`/`Ctrl-n` se recorre el historial por prefijo.
- En modo inserción: `Ctrl-a` / `Ctrl-e` — inicio/fin de línea.

Para comprobarlo: debe abrirse `python3`, escribir un comando, pulsarse `Esc` y probarse las teclas anteriores.

### 4. oh-my-zsh

Debe instalarse el framework (una sola vez):

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
```

Configuración relevante en este repositorio:

- **Tema:** `pygmalion` (`ZSH_THEME` en `zsh/zshenv`).
- **Plugins de omz:** listados en `zsh/zshrc` (git, tmux, vi-mode, postgres, npm, etc.).
- **Actualizaciones:** automáticas cada 15 días (`zstyle ':omz:update'` en `zshenv`); manualmente con `omz update`.

Los plugins **externos** deben clonarse (una sola vez):

```bash
git clone https://github.com/zsh-users/zsh-completions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions

git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

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

**Vim y el esquema de color**

```bash
mkdir -p "$HOME/.vim/pack/themes/start" "$HOME/.vim/pack/plugins/start"
git clone https://github.com/flazz/vim-colorschemes.git "$HOME/.vim/pack/themes/start/colorschemes"
```

En el `vimrc` de este repositorio se usa `colorscheme cobalt` (archivo `colors/cobalt.vim` del paquete flazz/vim-colorschemes).

**Directorios de trabajo de Vim** (deben crearse una vez):

```bash
mkdir -p "$HOME/.vim/backup" "$HOME/.vim/swap" "$HOME/.vim/undodir" "$HOME/.vim/snippets"
```

Los **plugins** (sistema `pack` de Vim 8+) deben clonarse en `~/.vim/pack/plugins/start/`. La lista completa y los pasos adicionales (YouCompleteMe, etc.) se documentan en `vim/instrucciones.md` del repositorio.

El enlace `~/.vimrc` → `vim/vimrc` debe existir desde el paso 1.

### 7. Vimdiff

**vimdiff** es el modo diff de Vim; no se instala por separado. Sirve para comparar dos o más archivos en terminal:

```bash
vimdiff archivo1 archivo2
# o
vim -d archivo1 archivo2
```

Se usa la misma configuración que `~/.vimrc`.

### 8. VSCodium

VSCodium no está en los repos base de Fedora; debe añadirse su repositorio RPM:

```bash
sudo rpm --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg

printf '%s\n' '[codium]' \
  'name=Download VSCodium - RPM' \
  'baseurl=https://download.vscodium.com/rpms/' \
  'enabled=1' \
  'gpgcheck=1' \
  "gpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg" \
  | sudo tee /etc/yum.repos.d/vscodium.repo

sudo dnf install -y codium
```

En `zsh/zshenv`, fuera de SSH, `EDITOR` apunta a `codium --wait` para commits y herramientas que abren un editor gráfico.

**Extensiones usadas en Codium y Cursor** (misma lista; en Codium: `codium --list-extensions`):

| Extensión                                     | Uso                                     |
| --------------------------------------------- | --------------------------------------- |
| `editorconfig.editorconfig`                   | EditorConfig                            |
| `eamodio.gitlens`                             | GitLens                                 |
| `esbenp.prettier-vscode`                      | Formato con Prettier                    |
| `dbaeumer.vscode-eslint`                      | ESLint                                  |
| `bmewburn.vscode-intelephense-client`         | PHP (Intelephense)                      |
| `anessaeah.php-intelephense-language-support` | Soporte de idioma PHP para Intelephense |
| `porifa.laravel-intelephense`                 | Laravel en Intelephense                 |
| `laravel.vscode-laravel`                      | Laravel                                 |
| `doonfrs.livewire-support`                    | Livewire                                |
| `open-southeners.laravel-pint`                | Laravel Pint                            |
| `mikestead.dotenv`                            | Archivos `.env`                         |
| `mtxr.sqltools`                               | SQLTools                                |
| `mtxr.sqltools-driver-pg`                     | Driver PostgreSQL para SQLTools         |
| `dart-code.dart-code`                         | Dart                                    |
| `dart-code.flutter`                           | Flutter                                 |
| `dsznajder.es7-react-js-snippets`             | Snippets React/JS                       |
| `timsexperiments.vscode-tailwindcss`          | Tailwind CSS                            |
| `prince781.vala`                              | Vala                                    |
| `redhat.vscode-xml`                           | XML                                     |
| `anthropic.claude-code`                       | Claude Code (asistente de IA)           |

Para reinstalarlas en **Codium** (marketplace Open VSX):

```bash
codium --install-extension editorconfig.editorconfig \
  --install-extension eamodio.gitlens \
  --install-extension esbenp.prettier-vscode \
  --install-extension dbaeumer.vscode-eslint \
  --install-extension bmewburn.vscode-intelephense-client \
  --install-extension anessaeah.php-intelephense-language-support \
  --install-extension porifa.laravel-intelephense \
  --install-extension laravel.vscode-laravel \
  --install-extension doonfrs.livewire-support \
  --install-extension open-southeners.laravel-pint \
  --install-extension mikestead.dotenv \
  --install-extension mtxr.sqltools \
  --install-extension mtxr.sqltools-driver-pg \
  --install-extension dart-code.dart-code \
  --install-extension dart-code.flutter \
  --install-extension dsznajder.es7-react-js-snippets \
  --install-extension timsexperiments.vscode-tailwindcss \
  --install-extension prince781.vala \
  --install-extension redhat.vscode-xml \
  --install-extension anthropic.claude-code
```

#### Cursor

**Cursor** debe instalarse desde su [repositorio RPM](https://cursor.com/download).

Deben usarse los mismos identificadores de extensión con el comando `cursor`:

```bash
cursor --install-extension editorconfig.editorconfig \
  --install-extension eamodio.gitlens \
  --install-extension esbenp.prettier-vscode \
  --install-extension dbaeumer.vscode-eslint \
  --install-extension bmewburn.vscode-intelephense-client \
  --install-extension porifa.laravel-intelephense \
  --install-extension laravel.vscode-laravel \
  --install-extension doonfrs.livewire-support \
  --install-extension open-southeners.laravel-pint \
  --install-extension mikestead.dotenv \
  --install-extension mtxr.sqltools \
  --install-extension mtxr.sqltools-driver-pg \
  --install-extension dart-code.dart-code \
  --install-extension dart-code.flutter \
  --install-extension dsznajder.es7-react-js-snippets \
  --install-extension timsexperiments.vscode-tailwindcss \
  --install-extension prince781.vala \
  --install-extension redhat.vscode-xml \
  --install-extension anthropic.claude-code
```

Para comprobar o actualizar extensiones en Cursor:

```bash
cursor --list-extensions
cursor --update-extensions
```

### 9. EditorConfig

No se requiere paquete: basta con el enlace `~/.editorconfig` → `editorconfig/editorconfig`. Los editores con soporte EditorConfig leerán las reglas al abrir un proyecto. Vim usa el archivo directamente; Codium y Cursor usan la extensión EditorConfig de la tabla anterior.

### 10. tmux

**tmux** se instala con DNF; la configuración está en `~/.tmux.conf` (prefijo **`C-a`**, paleta Tango).

**TPM** (gestor de plugins de tmux) debe clonarse:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Dentro de tmux: con `C-a I` (mayúscula) se instalan los plugins; con `C-a U` se actualizan.

Plugins configurados: tmux-sensible, tmux-cpu, tmux-battery, tmux-online-status. La barra muestra CPU, RAM, batería, conectividad, clima (wttr.in) y fecha.

#### Atajos principales de tmux

| Ámbito  | Comando                             | Acción                                      |
| ------- | ----------------------------------- | ------------------------------------------- |
| Sesión  | `tmux` / `tmux new -s nombre`       | Nueva sesión                                |
| Sesión  | `tmux ls` / `tmux attach -t nombre` | Listar / conectar                           |
| Sesión  | `C-a d`                             | Desconectar                                 |
| Ventana | `C-a c`                             | Nueva ventana                               |
| Ventana | `C-a K`                             | Cerrar ventana                              |
| Ventana | `C-a n` / `C-a p`                   | Siguiente / anterior                        |
| Panel   | `C-a \|` / `C-a -`                  | Dividir vertical / horizontal               |
| Panel   | `C-a h/j/k/l`                       | Moverse entre paneles                       |
| Panel   | `C-a S` / `C-a s`                   | Sincronizar paneles on/off                  |
| Copia   | `C-a [` luego `y`                   | Modo copia; copia al portapapeles (`xclip`) |
| Otros   | `C-a r`                             | Recargar configuración                      |

El ratón está activado para seleccionar paneles y texto.

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

Deben instalarse los paquetes PHP y Composer:

```bash
sudo dnf install -y \
  composer \
  php \
  php-bcmath \
  php-cli \
  php-curl \
  php-fpm \
  php-gd \
  php-imagick \
  php-intl \
  php-mbstring \
  php-memcached \
  php-pgsql \
  php-pecl-pcov \
  php-sodium \
  php-sqlite3 \
  php-xml \
  php-xdebug \
  php-zip
```

En Fedora 44, extensiones como `opcache` suelen incluirse con `php` y `php-common`. Los binarios de Composer en proyectos (`vendor/bin`) se añaden al `PATH` en `zsh/zshenv`.

### 14. Node.js (nvm)

Node no está en DNF; debe instalarse con **nvm**:

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source "$HOME/.zshrc"
nvm install node
nvm use node
```

En `zsh/zshrc` se carga nvm en cada shell interactiva.

### 15. Rust

Debe instalarse rustup y, a continuación, typst-cli:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
cargo install typst-cli
```

En `zshenv` se añade `~/.cargo/bin` al `PATH` si existe ese directorio.

### 16. curl

El cliente **curl** suele estar ya instalado; las opciones por defecto están en `curl/curlrc` (enlace `~/.curlrc` en el paso 1). No se requiere ningún paso adicional si el enlace ya fue creado.

### 17. Git

**git** y **git-lfs** se instalan con DNF. Los enlaces `~/.gitconfig`, `~/.gitignore` y `~/.gitattributes` se crean en el paso 1.

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

**gh** no está en los repos base de Fedora; debe añadirse el repositorio oficial de GitHub CLI:

```bash
sudo dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo
sudo dnf install -y gh
```

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

**docker** no está en los repos base de Fedora; debe añadirse el repositorio oficial de Docker CE:

```bash
sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Debe habilitarse el servicio y añadirse el usuario al grupo `docker` (para no requerir `sudo` en cada comando):

```bash
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
```

Debe cerrarse sesión y volverse a entrar para que el nuevo grupo surta efecto. Para comprobar que todo funciona:

```bash
docker run hello-world
```

---

## Otros

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
