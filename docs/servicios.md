# Servicios locales

Valkey, Memcached, Postfix, Caddy, Mailpit, rsyslog, logrotate y MiniDLNA.

[← Volver al índice](README.md)

## Rsyslog y logrotate

**rsyslog** y **logrotate** se instalan con el bloque DNF. Rsyslog recibe y
escribe registros del sistema; logrotate rota y comprime los archivos en
`/var/log` según reglas en `/etc/logrotate.d/`.

### Escuchar en el puerto 514 (UDP y TCP)

Por defecto, rsyslog en Fedora no abre el puerto 514 para tráfico remoto. Debe
crearse un fragmento en `/etc/rsyslog.d/` (por ejemplo `listen-514.conf`):

```
module(load="imudp")
input(type="imudp" port="514")

module(load="imtcp")
input(type="imtcp" port="514")
```

Debe reiniciarse el servicio y habilitarse al arranque:

```bash
sudo systemctl enable --now rsyslog
sudo systemctl restart rsyslog
```

Puede comprobarse que escucha en 514 con:

```bash
sudo ss -ulnp | grep ':514'
sudo ss -tlnp | grep ':514'
```

**Firewall (firewalld):** deben abrirse UDP y TCP en el puerto 514 de forma
permanente:

```bash
sudo firewall-cmd --permanent --add-port=514/udp
sudo firewall-cmd --permanent --add-port=514/tcp
sudo firewall-cmd --reload
```

Para comprobar las reglas activas:

```bash
sudo firewall-cmd --list-ports
```

Si el host usa SELinux en modo enforcing y rsyslog no enlaza el puerto, puede
revisarse el contexto con `ausearch` / `audit2why`; el puerto 514 suele estar ya
asociado al tipo `syslogd_port_t`.

Los clientes remotos deben enviar syslog a la IP de este equipo en el puerto
**514** (UDP o TCP, según lo que soporte el emisor).

### Rotación de logs con logrotate

**logrotate** se ejecuta de forma periódica mediante el temporizador systemd
`logrotate.timer` (habitualmente una vez al día). La configuración global está
en `/etc/logrotate.conf`; cada servicio o familia de logs tiene un fichero en
`/etc/logrotate.d/` (por ejemplo `rsyslog`, `nginx`, `httpd`).

Un bloque típico (como en `/etc/logrotate.d/rsyslog`) define la frecuencia,
cuántas copias se conservan y si se comprimen:

```
/var/log/messages
/var/log/secure
/var/log/maillog
/var/log/spooler
/var/log/boot.log
/var/log/cron
{
    missingok
    sharedscripts
    postrotate
        /usr/bin/systemctl kill -s HUP rsyslog.service >/dev/null 2>&1 || true
    endscript
}
```

En Fedora, la frecuencia y el número de rotaciones suelen definirse en
`/etc/logrotate.conf` (`weekly`, `rotate 4`, `compress`, etc.) y aplicarse a los
ficheros listados en cada snippet.

Comandos útiles:

| Comando                                 | Acción                                  |
| --------------------------------------- | --------------------------------------- |
| `sudo logrotate -d /etc/logrotate.conf` | Simular una pasada (modo depuración)    |
| `sudo logrotate -f /etc/logrotate.conf` | Forzar rotación ahora                   |
| `systemctl list-timers logrotate*`      | Ver cuándo se ejecutará el temporizador |

Tras cambiar un fichero en `/etc/logrotate.d/`, no hace falta reiniciar un
servicio; la siguiente ejecución de logrotate aplicará las reglas (o puede
forzarse con `-f`).

## MiniDLNA

**MiniDLNA** (paquete `minidlna`) comparte música, vídeos e imágenes con
clientes DLNA/UPnP de la red (televisores, consolas, VLC, etc.).
`scripts/fedora-install.sh` lo deja funcionando con
`scripts/install-minidlna.sh`, que puede ejecutarse de nuevo en cualquier
momento (sin `sudo`; lo pide cuando hace falta).

### Configuración generada

`/etc/minidlna.conf` no se copia del repositorio: se genera a partir de la
plantilla `etc/minidlna.conf.in` con los datos de cada equipo.

| Ajuste              | Valor generado                                                                    |
| ------------------- | --------------------------------------------------------------------------------- |
| `network_interface` | `lo` y las interfaces Ethernet y Wi-Fi de NetworkManager (sin Docker ni libvirt)  |
| `friendly_name`     | `Servidor DLNA de <nombre> (<equipo>)`, con el nombre del usuario y el del equipo |
| `serial`            | Derivado de `/etc/machine-id` (distinto en cada equipo)                           |
| `media_dir`         | Las carpetas XDG: Música (audio), Vídeos (vídeo) e Imágenes (imágenes)            |

El resto (puerto 8200, `inotify`, rutas de la base de datos y de los registros
del paquete de Fedora, etc.) está en la plantilla. Para cambiar un ajuste, debe
editarse `etc/minidlna.conf.in` y ejecutarse el script; si la configuración
cambió, respalda la anterior como `/etc/minidlna.conf.bak.<fecha>` y reinicia el
servicio. Para ver lo que generaría, sin instalar nada:

```bash
bash scripts/install-minidlna.sh --mostrar
```

MiniDLNA vigila las interfaces: una desconectada (por ejemplo, el cable
Ethernet) se usa cuando se conecta. Si se agrega una interfaz nueva (un
adaptador USB), debe ejecutarse el script otra vez.

### Permisos, SELinux y firewall

El script también:

- da al usuario `minidlna` acceso de solo lectura con ACL: en el home
  (permisos 700) solo puede atravesarlo, sin listarlo; en las carpetas de
  medios, lectura para lo que hay y, por defecto, para lo que se agregue;
- activa el booleano SELinux `minidlna_read_generic_user_content`;
- desactiva **Compartir multimedia** de GNOME (Configuración → Compartir), que
  es otro servidor DLNA (Rygel) con las mismas carpetas: los clientes verían dos
  servidores. MiniDLNA además funciona sin sesión iniciada y permite ajustar el
  intervalo de anuncio (`notify_interval`). «Compartir archivos» (WebDAV de
  `~/Público`) no se toca;
- abre el servicio `minidlna` de firewalld (8200/tcp y 1900/udp, el
  descubrimiento SSDP) solo en la zona de casa (`FedoraWorkstation`; ver
  [Zonas](seguridad.md#zonas-casa-y-fuera-de-casa)): fuera de casa, MiniDLNA no
  se anuncia;
- habilita el servicio `minidlna`.

Basta con copiar archivos en esas carpetas: con `inotify=yes`, aparecen solos en
los clientes.

### Comandos útiles

| Comando                               | Acción                                            |
| ------------------------------------- | ------------------------------------------------- |
| `systemctl status minidlna`           | Estado del servicio                               |
| `journalctl -u minidlna -f`           | Seguir los registros del servicio                 |
| `less /var/log/minidlna/minidlna.log` | Registro del escaneo de medios                    |
| `xdg-open http://localhost:8200/`     | Página de estado (cantidad de archivos, clientes) |

Para reconstruir el índice desde cero (por ejemplo, si un cliente muestra
archivos que ya no existen):

```bash
sudo systemctl stop minidlna
sudo rm -f /var/cache/minidlna/files.db
sudo systemctl start minidlna
```

En **VLC**: _Ver_ → _Listas de reproducción locales_ → _Red universal
plug'n'play_. En un televisor o consola, suele aparecer como servidor de medios
en el menú de red.

## Servicios locales (Valkey, Memcached y Postfix)

`scripts/fedora-install.sh` los habilita junto con PostgreSQL (Postfix, con
`scripts/install-postfix.sh`). Con la configuración de Fedora solo escuchan en
`localhost`:

| Servicio      | Puerto | Para qué                                                                                 |
| ------------- | ------ | ---------------------------------------------------------------------------------------- |
| **Valkey**    | 6379   | Caché, colas y sesiones (compatible con Redis; `valkey-compat-redis` agrega `redis-cli`) |
| **Memcached** | 11211  | Caché (extensión `php-memcached`)                                                        |
| **Postfix**   | 25     | Correo solo local: no entrega fuera del equipo; lo externo rebota al buzón local         |

```bash
systemctl status valkey memcached postfix
redis-cli ping   # PONG
```

Para probar la entrega local, **swaks** (bloque DNF) envía un correo por SMTP y
muestra el diálogo completo con Postfix; el mensaje queda en el buzón local:

```bash
swaks --server localhost --to "$USER@localhost" --header "Subject: prueba"
tail -n 20 "/var/spool/mail/$USER"
```

## Caddy (HTTPS local)

**Caddy** (bloque DNF) es un proxy inverso con HTTPS delante de los servidores
de desarrollo que se ejecutan a mano, con nombres `*.lvh.me`: `lvh.me` es un
dominio real cuyos subdominios resuelven a `127.0.0.1`, así que no hay que
configurar DNS. `scripts/install-caddy.sh` (lo ejecuta `fedora-install.sh`)
instala `etc/caddy/Caddyfile` en `/etc/caddy/Caddyfile` (reemplaza al de
Fedora; se respalda), genera con **mkcert** un certificado para `*.lvh.me` en
`/etc/caddy/certs/`, instala la autoridad de mkcert en el almacén del sistema y
en el de Chrome (`nss-tools`), agrega los nombres a `/etc/hosts` en un bloque
propio (para que funcionen sin conexión) y habilita el servicio. Caddy escucha
solo en `127.0.0.1` (80, que redirige a HTTPS, y 443), así que nada queda
expuesto a la red.

| Nombre                   | Servidor                                        |
| ------------------------ | ----------------------------------------------- |
| `https://laravel.lvh.me` | `php artisan serve` (8000)                      |
| `https://rails.lvh.me`   | `bin/rails server` (3000)                       |
| `https://go.lvh.me`      | Servidor Go (8080)                              |
| `https://flutter.lvh.me` | `flutter run -d web-server` (8080)              |
| `https://sinatra.lvh.me` | `ruby app.rb` (9292)                            |
| `https://reverb.lvh.me`  | `php artisan reverb:start --port=9000`          |
| `https://mailpit.lvh.me` | [Mailpit](#mailpit-correo-de-desarrollo) (8025) |

**Destino del proxy:** Caddy envía las peticiones a `localhost`, no a
`127.0.0.1`. Vite (y otros servidores de Node) escuchan a veces solo en `::1`,
la loopback IPv6: con `127.0.0.1`, Caddy respondía 502 aunque el servidor
estuviera en marcha. Con `localhost` prueba ambas direcciones. Si un servidor
no responde por `https://<nombre>.lvh.me` pero sí con
`curl http://localhost:<puerto>`, el problema no es Caddy.

Para agregar un nombre, se copia un bloque en `etc/caddy/Caddyfile` y se vuelve
a ejecutar el script, que valida el archivo antes de instalarlo y recarga Caddy.
El certificado dura algo más de dos años; el script lo renueva cuando le queda
menos de un mes (o si cambió la autoridad de mkcert). Si Chrome nunca se había
abierto al instalar, aún no tiene almacén de certificados: debe ejecutarse de
nuevo el script después de abrirlo.

```bash
bash scripts/install-caddy.sh
systemctl status caddy
curl -I https://laravel.lvh.me   # 502 si php artisan serve no está en marcha
```

**Laravel detrás del proxy:** la aplicación recibe las peticiones por HTTP desde
`127.0.0.1`, así que debe confiar en el proxy para generar URLs `https://`
(`->trustProxies(at: '127.0.0.1')` en `bootstrap/app.php`) y usar
`APP_URL=https://laravel.lvh.me`. Para Reverb: `REVERB_HOST=reverb.lvh.me`,
`REVERB_PORT=443` y `REVERB_SCHEME=https` en el `.env` (el servidor sigue en el
puerto 9000).

## Mailpit (correo de desarrollo)

**Mailpit** recibe por SMTP todo lo que mandan las aplicaciones en desarrollo y
lo muestra en una interfaz web (HTML, texto, adjuntos, cabeceras), sin
entregarlo a nadie: es lo que Postfix no hace. No está en Fedora:
`scripts/install-mailpit.sh` (lo ejecuta `extras-install.sh`) instala el
binario de los releases del upstream en `~/.local/bin/mailpit`, en una versión
fija y con su sha256 (`scripts/check-versions.sh` avisa cuando hay una nueva),
y habilita la unidad de usuario `systemd/mailpit.service`: SMTP en
`127.0.0.1:1025` y web en `http://localhost:8025` (también
`https://mailpit.lvh.me` por [Caddy](#caddy-https-local)). Los correos se
guardan en `~/.local/share/mailpit/mailpit.db`.

En el `.env` de Laravel:

```dotenv
MAIL_MAILER=smtp
MAIL_HOST=127.0.0.1
MAIL_PORT=1025
MAIL_ENCRYPTION=null
```

```bash
systemctl --user status mailpit
swaks --server 127.0.0.1:1025 --to prueba@lvh.me --header "Subject: prueba"   # aparece en la web
```

## ngrok (exponer un puerto a Internet)

**ngrok** crea un túnel desde una URL pública hasta un puerto de este equipo.
Es lo contrario de Caddy: Caddy solo escucha en `127.0.0.1`; ngrok sale a
Internet, así que se usa a mano y solo mientras haga falta.
`scripts/install-ngrok.sh` (lo ejecuta `extras-install.sh`) instala el binario
en `~/.local/bin/ngrok`, en versión fija con su sha256.

Una vez por equipo, con el token de la cuenta de ngrok (no va en el repositorio;
ver [Secretos locales](terminal.md#secretos-locales-zshsecrets)):

```bash
ngrok config add-authtoken <TOKEN>   # se guarda en ~/.config/ngrok/ngrok.yml
```

```bash
ngrok http 3000     # publica Rails: https://<algo>.ngrok-free.app
ngrok http 8000     # publica php artisan serve
```

Un túnel abierto expone la aplicación a cualquiera que tenga la URL: ciérralo
con `Ctrl-C` al terminar. Con Laravel detrás de ngrok, `APP_URL` debe ser la URL
del túnel, y el proxy debe ser de confianza (`trustProxies`), como con Caddy.
