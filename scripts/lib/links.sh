# shellcheck shell=bash
# Enlaces de los dotfiles en $HOME: la lista única. La usan dotfiles-install.sh,
# que los crea (con --mostrar, los imprime como órdenes ln -sf), y
# dotfiles-uninstall.sh, que los quita. docs/instalacion.md y CLAUDE.md remiten aquí.
# Se carga con source.

# origen (relativo al repositorio, o ruta absoluta):destino (relativo a $HOME)
# shellcheck disable=SC2034
links=(
  "curl/curlrc:.curlrc"
  "codium/settings.json:.config/VSCodium/User/settings.json"
  "codium/cursor-settings.json:.config/Cursor/User/settings.json"
  "editorconfig/editorconfig:.editorconfig"
  "fontconfig/conf.d/50-aptos-display.conf:.config/fontconfig/conf.d/50-aptos-display.conf"
  "gnome/background.jpg:.config/background"
  "git/gitconfig:.gitconfig"
  "git/gitconfig-personal:.gitconfig-personal"
  "git/gitconfig-seadragon:.gitconfig-seadragon"
  "git/gitignore:.gitignore"
  "git/gitattributes:.gitattributes"
  "git/hooks:.config/git/hooks"
  "input/dircolors:.dircolors"
  "input/inputrc:.inputrc"
  "mc/skins/dracula.ini:.local/share/mc/skins/dracula.ini"
  "opencode/opencode.json:.config/opencode/opencode.json"
  "opencode/tui.json:.config/opencode/tui.json"
  "pgcli/config:.config/pgcli/config"
  "postgresql/psqlrc:.psqlrc"
  "screen/screenrc:.screenrc"
  "tmux/tmux.conf:.tmux.conf"
  "tmux/tmux-weather.sh:.local/bin/tmux-weather"
  "tmux/clipboard-copy.sh:.local/bin/clipboard-copy"
  "vim/vimrc:.vimrc"
  "node/npmrc:.npmrc"
  "zed/settings.json:.config/zed/settings.json"
  "zsh/zlogout:.zlogout"
  "zsh/zshenv:.zshenv"
  "zsh/zshrc:.zshrc"
  "zsh/zshoptions:.zshoptions"
  "zsh/zshaliases:.zshaliases"
  "zsh/zshfunctions:.zshfunctions"
  "zsh/scripts/buenos_dias.zsh:.local/bin/buenos-dias"
  "systemd/buenos-dias.service:.config/systemd/user/buenos-dias.service"
  "systemd/buenos-dias.timer:.config/systemd/user/buenos-dias.timer"
  # vimx (Vim con portapapeles, paquete vim-X11) con los nombres de siempre;
  # Vim elige el modo según el nombre (vimdiff compara, view abre en solo lectura)
  "/usr/bin/vimx:.local/bin/vim"
  "/usr/bin/vimx:.local/bin/vi"
  "/usr/bin/vimx:.local/bin/vimdiff"
  "/usr/bin/vimx:.local/bin/view"
)

# link_source <origen>: la ruta absoluta del origen de un enlace
link_source() {
  if [[ "$1" == /* ]]; then
    echo "$1"
  else
    echo "${repo_root:?}/$1"
  fi
}
