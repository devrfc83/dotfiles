# Dotfiles — Rodrigo Fuentealba Cartes

Todas las explicaciones y comentarios deberían estar en idioma castellano.

Siempre confirma antes de modificar algo.

## Sistema

- Fedora Linux 44+ (Workstation) x86_64
- Shell: zsh + oh-my-zsh (tema pygmalion)
- Terminal: Ptyxis (VTE) + tmux
- Editor GUI: VSCodium + Cursor
- Editor terminal: Vim 9.2

## Estructura

dotfiles/

- curl/ — curlrc
- fontconfig/ — conf.d/50-aptos-display.conf (Aptos Display solo en su propia familia)
- etc/ — minidlna.conf (plantilla para `/etc/minidlna.conf`); yum.repos.d/ con los repositorios de VSCodium, Cursor, GitHub CLI y Docker CE
- codium/ — settings.json (VSCodium), cursor-settings.json (Cursor; igual salvo el tema automático) y extensions.txt (extensiones de VSCodium y Cursor)
- editorconfig/ — editorconfig
- gnome/ — background.jpg (fondo de escritorio); volcados de dconf de las extensiones (dash-to-dock, just-perfection) y lista de extensiones activas; los carga dotfiles-install y los regenera export-gnome-settings
- git/ — gitconfig, gitconfig-personal (solo repos propios, vía includeIf), gitignore, gitattributes
- input/ — inputrc, dircolors
- node/ — npmrc (público; token en `~/.config/npm/npmrc-private`)
- postgresql/ — template_full_es.sql
- scripts/ — fedora-install, dotfiles-install (enlaces a $HOME), install-pgformatter, update-pgformatter, install-piper, install-tty-clock, install-tint, install-genesis-plus-gx, install-vim-plugins, install-editor-extensions, install-runtimes (rustup y nvm), install-shell-plugins (oh-my-zsh, TPM), extras-install, export-gnome-settings; lib/sync-repo.sh (función compartida), lib/gnome-dconf.sh (archivos de gnome/ y sus rutas de dconf) (ejecuta los install-* y los crates de Cargo)
- packages.txt — lista única de paquetes DNF (la leen fedora-install.sh y el README)
- retroarch/ — retroarch.cfg (solo los ajustes propios; dotfiles-install los aplica sobre ~/.config/retroarch/retroarch.cfg); autoconfig/udev/ con perfiles de mandos corregidos (GameSir Nova Lite); dotfiles-install arma ~/.config/retroarch/{cores,autoconfig} con enlaces
- screen/ — screenrc
- tmux/ — tmux.conf, tmux-weather.sh (clima con caché para la barra)
- vim/ — vimrc
- systemd/ — buenos-dias.service y buenos-dias.timer (unidades de usuario)
- zsh/ — zlogin, zlogout, zshenv, zprofile, zshrc, zshoptions, zshaliases, zshfunctions; scripts/buenos_dias.zsh

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
- DNF — PHP/Composer en su propia sección de `packages.txt`
- Repositorios RPM — VSCodium, Cursor, GitHub CLI, Docker CE (archivos en etc/yum.repos.d, llaves verificadas por huella)
- Cargo — typst-cli, genact, tetris-tui
- Compilados desde el upstream — pgFormatter, tty-clock, Genesis Plus GX (core de RetroArch, commit fijo); desde fuentes de Debian — tint
- pipx — piper-tts (voz del saludo matutino)
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

## No tocar

- Paleta de colores — siempre Tango
- `zsh/zshfunctions` — las funciones pgstart/pgstop/pglog/pgstatus usan la unidad `postgresql`
- `git/gitconfig` — las URLs insteadOf son intencionales
- `postgresql/template_full.sql` — no modificar sin probar primero
- `postgresql/template_full_es.sql` — no modificar sin probar primero
- Scripts en `scripts/` — siempre con `set -euo pipefail`
