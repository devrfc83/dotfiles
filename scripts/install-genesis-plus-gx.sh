#!/usr/bin/env bash
set -euo pipefail

# Genesis Plus GX (Sega Genesis/Mega Drive, Master System, Game Gear, Sega CD)
# como core de RetroArch. Fedora no lo distribuye por su licencia (solo uso no
# comercial), así que se compila desde el upstream en un commit fijo. Requiere
# gcc y make. Para actualizar, debe cambiarse el commit y volver a ejecutarse.
#
# El core queda en ~/.local/lib/libretro/ y se enlaza en ~/.config/retroarch/cores/,
# el directorio de cores de RetroArch (lo arma dotfiles-install.sh).

commit="aa74d79634cd230f65cce4180e92688e53883d2f"
repo_url="https://github.com/libretro/Genesis-Plus-GX.git"
core="genesis_plus_gx_libretro.so"
install_dir="${HOME}/.local/lib/libretro"
version_file="${install_dir}/genesis_plus_gx.commit"
cores_dir="${HOME}/.config/retroarch/cores"

link_core() {
  mkdir -p "${cores_dir}"
  ln -sf "${install_dir}/${core}" "${cores_dir}/${core}"
}

if [[ -f "${install_dir}/${core}" ]] && [[ "$(cat "${version_file}" 2>/dev/null)" == "${commit}" ]]; then
  link_core
  echo "Genesis Plus GX ya está compilado en el commit ${commit:0:7}."
  exit 0
fi

echo "Compilando Genesis Plus GX (commit ${commit:0:7})..."
build_dir="$(mktemp -d)"
trap 'rm -rf "${build_dir}"' EXIT

git -C "${build_dir}" init --quiet src
git -C "${build_dir}/src" fetch --quiet --depth 1 "${repo_url}" "${commit}"
git -C "${build_dir}/src" checkout --quiet FETCH_HEAD
make -C "${build_dir}/src" -f Makefile.libretro -j "$(nproc)"

install -D -m 755 "${build_dir}/src/${core}" "${install_dir}/${core}"
echo "${commit}" >"${version_file}"
link_core
echo "Genesis Plus GX instalado en ${install_dir}/${core}."
