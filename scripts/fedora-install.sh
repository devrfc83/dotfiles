#!/usr/bin/env bash
set -euo pipefail

if ! command -v dnf >/dev/null 2>&1; then
  echo "Este script requiere dnf (Fedora)." >&2
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

echo "Instalando paquetes base..."
sudo dnf install -y \
  7zip \
  asciiquarium \
  autoconf \
  automake \
  bat \
  bzip2 \
  cbonsai \
  cmatrix \
  composer \
  cowsay \
  direnv \
  doctl \
  espeak-ng \
  eza \
  fastfetch \
  fd-find \
  figlet \
  flatpak \
  fortune-mod \
  fzf \
  gcc \
  git \
  git-lfs \
  gnome-extensions-app \
  gnome-shell-extension-dash-to-dock \
  gnome-shell-extension-just-perfection \
  gtk4-devel \
  gzip \
  jq \
  lolcat \
  logrotate \
  make \
  mc \
  memcached \
  meson \
  minidlna \
  most \
  ncompress \
  ninja-build \
  perl \
  pgcli \
  pgrouting \
  php \
  php-bcmath \
  php-cli \
  php-curl \
  php-fpm \
  php-gd \
  php-imagick \
  php-intl \
  php-mbstring \
  php-memcached \
  php-pecl-pcov \
  php-pgsql \
  php-sodium \
  php-sqlite3 \
  php-xml \
  php-xdebug \
  php-zip \
  postfix \
  postgis \
  postgresql \
  postgresql-contrib \
  postgresql-plperl \
  postgresql-plpython3 \
  postgresql-server \
  python3 \
  python3-pip \
  python3-virtualenv \
  rsyslog \
  screen \
  ShellCheck \
  shfmt \
  sl \
  sqlite \
  tar \
  tmux \
  toilet \
  unrar \
  unzip \
  vala \
  valkey \
  vim \
  vlc \
  vlc-libs \
  vlc-plugins-all \
  wget \
  xclip \
  xz \
  zoxide \
  zsh \
  zstd

echo "Eliminando paquetes no deseados..."
sudo dnf remove -y \
  gnome-tour \
  libreoffice-core \
  unoconv \
  malcontent-control \
  malcontent-ui-libs || true

echo "Configurando Flathub..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "Instalación Fedora terminada."
echo "Siguiente paso: enlazar dotfiles y ejecutar ajustes manuales del README."
