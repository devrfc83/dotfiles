# Dotfiles — Rodrigo Fuentealba Cartes

Todas las explicaciones y comentarios deberían estar en idioma castellano.

Siempre confirma antes de modificar algo.

## Sistema

- Fedora Linux 44+ (Workstation) x86_64
- Shell: zsh + oh-my-zsh (tema pygmalion)
- Terminal: GNOME Terminal + tmux
- Editor GUI: VSCodium + Cursor
- Editor terminal: Vim 9.2

## Estructura

dotfiles/

- curl/ — curlrc
- etc/ — minidlna.conf (plantilla para `/etc/minidlna.conf`)
- editorconfig/ — editorconfig
- git/ — gitconfig, gitignore, gitattributes
- input/ — inputrc, dircolors
- node/ — npmrc (público; token en `~/.config/npm/npmrc-private`)
- postgresql/ — template_full_es.sql
- scripts/ — fedora-install, install-pgformatter, update-pgformatter
- screen/ — screenrc
- tmux/ — tmux.conf
- vim/ — vimrc
- zsh/ — zlogin, zlogout, zshenv, zprofile, zshrc, zshoptions, zshaliases, zshfunctions

## Principios de diseño

- Paleta de colores: **Tango** en terminal, tmux, screen, git y dircolors; Vim usa **cobalt** (flazz/vim-colorschemes)
- Configuraciones coordinadas entre sí (gitconfig, dircolors, fzf, tmux, vim)
- Herramientas opcionales habilitadas solo si el comando existe
- Sin dependencias de macOS, Windows o Snap (soporte Linux orientado a Fedora)
- `git/gitignore` contempla Laravel, Node, Python, Go, Rust y Vala
- `git/gitattributes` incluye tipos de Go (`*.go`), Rust (`*.rs`) y Vala (`*.vala`, `*.vapi`)

## Stack de desarrollo

Siempre las últimas versiones estables de:

- PHP 8.5 y Composer (repositorios oficiales de Fedora)
- Node (nvm)
- Python + virtualenv
- PostgreSQL + PostGIS + pgRouting
- Rust (rustup stable)
- Vala + GTK4 + libadwaita + Meson

## Fuentes de paquetes

- DNF — Fedora (fedora, updates) + **RPM Fusion** (free, nonfree): bat, direnv, eza, fastfetch, fd-find, fzf, minidlna, pgcli, screen, shfmt, zoxide, zsh, postgresql, vlc, cowsay, figlet, fortune-mod, lolcat, cmatrix, sl, toilet, etc.
- DNF — PHP/Composer en bloque aparte del README
- Repositorios RPM — VSCodium, Cursor
- Cargo — typst-cli
- Flatpak — Vesktop, Spotify

## Convenciones

- Encoding: UTF-8
- EOL: LF
- Indentación: 4 espacios por defecto, 2 para JS/TS/YAML/CSS/Shell
- Longitud máxima de línea: 132 (80 para Markdown)
- Scripts en `scripts/`: bash con shebang `#!/usr/bin/env bash`
- Todos los scripts pasan por ShellCheck y shfmt

## Symlinks

Todos los archivos se enlazan desde el repositorio a $HOME:

```bash
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

## No tocar

- Paleta de colores — siempre Tango
- `zsh/zshfunctions` — las funciones pgstart/pgstop/pglog/pgstatus usan la unidad `postgresql`
- `git/gitconfig` — las URLs insteadOf son intencionales
- `postgresql/template_full.sql` — no modificar sin probar primero
- `postgresql/template_full_es.sql` — no modificar sin probar primero
- Scripts en `scripts/` — siempre con `set -euo pipefail`
