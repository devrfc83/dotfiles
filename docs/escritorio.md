# Escritorio

Ajustes y extensiones de GNOME, tema de iconos y Flatpak.

[← Volver al índice](README.md)

## Extensiones de GNOME

Las extensiones son paquetes de Fedora incluidos en `packages.txt` (Dash to
Dock, Just Perfection y AppIndicator, más el gestor `gnome-extensions-app`). Sus
valores se guardan en dconf, una base de datos binaria que no se puede enlazar,
así que el repositorio guarda un volcado en `gnome/`:

- `gnome/appindicator.dconf`, `gnome/dash-to-dock.dconf` y
  `gnome/just-perfection.dconf`: los valores de cada extensión (solo los que
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
    color de acento, iconos, fuentes, reloj y calendario, distribución del
    teclado y opciones de XKB, bloqueo de pantalla, notificaciones, ventanas y
    espacios de trabajo, luz nocturna, energía, aplicaciones favoritas del dock,
    ubicación, Archivos (Nautilus) y el selector de archivos.
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

Para agregar un ajuste, se suma su ruta o su clave en
`scripts/lib/gnome-dconf.sh`
y se vuelca de nuevo. Para encontrar la clave de algo que se cambia en
Configuración, `dconf watch /` muestra cada clave que cambia:

```bash
dconf watch /                          # cambiar el ajuste en Configuración
bash scripts/export-gnome-settings.sh  # volcar extensiones y ajustes
git diff gnome/
```

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

## Chromium

Es el navegador predeterminado: `dotfiles-install.sh` lo fija para los enlaces
web y los archivos HTML (`xdg-settings` y `xdg-mime`).

**Políticas:** `fedora-install.sh` copia
`etc/chromium/policies/managed/50-dotfiles.json` en
`/etc/chromium/policies/managed/`. Instala sola la extensión de **Bitwarden**
desde la Chrome Web Store (`installation_mode: normal_installed`): puede
desactivarse, pero no quitarse. Por tener políticas, Chromium muestra
«Administrado por tu organización» en su menú. Se aplican al abrir Chromium;
para verlas, `chrome://policy`.

## Flatpak

Algunas aplicaciones de escritorio se instalan con **Flatpak** (fuera de los
repos DNF habituales).

**Flatpak y Flathub** (configuración única):

```bash
sudo dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

**Vesktop** (cliente de Discord con Vencord):

```bash
flatpak install flathub dev.vencord.Vesktop
```

Puede iniciarse desde el menú de aplicaciones o con:

```bash
flatpak run dev.vencord.Vesktop
```

**Bitwarden** (gestor de contraseñas; no está en Fedora, y Flatpak es la vía
que recomienda Bitwarden para Linux). La extensión de Chromium se instala sola
([Chromium](#chromium)):

```bash
flatpak install flathub com.bitwarden.desktop
```

**Spotify** (música en streaming):

```bash
flatpak install flathub com.spotify.Client
```

Puede iniciarse desde el menú de aplicaciones o con:

```bash
flatpak run com.spotify.Client
```
