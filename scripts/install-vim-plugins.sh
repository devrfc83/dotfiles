#!/usr/bin/env bash
set -euo pipefail

# Instala o actualiza el esquema de colores (Dracula) y los plugins de Vim (sistema pack,
# en ~/.vim/pack) y compila YouCompleteMe cuando hace falta (primera vez, cuando
# cambió o cuando cambiaron sus opciones). Requiere git, python3-devel, cmake y
# gcc-c++ (packages.txt); para el completado de TypeScript, Node con fnm. El de
# Rust usa el rust-analyzer que descarga YouCompleteMe. Lo ejecuta extras-install.sh.
# EditorConfig y hlyank no se clonan: vienen con Vim 9.2 (ver vim/vimrc).

# shellcheck source=scripts/lib/sync-repo.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/sync-repo.sh"

pack_dir="${HOME}/.vim/pack"
ycm_dir="${pack_dir}/plugins/start/youcompleteme"
ycm_flags_file="${pack_dir}/youcompleteme.flags"
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
  "plugins/start/youcompleteme https://github.com/ycm-core/YouCompleteMe.git"
)

# fnm solo se activa en zsh; aquí se activa a mano (Node por defecto) para encontrar npm
if ! command -v npm >/dev/null 2>&1 && command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --shell bash)"
fi

# Opciones de compilación de YouCompleteMe; se guardan en ycm_flags_file para
# volver a compilar si cambian
ycm_flags=(--rust-completer)
if command -v npm >/dev/null 2>&1; then
  ycm_flags+=(--ts-completer)
fi

build_ycm() {
  if [[ " ${ycm_flags[*]} " != *" --ts-completer "* ]]; then
    echo "Advertencia: no se encontró npm (fnm); YouCompleteMe se compila sin completado de TypeScript." >&2
  fi

  (cd "${ycm_dir}" && python3 install.py "${ycm_flags[@]}") &&
    echo "${ycm_flags[*]}" >"${ycm_flags_file}"
}

echo "Plugins de Vim en ${pack_dir}..."
ycm_before="$(git -C "${ycm_dir}" rev-parse HEAD 2>/dev/null || echo ninguno)"

for entry in "${repos[@]}"; do
  sync_repo "${pack_dir}/${entry%% *}" "${entry#* }" || failed+=("$(basename "${entry%% *}")")
done

if [[ -d "${ycm_dir}/.git" ]]; then
  git -C "${ycm_dir}" submodule update --init --recursive --quiet
  ycm_after="$(git -C "${ycm_dir}" rev-parse HEAD)"
  if [[ "${ycm_after}" != "${ycm_before}" ]] ||
    [[ "$(cat "${ycm_flags_file}" 2>/dev/null)" != "${ycm_flags[*]}" ]] ||
    ! compgen -G "${ycm_dir}/third_party/ycmd/ycm_core*.so" >/dev/null; then
    echo "Compilando YouCompleteMe (puede tardar varios minutos)..."
    build_ycm || failed+=("compilación de YouCompleteMe")
  else
    echo "YouCompleteMe ya está compilado y al día."
  fi
fi

# Índices de ayuda (:help) de todos los plugins
vim -N -u NONE -i NONE -es -c 'packloadall' -c 'silent! helptags ALL' -c 'qa!' || true

if ((${#failed[@]} > 0)); then
  echo "Terminado con errores en: ${failed[*]}" >&2
  exit 1
fi
echo "Plugins de Vim listos."
