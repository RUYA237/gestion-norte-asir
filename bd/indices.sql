-- Indice de la medicion de rendimiento (apartado 6.5 de la memoria).
-- Acelera las consultas que filtran nomina por periodo.
CREATE INDEX ix_nomina_periodo ON nomina (periodo);
ANALYZE nomina;