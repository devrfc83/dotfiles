# Escritorio

Ajustes y extensiones de GNOME, tema MacTahoe, tema de iconos, cursor,
aplicaciones de escritorio (Chrome, OnlyOffice, Discord, Bitwarden), gráficos y
Flatpak.

[← Volver al índice](README.md)

## Extensiones de GNOME

Las extensiones son paquetes de Fedora incluidos en `packages.txt` (Dash to
Dock, Just Perfection, AppIndicator, Blur my Shell y User Themes, más el gestor
`gnome-extensions-app`). Sus valores se guardan en dconf, una base de datos
binaria que no se puede enlazar, así que el repositorio guarda un volcado en
`gnome/`:

- `gnome/appindicator.dconf`, `gnome/blur-my-shell.dconf`,
  `gnome/dash-to-dock.dconf`, `gnome/just-perfection.dconf` y
  `gnome/user-theme.dconf`: los valores de cada extensión (solo los que
  difieren del valor por defecto; vacío si no se cambió ninguno).
- `gnome/enabled-extensions.txt`: las extensiones activas, una por línea.

`scripts/dotfiles-install.sh` los carga con `dconf load` y activa esas
extensiones; las recién instaladas aparecen al volver a iniciar sesión. Tras
cambiar algo en las preferencias de una extensión, o activar o desactivar una,
debe volcarse de nuevo y hacerse commit (el mismo script vuelca los ajustes del
escritorio; ver [Ajustes de GNOME](#ajustes-de-gnome)):

```bash
bash scripts/export-gnome-settings.sh
git diff gnome/
```

**Fondo de escritorio:** `gnome/background.jpg` se enlaza como
`~/.config/background` (el archivo que crea GNOME al elegir una imagen en
Configuración) y `dotfiles-install.sh` lo fija para el tema claro y el oscuro y
para la pantalla de bloqueo, con ajuste `zoom`. Si no existe la imagen, no
cambia el fondo.

**Foto de perfil:** `profile.webp` es la foto de la cuenta en GNOME (pantalla de
inicio de sesión, menú del sistema y Configuración → Usuarios).
`dotfiles-install.sh` se la pasa a AccountsService, que la copia en
`/var/lib/AccountsService/icons/<usuario>`; solo la cambia si esa copia es
distinta, así que basta con reemplazar `profile.webp` y volver a ejecutarlo.
AccountsService no acepta imágenes de más de 1 MB.

Dash to Dock guarda el monitor preferido por conector (`eDP-1`, la pantalla del
portátil); en un equipo sin ese conector usa el monitor principal.

## Ajustes de GNOME

Además de las extensiones, se versionan los ajustes del escritorio que son
preferencias y no estado de la máquina. dconf solo guarda lo que difiere del
valor por defecto, así que el archivo tiene solo lo que se cambió:

- `gnome/settings.dconf`: un solo archivo con rutas absolutas, que
  `dotfiles-install.sh` carga con `dconf load /` (solo escribe esas claves).
  Incluye:
  - **ramas enteras**, que solo contienen preferencias: atajos de teclado (de
    ventanas, del shell, de mutter y los personalizados), touchpad, ratón y
    teclado, botones de la barra de título, privacidad, recordatorios de pausas,
    tiempo de pantalla y proveedores de búsqueda;
  - **claves sueltas** de ramas que mezclan preferencias y estado: tema oscuro,
    color de acento, tema de GTK, iconos, fuentes, reloj y calendario,
    distribución del teclado y opciones de XKB, bloqueo de pantalla,
    notificaciones, ventanas y espacios de trabajo, luz nocturna, energía,
    aplicaciones favoritas del dock, ubicación, Archivos (Nautilus) y el
    selector de archivos.
- `gnome/alert-sound.txt`: el sonido de alerta, como el nombre de una alerta de
  GNOME (`/usr/share/sounds/gnome/default/alerts/<nombre>.ogg`). Configuración
  lo
  guarda como un tema de sonido propio, `~/.local/share/sounds/__custom`, con
  enlaces a esa alerta; `dotfiles-install.sh` lo vuelve a armar.

Qué se vuelca está en `scripts/lib/gnome-dconf.sh` (`gnome_settings_paths` y
`gnome_settings_keys`). No se vuelcan ramas como
`/org/gnome/desktop/interface/` o la de la luz nocturna enteras: también guardan
tamaños de ventana, carpetas recientes, marcas de tiempo y hasta las
coordenadas del equipo (`night-light-last-coordinates`), que no deben ir a un
repositorio público. La fuente monoespaciada, el fondo y la paleta de Ptyxis no
están en el archivo: los fija `dotfiles-install.sh`.

**Fuentes:** IBM Plex Sans Medium 11 en la interfaz (`font-name`) e IBM Plex
Sans 11 en los documentos (`document-font-name`), del paquete
`ibm-plex-fonts-all`; la monoespaciada es FiraCode Nerd Font Mono 11
([Nerdfonts](terminal.md#nerdfonts)).

Para agregar un ajuste, se suma su ruta o su clave en
`scripts/lib/gnome-dconf.sh`
y se vuelca de nuevo. Para encontrar la clave de algo que se cambia en
Configuración, `dconf watch /` muestra cada clave que cambia:

```bash
dconf watch /                          # cambiar el ajuste en Configuración
bash scripts/export-gnome-settings.sh  # volcar extensiones y ajustes
git diff gnome/
```

## Menú de aplicaciones

El menú de la barra superior (extensión «Menú de aplicaciones», `apps-menu`) se
arma con `gnome/menus/gnome-applications.menu`, que se enlaza en
`~/.config/menus/` y reemplaza por completo al del sistema: solo aparece lo que
está en ese archivo, en su orden. Una aplicación nueva no se agrega sola; para
sumarla, se agrega su `.desktop` en el `<Include>` y el `<Layout>` de su
submenú. La cuadrícula de aplicaciones y la búsqueda no cambian.

Los nombres propios (por ejemplo, «Navegador web» para Google Chrome) están en
`gnome/menus/nombres.txt`; todos llevan mayúscula solo en la primera palabra,
salvo los nombres de marca. `dotfiles-install.sh` genera con ellos copias de los
`.desktop` del sistema en `~/.local/share/applications/` (que tienen prioridad)
y las vuelve a generar en cada ejecución, también desde `dotfiles-update.sh`,
para seguir los cambios de los paquetes. Esos nombres se ven también en la
cuadrícula y en el dock. Las copias no llevan `NotShowIn`, así que sirven
también para mostrar una aplicación que Fedora oculta en GNOME.

## Tema (MacTahoe)

El tema de las ventanas y de la barra superior es
[MacTahoe](https://github.com/vinceliuice/MacTahoe-gtk-theme), en su variante
oscura con acento morado (`MacTahoe-Dark-purple`), que calza con el acento de
GNOME y la paleta Dracula. No está en Fedora:
`scripts/install-mactahoe-theme.sh` (lo ejecuta `extras-install.sh`) lo compila
con el `install.sh` del upstream, en una versión fija, en
`~/.local/share/themes` (no en `~/.themes`). `scripts/check-versions.sh` avisa
cuando hay una versión nueva. Se aplica en cuatro partes:

- **Ventanas GTK 3:** `gtk-theme` en `gnome/settings.dconf`.
- **Barra superior:** la extensión User Themes, con el nombre del tema en
  `gnome/user-theme.dconf`.
- **Aplicaciones libadwaita** (casi todas las de GNOME), que no admiten temas:
  el script copia el CSS del tema en `~/.config/gtk-4.0` (opción `-l` del
  `install.sh`). Esas aplicaciones quedan siempre en oscuro, y una
  actualización de GNOME puede desarreglarlas hasta que el tema se actualice.
  Para volver a Adwaita: borrar `gtk.css`, `gtk-dark.css`, `gtk-Light.css`,
  `gtk-Dark.css`, `assets` y `windows-assets` de `~/.config/gtk-4.0`.
- **Pantalla de inicio de sesión (GDM):** con el `tweaks.sh -g` del upstream y
  sudo, con el fondo del escritorio (`gnome/background.jpg`, desenfocado y
  oscurecido). GNOME no permite cambiarle el tema a GDM, así que se reemplaza un
  archivo del paquete `gnome-shell`,
  `/usr/share/gnome-shell/gnome-shell-theme.gresource`: `rpm -V gnome-shell`
  lo muestra como modificado. Cada actualización de gnome-shell lo restaura; el
  script lo detecta con `rpm -V` y lo vuelve a aplicar (`dotfiles-update.sh`
  corre los extras después de `dnf upgrade`), y también si cambian la versión
  del tema o el fondo. El tema de GDM del upstream está hecho para GNOME 48:
  en versiones más nuevas puede faltar algún detalle. Para volver al de Fedora:
  `sudo dnf reinstall gnome-shell` (no `tweaks.sh -r`, cuyo respaldo no se
  renueva cuando gnome-shell se actualiza).

Los botones de las ventanas van a la izquierda, como en macOS (cerrar,
minimizar, maximizar): `button-layout='close,minimize,maximize:appmenu'`, en
`/org/gnome/desktop/wm/preferences/` de `gnome/settings.dconf`. El
`install.sh` agrega además `gnome-theme-switcher` en `~/.local/bin`, con su
entrada en el menú; el script los borra, porque solo cambia de variante y la
variante es fija.

## Tema de iconos (Tela)

El tema de iconos es [Tela](https://github.com/vinceliuice/Tela-icon-theme)
(`icon-theme` en `gnome/settings.dconf`), que no está en Fedora.
`scripts/install-tela-icons.sh` (lo ejecuta `extras-install.sh`) lo instala en
`~/.local/share/icons` con el `install.sh` del upstream, en una versión fija, y
solo en los colores de `colors` (por defecto, `dracula`, el de la paleta:
Tela-dracula, Tela-dracula-dark y Tela-dracula-light, unos 80 MB; todos los
colores ocupan unos 2,7 GB).
`scripts/check-versions.sh` avisa cuando hay una versión nueva. Si se cambia el
color en `icon-theme`, debe agregarse también en `colors`.

## Cursor (Bibata Modern Ice)

El cursor es [Bibata Modern Ice](https://github.com/ful1e5/Bibata_Cursor)
(`cursor-theme` en `gnome/settings.dconf`), que no está en Fedora.
`scripts/install-bibata-cursor.sh` (lo ejecuta `extras-install.sh`) descarga el
tema ya compilado de los releases del upstream, en una versión fija y con su
sha256, y lo extrae en `~/.local/share/icons` (unos 27 MB).

Para actualizarlo: cuando `scripts/check-versions.sh` (al final de
`dotfiles-update.sh`) avise de una versión nueva, se cambian `version` y
`sha256` en el script (el upstream no publica el checksum: se calcula con
`sha256sum` sobre `Bibata-Modern-Ice.tar.xz`) y el siguiente
`dotfiles-update.sh` la instala.

## Google Chrome

Es el navegador predeterminado: `dotfiles-install.sh` lo fija para los enlaces
web y los archivos HTML (`xdg-settings` y `xdg-mime`). No está en Fedora: viene
del repositorio de Google (`etc/yum.repos.d/google-chrome.repo`, con la huella
de su llave verificada por `fedora-install.sh`), que reemplaza al que trae
deshabilitado `fedora-workstation-repositories`. Flutter lo encuentra solo para
las apps web (busca `google-chrome` en el `PATH`).

**Políticas:** `fedora-install.sh` copia
`etc/opt/chrome/policies/managed/50-dotfiles.json` en
`/etc/opt/chrome/policies/managed/`. Instala sola la extensión de **Bitwarden**
desde la Chrome Web Store (`installation_mode: normal_installed`): puede
desactivarse, pero no quitarse. Por tener políticas, Chrome muestra
«Administrado por tu organización» en su menú. Se aplican al abrir Chrome;
para verlas, `chrome://policy`.

## OnlyOffice

La suite ofimática (documentos, hojas de cálculo y presentaciones, con los
formatos de Microsoft Office como nativos), en lugar de LibreOffice, que
`fedora-install.sh` desinstala. No está en Fedora: viene del repositorio de
OnlyOffice (`etc/yum.repos.d/onlyoffice.repo`, con la huella de su llave
verificada por `fedora-install.sh`). Ese repositorio publica también paquetes
del sistema que reemplazarían a los de Fedora, así que `includepkgs` lo limita
al editor (`onlyoffice-desktopeditors`); se actualiza con `dnf upgrade`.

## Discord

El cliente oficial de **Discord** viene de RPM Fusion nonfree (`discord`, en
`packages.txt`), que ya habilita `fedora-install.sh`; se actualiza con `dnf`.
El correo se lee con **Geary** (`geary`, de Fedora).

## Bitwarden

La aplicación de escritorio de **Bitwarden** (gestor de contraseñas) no está en
Fedora: `scripts/install-bitwarden.sh` (lo ejecuta `extras-install.sh`) instala
el RPM de los releases de GitHub del upstream, en una versión fija y con su
sha256; `check-versions.sh` avisa cuando hay una nueva. La extensión de Chrome
se instala sola ([Google Chrome](#google-chrome)) y la CLI `bw`, con npm.

**bw2kp** exporta el almacén de Bitwarden (Vaultwarden) a una base de KeePassXC
(`KP_PATH`), para poder entrar a las cuentas si el servidor no está disponible.
Necesita `bw` (`extras-install.sh`) y `pykeepass` (`packages.txt`, sección
Python). Se instala como `~/.local/bin/bw2kp`. Cómo traduce cada cosa:

- Cada URI de un elemento genera una entrada, porque KeePassXC solo admite una
  URL por entrada; con varias, el título lleva el sitio entre paréntesis.
- El TOTP va en el atributo `otp`, que KeePassXC usa para sus códigos.
- Los campos personalizados son atributos con su mismo nombre (los ocultos,
  protegidos). Si el nombre choca con uno de KeePassXC o se repite, se le agrega
  un sufijo, como `license (2)`.
- La clave privada de un elemento SSH y los adjuntos van como archivos adjuntos
  de cada entrada; la clave pública y la huella, en las notas. La entrada SSH
  lleva además `KeeAgent.settings`, y con la integración con el agente SSH
  activada (Herramientas → Configuración → SSH Agent), KeePassXC carga la clave
  en el agente al abrir la base y la quita al cerrarla.
- Cada organización es un grupo de primer nivel llamado `Org: ` más su nombre,
  con sus elementos dentro; los personales siguen en sus carpetas.
- Cada passkey va en una entrada propia, con la clave privada en
  `KPEX_PASSKEY_PRIVATE_KEY_PEM` (protegida) y el resto de atributos
  `KPEX_PASSKEY_*`: KeePassXC-Browser inicia sesión con ellas igual que con las
  que registra él mismo (probado en webauthn.io).
- Las tarjetas y las identidades no se respaldan.

Lee de su entorno `BW_SERVER`, `BW_CLIENTID`, `BW_CLIENTSECRET` y `BW_PASSWORD`
(Bitwarden), y `KP_PATH` y `KP_PASSWORD` (la base de KeePassXC). Se definen con
`export` en `~/.zshsecrets`, fuera del repositorio (ver
[Secretos locales](terminal.md#secretos-locales-zshsecrets)). `KP_PASSWORD` debe
ser distinta de `BW_PASSWORD`: con la misma, descubrir una abriría las dos
copias de los secretos, y `bw2kp` no arranca si coinciden.

```bash
bw2kp
```

Sale sin hacer nada si `bw` ya tiene una sesión iniciada, y la base nueva solo
reemplaza a `KP_PATH` cuando está completa. `systemd/bw2kp.timer` lo ejecuta
cada 6 horas (00:00, 06:00, 12:00 y 18:00; si el equipo estaba apagado, al
encenderlo). `dotfiles-install.sh` lo activa solo si `~/.zshsecrets` define
`KP_PASSWORD`:

```bash
systemctl --user list-timers bw2kp.timer   # próxima ejecución
journalctl --user -u bw2kp.service         # resultado de las ejecuciones
```

## Gráficos

Todos del bloque DNF (sección «Gráficos» de `packages.txt`):

| Programa        | Para qué                                                           |
| --------------- | ------------------------------------------------------------------ |
| **GIMP**        | Edición de imágenes                                                |
| **Inkscape**    | Gráficos vectoriales (SVG)                                         |
| **darktable**   | Revelado de fotos RAW                                              |
| **Shotwell**    | Organizar fotos y retoques rápidos (recorte, exposición, color)    |
| **ImageMagick** | `magick`: convertir, redimensionar y componer imágenes en terminal |

```bash
magick foto.jpg -resize 50% foto.webp            # formato y tamaño
magick '*.png' -quality 85 miniatura-%02d.jpg    # un lote
magick identify -verbose foto.jpg | head         # metadatos
```

## Flatpak

Algunas aplicaciones de escritorio se instalan con **Flatpak** (fuera de los
repos DNF habituales).

**Flatpak y Flathub** (configuración única):

```bash
sudo dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

**Spotify** (música en streaming) se instala solo: está en la lista
`flatpak_apps` de `scripts/extras-install.sh`, que instala cada aplicación de
Flathub en la instalación del sistema; `dotfiles-update.sh` las actualiza con
`flatpak update`. Para agregar otra aplicación de Flathub, se suma su
identificador a esa lista.

Spotify corre por X11 (XWayland): por Wayland muestra un panel azul encima de
la ventana. Lo fijan dos archivos de `spotify/` que enlaza
`dotfiles-install.sh`:

- `flatpak-override`, en
  `~/.local/share/flatpak/overrides/com.spotify.Client`: le da acceso a X11
  (es lo que escribe `flatpak override --user --socket=x11 com.spotify.Client`).
- `spotify-flags.conf`, en `~/.var/app/com.spotify.Client/config/`: le pasa
  `--ozone-platform=x11`.

`flatpak override` reemplaza el archivo en vez de editar el enlace: si se usa
para otro cambio, debe copiarse el resultado a `spotify/flatpak-override`.
