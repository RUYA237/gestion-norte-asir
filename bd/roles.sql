BEGIN;

DO $$
DECLARE r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['usr_laboral','usr_fiscal','usr_administracion','usr_atencion','usr_auditoria',
                           'gn_laboral','gn_fiscal','gn_administracion','gn_atencion','gn_auditoria']
  LOOP
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
      EXECUTE format('DROP OWNED BY %I', r);
      EXECUTE format('DROP ROLE %I', r);
    END IF;
  END LOOP;
END $$;

CREATE ROLE gn_laboral        NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
CREATE ROLE gn_fiscal         NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
CREATE ROLE gn_administracion NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
CREATE ROLE gn_atencion       NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
CREATE ROLE gn_auditoria      NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;

CREATE ROLE usr_laboral         LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE CONNECTION LIMIT 5 IN ROLE gn_laboral;
CREATE ROLE usr_fiscal          LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE CONNECTION LIMIT 5 IN ROLE gn_fiscal;
CREATE ROLE usr_administracion LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE CONNECTION LIMIT 5 IN ROLE gn_administracion;
CREATE ROLE usr_atencion        LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE CONNECTION LIMIT 5 IN ROLE gn_atencion;
CREATE ROLE usr_auditoria       LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE CONNECTION LIMIT 2 IN ROLE gn_auditoria;

REVOKE ALL ON DATABASE gestion_norte FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM PUBLIC;

GRANT CONNECT ON DATABASE gestion_norte TO gn_laboral, gn_fiscal, gn_administracion, gn_atencion, gn_auditoria;
GRANT USAGE ON SCHEMA public TO gn_laboral, gn_fiscal, gn_administracion, gn_atencion, gn_auditoria;

GRANT SELECT, INSERT, UPDATE ON trabajador, nomina, documento TO gn_laboral;
GRANT SELECT ON cliente, contratacion, servicio, departamento, empleado, tipo_documento TO gn_laboral;

GRANT SELECT, INSERT, UPDATE ON obligacion, documento TO gn_fiscal;
GRANT SELECT ON cliente, contratacion, servicio, departamento, empleado, tipo_documento, tipo_obligacion TO gn_fiscal;

GRANT SELECT, INSERT, UPDATE ON factura, linea_factura, cuenta_bancaria, contratacion, cliente TO gn_administracion;
GRANT SELECT ON v_factura_total, servicio, departamento, empleado TO gn_administracion;
GRANT INSERT ON auditoria_cambio TO gn_administracion;

GRANT SELECT, INSERT, UPDATE ON cliente, contacto_cliente, consulta TO gn_atencion;
GRANT SELECT ON servicio, contratacion, empleado, departamento TO gn_atencion;

GRANT SELECT ON auditoria_cambio TO gn_auditoria;

COMMIT;
