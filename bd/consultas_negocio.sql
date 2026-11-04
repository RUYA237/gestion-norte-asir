-- =====================================================================
-- Gestión Norte · Consultas de negocio (10)
-- Cada consulta indica el caso de uso: quién la usaría y para qué.
-- Se ejecutan con admin; en producción cada una correría con el rol
-- del departamento que la necesita (se indica entre paréntesis).
-- =====================================================================
\pset pager off

-- 1. Obligaciones vencidas y sin presentar, con cliente, modelo, responsable y días de retraso.
-- Caso de uso: control diario de plazos del equipo fiscal (rol gn_fiscal). Un plazo
-- incumplido en campaña genera recargos para el cliente, así que se revisa cada mañana.
select c.nif, c.denominacion, t.codigo as modelo, o.periodo, o.fecha_limite,
       current_date - o.fecha_limite as dias_retraso, e.usuario_ad as responsable
from obligacion o
join cliente c on c.id_cliente = o.id_cliente
join tipo_obligacion t on t.id_tipo_obligacion = o.id_tipo_obligacion
join empleado e on e.id_empleado = o.id_empleado_responsable
where o.estado = 'PENDIENTE' and o.fecha_limite < current_date
order by dias_retraso desc, c.nif
limit 15;

-- 2. Facturas impagadas con su importe total y antigüedad de la deuda.
-- Caso de uso: administración prepara las reclamaciones de cobro (rol gn_administracion),
-- empezando por las deudas más antiguas. El total sale de la vista v_factura_total.
select f.numero, c.denominacion, f.fecha_emision, v.total,
       current_date - f.fecha_emision as dias_desde_emision
from factura f
join v_factura_total v on v.id_factura = f.id_factura
join cliente c on c.id_cliente = f.id_cliente
where f.estado_cobro = 'IMPAGADA'
order by dias_desde_emision desc, f.numero
limit 15;

-- 3. Clientes cuya deuda acumulada (facturas impagadas o pendientes con más de 30 días) supera 500 euros.
-- Caso de uso: dirección decide a qué clientes se les reclama formalmente o se les
-- suspende un servicio. Agrupa por cliente y filtra con HAVING sobre la suma.
select c.nif, c.denominacion, count(*) as facturas_adeudadas, sum(v.total) as deuda_total
from cliente c
join factura f on f.id_cliente = c.id_cliente
join v_factura_total v on v.id_factura = f.id_factura
where f.estado_cobro = 'IMPAGADA'
   or (f.estado_cobro = 'PENDIENTE' and f.fecha_emision < current_date - 30)
group by c.id_cliente, c.nif, c.denominacion
having sum(v.total) > 500
order by deuda_total desc
limit 15;

-- 4. Ingresos mensuales recurrentes por departamento y servicio (contratos activos).
-- Caso de uso: cuadro de mando de gerencia. Muestra qué servicios sostienen la facturación
-- y cuántos contratos hay detrás de cada uno.
select d.nombre as departamento, s.nombre as servicio,
       count(*) as contratos_activos, sum(ct.cuota_mensual) as cuota_mensual_total
from contratacion ct
join servicio s on s.id_servicio = ct.id_servicio
join departamento d on d.id_departamento = s.id_departamento
where ct.fecha_baja is null
group by d.id_departamento, d.nombre, s.id_servicio, s.nombre
order by cuota_mensual_total desc;

-- 5. Carga de clientes por empleado: contratos activos y clientes distintos, incluyendo a quien no lleva ninguno.
-- Caso de uso: el responsable de cada departamento reparte los clientes nuevos al compañero
-- con menos carga. El LEFT JOIN hace que aparezcan también los empleados sin contratos.
select e.usuario_ad, d.nombre as departamento, e.sede,
       count(ct.id_contratacion) as contratos_activos,
       count(distinct ct.id_cliente) as clientes
from empleado e
join departamento d on d.id_departamento = e.id_departamento
left join contratacion ct on ct.id_empleado_responsable = e.id_empleado and ct.fecha_baja is null
where e.activo = true
group by e.id_empleado, e.usuario_ad, d.nombre, e.sede
order by contratos_activos asc, e.usuario_ad;

-- 6. Clientes activos que no han contactado con la asesoría en los últimos 30 días.
-- Caso de uso: atención al cliente hace seguimiento proactivo antes del cierre del trimestre.
-- La condición de fecha va en el ON para conservar a los clientes sin consultas recientes.
select c.nif, c.denominacion, c.telefono, c.localidad
from cliente c
left join consulta q on q.id_cliente = c.id_cliente and q.fecha_hora >= now() - interval '30 days'
where c.fecha_baja is null and q.id_consulta is null
order by c.denominacion
limit 15;

-- 7. Clientes a los que no se ha emitido ninguna factura.
-- Caso de uso: administración detecta clientes inactivos para revisar su baja y, si procede,
-- aplicar la política de retención de datos (RGPD). Usa una subconsulta con NOT IN.
select c.nif, c.denominacion, c.fecha_alta, c.fecha_baja
from cliente c
where c.id_cliente not in (select id_cliente from factura)
order by c.fecha_baja, c.nif;

-- 8. Clientes cuya masa salarial bruta del primer trimestre de 2026 supera los 20.000 euros.
-- Caso de uso: el área laboral prioriza a los clientes con más nóminas gestionadas
-- (más trabajo y más riesgo). Une nómina, trabajador y cliente y filtra con HAVING.
select c.nif, c.denominacion, count(distinct t.id_trabajador) as trabajadores,
       sum(n.bruto) as bruto_1t_2026, sum(n.liquido) as liquido_1t_2026
from nomina n
join trabajador t on t.id_trabajador = n.id_trabajador
join cliente c on c.id_cliente = t.id_cliente
where n.periodo >= date '2026-01-01' and n.periodo < date '2026-04-01'
group by c.id_cliente, c.nif, c.denominacion
having sum(n.bruto) > 20000
order by bruto_1t_2026 desc;

-- 9. Consultas sin cerrar por empleado de atención y canal, con la más antigua.
-- Caso de uso: la persona que coordina atención al cliente revisa qué consultas llevan
-- más tiempo abiertas y quién las tiene. Solo salen los grupos con 2 o más.
select e.usuario_ad, q.canal, count(*) as sin_cerrar, min(q.fecha_hora)::date as mas_antigua
from consulta q
join empleado e on e.id_empleado = q.id_empleado
where q.estado <> 'CERRADA'
group by e.id_empleado, e.usuario_ad, q.canal
having count(*) >= 2
order by sin_cerrar desc, e.usuario_ad;

-- 10. Calendario de vencimiento de la conservación de documentos, por año y tipo.
-- Caso de uso: el responsable de protección de datos planifica la revisión y el borrado de
-- documentos cuyo plazo ha vencido. Usa el campo que calcula el trigger de documento.
select extract(year from d.conservar_hasta)::int as anio_vencimiento, td.nombre as tipo,
       count(*) as documentos,
       count(*) filter (where d.conservar_hasta < current_date) as ya_vencidos
from documento d
join tipo_documento td on td.id_tipo_documento = d.id_tipo_documento
group by 1, td.nombre
order by 1, td.nombre;
