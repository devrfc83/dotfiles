# Seguridad

Herramientas para revisar que los equipos propios no estén expuestos: puertos y
servicios abiertos, configuración del sistema, rootkits, servidores web y
aplicaciones en desarrollo. Deben usarse solo en equipos y redes propios o con
autorización de su dueño.

[← Volver al índice](README.md)

## Herramientas

| Herramienta   | Para qué                                                      | De dónde                             |
| ------------- | ------------------------------------------------------------- | ------------------------------------ |
| **nmap**      | Puertos abiertos y servicios que responden en ellos           | DNF                                  |
| **lynis**     | Auditoría de la configuración del sistema, con sugerencias    | DNF                                  |
| **rkhunter**  | Rootkits y cambios en los archivos del sistema                | DNF                                  |
| **wireshark** | Captura y análisis de tráfico (también `tshark`, en terminal) | DNF                                  |
| **nikto**     | Problemas conocidos de servidores web                         | Upstream, `scripts/install-nikto.sh` |
| **sqlmap**    | Inyección SQL en aplicaciones propias                         | pipx (PyPI)                          |

Los de DNF están en la sección «Seguridad» de `packages.txt`, junto con los
módulos de Perl que necesita nikto. nikto y sqlmap no están en Fedora:
`scripts/extras-install.sh` instala nikto en una versión fija
(`scripts/check-versions.sh` avisa cuando hay una nueva) y sqlmap con pipx
(`scripts/dotfiles-update.sh` lo actualiza con `pipx upgrade-all`).

`scripts/fedora-install.sh` además agrega el usuario al grupo `wireshark`, para
capturar sin `root` (se aplica al volver a iniciar sesión), y crea la base de
referencia de rkhunter.

## Qué expone este equipo

Los servicios que configuran estos dotfiles escuchan casi todos solo en
`localhost`:

| Servicio      | Puerto             | Alcance                                                                    |
| ------------- | ------------------ | -------------------------------------------------------------------------- |
| MiniDLNA      | 8200/tcp, 1900/udp | **Red de casa**: abiertos en firewalld ([MiniDLNA](servicios.md#minidlna)) |
| `www` (alias) | 8000/tcp           | **Red de casa**, mientras se ejecuta (permitido en el firewall)            |
| sshd          | 22/tcp             | **Red de casa** (con contraseña; sin `root`)                               |
| PostgreSQL    | 5432/tcp           | `localhost`                                                                |
| Valkey        | 6379/tcp           | `localhost`                                                                |
| Memcached     | 11211/tcp          | `localhost`                                                                |
| Postfix       | 25/tcp             | `localhost` (solo entrega local)                                           |

Un ejemplo de lo que encuentran estas herramientas: MiniDLNA anuncia en la
cabecera `Server` la versión del kernel y la suya propia a toda la red de casa
(`nikto -h http://127.0.0.1:8200` lo muestra).

### Zonas: casa y fuera de casa

firewalld aplica a cada conexión la zona que tenga asignada en NetworkManager y,
si no tiene, la zona por defecto. `scripts/install-firewall.sh` (lo ejecuta
`fedora-install.sh`) reparte el equipo en dos zonas (`scripts/lib/zones.sh`):

- **Casa** (`FedoraWorkstation`): las conexiones marcadas con `--casa`. Es la
  única con MiniDLNA, ssh, el alias `www` y los servicios de **Configuración →
  Compartir**.
- **Fuera de casa** (`public`): la zona por defecto, así que toda red nueva o
  ajena (un café, un hotel) queda en ella. Solo permite DHCPv6 y mDNS; el
  script le quita ssh.

En un equipo recién instalado ninguna conexión es de casa: el script lo avisa y
debe marcarse la red de casa (el nombre de la conexión, o su UUID, de
`nmcli connection show`):

```bash
bash scripts/install-firewall.sh --casa "Mi red Wi-Fi" --casa "Conexión cableada 1"
bash scripts/install-firewall.sh --mostrar   # ver los cambios sin aplicarlos
```

La zona de casa permite de fábrica todos los puertos del 1025 al 65535, TCP y
UDP: cualquier programa que escuche en todas las interfaces en esos puertos
queda accesible en la red (un servidor de desarrollo con `--host 0.0.0.0`, un
contenedor...). El script quita ese rango y permite solo lo que usan los
servicios de Compartir que estén instalados y el descubrimiento en la red:

| Permite                         | Para                                                                     |
| ------------------------------- | ------------------------------------------------------------------------ |
| `rdp` (3389/tcp) y 3390/tcp     | Escritorio remoto: inicio de sesión remoto y compartir la sesión         |
| 32768–60999/tcp                 | Compartir archivos (WebDAV), solo si está activado: su puerto es al azar |
| `mdns`, `llmnr`, `llmnr-client` | Anunciar y encontrar equipos y servicios en la red                       |
| `wsdd`, `ws-discovery-client`   | Descubrimiento de equipos Windows/SMB                                    |
| `upnp-client`                   | Respuestas de dispositivos UPnP/DLNA                                     |
| 8000/tcp                        | El alias `www`, para probar sitios desde el móvil                        |

Se mantienen los servicios que ya tenía la zona (`ssh`, `samba-client`,
`minidlna`). El rango 32768–60999/tcp es un compromiso: el servidor WebDAV de
GNOME elige su puerto al azar en el rango efímero del kernel y no se puede
fijar, así que, mientras **Compartir archivos** esté activado, lo que escuche en
ese rango es accesible en casa. Si está desactivado, el rango se cierra; al
activarlo o desactivarlo debe ejecutarse el script de nuevo. Los puertos
habituales de desarrollo (3000, 5173, 8080...) y los de contenedores quedan
cerrados.

### sshd

sshd acepta contraseña, para entrar desde equipos ajenos sin la llave, así que
`fedora-install.sh` instala `etc/ssh/sshd_config.d/30-dotfiles.conf`: sin
`root` (`PermitRootLogin no`), con 3 intentos por conexión (`MaxAuthTries`,
que cuenta también las llaves que ofrece el agente) y 30 segundos para
autenticarse (`LoginGraceTime`). Antes de recargar sshd comprueba la
configuración con `sshd -t`; si no es válida, quita el archivo. Fuera de casa
sshd no responde, porque la zona `public` no tiene ssh.

### Contenedores

**Docker** publica los puertos de los contenedores con reglas propias, que
firewalld no filtra; por eso `install-docker.sh` lo configura para publicarlos
en `127.0.0.1` ([Docker](desarrollo.md#docker)). Podman sin `root` no tiene ese
problema: sus puertos pasan por firewalld. Las redes de Compose creadas antes de
ese cambio siguen publicando en todas las interfaces: `install-docker.sh` las
nombra, y se recrean con `docker compose down && docker compose up -d` en cada
proyecto.

**El grupo `docker` equivale a `root`**: quien pertenece a él puede montar todo
el sistema en un contenedor con privilegios. Se mantiene a propósito, porque en
este equipo se usa Docker para algunos proyectos y Podman para otros; cuando
cualquiera de los dos sirve, Podman sin `root` no da ese privilegio.

## Revisar un equipo

**Qué escucha**, desde el mismo equipo y desde otro de la red (lo que ve la red
es lo que importa):

```bash
sudo ss -tulpn                         # sockets abiertos y el proceso de cada uno
sudo firewall-cmd --get-active-zones   # zonas e interfaces
sudo firewall-cmd --list-all           # servicios y puertos permitidos
nmap -sV localhost                     # servicios y versiones, desde el equipo
nmap -sV -p- 192.168.1.10              # todos los puertos TCP, desde otro equipo
sudo nmap -sU --top-ports 50 192.168.1.10   # los UDP más comunes
```

**Configuración del sistema** con lynis: el informe queda en
`/var/log/lynis.log` y `/var/log/lynis-report.dat`, con advertencias y
sugerencias ordenadas por tema.

```bash
sudo lynis audit system
```

**Rootkits y archivos del sistema** con rkhunter. Compara con su base de
referencia, que crea `fedora-install.sh`. `dotfiles-update.sh` revisa antes de
`dnf upgrade` y, solo si no hay avisos, actualiza la base después: así los
cambios de las actualizaciones no aparecen como avisos, pero un cambio ajeno a
ellas no se acepta. Los avisos que resulten ser falsos se permiten en
`/etc/rkhunter.conf.local`.

```bash
sudo rkhunter --check --skip-keypress --report-warnings-only
sudo rkhunter --propupd   # actualizar la base a mano, solo si el sistema está limpio
```

**Servidores web** con nikto (por ejemplo, MiniDLNA o una aplicación en
desarrollo):

```bash
nikto -h http://127.0.0.1:8200
nikto -h https://localhost:8443 -ssl
```

**Inyección SQL** con sqlmap, contra una aplicación propia en desarrollo:

```bash
sqlmap -u "http://localhost:8000/productos?id=1" --batch
```

**Tráfico** con Wireshark (gráfico) o tshark, por ejemplo para ver los anuncios
SSDP con que MiniDLNA se presenta en la red:

```bash
tshark -i any -f "udp port 1900"
```
