# Configuración de ubu-fw (red/)

Cada fichero del repositorio va, con ese nombre, a la ruta indicada en ubu-fw. Estado: implementado en el laboratorio de VMware el 03/11 para las VLAN 10 a 40 (capturas en `evidencias/redes/20261103-*` y `20261104-*`). Las VLAN 50 a 80, las reglas de los servicios de ubu-svc, wazuh01 y bkp01, OpenVPN y el bastión son propuestos y no están en estos ficheros.

| Fichero del repo | Ruta en ubu-fw | Qué hace |
|---|---|---|
| `config-red-vlan.yaml.plantilla` | `/etc/netplan/config-red-vlan.yaml` | Nombra las tarjetas por MAC (`wan`, `v10`, `v20`, `v30`, `v40`) y les da la IP `.1` de cada VLAN |
| `sysctl-seguridad-red.conf` | `/etc/sysctl.d/99-seguridad-red.conf` | Antisuplantación (rp_filter), sin redirecciones, sin enrutamiento de origen |
| `nftables.conf` | `/etc/nftables.conf` | Firewall: política por defecto denegar y registrar |
| `dns-gestion-norte.conf` | `/etc/unbound/unbound.conf.d/dns-gestion-norte.conf` | DNS: zona de AD hacia dc1/dc2, el resto a Internet |
| `kea-dhcp4.conf` | `/etc/kea/kea-dhcp4.conf` | DHCP de las VLAN 30 y 40 |

El reenvío de paquetes (`ip_forward`) no está en sysctl: lo activa `nftables.service` después de cargar las reglas
(`/etc/systemd/system/nftables.service.d/activar-reenvio.conf`), para que nunca haya un momento con el reenvío activo y sin firewall.

IPv6 se apaga en el kernel, no con sysctl: el sysctl no llegaba a las tarjetas renombradas por netplan (comprobado el 03/11: `all` y `default` a 1, `wan` y `v30` a 0). En `/etc/default/grub`: `GRUB_CMDLINE_LINUX_DEFAULT="quiet splash ipv6.disable=1"`, después `update-grub` y reinicio. Verificado tras el reinicio: sin direcciones `fe80::` y `ipv6.disable=1` en `/proc/cmdline`.
