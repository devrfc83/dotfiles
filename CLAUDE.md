# Dotfiles — Rodrigo Fuentealba Cartes

Todas las explicaciones y comentarios deberían estar en idioma castellano.

Siempre confirma antes de modificar algo.

## Sistema

- Fedora Linux 44+ (Workstation) x86_64
- Shell: zsh + oh-my-zsh (tema pygmalion)
- Terminal: Ptyxis (VTE) + tmux
- Editor GUI: VSCodium + Cursor + Zed
- Editor terminal: Vim 9.2

## Estructura

Cada dato vive en un solo lugar: lo que hace un script, en su cabecera; cómo se
usa cada cosa, en docs/ (índice en docs/README.md); qué se instala y qué se
enlaza, en packages.txt y scripts/lib/links.sh. Al cambiar algo, se actualiza
ese lugar y no se repite aquí.

- README.md — inicio rápido; docs/ — documentación por tema
- Un directorio por programa con su configuración: btop/, codium/, curl/,
  editorconfig/, fontconfig/, git/ (con hooks/, los hooks globales), input/,
  mc/, node/, opencode/, pgcli/, php/, postgresql/, retroarch/, screen/, tmux/,
  vim/, zed/, zsh/
- gnome/ — ajustes del escritorio que carga dotfiles-install y vuelca
  export-gnome-settings
- systemd/ — unidades de usuario (saludo matutino)
- etc/ — archivos de /etc que instalan los scripts (repositorios, mirrors,
  Docker, sshd, políticas de Chromium y la plantilla de MiniDLNA)
- scripts/ — instalación (fedora-install, dotfiles-install, extras-install,
  install-*), mantenimiento (dotfiles-update, dotfiles-uninstall,
  export-gnome-settings) y revisiones (lint, check-*); lib/ con lo compartido
- packages.txt — lista única de paquetes DNF; scripts/lib/links.sh — lista
  única de enlaces
- .githooks/ — pre-commit de este repositorio (scripts/lint.sh); .editorconfig
  — enlace a editorconfig/editorconfig. Sin CI: las revisiones corren en local

## Principios de diseño

- Paleta de colores: **Dracula** en todo, definida una sola vez en
  scripts/lib/dracula.palette (lint revisa que tmux, screen, git, fzf, dircolors
  y pgcli solo usen esos colores): Ptyxis (paleta dracula; la fija
  dotfiles-install), bat, btop, pgcli, pspg, mc, Vim (dracula/vim), VSCodium y
  Cursor (dracula-theme.theme-dracula), Zed (extensión dracula), opencode (tema
  dracula) y GNOME (iconos Tela-dracula, acento morado; el fondo es propio)
- Configuraciones coordinadas entre sí (gitconfig, dircolors, fzf, tmux, vim)
- Herramientas opcionales habilitadas solo si el comando existe
- Sin dependencias de macOS, Windows o Snap (soporte Linux orientado a Fedora)
- `git/gitignore` contempla Laravel, Node, Python, Go, Rust y Vala
- `git/gitattributes` incluye tipos de Go (`*.go`), Rust (`*.rs`) y Vala
  (`*.vala`, `*.vapi`)

## Stack de desarrollo

Siempre las últimas versiones estables de:

- PHP 8.5 y Composer (repositorios oficiales de Fedora)
- Node (fnm)
- Python + virtualenv
- PostgreSQL + PostGIS + pgRouting
- Rust (rustup stable + rust-analyzer)
- Vala + GTK4 + libadwaita + Meson

## Fuentes de paquetes

De dónde sale cada paquete (DNF con RPM Fusion y mirrors fijos, repositorios RPM
con llaves verificadas por huella, Cargo, pipx, compilados desde el upstream en
versión fija y Flatpak): docs/instalacion.md, sección «Fuentes de paquetes».

## Convenciones

- Encoding: UTF-8
- EOL: LF
- Indentación: 4 espacios por defecto, 2 para JS/TS/YAML/CSS/Shell
- Longitud máxima de línea: 132 (80 para Markdown)
- Scripts en `scripts/`: bash con shebang `#!/usr/bin/env bash`
- Todos los scripts pasan por ShellCheck y shfmt

## Symlinks

Todos los archivos se enlazan desde el repositorio a $HOME. La lista única es el
arreglo `links` de `scripts/lib/links.sh` (la usan dotfiles-install y
dotfiles-uninstall); `bash scripts/dotfiles-install.sh --mostrar` la imprime
como órdenes `mkdir -p` y `ln -sf`. Al agregar o quitar un enlace, se cambia
solo ahí.

## No tocar

- Paleta de colores — siempre Dracula (scripts/lib/dracula.palette)
- `zsh/zshfunctions` — las funciones pgstart/pgstop/pglog/pgstatus usan la
  unidad `postgresql`
- `git/gitconfig` — las URLs insteadOf son intencionales
- `postgresql/template_full.sql` — no modificar sin probar primero
- `postgresql/template_full_es.sql` — no modificar sin probar primero
- Scripts en `scripts/` — siempre con `set -euo pipefail`
