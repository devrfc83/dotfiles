-- =============================================================================
-- Base de datos plantilla: template_full_es
-- =============================================================================
-- Crea una base plantilla con PostGIS, pgRouting y extensiones de uso común
-- (collation es_CL, para proyectos en castellano), para clonarla en cada proyecto:
--
--   createdb -T template_full_es mi_proyecto
--
-- Debe ejecutarse como superusuario (postgres o developer), conectado a otra
-- base (por ejemplo, postgres):
--
--   psql -d postgres -f postgresql/template_full_es.sql
--
-- La parte 1 crea la base; la parte 2 se conecta a ella y crea las extensiones.
-- Con ON_ERROR_STOP, psql se detiene en el primer error: sin eso, si falla la
-- conexión, las extensiones se crearían en la base actual.
-- =============================================================================

\set ON_ERROR_STOP on

-- -----------------------------------------------------------------------------
-- Parte 1: crear la base plantilla
-- -----------------------------------------------------------------------------
-- Para volver a crearla (una plantilla no se puede borrar sin desmarcarla):
--   ALTER DATABASE template_full_es IS_TEMPLATE = false;
--   DROP DATABASE template_full_es;
CREATE DATABASE template_full_es
    WITH OWNER = postgres
    TEMPLATE = template0
    ENCODING = 'UTF8'
    LC_COLLATE = 'es_CL.UTF-8'
    LC_CTYPE = 'es_CL.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = true;

COMMENT ON DATABASE template_full_es IS 'Template database with PostGIS and common extensions for Spanish projects';

-- -----------------------------------------------------------------------------
-- Parte 2: extensiones, dentro de template_full_es
-- -----------------------------------------------------------------------------
\connect template_full_es

-- Lenguajes procedurales
CREATE EXTENSION IF NOT EXISTS "plpgsql";
CREATE EXTENSION IF NOT EXISTS "plpython3u";
CREATE EXTENSION IF NOT EXISTS "plperl";
-- Datos geográficos
CREATE EXTENSION IF NOT EXISTS "postgis";
-- Rutas sobre grafos (pgRouting)
CREATE EXTENSION IF NOT EXISTS "pgrouting";
-- Datos ráster
CREATE EXTENSION IF NOT EXISTS "postgis_raster";
-- Topología
CREATE EXTENSION IF NOT EXISTS "postgis_topology";
-- Geometría 3D y operaciones avanzadas (SFCGAL)
CREATE EXTENSION IF NOT EXISTS "postgis_sfcgal";
-- Texto sin distinguir mayúsculas
CREATE EXTENSION IF NOT EXISTS "citext";
-- Búsqueda sin acentos
CREATE EXTENSION IF NOT EXISTS "unaccent";
-- Comparación aproximada de cadenas (levenshtein, soundex)
CREATE EXTENSION IF NOT EXISTS "fuzzystrmatch";
-- Búsqueda por similitud de trigramas (índices para LIKE e ILIKE)
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
-- Inspección del mapa de visibilidad
CREATE EXTENSION IF NOT EXISTS "pg_visibility";
-- Estadísticas de consultas (registra datos solo con
-- shared_preload_libraries = 'pg_stat_statements' en postgresql.conf)
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
-- Generación de UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- Índices GIN sobre tipos de btree
CREATE EXTENSION IF NOT EXISTS "btree_gin";
-- Pares clave-valor
CREATE EXTENSION IF NOT EXISTS "hstore";
-- Funciones criptográficas
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
