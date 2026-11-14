# Configuración de ubu-fw (red/)

Estado: las VLAN 10 a 40 se implementaron en VMware el 03/11 (capturas en `evidencias/redes/20261103-*` y `20261104-*`). La versión del 14/11 añade las VLAN 50 a 80, las reglas de los servicios y la hora: validada en sintaxis (`nft -c`), pendiente de verificar en ubu-fw. OpenVPN y el bastión son propuestos y no están en estos ficheros.

| Fichero del repo | Ruta en ubu-fw | Qué hace |
|---|---|---|
| `ubu-fw-tarjetas.vmx.txt` | Fichero `.vmx` de la máquina (en el anfitrión) | Nueve tarjetas con MAC fija: WAN por NAT y VMnet11 a VMnet18 para las VLAN 10 a 80 |
| `config-red-vlan.yaml` | `/etc/netplan/config-red-vlan.yaml` | Nombra las tarjetas por MAC (`wan`, `v10` a `v80`) y les da la IP `.1` de cada VLAN |
| `sysctl-seguridad-red.conf` | `/etc/sysctl.d/99-seguridad-red.conf` | Antisuplantación (rp_filter), sin redirecciones, sin enrutamiento de origen |
| `nftables.conf` | `/etc/nftables.conf` | Firewall: política por defecto denegar y registrar |
| `activar-reenvio.conf` | `/etc/systemd/system/nftables.service.d/activar-reenvio.conf` | Activa el reenvío solo después de cargar las reglas |
| `dns-gestion-norte.conf` | `/etc/unbound/unbound.conf.d/dns-gestion-norte.conf` | DNS: zona de AD hacia dc1/dc2, el resto a Internet |
| `kea-dhcp4.conf` | `/etc/kea/kea-dhcp4.conf` | DHCP de las VLAN 30, 40, 50, 60 y 80 |
| `chrony-gestion-norte.conf` | `/etc/chrony/conf.d/gestion-norte.conf` | Sirve la hora a las VLAN 10 y 20 |
| `instalar-ubu-fw.sh` | Se ejecuta con sudo desde esta carpeta | Instala los paquetes, copia cada fichero a su ruta, valida y arranca |

## Matriz de permisos de `nftables.conf` (14/11)

Todo lo que no aparece se deniega y se registra.

| Origen | Destino | Permitido |
|---|---|---|
| VLAN 10 a 70 | ubu-fw | Ping con límite |
| VLAN 30, 40, 50, 60 y 80 | ubu-fw | DHCP |
| VLAN 10 a 60 | ubu-fw | DNS |
| VLAN 10 y 20 | ubu-fw | Hora (NTP) |
| VLAN 10 | ubu-fw | SSH |
| VLAN 30 a 60 | Internet | Web (TCP 80 y 443, UDP 443) |
| VLAN 30 a 60 | dc1 y dc2 | Puertos de Active Directory |
| VLAN 30 a 60 | ubu-svc (10.1.20.20) | 443 (web por Caddy). El 5432 de PostgreSQL no se abre |
| VLAN 30 a 60 | wazuh01 (10.1.20.30) | 1514 y 1515 (agentes) |
| VLAN 30 a 60 | VLAN 70 | Impresión (631 y 9100) |
| VLAN 80 | Internet | Web y DNS solo hacia Quad9; nada hacia direcciones privadas |
| VLAN 10 | VLAN 20 | SSH, 443, escritorio remoto, WinRM con TLS y ping |
| VLAN 10 y 20 | Internet | Web (actualizaciones) |

Los invitados no usan el DNS interno: reciben Quad9 por DHCP para que no puedan consultar los nombres del dominio. Los equipos de la VLAN 20 se ven entre sí sin pasar por ubu-fw; eso lo limita el cortafuegos de cada servidor (propuesto).

El reenvío de paquetes (`ip_forward`) no está en sysctl: lo activa `nftables.service` después de cargar las reglas
(`/etc/systemd/system/nftables.service.d/activar-reenvio.conf`), para que nunca haya un momento con el reenvío activo y sin firewall.

IPv6 se apaga en el kernel, no con sysctl: el sysctl no llegaba a las tarjetas renombradas por netplan (comprobado el 03/11: `all` y `default` a 1, `wan` y `v30` a 0). En `/etc/default/grub`: `GRUB_CMDLINE_LINUX_DEFAULT="quiet splash ipv6.disable=1"`, después `update-grub` y reinicio. Verificado tras el reinicio: sin direcciones `fe80::` y `ipv6.disable=1` en `/proc/cmdline`.
