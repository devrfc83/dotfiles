#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
packages_file="${repo_root}/packages.txt"
user="${USER:-$(id -un)}"

if ! command -v dnf >/dev/null 2>&1; then
  echo "Este script requiere dnf (Fedora)." >&2
  exit 1
fi

if [[ ! -f "${packages_file}" ]]; then
  echo "No se encontró ${packages_file}." >&2
  exit 1
fi

fedora_version="$(rpm -E %fedora 2>/dev/null || true)"
if [[ -n "${fedora_version}" ]] && [[ "${fedora_version}" -lt 44 ]]; then
  echo "Advertencia: este script está pensado para Fedora 44+ (detectado: ${fedora_version})."
fi

echo "Habilitando RPM Fusion (free y nonfree)..."
sudo dnf install -y \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

# Importa una llave GPG en rpm solo si la huella esperada está entre las llaves
# del archivo (algunos, como el de GitHub CLI, traen la llave anterior y la nueva).
import_key() {
  local url="$1"
  local expected="$2"
  local key_file

  key_file="$(mktemp)"
  curl -sSfL -o "${key_file}" "${url}"
  if ! gpg --show-keys --with-colons "${key_file}" 2>/dev/null |
    awk -F: '/^pub:/ {primary = 1; next} /^fpr:/ && primary {print $10; primary = 0}' |
    grep -qx "${expected}"; then
    echo "La huella ${expected} no está en ${url}; no se importa." >&2
    rm -f "${key_file}"
    return 1
  fi
  sudo rpm --import "${key_file}"
  rm -f "${key_file}"
}

echo "Configurando los repositorios de VSCodium, Cursor, GitHub CLI y Docker CE..."
import_key "https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg" \
  "1302DE60231889FE1EBACADC54678CF75A278D9C"
import_key "https://downloads.cursor.com/keys/anysphere.asc" \
  "380FF4BCDC34A4BD92A3565342A1772E62E492D6"
import_key "https://cli.github.com/packages/githubcli-archive-keyring.asc" \
  "7F38BBB59D064DBCB3D84D725612B36462313325"
import_key "https://download.docker.com/linux/fedora/gpg" \
  "060A61C51B558A7F742B77AAC52FEB6B621E9F35"
sudo install -m 644 "${repo_root}"/etc/yum.repos.d/*.repo /etc/yum.repos.d/
# dnf 5 guarda aparte las llaves con que verifica los índices (repo_gpgcheck);
# -y acepta las mismas llaves ya verificadas arriba.
sudo dnf makecache -y

echo "Instalando paquetes de packages.txt..."
mapfile -t packages < <(grep -vE '^[[:space:]]*(#|$)' "${packages_file}")
# Solo los cores libretro de packages.txt, no los que recomienda retroarch
sudo dnf install -y --setopt=exclude_from_weak='libretro-*' "${packages[@]}"

echo "Eliminando paquetes no deseados..."
sudo dnf remove -y \
  firefox \
  firefox-langpacks \
  gnome-boxes \
  gnome-tour \
  libreoffice-core \
  unoconv \
  malcontent-control \
  malcontent-ui-libs || true

echo "Configurando Flathub..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "Configurando Podman (rootless)..."
if ! grep -q "^${user}:" /etc/subuid || ! grep -q "^${user}:" /etc/subgid; then
  sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "${user}"
  podman system migrate
fi

# systemctl --user necesita la sesión del usuario (falla con sudo o sin sesión gráfica/SSH)
if ! systemctl --user enable --now podman.socket; then
  echo "Advertencia: no se pudo habilitar podman.socket; debe ejecutarse a mano:" >&2
  echo "  systemctl --user enable --now podman.socket" >&2
fi

sudo loginctl enable-linger "${user}"

echo "Configurando Docker..."
sudo systemctl enable --now docker
if ! id -nG "${user}" | grep -qw docker; then
  sudo usermod -aG docker "${user}"
  echo "Se agregó ${user} al grupo docker; se aplica al volver a iniciar sesión."
fi

# Con el grupo libvirt, virt-manager administra las máquinas del sistema
# (qemu:///system) sin pedir la contraseña
echo "Configurando libvirt..."
if ! id -nG "${user}" | grep -qw libvirt; then
  sudo usermod -aG libvirt "${user}"
  echo "Se agregó ${user} al grupo libvirt; se aplica al volver a iniciar sesión."
fi

if [[ "$(getent passwd "${user}" | cut -d: -f7)" != "/usr/bin/zsh" ]]; then
  echo "Cambiando la shell de inicio a zsh..."
  sudo usermod -s /usr/bin/zsh "${user}"
fi

echo "Instalación Fedora terminada."
echo "Siguientes pasos: bash scripts/dotfiles-install.sh y bash scripts/extras-install.sh."
