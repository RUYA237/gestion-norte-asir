# Plan de red (fuente única)

Si algo de aquí cambia, se cambia primero en este fichero y después en las configuraciones.

## Direccionamiento
- Esquema `10.<sede>.<vlan>.0/24`. Sede: 1 Zaragoza, 2 Huesca, 3 Teruel, 4 futura cuarta sede, 0 túneles entre sedes.
- El mismo ID de VLAN significa el mismo uso en todas las sedes.
- Dentro de cada /24: `.1` puerta de enlace · `.2-.49` estáticas y reservas Kea · `.50-.249` pool DHCP · `.250-.254` reserva.
- Dominio AD: `ad.gestionnorte.es`.

## VLAN (Zaragoza; Huesca y Teruel repiten los ID con 10.2.x y 10.3.x)
| VLAN | Nombre | Red | VMnet (lab) | Uso | Laboratorio |
|---|---|---|---|---|---|
| — | WAN | DHCP de VMware | VMnet8 (NAT) | Salida de ubu-fw | Sí |
| 10 | GESTION | 10.1.10.0/24 | VMnet11 | Equipos de administración (PAW) | Sí |
| 20 | SERVIDORES | 10.1.20.0/24 | VMnet12 | dc1, dc2, ubu-svc, wazuh01, bkp01 | Sí |
| 30 | LABORAL | 10.1.30.0/24 | VMnet13 | Asesoría laboral | Sí (cli01) |
| 40 | FISCAL | 10.1.40.0/24 | VMnet14 | Asesoría fiscal | Sí |
| 50 | ADMIN | 10.1.50.0/24 | VMnet15 | Administración y facturación | Diseño |
| 60 | ATENCION | 10.1.60.0/24 | VMnet16 | Atención y gestión de clientes | Diseño |
| 70 | IMPRESORAS | 10.1.70.0/24 | VMnet17 | Impresoras y multifunción | Diseño |
| 80 | INVITADOS | 10.1.80.0/24 | VMnet18 | Wi-Fi de visitas (red pública), aislada y solo Internet (D28) | Diseño |
| 90 | VPN-USR | 10.1.90.0/24 | tun0 | Teletrabajo | Sí (paso VPN) |
| 91 | VPN-ADM | 10.1.91.0/24 | tun0 (CCD) | Administradores en remoto | Sí (paso VPN) |
| 99 | CUARENTENA | 10.1.99.0/24 | — | Equipos con Windows 7 hasta migrarlos; sin Internet (D19) | Diseño |
| — | WG-SEDES | 10.0.0.0/24 | wg0 | Túneles: ZGZ .1, Huesca .2, Teruel .3 | Nivel 3 |
| 30 (Hu) | LABORAL Huesca | 10.2.30.0/24 | VMnet19 | VM de Huesca que simula la sede | Nivel 3 (solo si sobra tiempo) |

VMnet11-19: tipo host-only, **sin** "Use local DHCP service" y **sin** "Connect a host virtual adapter".

## IP fijas (VLAN 20)
| Equipo | IP | Función |
|---|---|---|
| ubu-fw | 10.1.20.1 (y .1 en cada VLAN) | Firewall, router, Kea, Unbound, VPN, bastión |
| dc1 | 10.1.20.10 | AD DS, DNS de la zona, GPO, ficheros |
| dc2 | 10.1.20.11 | AD DS, DNS de la zona |
| ubu-svc | 10.1.20.20 | Podman: PostgreSQL, Zabbix, Caddy |
| wazuh01 | 10.1.20.30 | Wazuh |
| bkp01 | 10.1.20.40 | rest-server (restic, solo-añadir) |

## Matriz de permisos (resumen; detalle y justificación en el paso 1 del chat de Redes)
- Política por defecto: denegar y registrar.
- Departamentos → servidores: AD, ficheros, aplicaciones y agentes. Nunca al 5432 de PostgreSQL.
- Departamento ↔ departamento: denegado.
- Administración (SSH, RDP, WinRM) solo desde VLAN 10 o VPN-ADM a través del bastión.
- Invitados: solo web a Internet. DNS solo hacia ubu-fw (el 53 directo a Internet se bloquea).
- Cuarentena (VLAN 99): sin Internet y solo hacia el servidor de ficheros; nunca hacia la VLAN 20 completa.
- NAS (recurso SMB en dc1, D26): departamentos → 10.1.20.10:445/tcp, cada uno solo a su recurso (permisos AGDLP).

## SSH (acceso administrativo a Linux)

Solo Linux usa SSH. Windows se administra con PowerShell Remoting (WinRM), no con SSH.

| Origen | Destino | Puerto | Regla |
|---|---|---|---|
| VLAN 10 (GESTION) | ubu-fw, ubu-svc, wazuh01, bkp01 | 22/tcp | Permitido |
| VPN-ADM (10.1.91.0/24) | ubu-fw (salto) | 22/tcp | Permitido, solo hacia el bastión |
| Resto de VLAN y VPN-USR | cualquier Linux | 22/tcp | Denegado y registrado |
| Internet | ubu-fw | 22/tcp | Denegado (solo se llega por VPN) |

Solo el bastión (ubu-fw) acepta conexiones desde fuera de sus VLAN. Desde ubu-fw se salta a ubu-svc, wazuh01 y bkp01 con `ssh -J` o `ProxyJump`.

**Configuración de sshd en cada Linux:**
- Solo clave pública (`PasswordAuthentication no`, `KbdInteractiveAuthentication no`).
- Sin root (`PermitRootLogin no`).
- Acceso solo al grupo `gn-admin` (`AllowGroups gn-admin`).
- `MaxAuthTries 3`, `LoginGraceTime 30`.

**Registro y bloqueo:**
- Intentos fallidos a Wazuh (nivel 2).
- fail2ban en ubu-fw, con bloqueo de 10 minutos tras 5 fallos (nivel 2).

**Estado:**

| Pieza | Estado | Nivel |
|---|---|---|
| SSH con clave, sin root y con grupo permitido en ubu-fw, ubu-svc, wazuh01 y bkp01 | Pendiente de verificar | 1 |
| Reglas nftables de acceso a 22/tcp (desde VLAN 10 y VPN-ADM) | Pendiente de verificar | 1 |
| Intentos fallidos enviados a Wazuh | Pendiente de verificar | 2 |
| fail2ban | Pendiente de verificar | 2 |
| Certificados SSH con caducidad | Propuesto | — |
| WinRM por HTTPS en dc1 y dc2 | Propuesto | — |
