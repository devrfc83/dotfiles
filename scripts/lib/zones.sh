# shellcheck shell=bash
# Zonas de firewalld de estos dotfiles: la de casa y la de fuera de casa. Las usan
# install-firewall.sh, que las configura, e install-minidlna.sh. Se carga con source.

# Casa: las conexiones marcadas con install-firewall.sh --casa. Ahí se abren
# MiniDLNA, ssh, los servicios de Compartir de GNOME y el alias www.
# shellcheck disable=SC2034
zone_home="FedoraWorkstation"

# Fuera de casa: la zona por defecto, para toda conexión sin zona propia (una red
# nueva o ajena). Sin ssh.
# shellcheck disable=SC2034
zone_away="public"
