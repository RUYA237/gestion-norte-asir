# Análisis y arranque — Consultoría Kalima · Gestión Norte (28/10)

Qué cambia con la segunda respuesta del cliente, qué queda por hacer y cómo empieza cada uno. Manda sobre `03-PLAN-PROYECTO` donde choquen.

## 1. Qué cambia con la respuesta del cliente

| Dato nuevo | Consecuencia | Dónde va | Quién |
|---|---|---|---|
| **~45 equipos con Windows 7** (sin parches desde 2020; las actualizaciones extendidas terminaron en enero de 2023) | Riesgo alto nuevo. No admiten Windows LAPS ni las políticas modernas. Partida de presupuesto importante | Riesgos 7.1, SO 5.4, presupuesto 9.1 | Arian |
| App antigua de nóminas para expedientes históricos, quizá ligada a Windows 7 | No se puede retirar Windows 7 a ciegas | Plan Windows 7 (abajo) | Arian |
| 105 sobremesa + 45 portátiles + 12 impresoras; 2 servidores en Zaragoza | Inventario real; diagrama y presupuesto con cifras | Cap. 2, 3.1, 9.1 | Raúl |
| **45 portátiles para 65 teletrabajadores** | Hasta 20 personas podrían trabajar con equipo propio | Política de teletrabajo, presupuesto | Raúl |
| Disco compartido + carpetas de PC + correo/USB → duplicados | El servidor de ficheros con AGDLP lo sustituye; argumento central del capítulo 5.1 | 5.1 | Arian |
| **Nos piden proponer el RPO** | Tabla de RPO/RTO por servicio es nuestra (abajo) | 7.4 | Álvaro |
| **Wi-Fi de visitas: lo decidimos nosotros** | Sí: VLAN 80 aislada, solo Internet | 4.1 | Raúl |
| Sin procedimiento de altas y bajas | Procedimiento con AD (alta por CSV, baja: deshabilitar, revocar VPN) | 7.2 | Arian |
| Les interesa ver **quién cambia datos bancarios** | Auditoría de cambios en la BD (trigger + tabla) además de pgaudit | 6.3, 7.5 | Álvaro |
| Datos de clientes, servicios, trabajadores, nóminas, obligaciones, documentos, facturas, consultas | **El modelo ya tiene requisitos reales** | 6.1 | Álvaro |
| Sin calendario de conservación | Campo de conservación en documentos + política de retención | 6.1, 7.6 | Álvaro, Raúl |
| Programas: local o nube desconocido; no son de Office | Inventario de software pendiente; se asume local | 2.2 | Raúl |
| Soporte, contrato, normas y formación: sin datos | RACI, contrato con SLA, política de uso y formación | 7.7, 9.2 | Los tres |

## 2. Decisiones nuevas (añadidas a `DECISIONES.md`)

**D17 · Wi-Fi de visitas.** VLAN 80 aislada con portal y solo web a Internet. Motivo: hay atención presencial de clientes y hoy no hay nada separado. Estado: propuesto.

**D18 · RPO y RTO propuestos al cliente.** Para el laboratorio se mide la restauración real.

| Servicio | RTO en campaña | RPO en campaña | RPO fuera de campaña | Cómo se consigue |
|---|---|---|---|---|
| Identidad (AD, DNS) | < 30 min | Casi 0 | Casi 0 | Dos controladores que se replican |
| Base de datos de gestión | ≤ 2 h | ≤ 15 min | 24 h | Volcado diario (lab) + archivado continuo WAL (propuesto) |
| Ficheros de departamentos | ≤ 2 h | 1 h | 24 h | Instantáneas horarias en campaña + restic diario |
| Firewall y VPN | ≤ 2 h (lab) / minutos (producción) | — | — | Configuración en Git y reconstrucción medida; pareja VRRP propuesta |
| Correo y portales públicos | Depende del proveedor | — | — | Fuera de alcance; pendiente de verificar |

**D19 · Windows 7.**
1. Inventario de los 45 equipos y comprobación con el proveedor de la app antigua de nóminas (lo pide el cliente).
2. Mientras tanto, aislados en una VLAN de cuarentena sin Internet (propuesta: VLAN 99, 10.1.99.0/24).
3. Migración a Windows 11 de los que cumplan requisitos (TPM 2.0) y sustitución del resto.
4. La app antigua, si hace falta, en una única máquina virtual aislada de solo consulta.

Estado: propuesto. Partida en el capítulo 9.

**D20 · Teletrabajo solo con equipos de la empresa.** El acceso VPN exige certificado instalado en un equipo gestionado; con equipo propio no se entra. Hay un déficit de hasta 20 portátiles (pendiente de verificar) que va al presupuesto. Alternativa descartada: permitir equipos personales con VPN (no se pueden cifrar ni gestionar).

**D21 · Auditoría de datos bancarios.** Tabla de auditoría con trigger en PostgreSQL que guarda usuario, fecha, valor anterior y valor nuevo de cada cambio de cuenta bancaria. Además, pgaudit registra las lecturas de las tablas sensibles. Estado: implementar (nivel 1).

## 3. Modelo de datos: requisitos para Álvaro (propuesta a validar)

| Entidad | Atributos clave | Relaciones |
|---|---|---|
| CLIENTE | id, tipo (empresa/autónomo), razón social o nombre, **NIF único**, dirección, teléfono, correo | 1–N contactos, contrataciones, trabajadores, facturas, consultas, documentos |
| CONTACTO_CLIENTE | nombre, cargo, teléfono, correo | N–1 cliente |
| CUENTA_BANCARIA | IBAN, titular, vigente | N–1 cliente o trabajador · **auditada** |
| SERVICIO | código, nombre (laboral, nóminas, fiscal, impuestos, contabilidad, trámites), departamento | — |
| CONTRATACION | cliente, servicio, fecha alta/baja, cuota, **empleado responsable** | N–N cliente–servicio |
| DEPARTAMENTO / EMPLEADO | departamento (laboral, fiscal, administración, atención), sede | Responsables y autores de consultas |
| TRABAJADOR | nombre, documento, nº afiliación, puesto, tipo de contrato, alta, baja | N–1 cliente |
| NOMINA | periodo, bruto, deducciones, líquido, documento | N–1 trabajador · única por trabajador y periodo |
| OBLIGACION | tipo (IVA, IRPF, sociedades, seguros sociales…), periodo, **fecha límite**, estado, responsable, justificante | N–1 cliente |
| DOCUMENTO | tipo, fecha, ruta, **conservar hasta** | N–1 cliente, opcional trabajador |
| FACTURA / LINEA_FACTURA | número único, fecha, periodo, concepto, importes, **estado de cobro** | N–1 cliente; líneas por servicio |
| CONSULTA | fecha, canal, motivo, empleado que atiende, estado, resolución | N–1 cliente |
| AUDITORIA_CAMBIO | tabla, registro, campo, valor anterior, nuevo, usuario, fecha | Rellenada por trigger |

Así se resuelve el problema del cliente: **NIF y número de factura únicos** eliminan duplicados, un solo registro por cliente sustituye a las listas en carpetas, y **conservar hasta** permite la política de borrado. Volumen: 2.400 clientes confirmado; trabajadores y nóminas, estimados y marcados como supuesto.

## 4. Todo lo que queda por hacer

Las issues de GitHub son la lista oficial. Resumen por persona; en negrita, lo que entra en el borrador del 06/11:

| Raúl (Redes, coordinación) | Arian (Sistemas) | Álvaro (Bases de datos) |
|---|---|---|
| **#1 Pasar al profesor lo pendiente y confirmar fechas** | **#14 Plantilla Windows Server** | **#22 Modelo .sql con la tabla de arriba** |
| **#2 PC de integración** | **#15 dc1: scripts 01-02** | **#23 ubu-svc + PostgreSQL** |
| **#3-#6 Plantilla Ubuntu, VMnets, ubu-fw, Kea, Unbound** | **#16 OU, AGDLP, usuarios CSV** | #24 Roles, TLS, pgaudit + **auditoría bancaria (D21)** |
| **#7 Integración 1** (con Arian) | **#17 GPO** | #25 Consultas y mantenimiento |
| **#8-#9 Pruebas de la matriz y dependencias** | **Plan Windows 7 (D19)** | #26 Copias y RTO medido |
| #10 Presupuesto con inventario real | #18 Cuentas Linux, cambios, parches | **RPO/RTO (D18) en #29** |
| #11 OpenVPN + TOTP + política de teletrabajo (D20) | #19-#21 Incidencia, dc2, BitLocker/LAPS | #27-#28 Wazuh, Zabbix |
| SSH bastión (PLAN-RED) | | |
| **#32 Capítulos 1-3 con la respuesta del cliente** | | |

Comunes: **#29 matriz de riesgos (añadir Windows 7)**, #30 documentos de Seguridad, #31 simulacro, #33 capítulos 4-8.

## 5. Cómo empezar (hoy, 28/10)

### 5.1 Lo que hace cada uno una sola vez (30-45 min)
1. **Aceptar la invitación** al repositorio `RUYA237/gestion-norte-asir` (Raúl la envía desde Settings → Collaborators).
2. Instalar **Git para Windows** y **VMware Workstation** (gratuito para uso personal).
3. Clonar y configurar tu nombre real (cuenta para la aportación individual):
   ```powershell
   git clone https://github.com/RUYA237/gestion-norte-asir.git
   cd gestion-norte-asir
   git config user.name "Tu Nombre"
   git config user.email "tu-correo-de-github"
   ```
4. Descargar las ISO: **Windows Server 2025 (evaluación)** del Evaluation Center de Microsoft y **Ubuntu Server 24.04 LTS** de ubuntu.com. Las ISO no se suben a Git.
5. Leer en este orden: `README.md`, `PLAN-RED.md`, `DECISIONES.md`, este documento y tus issues (filtra por tu etiqueta).

### 5.2 Rutina de cada sesión de trabajo
```powershell
git pull --rebase            # antes de empezar
# ... trabajas, guardas scripts en red/, ad/, svc/ o bd/ y capturas en evidencias/<módulo>/
git add .
git commit -m "Kea con reservas de servidores. Refs #6"
git pull --rebase
git push
```
- Commits pequeños, uno por tarea, con el número de issue. `Cierra #6` la cierra al subir.
- Una línea en tu bitácora (`docs/bitacoras/<tu-nombre>.md`) al terminar.
- Instantánea de VMware antes de cada paso importante.
- Nada de contraseñas en Git: gestor compartido (Bitwarden o KeePass).

### 5.3 Primer paso de cada uno
| Quién | Hoy | Resultado que se sube |
|---|---|---|
| Raúl | Plantilla Ubuntu generalizada; VMnet11-14 host-only sin DHCP; ubu-fw con 5 NIC | Capturas del editor de redes y `ip -br link` en `evidencias/redes/` |
| Arian | Plantilla Windows Server con `sysprep /generalize /oobe /shutdown`; clon dc1; script 01 | Log de `C:\Evidencias` en `evidencias/so/` |
| Álvaro | Modelo entidad-relación a partir de la tabla del punto 3 | `bd/modelo.sql` y el diagrama en `bd/` |

### 5.4 Chats de Claude
- **Raúl**: este chat, para coordinación y memoria, y el chat de Redes.
- **Arian y Álvaro**: cada uno su chat de módulo, en su cuenta, con el prompt de su módulo y adjuntando `CLIENTE-GESTION-NORTE.md`, `PLAN-RED.md` y este documento.
- Lo que decida un chat se apunta en `DECISIONES.md`, no se queda en la conversación.

### 5.5 Puntos de control
| Fecha | Qué tiene que funcionar |
|---|---|
| Jue 29/10 | Plantillas compartidas; ubu-fw enrutando; dc1 con el bosque |
| Dom 01/11 | Integración 1: cliente con IP de Kea, resuelve el dominio, se une; modelo cargado en PostgreSQL |
| Mié 04/11 | Pruebas de la matriz, GPO, roles de BD, matriz de riesgos y capítulos 1-3 |
| Vie 06/11 | **Borrador**: todo escrito; lo esencial probado; resto "pendiente de verificar" |

## 6. Pendiente con el cliente (lo que hay que pedir o asumir)
- **Inventario del lunes**: subirlo al proyecto y al repositorio.
- Resultado de la comprobación de la app antigua de nóminas.
- Antigüedad y función de los 2 servidores.
- Qué es el disco compartido (NAS, PC, servidor) y dónde está.
- Validación de nuestra propuesta de RPO/RTO.
- Partidas del presupuesto que aceptan.
