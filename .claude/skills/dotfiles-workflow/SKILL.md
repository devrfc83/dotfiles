---
name: dotfiles-workflow
description: >-
    Convenciones de Rodrigo para sus dotfiles (devrfc83/dotfiles, Fedora
    Workstation) y su código en general. Úsala al tocar zsh, tmux, vim, git,
    gnome, paquetes DNF, enlaces a $HOME, scripts de instalación o al escribir
    código y documentación, en cualquier directorio.
---

# Flujo de trabajo con mis dotfiles

Sistema: Fedora Linux 45+ (Workstation) x86_64. Shell zsh con oh-my-zsh (tema
pygmalion), Ptyxis (VTE) + tmux, Zed como editor gráfico (en transición desde
VSCodium), Vim 9.2 en terminal.

Esta skill resume las reglas para trabajar fuera del repositorio. Dentro de
él, `CLAUDE.md`, `editorconfig/editorconfig` y `scripts/lint.sh` mandan: si
algo aquí los contradice, ellos tienen la razón y esta skill se corrige.

## Reglas que no se negocian

- Todas las explicaciones y comentarios van en castellano.
- Antes de modificar cualquier archivo, describe el cambio y espera
  confirmación.
- No modifiques `postgresql/template_full.sql` ni
  `postgresql/template_full_es.sql` sin probar antes.
- No toques `zsh/zshfunctions` (pgstart, pgstop, pglog y pgstatus dependen de
  la unidad `postgresql`, alias de `postgresql-19`; pglog resuelve la real).
- No cambies las URLs `insteadOf` de `git/gitconfig`; son intencionales.
- No cambies la paleta: todo es Dracula, definida en
  `scripts/lib/dracula.palette`.
- Todo script ejecutable de `scripts/` lleva `set -euo pipefail`.
- No pongas credenciales en el repositorio. Los tokens de npm van en
  `~/.config/npm/npmrc-private` (0600), fuera del repo.
- Este repositorio no guarda historial: cada cambio se funde en el único
  commit con `git rfc` y se sube con `git psr origin seadragon`. No uses
  `git psf`: `--force-if-includes` siempre rechaza con las fechas de 1983 de
  `rfc`. Si `psr` dice que la rama remota no está en el reflog, haz `git fetch`
  y avísame antes de seguir. El hook `.claude/hooks/git-guard.sh` bloquea
  cualquier otro commit o push. La documentación refleja solo el estado actual.

## Dónde vive cada cosa (cada dato en un solo lugar)

- Paquetes DNF: `packages.txt` (lista única).
- Enlaces a `$HOME`: arreglo `links` en `scripts/lib/links.sh` (lista única,
  la usan dotfiles-install y dotfiles-uninstall). Al agregar o quitar un
  enlace, cambia solo ahí. Para verlos sin tocar nada:
  `bash scripts/dotfiles-install.sh --mostrar`.
- Qué hace un script: su cabecera.
- Cómo se usa algo: `docs/` (índice en `docs/README.md`). No repitas
  instrucciones en README.md ni en CLAUDE.md.
- De dónde sale cada paquete: `docs/instalacion.md`, sección «Fuentes de
  paquetes».
- Versiones fijas (Go, Android, Bruno, DBeaver, Mailpit, ngrok, Node major…):
  en el script correspondiente, con su sha256 o su commit.
  `scripts/check-versions.sh` avisa de versiones nuevas.
- Colores: solo los de `scripts/lib/dracula.palette`.
- Skills globales de Claude Code: `skills/`, enlazadas archivo por archivo en
  `~/.claude/skills` (directorio real; nunca enlaces el directorio). Las
  sincronizadas de los marketplaces (`~/.claude/skills/synced`) no se
  versionan ni se enlazan.

Un directorio por programa con su configuración (`zsh/`, `tmux/`, `vim/`,
`git/`, `zed/`, `codium/`, etc.). Además:

- `git/hooks/`: hooks globales de git (`dispatch.sh` y enlaces a él).
- `.githooks/pre-commit`: hook de este repositorio.
- `gnome/`: ajustes del escritorio (los carga dotfiles-install y los vuelca
  export-gnome-settings).
- `systemd/`: unidades de usuario.
- `etc/`: archivos de `/etc` que instalan los scripts.
- `scripts/lib/`: código compartido.

## Formato del código (editorconfig)

Reglas de `editorconfig/editorconfig` (`.editorconfig` es un enlace a él):

- UTF-8, fin de línea LF, salto de línea al final del archivo y sin espacios
  al final de las líneas.
- Largo máximo: 132 columnas en todo; 80 en Markdown.
- Sangría con espacios: 4 por defecto (PHP, Python, SQL, Rust, Vala, Meson,
  C/C++).
- 2 espacios: shell (`*.sh`, `*.bash`, `*.zsh` y los hooks sin extensión de
  `.githooks/` y `git/hooks/`), JS/TS/Vue, JSON, CSS/SCSS/Less, YAML, TOML,
  Dart y Typst.
- Tabuladores: HTML/XML, Makefile, Procfile, Caddyfile y `devcontainer.json`.
- Comillas simples (`quote_type = single`) en JS/TS y PHP.
- Excepciones: Markdown conserva los espacios finales (dos espacios son un
  salto de línea); CSV/TSV no llevan salto final ni se recortan.

## Scripts

- Ejecutables: bash con `#!/usr/bin/env bash` en la primera línea y
  `set -euo pipefail` en la segunda.
- Bibliotecas de `scripts/lib/*.sh`: se cargan con `source`, no llevan
  shebang sino `# shellcheck shell=bash`, y heredan las opciones del script
  que las carga.
- Cabecera con comentarios que explican qué hace, cómo se usa y por qué.
- Deben pasar ShellCheck (`shellcheck -x`) y shfmt (toma las reglas del
  editorconfig). Para corregir el formato: `shfmt -w <archivo>`.
- Herramientas opcionales: se habilitan solo si el comando existe
  (`command -v <programa> >/dev/null 2>&1`).
- Los scripts piden `sudo` cuando hace falta. Nunca pidas ejecutar algo como
  root de entrada.
- Orden de instalación: `scripts/fedora-install.sh` → `dotfiles-install.sh`
  → `extras-install.sh`.

## Principios de diseño

- Dracula en todo: Ptyxis, bat, btop, pgcli, pspg, mc, ripgrep, psysh, Vim
  (dracula/vim), VSCodium, Zed, opencode y GNOME (MacTahoe-Dark-purple, iconos
  Tela-dracula, acento morado). `scripts/lint.sh` revisa que tmux, screen, git,
  fzf, dircolors, pgcli, ripgrep y psysh solo usen colores de la paleta.
- Configuraciones coordinadas entre sí: gitconfig, dircolors, fzf, tmux y
  vim. Si cambias una, revisa las demás.
- Solo Linux, orientado a Fedora. No agregues soporte para macOS, Windows ni
  Snap.
- `git/gitignore` contempla Laravel, Node, Python, Go, Dart/Flutter, Android,
  Rust y Vala; `git/gitattributes` incluye Go, Dart, Kotlin, Rust y Vala. Al
  sumar un lenguaje al stack, actualiza ambos.
- Software de terceros con origen verificado: repositorios RPM con la llave
  GPG importada solo si coincide la huella esperada; descargas con versión y
  sha256 fijos; código compilado desde el upstream en un commit fijo.

## Stack de desarrollo

Siempre las últimas versiones estables. Lo que no es convencional aquí:

- PHP 8.6 del repositorio Remi (`php86`), no de Fedora; Composer sí de
  Fedora. Xdebug está apagado por defecto (`XDEBUG_MODE` se activa por
  comando).
- Node con **fnm** (compilado con cargo), no con nvm. La versión mayor está
  en `node_major` de `scripts/lib/node.sh`.
- Python: `uv` en proyectos propios; en proyectos de clientes,
  `requirements.txt` y `virtualenv`, sin cambiar su repositorio.
- PostgreSQL 19 + PostGIS + pgRouting del repositorio PGDG.
- Rust con rustup (stable) y rust-analyzer.
- Go desde el tarball de go.dev en `/usr/local/go`, no el RPM de Fedora;
  GOPATH es `~/.local/go`, no `~/go`. gopls, delve, govulncheck y
  shfmt van con `go install`.
- Flutter (con Dart) en `~/.local/share/flutter`, Android SDK en
  `~/.local/share/android-sdk` y Android Studio en
  `~/.local/share/android-studio`.
- Java 21 de Temurin (Adoptium) es el JDK por defecto: Gradle no funciona con
  Java 25.
- Vala + GTK4 + libadwaita + Meson.
- Contenedores: Podman rootless es el principal. Docker CE sí está instalado,
  pero **nunca** instales `podman-docker` junto con Docker CE.
- Paquetes globales de npm con `--ignore-scripts`. Claude Code es la
  excepción (`--allow-scripts=@anthropic-ai/claude-code`).
- `settings.json` de Claude Code no está en el repositorio.

## Git

- `pull.ff = only` en todos lados. Si las ramas divergieron, decide entre
  `git pr` (rebase) y `git m` (merge). No uses `git pull` sin pensar.
- Repos personales (remoto `github.com:devrfc83/` o `github://`): rebase
  automático.
- Repos de Sea Dragon: `gitconfig-seadragon` cambia el correo. No los trates
  como personales.
- Antes de cada commit corre `gitleaks` (hook global). En este repositorio,
  `.githooks/pre-commit` corre además `scripts/lint.sh` y, si cambió
  `packages.txt`, `scripts/check-packages.sh`. No uses `--no-verify` salvo
  que lo pida. No hay CI: las revisiones corren en local.
- Commits firmados con `~/.ssh/id_ed25519`.

## Verificación tras un cambio

`scripts/lint.sh` revisa los archivos versionados y también los nuevos sin
`git add`: ShellCheck y shfmt; sintaxis de zsh (`zsh -n`) y del Python de
`zsh/scripts/`; `tmux.conf` en un servidor aparte; unidades de systemd;
gitconfig; JSON con comentarios (VSCodium, Zed, opencode) y JSON estricto
(Docker, Chrome, En Croissant); paleta; Markdown (80 columnas en la prosa y
enlaces relativos); orígenes de `links.sh`; y gitleaks en los archivos y en
todo el historial.

1. `bash scripts/lint.sh`
2. Si cambió `packages.txt`: `bash scripts/check-packages.sh`
3. Si cambió un enlace: `bash scripts/dotfiles-install.sh --mostrar` y luego
   `bash scripts/dotfiles-install.sh`
4. Si cambió un script de instalación y quieres probarlo:
   `bash scripts/check-install.sh`
5. Si cambió una versión fija: `bash scripts/check-versions.sh`
6. Actualizar la documentación en `docs/` del tema afectado, y solo ahí.

Antes de reportar algo como hecho, ejecuta el paso que corresponda y muestra
el resultado.
