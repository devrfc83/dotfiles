#!/usr/bin/env bash
set -euo pipefail

# Deja PostgreSQL listo para desarrollo (paquetes de packages.txt):
# - el clúster inicializado, con contraseña (scram-sha-256) en las conexiones TCP
#   locales;
# - el rol y la base de desarrollo, que coinciden con las variables PG* de
#   zsh/zshenv, y la contraseña en ~/.pgpass;
# - pg_stat_statements precargado y creado en la base de desarrollo.
# Lo ejecuta fedora-install.sh; puede ejecutarse varias veces (sin sudo).

# ~/.pgpass es del usuario que ejecuta el script
if ((EUID == 0)); then
  echo "Este script debe ejecutarse como usuario normal, sin sudo." >&2
  exit 1
fi

if ! rpm -q postgresql-server >/dev/null 2>&1; then
  echo "No está instalado postgresql-server (packages.txt)." >&2
  exit 1
fi

# Clúster, rol y base de desarrollo; el rol y la base coinciden con las variables
# PG* de zsh/zshenv, y la contraseña queda en ~/.pgpass. Fedora autentica las
# conexiones TCP locales con ident, que no sirve para PGHOST=localhost: se
# cambian a contraseña (scram-sha-256).
echo "Configurando PostgreSQL..."
pg_data="/var/lib/pgsql/data"
pg_role="developer"
pg_password="developer"
pg_database="development"
if ! sudo test -f "${pg_data}/PG_VERSION"; then
  sudo postgresql-setup --initdb
fi
sudo sed -i -E \
  's/^(host[[:space:]]+all[[:space:]]+all[[:space:]]+(127\.0\.0\.1\/32|::1\/128)[[:space:]]+)ident$/\1scram-sha-256/' \
  "${pg_data}/pg_hba.conf"
sudo systemctl enable --now postgresql
sudo systemctl reload postgresql
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

# Contraseña del rol en ~/.pgpass (la leen psql, pgcli y psqlx), no en el entorno.
# Se agrega la línea si falta, sin tocar las de otros servidores.
pgpass="${HOME}/.pgpass"
pgpass_entry="localhost:5432:*:${pg_role}:${pg_password}"
touch "${pgpass}"
chmod 600 "${pgpass}"
if ! grep -qxF "${pgpass_entry}" "${pgpass}"; then
  echo "${pgpass_entry}" >>"${pgpass}"
  echo "Agregado ${pg_role}@localhost a ${pgpass}"
fi
