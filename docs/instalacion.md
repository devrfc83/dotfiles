# Instalación

Sistema, fuentes de paquetes, scripts de instalación, DNF y enlaces.

[← Volver al índice](README.md)

## Sistema

Estos dotfiles se mantienen y prueban principalmente en **Fedora Linux 44+**
(Workstation).

## Fuentes de paquetes

| Origen                         | Para qué sirve                                                       |
| ------------------------------ | -------------------------------------------------------------------- |
| **DNF** (`fedora`, `updates`)  | Casi todo el software base y de terminal                             |
| **RPM Fusion** (free, nonfree) | VLC, codecs y paquetes no incluidos en los repos oficiales           |
| **Repositorio de VSCodium**    | Editor `codium`                                                      |
| **Repositorio de Cursor**      | Editor `cursor`                                                      |
| **Repositorio de GitHub CLI**  | `gh`                                                                 |
| **Repositorio de Docker CE**   | `docker-ce`, `docker-ce-cli`, `containerd.io` y plugins              |
| **rustup + Cargo**             | `typst-cli`, `genact`, `tetris-tui` y `fnm` (no están en Fedora)     |
| **fnm**                        | Versiones de Node.js (fnm se compila con Cargo)                      |
| **Tarball de go.dev**          | Go (`/usr/local/go`; versión y checksum en `scripts/install-go.sh`)  |
| **go install**                 | `gopls` y `delve` (en `~/go/bin`)                                    |
| **Git (Flutter, stable)**      | Flutter con Dart (`~/.local/share/flutter`)                          |
| **dl.google.com**              | Android SDK: command-line tools (checksum fijado) y la Android CLI   |
| **pipx**                       | `piper-tts` (voz del saludo matutino) y `sqlmap`                     |
| **Git (manual)**               | oh-my-zsh, plugins de zsh y tmux, Vim, pgFormatter, tty-clock, nikto |
| **Fuentes de Debian**          | `tint` (versión y checksum fijados en `scripts/install-tint.sh`)     |
| **Instaladores oficiales**     | Zed (`~/.local/zed.app`) y opencode (`~/.opencode/bin`)              |
| **RPM de opencode.ai**         | opencode Desktop (`/opt/OpenCode`)                                   |
| **Flatpak** (Flathub)          | Bitwarden, Vesktop, Spotify (a mano)                                 |

Los repositorios `fedora` y `updates` vienen habilitados por defecto; no hace
falta EPEL ni Remi. Sí deben añadirse **RPM Fusion** (free y nonfree) antes del
bloque DNF ([Paquetes](#paquetes)).

## Instalación automatizada (scripts)

Basta con ejecutar un script desde la raíz del repositorio, como usuario normal
(sin `sudo`; lo pide cuando hace falta):

```bash
# Fedora 44+
bash scripts/fedora-install.sh
```

Al terminar, ejecuta `dotfiles-install.sh` y `extras-install.sh`, en ese orden.
Los dos pueden ejecutarse también por separado, para volver a aplicar los
enlaces o para actualizar.

- `fedora-install.sh` fija los mirrors de Fedora y RPM Fusion
  ([Mirrors](#mirrors)), habilita RPM Fusion si aún no lo está, configura los
  repositorios
  de VSCodium, Cursor, GitHub CLI y Docker CE (verificando la huella de sus
  llaves), instala los paquetes de `packages.txt`, intenta eliminar paquetes no
  deseados, instala las políticas de Chromium (la extensión de Bitwarden; ver
  [Chromium](escritorio.md#chromium)), configura Flathub, deja Podman listo en
  modo _rootless_
  ([Podman](desarrollo.md#podman)), habilita Docker con el usuario en el grupo
  `docker` (y los puertos de los contenedores publicados en `127.0.0.1`; ver
  [Docker](desarrollo.md#docker)), agrega el usuario al
  grupo `libvirt` (virt-manager sin contraseña), inicializa PostgreSQL con el
  rol y la base de desarrollo ([PostgreSQL](postgresql.md#postgresql)), habilita
  Valkey, Memcached y Postfix, limita sshd (sin `root` y con menos intentos),
  reparte firewalld entre la zona de casa y la de fuera de casa
  ([Zonas](seguridad.md#zonas-casa-y-fuera-de-casa); al terminar debe marcarse
  la red de casa con `install-firewall.sh --casa`), deja MiniDLNA compartiendo
  las carpetas XDG
  ([MiniDLNA](servicios.md#minidlna)) y pone zsh
  como shell de inicio. PostgreSQL, Docker, Postfix, el firewall y MiniDLNA
  tienen su propio script (`install-postgresql.sh`, `install-docker.sh`,
  `install-postfix.sh`, `install-firewall.sh` e `install-minidlna.sh`), que
  puede ejecutarse de nuevo por separado para volver a aplicar solo esa parte.
- `dotfiles-install.sh` crea los enlaces de [Enlazar los
  dotfiles](#enlazar-los-dotfiles) (y reconstruye la caché de fuentes por las
  reglas de `fontconfig/`), incluidos `vim`/`vi`/`vimdiff`/`view` hacia `vimx`
  (respaldando como `*.bak.<fecha>` los archivos que ya existan), los
  directorios de trabajo de npm y Vim, las carpetas de juegos en `~/Juegos`, el
  archivo `~/.config/git/allowed_signers`, activa el hook de pre-commit del
  repositorio
  ([Mantenimiento](mantenimiento.md#hook-de-pre-commit-y-revisiones)), deja
  Chromium como navegador predeterminado (`xdg-settings` y `xdg-mime`), copia
  desde Nextcloud las fuentes (con FiraCode Nerd Font) en
  `~/.local/share/fonts/` y el BIOS de PlayStation ([Archivos privados desde
  Nextcloud](#archivos-privados-desde-nextcloud)), fija FiraCode Nerd Font Mono
  como fuente monoespaciada del sistema (la que usa Ptyxis) y la paleta Dracula
  en Ptyxis, aplica los ajustes de `retroarch/retroarch.cfg`
  ([Emulación](extras.md#emulación-nes-snes-playstation-sega-genesis-y-arcade)),
  pone `gnome/background.jpg` como fondo de escritorio y de la pantalla de
  bloqueo y `profile.webp` como foto de perfil, carga la configuración de las
  extensiones de GNOME ([Extensiones de
  GNOME](escritorio.md#extensiones-de-gnome)) y activa el timer del saludo
  matutino. Puede ejecutarse varias veces.
- `extras-install.sh` instala lo que no está en `packages.txt`: rustup (con
  rust-analyzer) y fnm con Node.js, Go (con gopls y delve), Flutter (con Dart)
  y el Android SDK ([Dart, Flutter y
  Android](desarrollo.md#dart-flutter-y-android)), oh-my-zsh y los plugins de
  zsh y tmux, los
  crates de Cargo (`typst-cli`, `genact`, `tetris-tui`), pgFormatter, tty-clock,
  tint, el core Genesis Plus GX de RetroArch, el tema de iconos Tela, nikto,
  sqlmap (con pipx), las
  extensiones de VSCodium y
  Cursor, Zed, opencode y opencode Desktop ([Zed](editores.md#zed) y
  [opencode](editores.md#opencode)), los plugins de Vim (con la compilación de
  YouCompleteMe) y Piper con la voz por defecto. Ejecuta los scripts
  `install-*.sh` correspondientes; si uno falla, sigue con los demás y lo
  informa al final. También sirve para actualizar.

Después quedan pocos pasos manuales: cerrar la sesión y volver a entrar (grupos
`docker` y `libvirt`, zsh y extensiones de GNOME), iniciar sesión en `gh` y
`doctl` y, si se usa, configurar rsyslog
([Rsyslog](servicios.md#rsyslog-y-logrotate)).

## Instalación base con DNF

### RPM Fusion (free y nonfree)

Varios paquetes del bloque siguiente (por ejemplo **VLC** con plugins completos)
están en [RPM Fusion](https://rpmfusion.org/), no en los repos `fedora` /
`updates`. Deben habilitarse **free** y **nonfree** antes de ejecutar la
instalación masiva:

```bash
sudo dnf install \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```

Puede comprobarse que los repos quedaron activos con:

```bash
dnf repolist | grep rpmfusion
```

`scripts/fedora-install.sh` descarga estos dos paquetes desde `mirror.hnd.cl` en
lugar de `mirrors.rpmfusion.org`, cuyo redirector puede elegir mirrors lejanos o
caídos, y los omite si ya están instalados.

### Mirrors

Por defecto, dnf elige mirrors con los metalinks de Fedora y RPM Fusion. Fedora
no tiene mirrors en Chile, y en la práctica las descargas iban a EE. UU. por
HTTP o fallaban por timeout. `etc/dnf/repos.override.d/50-mirrors.repo` fija
mirrors medidos desde Talca, sin modificar los `.repo` del sistema (es un
*override* de dnf5):

| Repositorios                          | Mirror principal                   | Respaldo                                        |
| ------------------------------------- | ---------------------------------- | ----------------------------------------------- |
| `fedora`, `updates`                   | `br.mirrors.cicku.me` (Cloudflare) | `southfront.mm.fcix.net`, `mirror.cedia.org.ec` |
| `rpmfusion-{free,nonfree}{,-updates}` | `mirror.hnd.cl` (Chile)            | `br.mirrors.cicku.me`                           |

Si un mirror falla, dnf prueba el siguiente de la lista. Los paquetes se siguen
verificando con las llaves GPG de cada repositorio. `scripts/fedora-install.sh`
lo instala antes de usar dnf; a mano:

```bash
sudo install -D -m 644 etc/dnf/repos.override.d/50-mirrors.repo /etc/dnf/repos.override.d/50-mirrors.repo
sudo dnf makecache --refresh
```

Para volver a los metalinks (por ejemplo, fuera de Chile):
`sudo rm /etc/dnf/repos.override.d/50-mirrors.repo`.

### Paquetes

La lista completa de paquetes DNF está en [`packages.txt`](../packages.txt),
agrupada por categoría (terminal, desarrollo, PHP, bases de datos, contenedores,
escritorio, multimedia, etc.). Es la única fuente: la usan tanto
`scripts/fedora-install.sh` como el comando siguiente. Para agregar o quitar un
paquete, debe editarse solo ese archivo.

Deben instalarse de una vez. Antes deben configurarse los repositorios de
VSCodium y Cursor ([VSCodium](editores.md#vscodium)), porque `codium` y `cursor`
están en la lista. El resto de la documentación asume que ya se habilitó RPM
Fusion y se ejecutó este bloque:

```bash
grep -vE '^[[:space:]]*(#|$)' packages.txt | xargs sudo dnf install -y --setopt=exclude_from_weak='libretro-*'
```

Tras instalarse las extensiones de GNOME Shell, debe reiniciarse la sesión o
recargarse el shell con `Alt`+`F2`, escribiendo `r` y pulsando Enter.

## Paquetes a eliminar

En Fedora Workstation suelen venir preinstalados programas que no se usan en
este entorno. Pueden desinstalarse tras el bloque de instalación anterior (o en
cualquier momento):

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

`dnf` mostrará las dependencias que también se eliminarán (resto de subpaquetes
de LibreOffice, etc.). Debe revisarse la lista antes de confirmar si se ejecuta
el comando sin `-y`.

Para comprobar que ya no están instalados:

```bash
rpm -q firefox firefox-langpacks gnome-boxes gnome-tour libreoffice-core unoconv \
  malcontent-control malcontent-ui-libs
```

Si el comando devuelve «no está instalado» para todos, la desinstalación fue
correcta.

## Enlazar los dotfiles

Lo más simple es ejecutar `bash scripts/dotfiles-install.sh`, que crea todos los
enlaces y respalda los archivos existentes (de cada uno guarda los tres
respaldos más recientes; ver [Respaldos](mantenimiento.md#respaldos)). La lista
de enlaces está en un solo lugar, el arreglo `links` de `scripts/lib/links.sh`.
Para hacerlos a mano, desde la raíz del repositorio,
`bash scripts/dotfiles-install.sh --mostrar` imprime las órdenes `mkdir -p` y
`ln -sf` correspondientes sin cambiar nada:

```bash
bash scripts/dotfiles-install.sh --mostrar        # revisar
bash scripts/dotfiles-install.sh --mostrar | sh   # ejecutar
```

Debe abrirse una terminal nueva para que los enlaces surtan efecto.

## Archivos privados desde Nextcloud

Las fuentes y el BIOS de PlayStation no pueden redistribuirse, así que no están
en el repositorio ni en una URL pública: están en Nextcloud, y
`scripts/dotfiles-install.sh` los copia desde la carpeta que sincroniza el
cliente de escritorio, **nextcloud-client** (bloque DNF, con
`nextcloud-client-nautilus` para ver el estado de sincronización en Archivos).
El repositorio no guarda contraseñas ni la dirección del servidor:
`scripts/lib/nextcloud.sh` busca la carpeta local en la configuración del
cliente (`~/.config/Nextcloud/nextcloud.cfg`), aunque no sea `~/Nextcloud` o se
sincronice solo una subcarpeta.

| En Nextcloud             | En el equipo                              | Cuándo se copia                                  |
| ------------------------ | ----------------------------------------- | ------------------------------------------------ |
| `Respaldos/Fonts/*.ttf`  | `~/.local/share/fonts/`                   | Si falta o cambió (rsync, por tamaño y fecha)    |
| `Respaldos/scph5501.bin` | `~/.config/retroarch/system/scph5501.bin` | Si falta o no coincide su SHA-256 (en el script) |

**Primera vez** (en un equipo recién instalado, `fedora-install.sh` instala el
cliente, pero iniciar sesión es un paso manual):

1. Abrir **Nextcloud** desde el menú de aplicaciones e iniciar sesión (se
   autoriza en el navegador; el cliente guarda la credencial en el llavero de
   GNOME).
2. Dejar la carpeta local por defecto, `~/Nextcloud`, o elegir otra.
3. En la selección de carpetas, incluir al menos `Respaldos`; el resto, a gusto
   (para el uso diario).
4. Esperar a que termine la sincronización y ejecutar
   `bash scripts/dotfiles-install.sh`.

Hasta entonces, el script avisa que `Respaldos` no está sincronizado y sigue con
lo demás. El cliente se inicia solo con la sesión (opción _Iniciar al arrancar
el sistema_ de su configuración, activa por defecto) y mantiene la carpeta al
día.
