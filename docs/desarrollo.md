# Desarrollo

PHP, Node.js, Rust, Git, gh, doctl, Docker, Podman, Ansible y Flutter.

[← Volver al índice](README.md)

## PHP y Composer

PHP 8.5, Composer y sus extensiones (bcmath, curl, fpm, gd, imagick, intl,
mbstring, memcached, pcov, pgsql, sodium, sqlite3, xdebug, xml, zip) se instalan
con el bloque DNF; están en la sección «PHP y Composer» de `packages.txt`.

**Xdebug apagado por defecto.** Sin `xdebug.mode`, Xdebug 3 queda en modo
`develop` y hace más lento todo PHP (Composer lo advierte).
`scripts/fedora-install.sh` instala `php/99-dotfiles.ini` en `/etc/php.d/` con
`xdebug.mode = off`; la variable `XDEBUG_MODE` tiene prioridad, así que se
activa por comando:

```bash
XDEBUG_MODE=debug XDEBUG_SESSION=1 php script.php       # depurar con VSCodium (puerto 9003)
XDEBUG_MODE=coverage vendor/bin/phpunit --coverage-text  # cobertura con Xdebug
php -d pcov.enabled=1 vendor/bin/phpunit --coverage-text # cobertura con PCOV (más rápida)
```

Para depurar con PHP-FPM: `sudo systemctl edit php-fpm`, agregar
`Environment=XDEBUG_MODE=debug` en `[Service]` y reiniciar el servicio.

En Fedora 44, extensiones como `opcache` suelen incluirse con `php` y
`php-common`. Los binarios globales de Composer (`~/.composer/vendor/bin`, de
`composer global require`) se añaden al final del `PATH` en `zsh/zshenv`, para
que no tapen comandos del sistema.

## Node.js (fnm)

Node no está en DNF; se instala con **fnm**, un gestor de versiones escrito en
Rust. fnm tampoco está en Fedora: `scripts/install-runtimes.sh` (lo ejecuta
`extras-install.sh`) lo compila con `cargo install` después de instalar rustup
y, si no hay una versión predeterminada de Node, instala la última y la deja
como predeterminada. Las versiones quedan en `~/.local/share/fnm`.

Para actualizar Node más adelante:

```bash
v="$(fnm list-remote --latest)" && fnm install "$v" && fnm default "$v"
```

En `zsh/zshrc`, el plugin `fnm` de oh-my-zsh activa fnm (unos milisegundos,
frente a los ~250 ms de nvm) y genera su completado. Al entrar en un directorio
con `.nvmrc` o `.node-version`, cambia a esa versión (si no está instalada, se
instala con `fnm install`). Para actualizar fnm: `cargo install --locked fnm`.

### npmrc privado (token fuera del repo)

El archivo `node/npmrc` **no** contiene credenciales. Si se necesita autenticar
contra npm, debe crearse un archivo privado fuera del repositorio en
`~/.config/npm/npmrc-private` (con permisos 0600):

```bash
install -d -m 700 "$HOME/.config/npm"
touch "$HOME/.config/npm/npmrc-private"
chmod 600 "$HOME/.config/npm/npmrc-private"
```

Luego debe añadirse el token (se pega una sola vez; el archivo **no** debe
versionarse):

```bash
printf '\n//registry.npmjs.org/:_authToken=%s\n' 'PEGAR_TOKEN_AQUI' >> "$HOME/.config/npm/npmrc-private"
```

`scripts/dotfiles-install.sh` genera `~/.config/npm/npmrc-effective` combinando
`~/.npmrc` (base) + `npmrc-private` (secreto), y `zsh/zshenv` exporta
`NPM_CONFIG_USERCONFIG` hacia ese archivo efectivo. Al cambiar el token o
`node/npmrc`, debe ejecutarse de nuevo `dotfiles-install.sh`.

## Rust

**rustup** (Rust estable) lo instala o actualiza `scripts/install-runtimes.sh`,
con `--no-modify-path` para no tocar los perfiles. El mismo script agrega los
componentes `rust-analyzer` (servidor de lenguaje para los editores) y
`rust-src` (fuentes de la biblioteca estándar, que necesita para completar). Los
crates `typst-cli`, `genact` y `tetris-tui` los instala después
`extras-install.sh` con `cargo install --locked`. La compilación de typst-cli
requiere `openssl-devel`, `gcc` y `make`, incluidos en el bloque DNF.

En `zshenv` se añade `~/.cargo/bin` al `PATH` si existe ese directorio.

## Git

**git** y **git-lfs** se instalan con DNF. Los enlaces `~/.gitconfig`,
`~/.gitconfig-personal`, `~/.gitconfig-seadragon`, `~/.gitignore` y
`~/.gitattributes` se crean al [enlazar los
dotfiles](instalacion.md#enlazar-los-dotfiles).

**Pull según el repositorio:**

- En cualquier repositorio, `git pull` solo avanza en _fast-forward_
  (`pull.ff = only`). Si las ramas divergieron, falla y debe decidirse a mano
  entre `git pr` (rebase) y `git m` (merge).
- En repositorios propios, `git/gitconfig-personal` activa el rebase automático
  (`pull.rebase = merges`). Se carga con `includeIf` cuando algún remoto apunta
  a `github://` o a `git@github.com:devrfc83/`. Los repos de Sea Dragon no son
  personales y usan la configuración general de pull.

**Correo según el repositorio:** en los repos de Sea Dragon (remoto
`seadragon://` o `ssh://git@git.seadragon.cl:2222/seadragon/`),
`git/gitconfig-seadragon` cambia `user.email` a `rfuentealba@seadragon.cl`; en
el resto se usa el correo de GitHub.

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

**Hooks globales y secretos:** `core.hooksPath` apunta a `~/.config/git/hooks`
(un enlace a `git/hooks/`). Antes de cada commit, `gitleaks` busca secretos
(contraseñas, tokens, llaves) en lo que se va a confirmar y, si encuentra
alguno, detiene el commit. Después se ejecuta el hook propio del repositorio
(`.git/hooks/<hook>`), que `core.hooksPath` dejaría sin ejecutar; si no tiene,
en los hooks de Git LFS se llama a `git lfs`. Un falso positivo se acepta
agregando su huella (`Fingerprint`) a `.gitleaksignore`, o se salta el hook en
un commit puntual con `git commit --no-verify`. Los repositorios con su propio
`core.hooksPath` (el de estos dotfiles, o los que usan husky) usan solo sus
hooks.

**Verificación de firmas:** los commits se firman con la llave SSH
`~/.ssh/id_ed25519`. Para que `git log --show-signature` pueda verificarlas,
`scripts/dotfiles-install.sh` genera `~/.config/git/allowed_signers` (opción
`gpg.ssh.allowedSignersFile`) a partir de `~/.ssh/id_ed25519.pub`, con los dos
correos (el general y el de Sea Dragon).

Para comprobar qué archivo define el comportamiento en un repositorio:

```bash
git config --show-origin pull.rebase
```

Las ramas creadas con la configuración anterior
(`branch.autosetuprebase = always`) guardan `branch.<rama>.rebase` en
`.git/config` y siguen haciendo rebase. Para limpiarlas, debe ejecutarse en cada
repositorio:

```bash
git config --get-regexp '^branch\..*\.rebase$' | cut -d' ' -f1 | xargs -rn1 git config --unset
```

`git/gitignore` está preparado para este stack y cubre reglas de **Laravel +
Node + Python + Go + Rust + Vala** (además de archivos temporales de
editores/sistema). `git/gitattributes` incluye normalización y diffs para varios
tipos, incluyendo **Go** (`*.go`), **Rust** (`*.rs`) y **Vala** (`*.vala`,
`*.vapi`).

Git LFS debe inicializarse una vez por usuario, sin instalar sus hooks
(`--skip-repo`): los de `git/hooks/` ya llaman a `git lfs`.

```bash
git lfs install --skip-repo
```

## gh (GitHub CLI)

**gh** no está en los repos base de Fedora. Su repositorio oficial está
versionado en `etc/yum.repos.d/gh-cli.repo`; `scripts/fedora-install.sh` lo
instala e importa su llave (huella
`7F38 BBB5 9D06 4DBC B3D8  4D72 5612 B364 6231 3325`; el archivo de GitHub
también trae la llave anterior, vencida en septiembre de 2026), y `gh` está en
`packages.txt`.

Autenticación (una sola vez por usuario):

```bash
gh auth login
```

Para comprobar el estado de la sesión:

```bash
gh auth status
```

## doctl (DigitalOcean CLI)

**doctl** está disponible directamente en los repos de Fedora
(`fedora`/`updates`); se instala con el bloque DNF
([Paquetes](instalacion.md#paquetes)).

Autenticación (una sola vez por usuario, requiere un token de la API de
DigitalOcean):

```bash
doctl auth init
```

Para comprobar el contexto activo:

```bash
doctl account get
```

## Docker

**docker** no está en los repos base de Fedora. Su repositorio oficial está
versionado en `etc/yum.repos.d/docker-ce.repo`; `scripts/fedora-install.sh` lo
instala e importa su llave (huella
`060A 61C5 1B55 8A7F 742B  77AA C52F EB6B 621E 9F35`). Los paquetes
(`docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`,
`docker-compose-plugin`) están en `packages.txt`, y el script habilita el
servicio y agrega el usuario al grupo `docker` para no requerir `sudo` en cada
comando.

**Puertos solo en el equipo:** por defecto, Docker publica los puertos de los
contenedores en todas las interfaces, con reglas propias que firewalld no
filtra. `scripts/install-docker.sh` (lo ejecuta `fedora-install.sh`) instala
`etc/docker/daemon.json` (combinado
con el `/etc/docker/daemon.json` que ya exista) para que se publiquen en
`127.0.0.1`: `ip` vale para la red `bridge` y `default-network-opts`, para las
redes que crea cada proyecto de Compose. Para publicar un puerto en la red, debe
indicarse la dirección: `-p 0.0.0.0:8080:80` (o `"0.0.0.0:8080:80"` en
`ports:`). Los contenedores y las redes creados antes del cambio conservan su
configuración: deben recrearse (`docker compose down` y `up`). El script nombra
las redes que siguen publicando en todas las interfaces.

Debe cerrarse sesión y volverse a entrar para que el nuevo grupo surta efecto.
Para comprobar que todo funciona:

```bash
docker run hello-world
```

## Podman

**podman** y **podman-compose** se instalan con el bloque DNF.
`scripts/fedora-install.sh` ya ejecuta los pasos de esta sección (subuid/subgid,
socket de usuario y _linger_); a mano son los siguientes. En Linux, Podman
funciona sin demonio y sin `root` (modo _rootless_); no hace falta
`podman machine init`, que solo se usa en macOS y Windows.

Debe comprobarse que el usuario tiene rangos de UID/GID subordinados (Fedora los
crea al dar de alta el usuario):

```bash
grep "$USER" /etc/subuid /etc/subgid
```

Si no aparecen, deben asignarse y migrarse los contenedores existentes:

```bash
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER"
podman system migrate
```

Debe habilitarse el socket de usuario (API compatible con Docker, usada por
`podman-compose`, editores y otras herramientas):

```bash
systemctl --user enable --now podman.socket
```

Para que los contenedores del usuario sigan en marcha tras cerrar sesión (y
arranquen con el sistema):

```bash
sudo loginctl enable-linger "$USER"
```

Para comprobar que todo funciona:

```bash
podman info --format '{{.Host.Security.Rootless}}'
podman run --rm quay.io/podman/hello
```

Docker y Podman pueden convivir en el mismo equipo. **No** debe instalarse
`podman-docker` (alias `docker` → `podman`) mientras esté instalado Docker CE,
porque ambos paquetes entran en conflicto.

## Ansible

Algunos proyectos propios se despliegan a un servidor remoto mediante
**Ansible** controlado con `make`. En la máquina cliente (la que ejecuta `make`)
se necesita:

- **Ansible** (`ansible-core` ≥ 2.15), **`make`** y **passlib** de Python (se
  usa localmente para generar el hash de la contraseña del usuario de
  despliegue).
- Una llave SSH que pueda acceder al servidor destino como `root` (u otro
  usuario con sudo) la primera vez.

Los tres paquetes están en el bloque DNF ([Paquetes](instalacion.md#paquetes))
(`ansible-core`, `make`,
`python3-passlib`); no requieren pasos adicionales de instalación.

Cada proyecto que use este flujo documenta en su propio repositorio los
playbooks, el `Makefile` y las variables específicas de su despliegue.

## Dart y Flutter

Las extensiones `dart-code.dart-code` y `dart-code.flutter` están en
`codium/extensions.txt`, pero el SDK no se instala automáticamente: no está en
los repositorios de Fedora y no siempre se usa. Para instalarlo a mano, sin
tocar el `PATH` (`~/.local/bin` ya está en él):

```bash
git clone --depth 1 -b stable https://github.com/flutter/flutter.git ~/.local/share/flutter
ln -sf ~/.local/share/flutter/bin/flutter ~/.local/bin/flutter
ln -sf ~/.local/share/flutter/bin/dart ~/.local/bin/dart
flutter doctor
```

Flutter incluye Dart; no hace falta instalarlo aparte. Según el destino de la
aplicación:

- **Escritorio Linux:** además de `cmake` y `ninja-build` (bloque DNF),
  `sudo dnf install -y clang gtk3-devel xz-devel`.
- **Web:** Flutter busca Google Chrome; para usar Chromium,
  `export CHROME_EXECUTABLE=/usr/bin/chromium-browser` (en el `.envrc` del
  proyecto, con direnv).
- **Android:** Android Studio (descarga desde developer.android.com) y luego
  `flutter doctor --android-licenses`.

Para actualizar: `flutter upgrade`. Para desinstalar: borrar
`~/.local/share/flutter`, `~/.local/bin/flutter` y `~/.local/bin/dart`.
