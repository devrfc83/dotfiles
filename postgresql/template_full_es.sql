-- =============================================================================
-- Template Database
-- =============================================================================
-- Creates a template database with common extensions for cloning.
--
-- Run as superuser.
--
-- Part 1 creates the DB.
-- Part 2 adds extensions (run connected to the new database).
--
-- Usage:
--   psql -U postgres -f 01_template_full_es.sql
-- =============================================================================
-- -----------------------------------------------------------------------------
-- Part 1: Create template database (run connected to postgres or any DB)
-- -----------------------------------------------------------------------------
-- Drop if exists (optional, for idempotency - comment out in production)
-- DROP DATABASE IF EXISTS template_full_es;
CREATE DATABASE template_full_es WITH OWNER = postgres TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'es_CL.UTF-8' LC_CTYPE = 'es_CL.UTF-8' TABLESPACE = pg_default CONNECTION
LIMIT = -1 IS_TEMPLATE = true;
COMMENT ON DATABASE template_full_es IS 'Template database with PostGIS and common extensions for Spanish projects';
-- -----------------------------------------------------------------------------
-- Part 2: Connect to template_full_es and create extensions
-- -----------------------------------------------------------------------------
-- Run: psql -U postgres -d template_full_es -f 01_template_full.sql
-- Or: \connect template_full_es
\ connect template_full_es -- Core extensions
CREATE EXTENSION IF NOT EXISTS "plpgsql";
CREATE EXTENSION IF NOT EXISTS "plpython3u";
CREATE EXTENSION IF NOT EXISTS "plperl";
-- Geographic/spatial data
CREATE EXTENSION IF NOT EXISTS "postgis";
-- Routing extensions
CREATE EXTENSION IF NOT EXISTS "pgrouting";
-- Raster support
CREATE EXTENSION IF NOT EXISTS "postgis_raster";
-- Topology support
CREATE EXTENSION IF NOT EXISTS "postgis_topology";
-- SFCGAL support
CREATE EXTENSION IF NOT EXISTS "postgis_sfcgal";
-- Case-insensitive text type
CREATE EXTENSION IF NOT EXISTS "citext";
-- Unaccent support
CREATE EXTENSION IF NOT EXISTS "unaccent";
-- Full-text search extensions
CREATE EXTENSION IF NOT EXISTS "fuzzystrmatch";
-- Statistics extensions
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
-- Visibility extensions
CREATE EXTENSION IF NOT EXISTS "pg_visibility";
-- Statistics extensions
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
-- UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- GIN index support for btree
CREATE EXTENSION IF NOT EXISTS "btree_gin";
-- HStore for key-value pairs
CREATE EXTENSION IF NOT EXISTS "hstore";
-- Cryptographic functions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";