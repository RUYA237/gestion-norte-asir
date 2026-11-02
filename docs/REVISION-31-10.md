# Revisión y plan — Consultoría Kalima · Gestión Norte (sáb 31/10/2026)

Fuentes: instrucciones del proyecto, los 8 documentos del proyecto, el PDF del enunciado, el repositorio (`origin/main` = 0652813, 28/10), las 36 issues y los chats de Arian y Álvaro del 28/10. Los adjuntos `DECISIONES.md` y `PLAN-RED.md` no llegaron con el mensaje: se usan las versiones del repositorio (28/10).

## 0. Estado real: preguntas abiertas

| # | Campo | Último dato conocido (sin confirmar) | Qué necesito |
|---|---|---|---|
| 1 | PC de 32 GB | Issue #2 abierta; nadie asignado | De quién es y si está confirmado |
| 2 | ubu-fw, Kea, Unbound, nftables | 28/10 13:45: instalándose, 1 NIC (NAT) | Salida de `ip -br a`, `sudo nft list ruleset \| head -40` y `systemctl is-active kea-dhcp4-server unbound` |
| 3 | dc1 y scripts de AD | Chat de Arian (28/10): plantilla en curso, script 01 entregado, VM parada en el Boot Manager UEFI | `Get-ADDomain \| fl DNSRoot` y `dcdiag /q`, o "no existe" |
| 4 | PostgreSQL y modelo | Chat de Álvaro (28/10): `.sql` de 17 tablas probado por Claude en PG16; ni ejecutado por él ni subido | ¿Lo ha ejecutado? ¿Existe ubu-svc? |
| 5 | Git | Sin commits desde el 28/10; 36 issues abiertas y sin asignar | ¿Hay trabajo local sin subir? ¿Han aceptado la invitación? |
| 6 | Cliente | Última respuesta del 28/10; inventario del 26/10 sin subir (#36) | ¿Hay respuesta nueva? ¿Tienes el fichero del inventario? |
| 7 | Profesor | #1 abierta: fechas (el PDF dice 2025), módulo web, si el borrador puntúa | ¿Ha contestado? |

Hasta que contestes, todo lo que sigue usa el último dato conocido y lo marca como **sin confirmar**.

## 1. Recordatorio

- **Encargo:** somos Consultoría Kalima y rediseñamos la infraestructura de Gestión Norte: asesoría laboral y fiscal, 150 personas (Zaragoza 110, Huesca 25, Teruel 15), 65 en teletrabajo, datos laborales, fiscales y bancarios. Más de 2 h de parada en campaña es grave.
- **Alcance:** diagnóstico, diseño justificado, laboratorio en VMware (sede de Zaragoza), propuesta para producción, presupuesto (75.000 € de referencia) y hoja de ruta.
- **Entregables:** borrador el 06/11; memoria y entregable (configuraciones, scripts, evidencias) el 17/11 a las 23:59; defensa del 23 al 27/11 (10-15 min más 5 de preguntas).
- **Pesos:** memoria 30 %, entregable 20 %, defensa por módulo 20 % (individual), tribunal 30 % (común). Cuatro rúbricas (R, S, SO, BD) puntúan la aportación individual.
- **Nivel 1** (obligatorio para la entrega final): ubu-fw con nftables, Kea y Unbound; dc1 con AD, usuarios y GPO; PostgreSQL securizado con el modelo; restic con restauración probada; OpenVPN con TOTP.
- **Nivel 2:** dc2, Wazuh con una alerta, Zabbix, cli01 con BitLocker y LAPS.
- **Nivel 3** (propuesto): Suricata, Huesca por WireGuard, Caddy, Kea en alta disponibilidad, copia externa, k3s.

## 2. Planteamiento actual

### 2.1 Arquitectura y reparto

| Módulo | Responsable | Qué se monta | Máquinas |
|---|---|---|---|
| Redes | Raúl | VLAN por función (VMnet = VLAN), nftables con denegación por defecto, Kea, Unbound con reenvío de `ad.gestionnorte.es`, bastión SSH, OpenVPN con TOTP | ubu-fw, cli-test |
| Sistemas | Arian | AD con 2 DC, OU, AGDLP, usuarios por CSV, GPO, ficheros SMB cifrados, LAPS, BitLocker, plan de Windows 7 | dc1, dc2, cli01 |
| Bases de datos | Álvaro | Modelo 3FN, PostgreSQL 17 en Podman con Quadlet, roles, SCRAM, TLS, pgaudit, auditoría bancaria, consultas y EXPLAIN | ubu-svc |
| Seguridad (repartida) | Los tres | Raúl: VPN, MFA y Suricata · Arian: LAPS, BitLocker y contraseñas · Álvaro: copias, Wazuh y Zabbix | wazuh01, bkp01 |

### 2.2 Decisiones D01-D21

Ninguna tiene todavía evidencia en Git, así que ninguna está implementada.

| # | Decisión | Tipo | Estado |
|---|---|---|---|
| D01 | AD con dc1 (escritorio) y dc2 (Core) | Laboratorio | Pendiente de verificar |
| D02 | ubu-fw como firewall, router, Kea, Unbound, VPN y bastión | Laboratorio | Pendiente de verificar |
| D03 | Unbound reenvía la zona AD a dc1 y dc2 | Laboratorio | Pendiente de verificar |
| D04 | Sin failover de DHCP; VRRP y Kea en HA en producción | Producción | Propuesto |
| D05 | OpenVPN con certificado, contraseña AD y TOTP | Laboratorio | Pendiente de verificar (fechado después del borrador) |
| D06 | Podman con Quadlet en ubu-svc | Laboratorio | Pendiente de verificar |
| D07 | PostgreSQL securizado (SCRAM, TLS 1.3, pg_hba, pgaudit) | Laboratorio | Pendiente de verificar |
| D08 | Wazuh en VM propia | Laboratorio (nivel 2) | Pendiente de verificar |
| D09 | VMware en cada PC; Git y OVA | Método | En uso, sin integración real todavía |
| D10 | Un VMnet por VLAN | Laboratorio | Pendiente de verificar (límite de NIC) |
| D11 | `PLAN-RED.md` como fuente única | Documentación | Implementado (el documento existe) |
| D12 | bkp01 con rest-server solo-añadir y disco externo | Laboratorio | Pendiente de verificar |
| D13 | WSUS propuesto; Windows Update por GPO | Producción | Propuesto |
| D14 | Kubernetes descartado; k3s en producción | Producción | Propuesto |
| D15 | AD, firewall y Wazuh en VM; solo PostgreSQL, Zabbix y Caddy en contenedor | Diseño | Decidido |
| D16 | Alcance por niveles | Método | Decidido |
| D17 | Wi-Fi de visitas en VLAN 80 | Producción | Propuesto |
| D18 | RPO/RTO por servicio | Propuesta al cliente | Propuesto, sin validar por el cliente |
| D19 | Windows 7 en VLAN 99 de cuarentena y migración | Producción | Propuesto |
| D20 | Teletrabajo solo con equipos de la empresa | Producción | Propuesto |
| D21 | Auditoría de cambios bancarios con trigger | Laboratorio (nivel 1) | Pendiente de verificar (el trigger existe en el `.sql`, sin ejecutar) |

**Decididas el 28/10 en el chat y sin registrar en `DECISIONES.md`:**
- D22: los ficheros los sirve dc1; nas01 queda en nivel 3; el NAS no va en contenedor.
- D23: no hay plantilla de Ubuntu; cada Linux se instala desde la ISO.
- D24: el usuario de instalación se llama como la máquina.

## 3. Cliente

| Dato | Estado | Impacto en el diseño |
|---|---|---|
| Plantilla, departamentos, sedes, modalidad | Bien | VLAN por departamento; dimensionado de la VPN |
| Equipos por sede (105 + 45 + 12 + 2 servidores) | Bien | Diagrama, switches y licencias |
| Inventario detallado (modelo, SO, antigüedad) del 26/10 | A medias (no lo tenemos subido) | Sin él no hay importes de presupuesto |
| ~45 Windows 7 y aplicación antigua de nóminas | A medias | Plan de VLAN 99 y la partida más cara del presupuesto |
| 2 servidores: antigüedad y función | Sin responder | Reutilizar o comprar (10.000-16.000 €) |
| Disco compartido: qué es | Sin responder | Migración de ficheros; decisión sobre el NAS (D22) |
| Conexión: proveedor sí; velocidad y cortes no | A medias | Línea de respaldo 4G/5G (supuesto) |
| Dispositivos de teletrabajo | A medias (45 portátiles para 65 personas) | Hasta 20 portátiles en el presupuesto (D20) |
| Cuentas compartidas | Sin responder | Supuesto: sí las hay; cuentas individuales |
| Copias actuales | Sin responder | Supuesto: no son fiables; diseño desde cero |
| RPO/RTO | A medias (nos piden proponerlo; sin validar) | Copias, WAL y dos DC |
| Programas: local o nube y nombres | A medias | Supuesto: local; inventario de software |
| Correo (proveedor) | No preguntado | Alcance de la MFA, del phishing y de las copias del correo |
| Soporte, contrato, normas, formación | Sin responder | RACI, SLA, uso aceptable y formación (requisitos 17, 21, 23, 29) |
| Presupuesto: partidas y aprobación | A medias | Priorizar fases |
| Datos que manejan | Bien | Modelo relacional de 17 tablas |
| Volumen de trabajadores y nóminas | Sin responder | Supuesto en los datos de prueba |

**Preguntas que aún faltan** (redactadas para enviar; entre corchetes, lo que asumimos si no contestan):
1. ¿Les ha confirmado el proveedor si la aplicación antigua de nóminas necesita Windows 7? [Asumimos que sí: quedará en un único equipo virtual aislado, solo para consulta.]
2. De los 2 servidores de Zaragoza: marca y modelo, año de compra y qué hace cada uno. [Asumimos más de 5 años y que se sustituyen.]
3. El disco compartido, ¿es un NAS, un PC o uno de los servidores? ¿Tiene copia? [Asumimos un NAS sin copia: se migra al nuevo servidor de ficheros.]
4. ¿Validan los tiempos de recuperación que proponemos (2 h de parada como máximo y 15 minutos de datos perdidos en la base de datos durante la campaña)? [Los aplicamos tal cual.]
5. Los 75.000 €, ¿incluyen renovar los equipos con Windows 7 y comprar portátiles? ¿Se puede repartir en dos ejercicios? [Asumimos que cubren infraestructura y seguridad; la renovación de puestos va en una segunda fase.]
6. ¿Qué correo usan (Microsoft 365, Google Workspace o el de un proveedor de alojamiento)? [Queda fuera de alcance; recomendamos activar la doble verificación.]
7. Nombres de los programas de nóminas, contabilidad y gestión documental, y si funcionan en el PC o por Internet. [Asumimos que son locales.]
8. Velocidad contratada en cada sede. [Asumimos fibra suficiente y proponemos un respaldo 4G/5G.]

## 4. Revisión crítica

### 4.1 ¿Es lógico?
**Parcialmente.** El diseño es coherente con las dos necesidades del cliente (confidencialidad y continuidad), está justificado y separa lo implementado de lo propuesto. Esa parte es defendible.

Lo que no es lógico es la ejecución frente al plazo. A 6 días del borrador:
- No hay ni un commit técnico, y las 36 issues siguen abiertas y sin asignar.
- El PC de integración no está decidido, y todo lo integrado depende de él.
- Los puntos de control del 29/10 y del 01/11 no se han cumplido, o no consta que se hayan cumplido.

### 4.2 Incoherencias

| # | Dónde | Choque | Qué manda / qué propongo |
|---|---|---|---|
| 1 | Instrucciones frente a lo decidido el 28/10 | Las instrucciones dicen "plantillas base Windows **y Ubuntu**, compartidas"; el 28/10 se decidió que no hay plantilla de Ubuntu (D23) | Manda lo decidido; actualizar las instrucciones |
| 2 | Instrucciones frente a 03-PLAN y D16 | Las instrucciones presentan "Suricata en modo detección" como decisión cerrada; el plan la pone en nivel 3 | Mandan DECISIONES y el plan: nivel 3 |
| 3 | Instrucciones | "Pendiente: decidir si Ubuntu es una VM o dos" ya está resuelto (D02, D06, D08 y D12: cuatro VM Ubuntu) | Quitarlo |
| 4 | Instrucciones frente a 06-ANALISIS | "Mínimo para el borrador: ubu-fw + dc1" choca con la lista en negrita del 06, que es mucho más larga | Ver 4.4 |
| 5 | `PLAN-RED.md` frente a 03-PLAN y 07-INVENTARIO | Huesca (VMnet19) aparece como "Laboratorio: Sí", pero es nivel 3 y queda fuera del borrador | Corregir PLAN-RED |
| 6 | `PLAN-RED.md` frente a D19 | La VLAN 99 (cuarentena de Windows 7) no está en la tabla de VLAN | Añadirla como diseño |
| 7 | `PLAN-RED.md`, apartado SSH | wazuh01 es Linux y no aparece en la tabla de acceso SSH | Añadirlo |
| 8 | D24 frente a la rúbrica y `PLAN-RED.md` | Un usuario genérico `ubu-fw` compartido por tres personas es justo lo que criticamos al cliente (claves compartidas). Rompe la trazabilidad (requisitos 5 y 16, SO criterio 2) y choca con `AllowGroups gn-admin` y con "usuarios con nombre" de 05-HUECOS | La cuenta de la máquina queda solo para la instalación o emergencias, sin SSH. Se usan cuentas personales `raul`, `arian` y `alvaro` en `gn-admin`, con clave SSH |
| 9 | 03-PLAN y 07-INVENTARIO | cli01 es nivel 2, pero la Integración 1 (nivel 1) necesita un cliente Windows que se una al dominio | cli01 básico (unión al dominio) pasa a nivel 1; BitLocker y LAPS siguen en nivel 2 |
| 10 | Chat de Álvaro frente al reparto | Allí se le dijo que confirmara contigo si Wazuh y Zabbix son suyos; el reparto dice que sí | Decidirlo hoy (ver 4.3) |
| 11 | Memoria 7.4 frente a D18 | La memoria tiene el RPO/RTO como "pendiente", pero la tabla ya existe en 06-ANALISIS | Copiarla a la memoria |
| 12 | 01-INDICE, apartado 4.4 | Todavía dice "por qué Firezone" | Cambiarlo a OpenVPN con TOTP; Firezone, descartado |
| 13 | Memoria 1.6 | Pone "31/10-01/11: Integración 1"; hoy no está hecha | Actualizar el calendario |

### 4.3 Carga por persona y rebalanceo
- **Raúl** es el más cargado: red completa, VPN con MFA, bastión, coordinación, capítulos 1-3, presupuesto y documentos de seguridad.
- **Álvaro** también va cargado: BD completa, copias, Wazuh y Zabbix.
- **Arian** tiene una carga media-alta.

**Rebalanceo:**
- **Zabbix pasa a Arian.** Monitorizar servicios y sistemas es criterio 4 de SO, y Arian ya instala el agente en dc1.
- **El presupuesto se reparte:** Arian, servidores y licencias; Raúl, red y puestos.
- **Requisitos documentales:** 14 y 17 para Raúl; 27 para Arian; 21, 22 y 29 para Álvaro.
- **Recortes de Raúl:** Suricata y WireGuard quedan en propuesto desde ya.

### 4.4 ¿Cabe el nivel 1 antes del 06/11?
**No.** OpenVPN con TOTP y restic están fechados del 7 al 11/11. El nivel 1 es para la entrega final.

**Mínimo realista para el borrador:**
- ubu-fw enrutando con nftables, Kea y Unbound.
- dc1 con el bosque, OU y usuarios del CSV.
- Modelo ejecutado en PostgreSQL con el trigger bancario probado.
- Memoria completa en texto, con cada apartado marcado (implementado / propuesto / pendiente de verificar).
- Documentos de seguridad (requisitos 14, 17, 21, 22, 27 y 29).

La VPN y las copias van al borrador como "pendiente de verificar", con su diseño escrito.

### 4.5 ¿Cuadran los 75.000 €?
Todos los precios son **supuesto**: precios orientativos de mercado, sin cotizar.

| Partida | Supuesto | Rango |
|---|---|---|
| Sustituir ~45 equipos con Windows 7 (sin TPM 2.0) | 45 × 600-900 € | 27.000-40.500 € |
| Portátiles de teletrabajo | 20 × 800-1.100 € | 16.000-22.000 € |
| Switches gestionables | 6-7 × 500-1.200 € | 3.000-8.400 € |
| Puntos de acceso Wi-Fi con VLAN | 6-8 × 150-350 € | 900-2.800 € |
| Equipos de firewall (2 en Zaragoza, 1 en Huesca, 1 en Teruel) | 4 × 500-1.000 € | 2.000-4.000 € |
| 2 servidores de virtualización (si no se reutilizan) | 2 × 5.000-8.000 € | 10.000-16.000 € |
| SAI | 2-3 | 1.000-3.600 € |
| Windows Server 2025 Standard (2 hosts) y 150 CAL de usuario | — | 7.000-11.000 € |
| Copias: almacenamiento y copia externa (año 1) | — | 1.500-4.000 € |
| Línea de respaldo 4G/5G en 3 sedes (año 1) | — | 1.000-2.500 € |
| Implantación, migración y formación | 150-250 h × 40-60 € | 6.000-15.000 € |
| **Total** | | **~75.000-130.000 €** |

**Conclusión:** los 75.000 € solo cubren todo en el escenario más barato y sin margen. Sin la renovación de puestos (43.000-62.500 €), la infraestructura, la seguridad y los servicios suman 32.000-67.000 € y sí caben.

Propuesta: fase 1 (infraestructura, seguridad y servicios) dentro de los 75.000 €, y fase 2 (renovación de puestos) en otro ejercicio o con renting. Es la pregunta 5 al cliente.

### 4.6 Huecos de rúbrica y de los requisitos sin cubrir
Los requisitos 14, 17, 21, 22, 27 y 29 **siguen sin cubrir**:
- La memoria 7.3 y 7.7 están en "pendiente".
- La issue #30 está abierta.
- Los capítulos 8.1-8.3 de la memoria están vacíos. Son la evidencia de las cuatro rúbricas.
- Las bitácoras individuales están vacías.

| Requisito | Qué falta | Quién | Cuándo |
|---|---|---|---|
| 14 | Niveles de clasificación de datos con ejemplos | Raúl | Jue 05/11 |
| 17 | Política de uso aceptable de una página | Raúl | Jue 05/11 |
| 21 | Proveedores, contrato y SLA | Álvaro | Jue 05/11 |
| 22 | Calendario de retención y borrado (usa `conservar_hasta`) | Álvaro | Jue 05/11 |
| 27 | Segregación de funciones (AGDLP y cuentas `adm_`) | Arian | Jue 05/11 |
| 29 | Matriz RACI | Álvaro | Jue 05/11 |

### 4.7 Una alternativa de enfoque
**Laboratorio centralizado:** todos los servidores corren desde ya en el PC de 32 GB, con dos sesiones conjuntas (martes 03/11 y sábado 14/11). Los PC personales quedan solo para desarrollar scripts.

- **Pros:**
  - La integración es real desde el principio y las capturas finales salen directamente.
  - Se evitan los problemas de importar OVA y de VMnets distintos en cada PC.
  - Resuelve lo que hoy no funciona: cuatro días sin integrar nada.
- **Contras:**
  - Todo depende de un PC y de su dueño.
  - Hay que coincidir físicamente.
  - La aportación individual tiene que seguir viéndose: cada uno ejecuta lo suyo y hace commit con su nombre.

**Mi elección: híbrido.** Cada uno desarrolla en su PC hasta el lunes 02/11, y desde el martes 03/11 los servidores viven solo en el PC de 32 GB. Sin dueño confirmado del PC hoy, no hay borrador integrado.

## 5. Plan

Supuesto: 2 h por persona y día.

### 5.1 Hasta el borrador (06/11)

| Día | Raúl | Arian | Álvaro |
|---|---|---|---|
| Sáb 31 | R #4-#5: VMnet 11-14, 4 NIC y netplan por MAC → `ip -br a` | SO #14-#15: plantilla con sysprep y script 01 con prueba de IP duplicada → capturas 04-07 | BD #22: ejecutar `modelo.sql` y subir `bd/` → captura de las 17 tablas |
| Dom 01 | R #5: nftables con denegación por defecto, NAT, SSH solo desde VLAN 10 → `nft list ruleset` y ping de cli-test | SO #15: script 02 (bosque) → `dcdiag`, `Get-ADDomain` | BD #23: ubu-svc desde ISO, Podman y PostgreSQL 17 con Quadlet → `systemctl status`, `psql \l` |
| Lun 02 | R #6: Kea y Unbound (zona de prueba si dc1 no está) → concesión en cli-test, `dig` | SO #16: scripts 04-05 (OU, AGDLP, 20 usuarios) → `Get-ADUser` | BD #35: modelo cargado y prueba del trigger bancario → fila en `auditoria_cambio` |
| Mar 03 | R/SO #7: Integración 1 en el PC de 32 GB (**depende de #2**) → cliente con IP de Kea que resuelve y se une | SO #7: Integración 1 con Raúl y unión de cli01 al dominio | BD #24: roles, `pg_hba` y SCRAM → captura de acceso denegado |
| Mié 04 | R #8-#9: matriz de pruebas y tabla de dependencias → tabla esperado/obtenido | SO #17: GPO de contraseñas, bloqueo y USB → `gpresult` | S #29: RPO/RTO en la memoria 7.4 y matriz de riesgos con responsables |
| Jue 05 | S #30: requisitos 14 y 17 | SO/S #34: plan de Windows 7 y requisito 27 | S #30: requisitos 21, 22 y 29 |
| Vie 06 | Montar el borrador y entregarlo (#32) | Fichas de 5 puntos del capítulo 5, memoria 8.1-8.3 y bitácora | Fichas del capítulo 6, memoria 8.1-8.3 y bitácora |

### 5.2 Hasta la entrega final (17/11)

| Día | Raúl | Arian | Álvaro |
|---|---|---|---|
| Sáb 07 | R: bastión SSH completo (sshd, `gn-admin`, fail2ban) | SO #20: dc2 en Core y replicación | BD #24: TLS 1.3 y pgaudit |
| Dom 08 | R/S #11: PKI de OpenVPN y certificados | S #21: cli01 con BitLocker | BD/S #26: bkp01 con rest-server solo-añadir |
| Lun 09 | R/S #11: autenticación contra AD y TOTP | S #21: LAPS | BD/S #26: restic, restauración y RTO medido |
| Mar 10 | R/S #11: prueba con el usuario de Arian y política de teletrabajo (D20) | SO: ficheros con SMB cifrado y permisos AGDLP | BD #25: 5 consultas con EXPLAIN antes y después |
| Mié 11 | Presupuesto (#10): red y puestos | Presupuesto (#10): servidores y licencias; SO #18: cuentas Linux, cambios y parches | BD #25: VACUUM, ANALYZE y `pg_stat` |
| Jue 12 | Memoria, capítulo 4 | SO #19: incidencia real | S #27: Wazuh y agentes |
| Vie 13 | Memoria, capítulos 9 y 10 | S #28: Zabbix y agente en dc1 | S #27: alerta de fuerza bruta |
| Sáb 14 | S #31: simulacro de incidente (los tres) | S #31 | S #31 |
| Dom 15 | Revisión global de la memoria | Memoria, capítulo 5 | Memoria, capítulo 6 |
| Lun 16 | Entrega interna: anexos, capturas e índice | Ídem | Ídem |
| Mar 17 | Margen; entrega antes de las 23:59 | | |

### 5.3 Qué se puede avanzar y qué está bloqueado
- **Sin esperar a nadie:** ubu-fw, Kea, Unbound, nftables; dc1, AD y GPO; modelo y PostgreSQL; requisitos 14, 17, 21, 22, 27 y 29; RPO/RTO en la memoria como propuesta; OpenVPN; copias.
- **Bloqueado por el cliente:** importes del presupuesto (inventario y servidores), plan definitivo de Windows 7 (aplicación de nóminas), validación del RPO/RTO, decisión sobre el NAS (disco compartido) y alcance del correo.
- **Bloqueado internamente:** Integración 1 y capturas finales (PC de 32 GB, #2), y cli01 (necesita un PC con RAM y TPM virtual).
- **Bloqueado por el profesor:** año de las fechas, módulo web y si el borrador puntúa.

### 5.4 Si vamos justos, se recorta en este orden
1. Suricata (#13).
2. WireGuard a Huesca (#12).
3. Caddy.
4. Zabbix (se mantiene Wazuh).
5. dc2: pasa a propuesto, con la justificación del RTO de identidad.
6. BitLocker en cli01 (LAPS se mantiene).

**No se recorta nunca:** ubu-fw con Kea y Unbound; dc1 con AD y GPO; modelo con roles y trigger; restic con restauración; OpenVPN con TOTP; documentos de seguridad.

## 6. Próximos 3 pasos para hoy
1. **Contestar la tabla del punto 0** y cerrar hoy el dueño del PC de 32 GB por WhatsApp. Sin eso, el martes no hay integración.
2. **ubu-fw:** VMnets, 4 NIC y pasarme `ip -br link` e `ip -br a`. Con eso te devuelvo el netplan y nftables listos para pegar.
3. **Pedir a Arian y Álvaro que suban hoy lo que tengan**, aunque esté a medias (script 01, `modelo.sql`), con su nombre y número de issue. Sin commits no hay aportación individual demostrable.

### Mensaje al cliente

Asunto: Gestión Norte · Datos pendientes para cerrar la propuesta

Buenas tardes, Lucas:

Gracias por las respuestas del 28/10. Con ellas hemos preparado la propuesta, y para cerrarla con importes reales necesitamos unos pocos datos más. Si alguno no se puede confirmar, indicamos entre paréntesis lo que asumiremos:

1. ¿Les ha confirmado el proveedor si la aplicación antigua de nóminas necesita Windows 7? (Si no, la dejaremos en un único equipo aislado, solo para consultar.)
2. De los dos servidores de Zaragoza: marca y modelo, año de compra y qué hace cada uno. (Si no, asumiremos que hay que sustituirlos.)
3. El disco compartido, ¿es un NAS, un PC o uno de los servidores? ¿Tiene copia? (Si no, lo trataremos como un NAS sin copia que se migra al nuevo servidor de ficheros.)
4. ¿Les parecen bien estos objetivos en campaña: volver a funcionar en 2 horas como máximo y no perder más de 15 minutos de trabajo en la base de datos? (Si no nos dicen nada, los aplicaremos.)
5. Los 75.000 €, ¿incluyen renovar los equipos con Windows 7 y comprar portátiles para teletrabajo? ¿Se podría repartir en dos años? (Si no, los dedicaremos a infraestructura y seguridad y propondremos la renovación de equipos en una segunda fase.)
6. ¿Qué servicio de correo utilizan?
7. ¿Cómo se llaman los programas de nóminas, contabilidad y gestión documental, y funcionan instalados en el PC o por Internet? (Si no, asumiremos que son locales.)
8. ¿Qué velocidad de Internet tienen contratada en cada oficina?

Si pudieran contestarnos antes del miércoles 4, lo incluiríamos en la versión que presentaremos.

Un saludo,
Consultoría Kalima (Raúl, Arian y Álvaro)
