-- Auditoria de lecturas con pgaudit (apartado 6.3.5 de la memoria).
-- Se ejecuta como admin en gestion_norte.
-- Requisito previo: el contenedor arranca con shared_preload_libraries=pgaudit (svc/postgres.container).
CREATE EXTENSION IF NOT EXISTS pgaudit;
CREATE ROLE gn_pgaudit NOLOGIN;
GRANT SELECT ON nomina, cuenta_bancaria, trabajador TO gn_pgaudit;
ALTER DATABASE gestion_norte SET pgaudit.role = 'gn_pgaudit';
ALTER DATABASE gestion_norte SET pgaudit.log = 'ddl, role';
ALTER DATABASE gestion_norte SET pgaudit.log_parameter = off;
ALTER SYSTEM SET log_line_prefix = '%m [%p] %u@%d ';
SELECT pg_reload_conf();