#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
packages_file="${repo_root}/packages.txt"
user="${USER:-$(id -un)}"

# Al final ejecuta dotfiles-install.sh y extras-install.sh, que trabajan en el
# $HOME del usuario: debe ejecutarse sin sudo (lo pide cuando hace falta).
if ((EUID == 0)); then
  echo "Este script debe ejecutarse como usuario normal, sin sudo." >&2
  exit 1
fi

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

# Mirrors fijos de Fedora y RPM Fusion (override de dnf5); antes del primer dnf
echo "Configurando los mirrors de Fedora y RPM Fusion..."
sudo install -D -m 644 "${repo_root}/etc/dnf/repos.override.d/50-mirrors.repo" \
  /etc/dnf/repos.override.d/50-mirrors.repo

# Los paquetes release se descargan del mismo mirror de 50-mirrors.repo: el
# redirector mirrors.rpmfusion.org puede elegir mirrors lejanos o caídos
echo "Habilitando RPM Fusion (free y nonfree)..."
rpmfusion_mirror="https://mirror.hnd.cl/rpmfusion"
rpmfusion_release=()
for variant in free nonfree; do
  if ! rpm -q "rpmfusion-${variant}-release" >/dev/null 2>&1; then
    rpmfusion_release+=("${rpmfusion_mirror}/${variant}/fedora/rpmfusion-${variant}-release-$(rpm -E %fedora).noarch.rpm")
  fi
done
if ((${#rpmfusion_release[@]} > 0)); then
  sudo dnf install -y "${rpmfusion_release[@]}"
else
  echo "RPM Fusion ya está habilitado."
fi

# Importa en rpm solo la llave GPG con la huella esperada. Algunos archivos traen
# más de una (el de GitHub CLI, la anterior, ya vencida, y la nueva): se extrae
# con gpg en un directorio temporal, sin tocar el llavero del usuario. Si la
# huella no está, la exportación queda vacía y no se importa nada.
import_key() {
  local url="$1"
  local expected="$2"
  local work_dir

  work_dir="$(mktemp -d)"
  curl -sSfL -o "${work_dir}/llaves" "${url}"
  gpg --homedir "${work_dir}" --quiet --import "${work_dir}/llaves" 2>/dev/null || true
  gpg --homedir "${work_dir}" --armor --export "${expected}" >"${work_dir}/llave.asc" 2>/dev/null || true
  # gpg deja un gpg-agent corriendo en ese directorio: se detiene antes de borrarlo
  gpgconf --homedir "${work_dir}" --kill all 2>/dev/null || true
  if [[ ! -s "${work_dir}/llave.asc" ]]; then
    echo "La huella ${expected} no está en ${url}; no se importa." >&2
    rm -rf "${work_dir}"
    return 1
  fi
  sudo rpm --import "${work_dir}/llave.asc"
  rm -rf "${work_dir}"
}

echo "Configurando los repositorios de VSCodium, Cursor, GitHub CLI, Docker CE, Adoptium y Google Chrome..."
import_key "https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg" \
  "1302DE60231889FE1EBACADC54678CF75A278D9C"
import_key "https://downloads.cursor.com/keys/anysphere.asc" \
  "380FF4BCDC34A4BD92A3565342A1772E62E492D6"
import_key "https://cli.github.com/packages/githubcli-archive-keyring.asc" \
  "7F38BBB59D064DBCB3D84D725612B36462313325"
import_key "https://download.docker.com/linux/fedora/gpg" \
  "060A61C51B558A7F742B77AAC52FEB6B621E9F35"
import_key "https://packages.adoptium.net/artifactory/api/gpg/key/public" \
  "3B04D753C9050D9A5D343F39843C48A565F8F04B"
import_key "https://dl.google.com/linux/linux_signing_key.pub" \
  "EB4C1BFD4F042F6DDDCCEC917721F63BD38B4796"
# google-chrome.repo reemplaza al de fedora-workstation-repositories (mismo
# nombre, pero deshabilitado)
sudo install -m 644 "${repo_root}"/etc/yum.repos.d/*.repo /etc/yum.repos.d/
# dnf 5 guarda aparte las llaves con que verifica los índices (repo_gpgcheck);
# -y acepta las mismas llaves ya verificadas arriba.
sudo dnf makecache -y

echo "Instalando paquetes de packages.txt..."
mapfile -t packages < <(grep -vE '^[[:space:]]*(#|$)' "${packages_file}")
# Solo los cores libretro de packages.txt, no los que recomienda retroarch
sudo dnf install -y --setopt=exclude_from_weak='libretro-*' "${packages[@]}"

# JDK por defecto: Temurin 21, porque Gradle no funciona con el Java 25 de Fedora.
# Su RPM lo registra en alternatives con menos prioridad que java-25-openjdk, así
# que se fija a mano (modo manual: las actualizaciones de dnf no lo cambian).
# install-android-sdk.sh se lo pasa a Flutter (flutter config --jdk-dir).
echo "Dejando Java 21 (Temurin) como JDK por defecto..."
temurin_jdk="/usr/lib/jvm/java-21-temurin-jdk"
sudo alternatives --set java "${temurin_jdk}/bin/java"
sudo alternatives --set javac "${temurin_jdk}/bin/javac"

echo "Eliminando paquetes no deseados..."
unwanted=(
  firefox
  firefox-langpacks
  gnome-boxes
  gnome-tour
  libreoffice-core
  unoconv
  malcontent-control
  malcontent-ui-libs
)
# Solo los que están instalados: así un error real de dnf detiene el script
unwanted_installed=()
for package in "${unwanted[@]}"; do
  if rpm -q "${package}" >/dev/null 2>&1; then
    unwanted_installed+=("${package}")
  fi
done
if ((${#unwanted_installed[@]} > 0)); then
  sudo dnf remove -y "${unwanted_installed[@]}"
else
  echo "No queda ninguno instalado."
fi

# Xdebug apagado por defecto (php/99-dotfiles.ini explica cómo activarlo)
echo "Configurando PHP..."
sudo install -m 644 "${repo_root}/php/99-dotfiles.ini" /etc/php.d/99-dotfiles.ini
if systemctl is-active --quiet php-fpm; then
  sudo systemctl reload php-fpm
fi

# Políticas de Google Chrome (etc/opt/chrome/policies/managed/; JSON sin
# comentarios): la extensión de Bitwarden (nngceckbapebfimnlniiiahkandclblb) se
# instala sola desde la Chrome Web Store y no puede quitarse, solo desactivarse.
# Chrome las aplica al abrirse.
echo "Configurando Google Chrome..."
sudo install -D -m 644 "${repo_root}/etc/opt/chrome/policies/managed/50-dotfiles.json" \
  /etc/opt/chrome/policies/managed/50-dotfiles.json

# sshd sin root y con menos intentos (etc/ssh/sshd_config.d/30-dotfiles.conf). Si
# la configuración resultante no es válida, se quita: un sshd que no arranca
# dejaría el equipo sin acceso remoto.
if rpm -q openssh-server >/dev/null 2>&1; then
  echo "Configurando sshd..."
  sshd_dropin="/etc/ssh/sshd_config.d/30-dotfiles.conf"
  sudo install -m 600 "${repo_root}/etc/ssh/sshd_config.d/30-dotfiles.conf" "${sshd_dropin}"
  if ! sudo sshd -t; then
    sudo rm -f "${sshd_dropin}"
    echo "La configuración de sshd no es válida; se quitó ${sshd_dropin}." >&2
    exit 1
  fi
  if systemctl is-active --quiet sshd; then
    sudo systemctl reload sshd
  fi
fi

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

# Docker: puertos publicados en 127.0.0.1, servicio habilitado y grupo docker
bash "${repo_root}/scripts/install-docker.sh"

# Con el grupo libvirt, virt-manager administra las máquinas del sistema
# (qemu:///system) sin pedir la contraseña
echo "Configurando libvirt..."
if ! id -nG "${user}" | grep -qw libvirt; then
  sudo usermod -aG libvirt "${user}"
  echo "Se agregó ${user} al grupo libvirt; se aplica al volver a iniciar sesión."
fi

# Con el grupo wireshark (lo crea el paquete), Wireshark y tshark capturan sin root:
# dumpcap tiene las capacidades necesarias y solo lo ejecuta ese grupo
echo "Configurando Wireshark..."
if ! id -nG "${user}" | grep -qw wireshark; then
  sudo usermod -aG wireshark "${user}"
  echo "Se agregó ${user} al grupo wireshark; se aplica al volver a iniciar sesión."
fi

# Ajustes de rkhunter (etc/rkhunter.conf.local): sshd sin root y /dev/shm
sudo install -m 644 "${repo_root}/etc/rkhunter.conf.local" /etc/rkhunter.conf.local
# rkhunter compara los archivos del sistema con una base de referencia: se crea
# una vez, recién instalado el sistema (dotfiles-update.sh la actualiza después
# de cada dnf upgrade, para que los cambios de las actualizaciones no sean avisos)
if ! sudo test -s /var/lib/rkhunter/db/rkhunter.dat; then
  echo "Creando la base de referencia de rkhunter..."
  sudo rkhunter --propupd --quiet
fi

# PostgreSQL: clúster, rol y base de desarrollo, pg_stat_statements y ~/.pgpass
bash "${repo_root}/scripts/install-postgresql.sh"

# Servicios locales de desarrollo; con su configuración de Fedora solo escuchan
# en localhost: Valkey (compatible con Redis) y Memcached. Postfix, solo local.
echo "Habilitando Valkey y Memcached..."
sudo systemctl enable --now valkey memcached
bash "${repo_root}/scripts/install-postfix.sh"

# Caddy: HTTPS local (*.lvh.me) delante de los servidores de desarrollo
bash "${repo_root}/scripts/install-caddy.sh"

# MiniDLNA con las carpetas XDG: genera /etc/minidlna.conf para este equipo
bash "${repo_root}/scripts/install-minidlna.sh"

# Zona por defecto de firewalld sin el rango 1025-65535: solo lo que usan los
# servicios de Compartir de GNOME y el descubrimiento en la red
bash "${repo_root}/scripts/install-firewall.sh"

if [[ "$(getent passwd "${user}" | cut -d: -f7)" != "/usr/bin/zsh" ]]; then
  echo "Cambiando la shell de inicio a zsh..."
  sudo usermod -s /usr/bin/zsh "${user}"
fi

echo "Paquetes del sistema instalados."
bash "${repo_root}/scripts/dotfiles-install.sh"
bash "${repo_root}/scripts/extras-install.sh"

echo "Instalación Fedora terminada."
echo "Debe cerrarse la sesión y volver a entrar: grupos docker y libvirt, zsh como shell y extensiones de GNOME."
