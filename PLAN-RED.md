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
| 50 | ADMIN | 10.1.50.0/24 | VMnet15 | Administración y facturación | Configurado el 14/11, pendiente de verificar |
| 60 | ATENCION | 10.1.60.0/24 | VMnet16 | Atención y gestión de clientes | Configurado el 14/11, pendiente de verificar |
| 70 | IMPRESORAS | 10.1.70.0/24 | VMnet17 | Impresoras y multifunción | Configurado el 14/11, pendiente de verificar |
| 80 | INVITADOS | 10.1.80.0/24 | VMnet18 | Wi-Fi de visitas (red pública), aislada y solo Internet (D28) | Configurado el 14/11, pendiente de verificar |
| — | VPN-USR | 10.0.1.0/24 | tun0 | Teletrabajo (no es una VLAN) | Propuesto |
| — | VPN-ADM | 10.0.2.0/24 | tun1 | Administradores en remoto; solo llegan al bastión (no es una VLAN) | Propuesto |
| — | WG-SEDES | 10.255.0.0/16 | wg-* | Un /30 por sede hacia ubu-fw: Huesca 10.255.12.0/30, Teruel 10.255.13.0/30, 4ª sede 10.255.14.0/30. Loopbacks OSPF 10.255.0.1 (ubu-fw), .2 (rt-hue), .3 (rt-ter) | Maqueta containerlab (D35) |
| 30 (Hu) | LABORAL Huesca | 10.2.30.0/24 | — | Detrás de rt-hue, en la maqueta de containerlab (`red/clab/`) | Maqueta (D34) |

## Sedes remotas (D30)
Topología en estrella: **ubu-fw es el firewall** de las tres sedes (en producción, una pareja ubu-fw1/ubu-fw2 con VRRP, D38). Huesca y Teruel no tienen servidor ni firewall propio, solo un router pequeño con VPN (rt-hue, rt-ter) y cuatro switches gestionables (D36).

| VLAN | Zaragoza | Huesca | Teruel | Motivo |
|---|---|---|---|---|
| 10 Gestión | Sí | Solo equipos de red | Solo equipos de red | IT en Zaragoza. En las sedes solo la IP de gestión del switch y del AP (10.<sede>.10.2…), administrados desde la VLAN 10 de Zaragoza (D36) |
| 20 Servidores | Sí (núcleo central) | No | No | Los 2 servidores están en Zaragoza; el presupuesto no da para servidores por sede |
| 30-60 Departamentos | Sí | Sí | Sí | Personal de los 4 departamentos en todas (reparto estimado) |
| 70 Impresoras | Sí (7) | Sí (3) | Sí (2) | Dato del cliente, 28/10 |
| 80 Invitados | Sí | Sí | Sí | Sale a Internet por ubu-fw, aislada de la empresa (D38) |

Qué hace el router de sede:
- Crea las VLAN de la sede (subinterfaces 802.1Q) con puerta de enlace 10.<sede>.<vlan>.1.
- Envía **todo** el tráfico de las VLAN de empresa por WireGuard a ubu-fw (ruta por defecto por el túnel). No enruta entre sus VLAN locales: quien decide es ubu-fw.
- DHCP de las VLAN de empresa con relay hacia Kea.
- VLAN 80: sale a Internet por ubu-fw, aislada del resto; no usa el DNS interno.
- Riesgo asumido: si cae la fibra de Zaragoza, las tres sedes se quedan sin servicio. Sin 4G en el diseño (D38).
- Un túnel WireGuard por sede hacia ubu-fw y OSPF área 0 dentro del túnel, con saludos cada 2 s y caída de vecino a los 8 s (D35).

## Switches (D36)
- Zaragoza: dos núcleos (raíz y respaldo, STP) y tres de acceso; Huesca y Teruel: cuatro switches de sede cada una (D36).
- Las VLAN se enrutan en ubu-fw (troncal al núcleo), nunca en un switch de capa 3.
- Diagrama: `docs/diagramas/red-v2.png`. Maqueta: `red/clab/`.

## Seguridad de las VLAN (obligatorio en lab y en producción)
- Laboratorio: VMnet11-18 solo anfitrión y sin DHCP de VMware. Solo VMnet11 (VLAN 10) tiene adaptador del PC, porque el anfitrión hace de equipo de administración (10.1.10.10); el resto no. Ninguna VM salvo ubu-fw tiene más de una NIC.
- ubu-fw: nftables con `policy drop` en input y forward, registro de lo denegado. `ip_forward` se activa **solo después** de cargar nftables.
- Antisuplantación: `rp_filter=1` (cada red solo entra por su interfaz). Sin redirecciones ICMP ni enrutamiento de origen. IPv6 apagado en el kernel (`ipv6.disable=1` en GRUB; no se usa).
- Servicios de ubu-fw solo donde hacen falta: DHCP/DNS en las VLAN de usuarios, SSH solo desde VLAN 10 y VPN-ADM, en la WAN solo 1194/udp (OpenVPN) y 51820-51821/udp (WireGuard: un puerto por túnel).
- Producción (switches): puertos de acceso con su VLAN fija, VLAN nativa sin uso (nunca la 1), troncal solo hacia ubu-fw o el router de sede, puertos libres apagados, DHCP snooping y protección de puerto. 802.1X, propuesto.

VMnet11-18: tipo host-only, **sin** "Use local DHCP service". "Connect a host virtual adapter" solo en VMnet11.

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


## Sedes remotas en el laboratorio de VMware (16/11)

Cada sede es un router pequeño (rt-hue, rt-ter: Ubuntu Server, 1 GB, 2 tarjetas: NAT de VMware como «Internet» y LAN en vmnet19 o vmnet20) unido a ubu-fw por un túnel WireGuard. La LAN de la sede no se conecta a ubu-fw: solo llega por el túnel.

| Sede | Túnel | Puerto en ubu-fw | LAN | Router | Estado |
|---|---|---|---|---|---|
| Huesca | 10.255.12.0/30 (ubu-fw .1, rt-hue .2) | 51820/udp | 10.2.30.0/24 (vmnet19) | rt-hue 10.2.30.1 | Implementado con pruebas de tráfico (15/11) |
| Teruel | 10.255.13.0/30 (ubu-fw .1, rt-ter .2) | 51821/udp | 10.3.40.0/24 (vmnet20) | rt-ter 10.3.40.1 | Túnel comprobado con ping (16/11); pruebas de tráfico pendientes de verificar |

Rutas estáticas por AllowedIPs: el router de cada sede manda a ubu-fw lo que va a 10.1.0.0/16 y ubu-fw manda a la sede su 10.2.0.0/16 o 10.3.0.0/16. Las sedes tienen los permisos de un departamento (grupos DEP, INTERNAS y CON_DNS de `nftables.conf`). OSPF y VRRP, propuestos (D42). Ficheros en `red/wireguard/`.
