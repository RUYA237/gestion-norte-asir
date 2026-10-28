# Registro de decisiones

Formato: fecha · decisión · por qué · alternativa descartada · estado. Una decisión nueva se añade abajo; una que cambia se marca como "sustituida" y se enlaza a la nueva. Sirve de base al apartado 3.2 de la memoria.

| # | Fecha | Decisión | Por qué | Descartado | Estado |
|---|---|---|---|---|---|
| D01 | 24/10 | Active Directory en Windows Server con 2 DC (dc1 con escritorio, dc2 Server Core) | Identidad centralizada, GPO, BitLocker y LAPS nativos; tolerancia a la caída de un DC | OpenLDAP, FreeIPA, Samba AD | Decidido |
| D02 | 26/10 | Ubuntu (ubu-fw) como firewall, router, DHCP (Kea), DNS (Unbound), VPN y bastión | Un único punto de control y registro en el borde; contenido propio para Redes | DHCP y DNS en los DC con relay; OPNsense | Decidido |
| D03 | 26/10 | Unbound reenvía `ad.gestionnorte.es` a dc1 y dc2; los clientes envían las actualizaciones dinámicas a los DC | AD necesita su DNS con registros SRV y actualización segura | Kea registrando en AD | Decidido |
| D04 | 26/10 | Sin failover de DHCP: ubu-fw es punto único de fallo reconocido | Recursos del laboratorio | — | Propuesto para producción: pareja con VRRP y Kea en alta disponibilidad |
| D05 | 26/10 | OpenVPN con certificado + contraseña AD + TOTP | MFA real con paquetes soportados de Ubuntu | Firezone (autoalojado sin soporte en producción, MFA vía OIDC externo); WireGuard (sin MFA nativo) | Decidido |
| D06 | 26/10 | Servicios en ubu-svc con Podman y Quadlet: PostgreSQL, Zabbix, Caddy | Sin demonio, unidades systemd versionables | Docker | Decidido |
| D07 | 26/10 | PostgreSQL securizado: SCRAM, TLS 1.3, `pg_hba` restrictivo, roles de mínimo privilegio, pgaudit sin volcar datos personales | Datos fiscales y bancarios | `log_statement=all`, md5 | Decidido |
| D08 | 26/10 | Wazuh en VM propia en el PC de integración | Trazabilidad y SIEM | Graylog/ELK (más RAM), rsyslog (sin correlación) | Decidido |
| D09 | 26/10 | Laboratorio distribuido: VMware Workstation en cada PC; compartir por scripts en Git y OVA en hitos | Sin servidor común; los PCs del equipo tienen hasta 32 GB | Proxmox en un portátil de 8 GB | Decidido |
| D10 | 26/10 | Un VMnet por VLAN (VMnet = 10 + VLAN/10) | No es fiable pasar 802.1Q por VMware Workstation | Trunk 802.1Q en VMware | Decidido (pendiente de verificar el límite de 10 NIC por VM) |
| D11 | 27/10 | Plan de red del chat de Redes como fuente única (ver `PLAN-RED.md`) | Evitar numeraciones distintas entre chats | Numeración del 24/10 (60 invitados, 80 VPN, 90 copias) | Decidido |
| D12 | 27/10 | Copias en `bkp01` (10.1.20.40) con rest-server en modo solo-añadir + copia al disco externo del PC de integración | Protección frente a ransomware; 3-2-1 | VLAN de copias propia | Decidido |
| D13 | 27/10 | WSUS propuesto; Windows Update por GPO en el laboratorio | Coste de RAM y tiempo | WSUS implementado | Decidido |
| D14 | 27/10 | Kubernetes descartado en el laboratorio; k3s propuesto para producción | Complejidad sin alta disponibilidad con un nodo; ningún criterio lo pide | k3s de un nodo | Decidido |
| D15 | 27/10 | AD, firewall y Wazuh en VM; solo PostgreSQL, Zabbix y Caddy en contenedor | Un DC no se puede contenerizar; los contenedores comparten kernel | Todo en contenedores | Decidido |
| D16 | 27/10 | Alcance por niveles: 1 obligatorio, 2 si da tiempo, 3 propuesto | 10 días hasta el borrador sin máquinas montadas | Implementarlo todo | Decidido |

| D17 | 28/10 | Wi-Fi de visitas en VLAN 80 aislada, solo web a Internet | El cliente nos pide valorarlo; hay atención presencial | Sin red de invitados; invitados en la red de empleados | Propuesto |
| D18 | 28/10 | RPO/RTO por servicio propuestos al cliente (tabla en `docs/ANALISIS-Y-ARRANQUE.md`) | El cliente pide que concretemos cuánto trabajo pueden perder | Un único RPO para todo | Propuesto; restauración medida en el lab |
| D19 | 28/10 | Plan Windows 7: inventario, comprobar app antigua de nóminas, VLAN 99 de cuarentena, migrar o sustituir, app antigua en VM aislada | ~45 equipos sin parches desde 2020 | Mantenerlos en la red de usuarios | Propuesto |
| D20 | 28/10 | Teletrabajo solo con equipos de la empresa (certificado VPN en equipo gestionado) | 45 portátiles para 65 teletrabajadores; un equipo propio no se puede cifrar ni gestionar | VPN desde equipos personales | Propuesto; déficit de portátiles al presupuesto |
| D21 | 28/10 | Auditoría de cambios en datos bancarios con trigger y tabla de auditoría, además de pgaudit | El cliente quiere saber quién cambia una cuenta bancaria | Solo pgaudit | Implementar (nivel 1) |

## Pendiente de decidir
- De quién es el PC de integración (32 GB).
- Confirmar con el profesor fechas, si participa el módulo de aplicaciones web y si quiere ver las 3 sedes.
