# Configuración de ubu-fw (red/)

Cada fichero del repositorio va, con ese nombre, a la ruta indicada en ubu-fw. Estado: borrador, pendiente de verificar.

| Fichero del repo | Ruta en ubu-fw | Qué hace |
|---|---|---|
| `config-red-vlan.yaml.plantilla` | `/etc/netplan/config-red-vlan.yaml` | Nombra las tarjetas por MAC (`wan`, `v10`, `v20`, `v30`, `v40`) y les da la IP `.1` de cada VLAN |
| `sysctl-seguridad-red.conf` | `/etc/sysctl.d/99-seguridad-red.conf` | Antisuplantación (rp_filter), sin redirecciones, sin IPv6 |
| `nftables.conf` | `/etc/nftables.conf` | Firewall: política por defecto denegar y registrar |
| `dns-gestion-norte.conf` | `/etc/unbound/unbound.conf.d/dns-gestion-norte.conf` | DNS: zona de AD hacia dc1/dc2, el resto a Internet |
| `kea-dhcp4.conf` | `/etc/kea/kea-dhcp4.conf` | DHCP de las VLAN 30 y 40 |

El reenvío de paquetes (`ip_forward`) no está en sysctl: lo activa `nftables.service` después de cargar las reglas
(`/etc/systemd/system/nftables.service.d/activar-reenvio.conf`), para que nunca haya un momento con el reenvío activo y sin firewall.
