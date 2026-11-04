
BEGIN;

INSERT INTO nomina (id_trabajador, periodo, tipo_paga, bruto, deducciones)
SELECT t.id_trabajador,
       p.periodo,
       p.tipo_paga,
       1100 + t.id_trabajador * 90 + (extract(year FROM p.periodo)::int - 2010) * 20,
       round((1100 + t.id_trabajador * 90 + (extract(year FROM p.periodo)::int - 2010) * 20) * 0.19, 2)
FROM trabajador t
CROSS JOIN (
    SELECT d::date AS periodo, 'ORDINARIA' AS tipo_paga
      FROM generate_series(date '2010-01-01', date '2025-12-01', interval '1 month') d
    UNION ALL
    SELECT d::date, 'EXTRA_JUNIO'
      FROM generate_series(date '2010-06-01', date '2025-06-01', interval '1 year') d
    UNION ALL
    SELECT d::date, 'EXTRA_DICIEMBRE'
      FROM generate_series(date '2010-12-01', date '2025-12-01', interval '1 year') d
) p;

COMMIT;
ANALYZE nomina;
