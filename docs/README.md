# Documentación

[← Volver al README](../README.md)

| Documento                                        | Contenido                                                                                |
| ------------------------------------------------ | ---------------------------------------------------------------------------------------- |
| [Instalación](instalacion.md)                    | Fuentes de paquetes, scripts, DNF, enlaces y archivos de Nextcloud                       |
| [Terminal](terminal.md)                          | Fuentes, zsh, oh-my-zsh, zoxide, tmux, screen, mc, ripgrep, curl y el clima              |
| [Editores](editores.md)                          | Vim, vimdiff, Meld, VSCodium, Zed, opencode, EditorConfig y pandoc                       |
| [Vim: plugins y atajos](../vim/instrucciones.md) | Referencia de los plugins y atajos de `vim/vimrc`                                        |
| [Desarrollo](desarrollo.md)                      | PHP, Node.js, Python, Rust, Go, Git, gh, doctl, Docker, Podman, Ansible y más            |
| [PostgreSQL](postgresql.md)                      | Servidor de desarrollo, psql (`~/.psqlrc`) y pgFormatter                                 |
| [Servicios locales](servicios.md)                | Valkey, Memcached, Postfix, Caddy, Mailpit, rsyslog, logrotate y MiniDLNA                |
| [Escritorio](escritorio.md)                      | Extensiones de GNOME, Chrome, OnlyOffice, Discord, Bitwarden, gráficos y Flatpak         |
| [Seguridad](seguridad.md)                        | nmap, lynis, rkhunter, Wireshark, nikto, sqlmap, trivy y más; firewall y VPN (WireGuard) |
| [Extras](extras.md)                              | Saludo matutino, diversión en la terminal, ajedrez y emulación                           |
| [Mantenimiento](mantenimiento.md)                | Actualizar, versiones fijas, lint, respaldos y desinstalar                               |

## Qué uso

Cada documento de la tabla explica sus herramientas. La lista de lo que se
instala está en un solo lugar según su tipo:

- [`packages.txt`](../packages.txt) — los paquetes DNF, por secciones;
- [`scripts/extras-install.sh`](../scripts/extras-install.sh) — lo que no está
  en Fedora: rustup, fnm, crates de Cargo, programas de pipx y los compilados
  desde el upstream
  ([de dónde sale cada uno](instalacion.md#fuentes-de-paquetes));
- [`codium/extensions.txt`](../codium/extensions.txt) — las extensiones de
  VSCodium, entre ellas Claude Code;
- [`scripts/lib/links.sh`](../scripts/lib/links.sh) — los archivos que se
  enlazan en `$HOME`.

## Historia

En 1995, cuando comencé a usar Linux, no era común hacer copias de seguridad de
los archivos de configuración. No me preocupé por los respaldos hasta 1998,
principalmente porque volver a aplicar mi configuración después de reinstalar el
sistema era una tarea tediosa.

Decidí comenzar desde cero y mantener mis archivos de configuración organizados
después de obtener mi título de ingeniería en 2024. Entonces descubrí que tenía
varios gigabytes de dotfiles. Después de pasar semanas recopilándolos y
limpiándolos, inicié este repositorio para reorganizarlo todo.

Para simplificar las cosas, opté por eliminar las configuraciones de software
que ya no uso y configurar instalaciones limpias de Linux en mis computadoras
personales para aplicar los fragmentos que encontré interesantes y útiles.
