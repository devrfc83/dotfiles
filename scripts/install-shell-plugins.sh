#!/usr/bin/env bash
set -euo pipefail

# Instala o actualiza oh-my-zsh, sus plugins externos (zsh-completions y
# zsh-syntax-highlighting) y TPM con los plugins de tmux declarados en
# tmux/tmux.conf. No toca ~/.zshrc: es un enlace a este repositorio.
# Si un paso falla, sigue con los demás y lo informa al final.

# shellcheck source=scripts/lib/sync-repo.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/sync-repo.sh"

zsh_dir="${ZSH:-${HOME}/.oh-my-zsh}"
zsh_custom="${ZSH_CUSTOM:-${zsh_dir}/custom}"
tpm_dir="${HOME}/.tmux/plugins/tpm"
failed=()

# destino y repositorio (la URL debe coincidir con el origen de los clones existentes)
repos=(
  "${zsh_dir} https://github.com/ohmyzsh/ohmyzsh.git"
  "${zsh_custom}/plugins/zsh-completions https://github.com/zsh-users/zsh-completions"
  "${zsh_custom}/plugins/zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting"
  "${tpm_dir} https://github.com/tmux-plugins/tpm"
)

for entry in "${repos[@]}"; do
  sync_repo "${entry%% *}" "${entry#* }" || failed+=("$(basename "${entry%% *}")")
done

# Plugins de tmux (tmux-sensible, tmux-cpu, etc.): TPM los instala y actualiza
# sin abrir tmux; equivale a C-a I y C-a U.
if [[ -x "${tpm_dir}/bin/install_plugins" ]]; then
  echo "Plugins de tmux..."
  "${tpm_dir}/bin/install_plugins" >/dev/null || failed+=("plugins de tmux (instalar)")
  "${tpm_dir}/bin/update_plugins" all >/dev/null || failed+=("plugins de tmux (actualizar)")
fi

if ((${#failed[@]} > 0)); then
  echo "Terminado con errores en: ${failed[*]}" >&2
  exit 1
fi
echo "oh-my-zsh, plugins de zsh y de tmux listos."
