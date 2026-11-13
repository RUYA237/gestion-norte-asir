-- Resincroniza las secuencias de las columnas IDENTITY tras cargar datos con ids explicitos.
-- Se ejecuta despues de seed_datos_prueba.sql y carga_nominas_historico.sql (apartado 6.2.6).
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT table_name, column_name FROM information_schema.columns
           WHERE table_schema = 'public' AND is_identity = 'YES' LOOP
    EXECUTE format('SELECT setval(pg_get_serial_sequence(%L, %L), coalesce(max(%I), 0) + 1, false) FROM %I',
                   r.table_name, r.column_name, r.column_name, r.table_name);
  END LOOP;
END $$;