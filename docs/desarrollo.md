# Desarrollo

PHP, Node.js, Python, Rust, Go, Git, gh, doctl, Docker, Podman, Ansible,
Flutter, el Android SDK, Android Studio y el JDK.

[← Volver al índice](README.md)

## PHP y Composer

PHP 8.6, Composer y sus extensiones (bcmath, curl, fpm, gd, imagick, intl,
mbstring, memcached, pcov, pgsql, sodium, sqlite3, xdebug, xml, zip) se instalan
con el bloque DNF; están en la sección «PHP y Composer» de `packages.txt`.

**PHP 8.6 viene de Remi.** Fedora 45 trae PHP 8.5 y no cambia de versión menor
hasta la siguiente versión de Fedora, así que PHP y sus extensiones salen del
repositorio `php86` de Remi (`etc/yum.repos.d/remi-php86.repo`, con su llave
verificada por huella en `fedora-install.sh`); Composer sigue viniendo de
Fedora. Solo se usa ese repositorio, limitado a `php*`, y con prioridad sobre
Fedora: así una extensión de Fedora con un número de versión mayor, compilada
para PHP 8.5, no reemplaza a la de Remi. Cuando Fedora traiga PHP 8.6, se puede
volver a sus paquetes:

```bash
sudo rm /etc/yum.repos.d/remi-php86.repo   # y borrar etc/yum.repos.d/remi-php86.repo de los dotfiles
sudo dnf distro-sync 'php*'
```

En ese caso, `php-zip` vuelve a ser `php-pecl-zip` en `packages.txt`.

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

Extensiones como `opcache` vienen incluidas en `php` y `php-common`. Los
binarios globales de Composer (`~/.composer/vendor/bin`, de `composer global
require`) se añaden al final del `PATH` en `zsh/zshenv`, para que no tapen
comandos del sistema.

**Valkey desde PHP:** `php-pecl-redis6` (phpredis) es el cliente que usa Laravel
por defecto (`REDIS_CLIENT=phpredis`) para caché, colas y sesiones en Valkey
([Servicios](servicios.md#servicios-locales-valkey-memcached-y-postfix)).

**PsySH (Tinker):** `php artisan tinker` abre PsySH, que Laravel trae en el
`vendor/` de cada proyecto. Todos leen `~/.config/psysh/config.php` (enlace a
`psysh/config.php`), con un tema [Dracula](terminal.md#paleta-dracula) propio:
palabras clave rosadas, cadenas amarillas, números morados y clases cyan.

**Paquetes globales de Composer:** `laravel/installer` (orden `laravel new`) lo
instala `extras-install.sh` (lista `composer_packages`) y lo actualiza
`dotfiles-update.sh` con `composer global update`. Para agregar otro, se suma a
la lista.

## Node.js (fnm)

Node no está en DNF; se instala con **fnm**, un gestor de versiones escrito en
Rust. fnm tampoco está en Fedora: `scripts/install-runtimes.sh` (lo ejecuta
`extras-install.sh`) lo compila con `cargo install` después de instalar rustup
y deja como predeterminada la última versión de **Node 26**, si la
predeterminada no es ya de Node 26. Las versiones quedan en
`~/.local/share/fnm`.

La versión mayor está fijada en un solo lugar, `node_major` en
`scripts/lib/node.sh`. No se usa `fnm list-remote --latest` porque elige
también las versiones de prueba (como `v27.0.0-alpha`). `dotfiles-update.sh`
actualiza a la última de Node 26; para pasar a otra versión mayor, se cambia
`node_major` y se ejecuta `install-runtimes.sh`. Las versiones anteriores
siguen instaladas (`fnm list`; para borrar una, `fnm uninstall <versión>`).

En `zsh/zshrc`, el plugin `fnm` de oh-my-zsh activa fnm (unos milisegundos,
frente a los ~250 ms de nvm) y genera su completado. Al entrar en un directorio
con `.nvmrc` o `.node-version`, cambia a esa versión (si no está instalada, se
instala con `fnm install`). Para actualizar fnm: `cargo install --locked fnm`.

**Paquetes globales de npm:** `@bitwarden/cli` (`bw`, la CLI de Bitwarden; ver
[Seguridad](seguridad.md#herramientas)), en la lista `npm_packages` de
`extras-install.sh`. npm los instala en la versión de Node activa, así que al
cambiar de versión desaparecen: por eso `dotfiles-update.sh` actualiza Node
antes de ejecutar `extras-install.sh`, que los vuelve a instalar en la nueva. Se
instalan con `--ignore-scripts`: npm 11 bloquea los scripts de instalación de
las dependencias no revisadas y avisa por cada uno, y ninguno de la lista los
necesita (el de `core-js` solo imprime publicidad). Si un paquete nuevo los
necesitara, se permite por nombre con `allow-scripts` en `node/npmrc`.

La CLI de Claude Code (`@anthropic-ai/claude-code`, orden `claude`) es la
excepción: descarga su binario en el `postinstall`, así que se instala con sus
scripts y `npm install -g --allow-scripts=@anthropic-ai/claude-code`, que solo
permite ese paquete. Su `settings.json` no está en el repositorio.

Las skills globales de Claude Code (las que carga en cualquier directorio)
viven en `skills/`: cada una es un directorio con su `SKILL.md`, y cada
archivo se enlaza por separado en `~/.claude/skills` (una línea por archivo
en `scripts/lib/links.sh`). `~/.claude/skills` es un directorio real y no un
enlace, porque Claude guarda ahí las skills que sincroniza desde los
marketplaces (`~/.claude/skills/synced`); esas no se versionan ni se enlazan.
Las skills de este repositorio están en `.claude/skills/`.

### Skills de Claude Code de terceros

`scripts/install-claude-skills.sh` (lo ejecuta `extras-install.sh`) instala
en `~/.claude/skills` las skills globales que vienen de terceros. No entran al
repositorio. Las listas están en su cabecera:

| Skill                                 | Origen e instalador                                     |
| ------------------------------------- | ------------------------------------------------------- |
| frontend-design                       | `anthropics/skills` (CLI skills)                        |
| docx, pdf, pptx y xlsx                | `anthropics/skills`, las document-skills (CLI skills)   |
| browser-use                           | `browser-use/browser-use` (CLI skills)                  |
| shannon                               | `unicodeveloper/shannon` (CLI skills)                   |
| excalidraw-diagram                    | `coleam00/excalidraw-diagram-skill` (CLI skills)        |
| caveman                               | `JuliusBrussee/caveman` (CLI skills)                    |
| todas las de agent-skills             | `addyosmani/agent-skills` (CLI skills)                  |
| code-reviewer                         | `development/code-reviewer` (claude-code-templates)     |

Ambos instaladores corren con `npx` en su última versión, sin versión fija,
desde `$HOME` (si no, instalarían en el `.claude/` del directorio actual) y
con la telemetría apagada (`DO_NOT_TRACK=1`, `CCT_NO_TRACKING=true`). El CLI
skills copia cada skill en `~/.claude/skills` y anota su origen y commit en
`~/.agents/.skill-lock.json`; `dotfiles-update.sh` las actualiza con
`npx skills update -g`. Para quitar una: `npx skills remove -g <skill>`.

Las document-skills también llegan sincronizadas desde claude.ai
(`~/.claude/skills/synced`), así que quedan dos copias.

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

## Python

Python, `pip` y `virtualenv` vienen del bloque DNF; **pipx** instala las
herramientas globales en entornos aislados (sqlmap, edge-tts, piper-tts) y
**ruff** es el linter y formateador (también en Vim, VSCodium y Zed).

**uv** (bloque DNF) es el gestor de los proyectos propios: `uv init` crea el
`pyproject.toml`, `uv add` agrega dependencias y escribe `uv.lock`, `uv run`
ejecuta en el `.venv` del proyecto sin activarlo, y `uv python install 3.12`
instala la versión de Python que pida el proyecto, sin tocar la del sistema
(como fnm con Node). Los proyectos de clientes siguen con su propio flujo
(`requirements.txt`, `virtualenv`); ahí `uv pip install -r requirements.txt` es
un reemplazo directo y más rápido de `pip` que no cambia nada en su repositorio.

## Rust

**rustup** (Rust estable) lo instala o actualiza `scripts/install-runtimes.sh`,
con `--no-modify-path` para no tocar los perfiles. El mismo script agrega los
componentes `rust-analyzer` (servidor de lenguaje para los editores) y
`rust-src` (fuentes de la biblioteca estándar, que necesita para completar). Los
crates `cargo-audit` (`cargo audit` revisa `Cargo.lock` contra la base de avisos
RustSec), `tealdeer` (`tldr`), `typst-cli`, `genact` y `tetris-tui` los instala
después `extras-install.sh` con `cargo install --locked`. La compilación de
typst-cli requiere `openssl-devel`, `gcc` y `make`, incluidos en el bloque DNF.

En `zshenv` se añade `~/.cargo/bin` al `PATH` si existe ese directorio.

## Go

El paquete `golang` de Fedora va una versión menor atrás (Fedora no cambia de
versión menor de Go dentro de una misma versión del sistema), así que
`scripts/install-go.sh` (lo ejecuta `extras-install.sh`) instala el tarball
oficial de go.dev en `/usr/local/go`, con la versión y el sha256 fijados en el
script. Si ya está esa versión, no descarga nada; si no, borra `/usr/local/go`
antes de extraer, como indica go.dev. Después instala con `go install` la última
versión de `gopls` (servidor de lenguaje para los editores), `delve` (depurador,
`dlv`), `govulncheck` (vulnerabilidades conocidas en las dependencias de un
módulo) y `shfmt` (formato de scripts de shell, que usan `scripts/lint.sh`, Vim
y la función `shfmt` de zsh; no está en Fedora 45).

El GOPATH es `~/.local/go`, no `~/go`: el script lo fija con
`go env -w GOPATH=~/.local/go` (queda en `~/.config/go/env`, que Go lee siempre,
también desde los editores abiertos desde GNOME). Ahí quedan lo de `go install`
(`~/.local/go/bin`) y la caché de módulos (`~/.local/go/pkg/mod`).

En `zshenv` se añaden `/usr/local/go/bin` y `~/.local/go/bin` al `PATH`, antes
que `/usr/bin`: si también está el RPM `golang`, se usa el de go.dev.

Para cambiar de versión: `scripts/check-versions.sh` avisa cuando hay una nueva
y muestra los valores de `go_version` y `go_sha256` que deben ponerse en el
script; después se ejecuta de nuevo `install-go.sh`.

## Bruno y DBeaver

**Bruno** es el cliente de API (REST y GraphQL): guarda cada colección como una
carpeta de archivos de texto (`.bru`), que puede ir en el repositorio del
proyecto. **DBeaver Community Edition** es el cliente gráfico de bases de datos
(PostgreSQL, SQLite, MySQL y otras por JDBC); trae su propio JRE, así que no
depende del JDK del sistema. Ninguno está en Fedora:
`scripts/install-bruno.sh` y `scripts/install-dbeaver.sh` (los ejecuta
`extras-install.sh`) instalan el RPM de los releases de GitHub del upstream, en
una versión fija y con su sha256, con `dnf` (lo común está en
`scripts/lib/release-rpm.sh`). `check-versions.sh` avisa cuando hay una versión
nueva; para actualizar, se cambian `version` y `sha256` en el script.

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
| `alias.psr`                    | Como `psf`, pero después de `git rfc` (con sus fechas de 1983, `--force-if-includes` siempre rechaza) |

**Diffs y historial en la terminal:** `core.pager` es **delta** (`git-delta`,
bloque DNF): resalta la sintaxis con el tema Dracula de bat, numera las líneas y
con `navigate` salta entre archivos con `n` y `N`; también en `git add -p`
(`interactive.diffFilter`). Pagina con `less`, no con `most`, que sigue siendo
el `PAGER` general. **tig** (bloque DNF) recorre el historial, el blame y el
estado (`tig`, `tig blame archivo`, `tig status`).

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
correos: el general, `devrfc83@gmail.com` (`git/gitconfig`), y el de Sea Dragon,
`rfuentealba@seadragon.cl` (`git/gitconfig-seadragon`).

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
Node + Python + Go + Dart/Flutter + Android + Rust + Vala** (además de archivos
temporales de editores/sistema); en Android ignora también la firma de la app
(`key.properties`, `*.jks`, `*.keystore`). `git/gitattributes` incluye
normalización y diffs para varios tipos, incluyendo **Go** (`*.go`), **Dart**
(`*.dart`, con `pubspec.lock` como generado), **Kotlin** y Gradle (`*.kt`,
`*.kts`, `*.gradle`), **Rust** (`*.rs`) y **Vala** (`*.vala`, `*.vapi`).

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

**Alias:** están en `gh/aliases.yml` y `scripts/dotfiles-install.sh` los
importa en `~/.config/gh/config.yml` (que no se enlaza: gh lo reescribe, y el
token va aparte, en `hosts.yml`). Para agregar uno, se suma al archivo y se
vuelve a ejecutar el script; `gh alias list` muestra los vigentes.

| Alias      | Equivale a       | Para qué                                            |
| ---------- | ---------------- | --------------------------------------------------- |
| `gh co 42` | `gh pr checkout` | Traer la rama de un pull request y cambiarse a ella |

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

## Dart, Flutter y Android

Flutter incluye Dart: no se instala aparte. Ninguno está en Fedora, así que
`scripts/install-flutter.sh` (lo ejecuta `extras-install.sh`, así que
`dotfiles-update.sh` también lo actualiza) clona el canal `stable` del
repositorio oficial en `~/.local/share/flutter` y, si ya está, ejecuta `flutter
upgrade`. También desactiva la telemetría de Flutter y de Dart. En `zshenv` se
añaden al `PATH` `~/.local/share/flutter/bin` (`flutter` y `dart`) y
`~/.pub-cache/bin` (lo de `dart pub global activate`). Las extensiones
`dart-code.dart-code` y `dart-code.flutter` están en `codium/extensions.txt`.

Según el destino de la aplicación:

- **Escritorio Linux:** `clang` y `gtk3-devel`, con `cmake`, `ninja-build` y
  `xz-devel` (bloque DNF).
- **Web:** Google Chrome (bloque DNF), que Flutter encuentra solo.
- **Android:** el Android SDK y Android Studio, con Java 21 (ver abajo).

`flutter doctor` revisa que esté todo.

### Android SDK

`scripts/install-android-sdk.sh` (también desde `extras-install.sh`, después
de Flutter) instala el SDK en `~/.local/share/android-sdk`. La primera vez
descarga las *command-line tools* de Google (la versión y el sha256 están
fijados en el script, de
[developer.android.com/studio](https://developer.android.com/studio), sección
«Command line tools only») y, con ellas, instala el paquete
`cmdline-tools;latest`. Así queda registrado en el SDK y se actualiza con el
resto; la versión fija solo cuenta en una instalación nueva. (Una copia del zip
puesta a mano en `cmdline-tools/latest`, sin `package.xml`, no se actualiza: el
script la reemplaza por el paquete.)

Después usa la **Android CLI** (`android sdk`, que reemplaza a `sdkmanager`,
marcado como obsoleto) para instalar `platform-tools` (`adb` y `fastboot`), la
plataforma con que compilan por defecto los proyectos de Flutter
(`compileSdkVersion`) y las build-tools estables más nuevas, y para actualizar
todo (`android sdk update`). Como `android sdk install` no falla si no
encuentra un paquete o le falta la licencia, el script comprueba al final que
estén instalados. Gradle descarga solo las otras versiones que pida cada
proyecto. Al final ejecuta `flutter config --android-sdk` y `flutter config
--jdk-dir` con el JDK por defecto ([JDK](#jdk)).

**Licencias:** las command-line tools actuales ya no piden aceptarlas
(`sdkmanager --licenses` quedó sin efecto y la Android CLI no tiene esa orden;
`flutter doctor` da el toolchain por bueno). El script solo lo intenta en la
primera instalación, con el zip de versión fija, por si esa versión aún las
exigiera: si corre en una terminal, pregunta por las que falten; si no, y esa
versión las exige, no se instala nada y el script falla. En ese caso se aceptan
con `flutter doctor --android-licenses` y se vuelve a ejecutar.

**Métricas:** la Android CLI envía datos de uso a Google si no se le pasa
`--no-metrics`, y no tiene un ajuste para apagarlas. El script la llama siempre
con esa opción y `zsh/zshaliases` define `android` como `android
--no-metrics`. La primera vez que se ejecuta, se descarga sola en
`~/.android/bin/android-cli`.

En `zshenv` se exporta `ANDROID_HOME` y se añaden al `PATH`
`cmdline-tools/latest/bin` (`android`, `sdkmanager`, `avdmanager`) y
`platform-tools`.

**Emulador:** no se instala (cada imagen de sistema pesa varios GB). Para
agregarlo, con una imagen de la API instalada (por ejemplo, 36):

```bash
android sdk install emulator system-images/android-36/google_apis/x86_64
avdmanager create avd -n pixel -k "system-images;android-36;google_apis;x86_64" -d pixel_8
flutter emulators --launch pixel
```

El emulador usa KVM, que ya está por virt-manager.

### Android Studio

`scripts/install-android-studio.sh` (también desde `extras-install.sh`, después
del SDK) descarga el tarball oficial de
[developer.android.com/studio](https://developer.android.com/studio) (la
versión y el sha256 están fijados en el script), lo extrae en
`~/.local/share/android-studio` y crea su entrada en el menú de aplicaciones
(`~/.local/share/applications/android-studio.desktop`). Solo lo instala la
primera vez: después se actualiza con su propio actualizador (_Help → Check for
Updates_), así que la versión fija solo cuenta en una instalación nueva.
`scripts/check-versions.sh` avisa cuando hay una más nueva, para mantenerla al
día.

En `zshenv` se exporta `CAPACITOR_ANDROID_STUDIO_PATH`, para que
`npx cap open android` (Capacitor) encuentre el binario `bin/studio`.

La primera vez que se abre, el asistente pregunta por el SDK: debe elegirse el
de `~/.local/share/android-sdk`, el que instala `install-android-sdk.sh`.

Android Studio trae su propio JDK (JetBrains Runtime), y por defecto Gradle usa
ese. Si un proyecto no compila por la versión de Java, debe elegirse
`java-21-temurin-jdk` en _Settings → Build, Execution, Deployment → Build Tools
→ Gradle → Gradle JDK_.

### JDK

El JDK de Fedora 45 es Java 25, con el que Gradle no funciona, y Fedora ya no
trae Java 21. `temurin-21-jdk` viene del repositorio de
[Adoptium](https://adoptium.net/) (`etc/yum.repos.d/adoptium.repo`, con la
huella de su llave verificada por `fedora-install.sh`) y se actualiza con dnf.
`java-25-openjdk-devel` sigue instalado.

El RPM de Temurin se registra en `alternatives` con menos prioridad que el de
Fedora, así que `fedora-install.sh` fija `java` y `javac` en Temurin 21 (en
modo manual: las actualizaciones no lo cambian). Para cambiar de versión, o para
revisar cuál está activa:

```bash
sudo alternatives --config java    # y lo mismo con javac
java -version
```

Gradle desde la terminal usa el `java` del `PATH`, o sea, el de
`alternatives`. Flutter usaría el de Android Studio si lo encuentra:
`install-android-sdk.sh` le fija el de `javac` con `flutter config --jdk-dir`.
