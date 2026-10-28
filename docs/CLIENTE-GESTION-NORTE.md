# CLIENTE: GESTIÓN NORTE — respuestas y pendientes

Contacto: Lucas Martin, Director de Operaciones. Equipo consultor: **Consultoría Kalima** (Raúl, Arian, Álvaro).
Última actualización: 28/10 (segunda respuesta del cliente).

## Cronología
| Fecha | Qué |
|---|---|
| ~24/10 | Primera respuesta del cliente al cuestionario inicial |
| 26/10 (lunes) | El cliente envía un inventario de equipos. **[Pendiente: subir el inventario al proyecto y al repositorio]** |
| 27-28/10 | Consulta de seguimiento de Kalima: 11 preguntas sobre equipos, conexión, teletrabajo, copias y soporte, y 12 sobre los datos que manejan |
| 28/10 | Segunda respuesta de Lucas Martin (resumida abajo) |

## 1. Primera respuesta (resumen fiel)
- Asesoría laboral y fiscal con servicios recurrentes a unas 2.400 empresas y autónomos.
- 150 personas: asesoría laboral 60, asesoría fiscal 45, administración y facturación 25, atención y gestión de clientes 20.
- Sedes: Zaragoza (principal) 110 personas, Huesca 25, Teruel 15.
- Modalidad: 85 en oficina, 50 híbridos, 15 principalmente en remoto. En los cierres fiscales aumenta el trabajo remoto.
- Programas: nóminas, contabilidad y gestión documental, más correo y portales de organismos públicos.
- Tareas críticas: nóminas, obligaciones fiscales, atención de consultas y entrega de documentación en plazo.
- Disponibilidad: en cierres mensuales una interrupción larga retrasa entregas; **en campaña fiscal, más de 2 h de parada tendría un impacto importante**.
- Datos: identificativos, laborales, fiscales y bancarios de clientes y de sus trabajadores.
- Preocupaciones: confidencialidad y continuidad de cierres y campañas.
- Incidentes: sin constancia de pérdidas ni incidentes graves, pero sin descripción completa de incidencias anteriores.
- Crecimiento: unas 20 personas más en dos años y posible oficina en otra provincia.
- Presupuesto de referencia: 75.000 €, sin partidas definidas ni aprobación total.

## 2. Segunda respuesta (28/10)

### 2.1 Equipos (dato confirmado)
| Oficina | Sobremesa | Portátiles | Impresoras | Total PC |
|---|---|---|---|---|
| Zaragoza | 77 | 33 | 7 | 110 |
| Huesca | 18 | 7 | 3 | 25 |
| Teruel | 10 | 5 | 2 | 15 |
| **Total** | **105** | **45** | **12** | **150** |

- **2 servidores, ambos en Zaragoza.**
- **Unos 45 equipos con Windows 7** (dato de nuestra consulta sobre su inventario). No está confirmado que algún programa solo funcione en ellos. Usan una **aplicación antigua de nóminas para consultar expedientes históricos**; no saben si depende de esos equipos: lo comprobarán con el proveedor y con quien la usa.

### 2.2 Conexión y trabajo entre oficinas
- Las tres oficinas tienen Internet con proveedores comerciales. **No hay registro fiable de cortes.**
- Las áreas comparten documentación: parte en carpetas de los PC, parte en **un disco compartido**, y también por correo y USB. Esto **ha generado duplicados y versiones desactualizadas**.
- **Wi-Fi para visitas: no lo tienen definido; nos piden que lo valoremos** según la atención a clientes.

### 2.3 Teletrabajo y cuentas
- 50 híbridos y 15 en remoto (confirmado). **No saben qué dispositivo usa cada persona.**
- **No pueden confirmar si todas las cuentas son individuales** o si hay claves compartidas.
- Altas y bajas se comunican a las áreas, pero **sin procedimiento común documentado**.

### 2.4 Copias y continuidad
- **No pueden confirmar** qué se copia, dónde, cada cuánto ni cuándo se probó una recuperación.
- Más de 2 h de parada en campaña tendría impacto importante (confirmado).
- **No tienen definido cuánto trabajo reciente pueden perder: nos piden que nuestra propuesta les ayude a concretar ese objetivo** (RPO).

### 2.5 Programas y soporte
- Programas de nóminas, contabilidad y gestión documental, correo y portales públicos. No saben cuáles están instalados en local y cuáles funcionan por Internet. **No consta que sean de Microsoft Office.**
- **Sin información verificada** sobre quién da hoy el soporte informático, contrato, normas escritas de uso ni formación sobre fraudes por correo.
- **Sin preferencia** entre oficina o nube.

### 2.6 Datos que manejan (base del modelo relacional)
- **Clientes** (~2.400, confirmado): razón social o nombre, NIF, dirección, datos de contacto, **personas de referencia**, datos de facturación y cobro.
- **Servicios**: cada cliente contrata **uno o varios** (gestión laboral, nóminas, asesoría fiscal, impuestos, contabilidad, trámites). El trabajo se reparte entre los equipos laboral y fiscal. No hay recuento por servicio ni asignación completa de responsables.
- **Trabajadores de los clientes**: nombre, documento identificativo, número de afiliación, puesto, tipo de contrato, fechas relevantes, datos bancarios. Número total desconocido.
- **Nóminas**: periodo, importes, deducciones y documento. Volumen mensual desconocido.
- **Obligaciones fiscales y laborales**: presentaciones periódicas y trámites de cotización. Cada equipo controla vencimientos y estado de los encargos a su manera; no hay método consolidado. Justificantes asociados al trabajo del cliente.
- **Documentos**: contratos, facturas, nóminas, justificantes, documentación fiscal y laboral, certificados para trámites. Se relacionan con el cliente y, si procede, con el trabajador.
- **Acceso por departamento**: Administración gestiona facturas y datos de clientes; Laboral y Fiscal consultan la documentación de sus servicios; Atención recoge consultas y hace seguimiento.
- **Conservación**: no hay calendario único de conservación y borrado.
- **Trazabilidad**: no hay registro de quién consulta o modifica cada dato. **Sí les interesa identificar cambios relevantes, por ejemplo en los datos bancarios de un cliente.**
- **Facturación**: cuotas recurrentes o por servicio. Cada factura: cliente, concepto, periodo o servicio, importes y estado de cobro.
- **Consultas de clientes**: Atención las recoge y hace seguimiento; el detalle registrado varía.
- **Herramientas actuales**: programas de nóminas, contabilidad y gestión documental, carpetas de PC y disco compartido. No saben si todo se puede exportar a hoja de cálculo ni los nombres de producto.

### 2.7 Presupuesto y lo que esperan de nosotros
- 75.000 € de referencia, **sin partidas definidas ni aprobación total**.
- Piden que **señalemos qué datos necesitamos verificar** y que **justifiquemos cada decisión** por sus necesidades: **confidencialidad** y **continuidad en cierres y campañas**.

## 3. Lo que sigue sin saberse (pendiente de verificar)
| Tema | Qué falta | Cómo lo tratamos |
|---|---|---|
| Windows 7 | Si la app antigua de nóminas depende de ellos | Supuesto: sí puede depender → se aísla hasta comprobarlo |
| Conexión | Calidad y cortes de cada línea | Supuesto: una línea por sede sin respaldo → se propone línea 4G/5G |
| Dispositivos en casa | Equipo propio o de empresa | Hay 45 portátiles para 65 teletrabajadores → hasta 20 podrían usar equipo propio |
| Cuentas | Si hay claves compartidas | Supuesto: sí → cuentas individuales obligatorias |
| Copias | Si existen y si se han probado | Supuesto: no fiables → se diseñan desde cero |
| Programas | Local o nube, nombres de producto | Supuesto: local → se protegen en el servidor; inventario de software pendiente |
| Soporte | Proveedor, contrato, normas, formación | Supuesto: soporte informal → RACI, contrato con SLA, políticas y formación |
| Servidores | Antigüedad y función de los 2 servidores | Pendiente del inventario |
| Volumen | Trabajadores de clientes y nóminas al mes | Se estiman en el modelo; se marca como supuesto |
| Presupuesto | Partidas y aprobación | Lo proponemos nosotros por partidas en el capítulo 9 |

## 4. Consecuencias para el diseño (ver `06-ANALISIS-Y-ARRANQUE`)
- Windows 7 pasa a ser **riesgo alto** y partida de presupuesto.
- El RPO lo **proponemos nosotros**, por servicio.
- **Wi-Fi de invitados**: lo decidimos nosotros (VLAN 80 aislada).
- El modelo de datos ya tiene requisitos reales: clientes, servicios contratados, trabajadores, nóminas, obligaciones, documentos, facturas, consultas y **auditoría de cambios bancarios**.
- El servidor de ficheros sustituye al disco compartido, las carpetas de PC y el envío por correo/USB.
