#!/usr/bin/env bash
set -euo pipefail

# Deja PostgreSQL listo para desarrollo (paquetes de packages.txt, del repositorio
# PGDG: etc/yum.repos.d/pgdg.repo):
# - el clúster inicializado (PGDG ya pide contraseña, scram-sha-256, en las
#   conexiones TCP locales);
# - el servicio postgresql-<versión> habilitado, con el alias postgresql.service
#   (lo usan pgstart, pgstop, pgstatus y pglog de zsh/zshfunctions);
# - el rol y la base de desarrollo, que coinciden con las variables PG* de
#   zsh/zshenv, y la contraseña en ~/.pgpass;
# - pg_stat_statements precargado y creado en la base de desarrollo.
# Lo ejecuta fedora-install.sh; puede ejecutarse varias veces (sin sudo).

# ~/.pgpass es del usuario que ejecuta el script
if ((EUID == 0)); then
  echo "Este script debe ejecutarse como usuario normal, sin sudo." >&2
  exit 1
fi

# Versión mayor: la misma de los paquetes de packages.txt y de pgdg.repo (para
# cambiarla, docs/postgresql.md)
pg_version="19"
if ! rpm -q "postgresql${pg_version}-server" >/dev/null 2>&1; then
  echo "No está instalado postgresql${pg_version}-server (packages.txt)." >&2
  exit 1
fi

# Clúster, rol y base de desarrollo; el rol y la base coinciden con las variables
# PG* de zsh/zshenv, y la contraseña queda en ~/.pgpass.
echo "Configurando PostgreSQL ${pg_version}..."
pg_data="/var/lib/pgsql/${pg_version}/data"
pg_unit="postgresql-${pg_version}.service"
pg_role="developer"
pg_password="developer"
pg_database="development"
if ! sudo test -f "${pg_data}/PG_VERSION"; then
  sudo "/usr/pgsql-${pg_version}/bin/postgresql-${pg_version}-setup" initdb
fi
# Alias: systemctl start postgresql arranca postgresql-<versión>
alias_link="/etc/systemd/system/postgresql.service"
if [[ "$(readlink "${alias_link}" 2>/dev/null)" != "/usr/lib/systemd/system/${pg_unit}" ]]; then
  sudo ln -sfn "/usr/lib/systemd/system/${pg_unit}" "${alias_link}"
  sudo systemctl daemon-reload
  echo "Alias     postgresql.service -> ${pg_unit}"
fi
sudo systemctl enable --now "${pg_unit}"
# cd /: el usuario postgres no puede leer el directorio actual
(cd / && sudo -u postgres psql -q -v ON_ERROR_STOP=1) <<SQL
SELECT 'CREATE ROLE ${pg_role} LOGIN SUPERUSER PASSWORD ''${pg_password}'''
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${pg_role}')\gexec
SELECT 'CREATE DATABASE ${pg_database} OWNER ${pg_role}'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${pg_database}')\gexec
SQL

# pg_stat_statements (estadísticas de las consultas; atajo :lentas de
# postgresql/psqlrc): se precarga en el servidor, lo que requiere reiniciarlo, y
# se crea en la base de desarrollo. ALTER SYSTEM lo guarda en postgresql.auto.conf.
preload="$(cd / && sudo -u postgres psql -XAtc 'SHOW shared_preload_libraries')"
if [[ ",${preload// /}," != *,pg_stat_statements,* ]]; then
  (cd / && sudo -u postgres psql -Xq -v ON_ERROR_STOP=1 \
    -c "ALTER SYSTEM SET shared_preload_libraries = '${preload:+${preload}, }pg_stat_statements'")
  sudo systemctl restart postgresql
  echo "Precargado pg_stat_statements (PostgreSQL reiniciado)"
fi
(cd / && sudo -u postgres psql -Xq -v ON_ERROR_STOP=1 -d "${pg_database}" \
  -c 'CREATE EXTENSION IF NOT EXISTS pg_stat_statements')

# Contraseña del rol en ~/.pgpass (la leen psql y pgcli), no en el entorno.
# Se agrega la línea si falta, sin tocar las de otros servidores.
pgpass="${HOME}/.pgpass"
pgpass_entry="localhost:5432:*:${pg_role}:${pg_password}"
touch "${pgpass}"
chmod 600 "${pgpass}"
if ! grep -qxF "${pgpass_entry}" "${pgpass}"; then
  echo "${pgpass_entry}" >>"${pgpass}"
  echo "Agregado ${pg_role}@localhost a ${pgpass}"
fi
