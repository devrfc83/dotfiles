#!/usr/bin/env bash
set -euo pipefail

# Instala o actualiza el esquema de colores (Dracula) y los plugins de Vim (sistema
# pack, en ~/.vim/pack) y regenera su ayuda (:help). Requiere git. Sin
# servidor de lenguaje: el completado es el de Vim y el de UltiSnips. EditorConfig
# y hlyank no se clonan: vienen con Vim 9.2 (ver vim/vimrc). Lo ejecuta
# extras-install.sh.

# shellcheck source=scripts/lib/sync-repo.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/sync-repo.sh"

pack_dir="${HOME}/.vim/pack"
failed=()

# destino (relativo a ~/.vim/pack) y repositorio
repos=(
  "themes/start/dracula https://github.com/dracula/vim.git"
  "plugins/start/airline https://github.com/vim-airline/vim-airline.git"
  "plugins/start/ale https://github.com/dense-analysis/ale.git"
  "plugins/start/easyalign https://github.com/junegunn/vim-easy-align.git"
  "plugins/start/easymotion https://github.com/easymotion/vim-easymotion.git"
  "plugins/start/emmet-vim https://github.com/mattn/emmet-vim.git"
  "plugins/start/endwise https://github.com/tpope/vim-endwise.git"
  "plugins/start/fugitive https://github.com/tpope/vim-fugitive.git"
  "plugins/start/gitgutter https://github.com/airblade/vim-gitgutter.git"
  "plugins/start/nerdcommenter https://github.com/preservim/nerdcommenter.git"
  "plugins/start/nerdtree https://github.com/preservim/nerdtree.git"
  "plugins/start/surround https://tpope.io/vim/surround.git"
  "plugins/start/ultisnips https://github.com/SirVer/ultisnips.git"
  "plugins/start/undotree https://github.com/mbbill/undotree.git"
  "plugins/start/vim-snippets https://github.com/honza/vim-snippets.git"
  "plugins/start/vim-test https://github.com/vim-test/vim-test.git"
)

echo "Plugins de Vim en ${pack_dir}..."
for entry in "${repos[@]}"; do
  sync_repo "${pack_dir}/${entry%% *}" "${entry#* }" || failed+=("$(basename "${entry%% *}")")
done

# Índices de ayuda (:help) de todos los plugins
vim -N -u NONE -i NONE -es -c 'packloadall' -c 'silent! helptags ALL' -c 'qa!' || true

if ((${#failed[@]} > 0)); then
  echo "Terminado con errores en: ${failed[*]}" >&2
  exit 1
fi
echo "Plugins de Vim listos."
