# PostgreSQL

Servidor de desarrollo, psql, pgcli y pgFormatter.

[← Volver al índice](README.md)

## PostgreSQL

Los paquetes de servidor, PostGIS y pgRouting están en el bloque DNF.
`scripts/install-postgresql.sh` (lo ejecuta `fedora-install.sh`) deja
PostgreSQL listo para desarrollo (si ya está hecho, no repite nada):

- inicializa el clúster (`postgresql-setup --initdb`) y habilita el servicio;
- en `pg_hba.conf`, cambia la autenticación de las conexiones TCP locales
  (`127.0.0.1` y `::1`) de `ident`, el valor de Fedora, a contraseña
  (`scram-sha-256`), porque `PGHOST=localhost` conecta por TCP y con `ident`
  falla;
- crea el rol `developer` (superusuario, contraseña `developer`) y la base
  `development`, que coinciden con las variables de abajo;
- guarda la contraseña en `~/.pgpass` (modo 600), que leen `psql`, `pgcli` y
  `psqlx`: no se exporta `PGPASSWORD`, que heredaría cada proceso.

A mano:

```bash
sudo postgresql-setup --initdb
sudo sed -i -E 's/^(host +all +all +(127\.0\.0\.1\/32|::1\/128) +)ident$/\1scram-sha-256/' /var/lib/pgsql/data/pg_hba.conf
sudo systemctl enable --now postgresql
sudo -u postgres createuser --superuser --pwprompt developer
sudo -u postgres createdb --owner developer development
echo 'localhost:5432:*:developer:developer' >> ~/.pgpass && chmod 600 ~/.pgpass
```

La unidad systemd en Fedora es `postgresql`.

**Variables por defecto** (`zsh/zshenv`), solo si no están ya definidas:

| Variable     | Valor         |
| ------------ | ------------- |
| `PGHOST`     | `localhost`   |
| `PGPORT`     | `5432`        |
| `PGUSER`     | `developer`   |
| `PGDATABASE` | `development` |

Un proyecto puede sobrescribirlas con `.env` o `direnv`.

**Bases plantilla:** `postgresql/template_full.sql` (collation `en_GB`) y
`postgresql/template_full_es.sql` (collation `es_CL`) crean las plantillas
`template_full` y `template_full_es`, con PostGIS (ráster, topología, SFCGAL),
pgRouting, plpython3u, plperl, `citext`, `unaccent`, `pg_trgm`, `fuzzystrmatch`,
`uuid-ossp`, `hstore`, `pgcrypto` y otras. Se cargan a mano, una vez, y luego
cada proyecto se crea a partir de una de ellas:

```bash
psql -d postgres -f postgresql/template_full_es.sql
createdb -T template_full_es mi_proyecto
```

**Herramientas en zsh** (`zsh/zshfunctions` y alias):

| Comando              | Acción                                        |
| -------------------- | --------------------------------------------- |
| `pgstart` / `pgstop` | Arrancar / parar el servicio                  |
| `pgstatus`           | Consultar el estado del servicio              |
| `pglog`              | Seguir los registros (`journalctl`)           |
| `psqlx`              | Abrir `psql` con las variables `PG*` actuales |
| `pg`                 | Alias de `pgcli` (si está instalado)          |

**pgcli** se instala con DNF. `~/.config/pgcli/config` es un enlace a
`pgcli/config`, con solo lo propio (el estilo y los colores Dracula); pgcli
toma el resto de su configuración por defecto.

## psql (`~/.psqlrc`)

`postgresql/psqlrc` se enlaza como `~/.psqlrc`. Para abrir psql sin él:
`psql -X`.

- **Resultados:** NULL se muestra como `∅` (distinto de una cadena vacía),
  bordes Unicode, formato expandido (`\x auto`) cuando una tabla no cabe a lo
  ancho y duración de cada consulta (`\timing`).
- **Paginador:** [pspg](https://github.com/okbob/pspg) (bloque DNF), hecho para
  tablas: columnas fijas, búsqueda y ratón. Lo que cabe en una pantalla se
  muestra sin paginar y el resultado queda en pantalla al salir. Sin pspg, se
  usa el de `PAGER`.
- **Historial:** uno por base de datos, en `~/.local/state/psql/` (lo crea
  `dotfiles-install.sh`), sin duplicados consecutivos.
- **Errores:** en una transacción abierta, un error al escribir a mano no la
  aborta entera: se deshace solo esa orden (`ON_ERROR_ROLLBACK interactive`).
- **Prompt:** `usuario@servidor:base`, con `*` si hay una transacción abierta y
  `!` si falló.
- **Completado:** las palabras clave salen en mayúsculas.

**Atajos:** se escriben solos en una línea, con dos puntos; `:ayuda` los lista.

| Atajo              | Muestra                                                     |
| ------------------ | ----------------------------------------------------------- |
| `:actividad`       | Conexiones activas, con su duración y su consulta           |
| `:bloqueos`        | Procesos bloqueados y quién los bloquea                     |
| `:lentas`          | Las 20 consultas con más tiempo total (pg_stat_statements)  |
| `:tamanos`         | Las 20 tablas, índices y vistas materializadas más grandes  |
| `:bases`           | Bases de datos del servidor, con su dueño y su tamaño       |
| `:indices_sin_uso` | Índices nunca usados (sin los únicos ni las claves)         |
| `:cache`           | Porcentaje de lecturas servidas desde la caché              |
| `:vacuum`          | Tablas con más filas muertas y su último VACUUM y ANALYZE   |
| `:ajustes`         | Ajustes del servidor distintos de su valor por defecto      |
| `:servidor`        | Versión y tiempo desde el arranque                          |

**pg_stat_statements:** `:lentas` necesita esta extensión (paquete
`postgresql-contrib`). `scripts/install-postgresql.sh` la precarga en el
servidor (`shared_preload_libraries`, con `ALTER SYSTEM`; requiere reiniciar
PostgreSQL) y la crea en la base `development`. En otra base debe crearse a
mano:

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

## pgFormatter (`pg_format`)

[pgFormatter](https://github.com/darold/pgFormatter) formatea SQL y PL/pgSQL.
**No está en Fedora**; debe compilarse con Perl (paquetes `perl`, `make` y `gcc`
del bloque DNF).

**Instalación** (versión fija, la de `version` y `commit` en el script; si ya
está instalada, no hace nada):

```bash
bash scripts/install-pgformatter.sh
```

Para actualizar, deben cambiarse `version` y `commit` (el del tag del upstream)
en `scripts/install-pgformatter.sh` y ejecutarse de nuevo.
`scripts/check-versions.sh` avisa cuando hay una versión nueva y muestra los dos
valores ([Actualizar](mantenimiento.md#actualizar)).

El script descarga ese commit en `/tmp`, ejecuta `perl Makefile.PL`, `make` y
`sudo make install`, y deja disponible el comando `pg_format`.

En zsh, el alias **`pgfmt`** se activa automáticamente si existe `pg_format`.
