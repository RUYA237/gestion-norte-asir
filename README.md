# Gestión Norte · Proyecto Intermodular 2º ASIR

Equipo consultor: **Consultoría Kalima**. Para empezar: [`docs/ANALISIS-Y-ARRANQUE.md`](docs/ANALISIS-Y-ARRANQUE.md). Datos del cliente: [`docs/CLIENTE-GESTION-NORTE.md`](docs/CLIENTE-GESTION-NORTE.md).

Rediseño de la infraestructura IT de Gestión Norte (asesoría laboral y fiscal, 150 personas, sedes en Zaragoza, Huesca y Teruel). Módulos: Redes, Seguridad y alta disponibilidad, Sistemas operativos y SGBD.

**Entregas:** borrador 06/11 · final 17/11 23:59 · defensa 23-27/11 (fechas pendientes de confirmar: el enunciado pone 2025).

## Equipo y reparto
| Persona | Responsable de | Seguridad (repartida) |
|---|---|---|
| Raúl | Redes: ubu-fw, VMnets, nftables, Kea, Unbound, WireGuard. Coordinación | OpenVPN + TOTP, Suricata |
| Arian | Sistemas: dc1, dc2, OU, AGDLP, usuarios CSV, GPO, ficheros, inventario y parches | LAPS, BitLocker, contraseñas |
| Álvaro | Bases de datos: modelo, PostgreSQL, roles, consultas, rendimiento | Copias restic, Wazuh, Zabbix |

Cada persona deja **al menos una evidencia propia en los cuatro módulos** (las cuatro rúbricas puntúan la aportación individual).

## Estructura
| Carpeta | Contenido |
|---|---|
| `red/` | netplan, `nftables.conf`, Kea, Unbound, OpenVPN, WireGuard |
| `ad/` | Scripts PowerShell numerados (`01-...ps1`) y CSV de usuarios |
| `svc/` | Ficheros Quadlet (`.container`) y configuración de ubu-svc |
| `bd/` | Modelo `.sql`, roles, `pg_hba.conf`, `postgresql.conf`, consultas |
| `seguridad/` | Matriz de riesgos, RPO/RTO, políticas, procedimiento de incidentes |
| `evidencias/<módulo>/` | Capturas y salidas de comandos: `AAAAMMDD-persona-tema.png/.txt` |
| `docs/diagramas/` | Diagramas Excalidraw (abrir en excalidraw.com con Ctrl+O) |
| `docs/bitacoras/` | Diario individual de cada persona: qué hizo, qué falló, qué cambió |
| `memoria/` | Borradores de los capítulos |

Documentos raíz: [`DECISIONES.md`](DECISIONES.md) (registro de decisiones) y [`PLAN-RED.md`](PLAN-RED.md) (VLAN e IP: fuente única).

## Cómo trabajamos
1. Cada uno desarrolla en su PC con VMware Workstation sobre las **plantillas base** (Windows Server con sysprep; Ubuntu con `cloud-init clean` y `machine-id` vacío).
2. Todo lo que se configura acaba en un **script o fichero en Git**. Quien lo prueba lo ejecuta en su plantilla y sube su captura a `evidencias/`.
3. Los **OVA** solo en hitos y por Drive o disco externo, nunca en Git. Se importan en un VMnet aislado.
4. El PC de integración (32 GB) ejecuta todo junto para las capturas finales.
5. Una issue por tarea, con responsable y módulo. Commits con vuestro nombre: son la prueba de la aportación individual.

## Una tarea está hecha cuando
- [ ] Script o configuración en Git, con commit propio.
- [ ] Salida de "Verificar" y captura en `evidencias/<módulo>/`.
- [ ] Ficha de 5 puntos: qué, cómo, por qué, alternativas descartadas, cómo se comprobó.
- [ ] Marcada como **implementado / propuesto / pendiente de verificar**.
- [ ] Apuntada en tu bitácora (`docs/bitacoras/`).

## Reglas
- Nada de contraseñas, claves ni certificados privados en Git (gestor de contraseñas compartido).
- Nunca encender a la vez un controlador de dominio y su clon.
- Instantánea de VMware antes de cada paso importante.
- No afirmar cumplimiento del RGPD: "alineado con" o "propuesta para cumplir".
- Si una decisión cambia, se cambia primero en `DECISIONES.md`.

## Cómo se sube algo (sin saber Git)
Después de cada tarea, el chat te da el bloque de comandos. Siempre es este y solo cambia el mensaje:
```powershell
cd RUTA\gestion-norte-asir
git pull --rebase
git add .
git commit -m "Qué has hecho. Refs #número"
git push
```
Si algo falla, copia el error entero en el chat. Los ficheros nuevos se copian antes a la carpeta que toque (`red/`, `ad/`, `bd/`, `evidencias/<módulo>/`, `memoria/`).
