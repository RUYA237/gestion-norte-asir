# Túneles WireGuard hacia Huesca y Teruel (VMware)

Estado a 16/11: túnel de Huesca **implementado con pruebas de tráfico** (15/11); túnel de Teruel **implementado y comprobado con ping** (16/11), con las pruebas desde un equipo de su LAN **pendientes de verificar**. No probado: reinicio de los routers, corte de un túnel sin afectar al otro, tráfico Huesca-Teruel y salida a Internet de las sedes (túnel dividido). OSPF y VRRP quedan propuestos (D42).

Los ficheros de aquí no llevan claves privadas: cada máquina genera la suya con `umask 077; wg genkey > /etc/wireguard/X.key` y no sale de ella.

| Fichero | Ruta en la máquina | Qué hace |
|---|---|---|
| `ubu-fw-wg-hue.conf` | ubu-fw `/etc/wireguard/wg-hue.conf` | Túnel 10.255.12.0/30, escucha en 51820/udp |
| `ubu-fw-wg-ter.conf` | ubu-fw `/etc/wireguard/wg-ter.conf` | Túnel 10.255.13.0/30, escucha en 51821/udp |
| `rt-hue-wg-fw.conf`, `rt-ter-wg-fw.conf` | rt-hue y rt-ter `/etc/wireguard/wg-fw.conf` | Extremo de la sede: manda a ubu-fw lo que va a 10.1.0.0/16 |
| `rt-hue-netplan.yaml`, `rt-ter-netplan.yaml` | `/etc/netplan/01-rt-*.yaml` | Tarjetas por MAC: `wan` (NAT) y `lan` (vmnet19 o vmnet20) |
| `cli-test-huesca-netplan.yaml` | cli-test `/etc/netplan/99-huesca.yaml` | Equipo de pruebas de la LAN de la sede |

Pasos (cada uno, en la máquina que indica): 1) netplan y reinicio (rt-*); 2) `apt install wireguard` y claves (todas); 3) en ubu-fw, recibir la clave pública con `read -r X && X=$(echo "$X" | tr -d '[:space:]') && echo ${#X}` (debe dar 44) y crear el fichero del túnel; 4) en rt-*, el fichero del túnel y `net.ipv4.ip_forward=1` en `/etc/sysctl.d/99-reenvio.conf`; 5) `systemctl enable --now wg-quick@wg-hue` (ubu-fw) y `wg-quick@wg-fw` (rt-*); 6) `wg show` y ping al otro extremo.

En `nftables.conf` los túneles están en los grupos DEP, INTERNAS y CON_DNS (mismos permisos que un departamento), la entrada acepta 51820 y 51821/udp por la WAN y el NAT cubre 10.1/10.2/10.3.0.0/16. En Unbound se escucha en 10.255.12.1 y 10.255.13.1 y se admiten 10.2.0.0/16 y 10.3.0.0/16.

Pruebas del 15/11 desde cli-test (10.2.30.50): DNS del dominio e Internet por el túnel correctos; 445 de dc1 abierto; 443 de ubu-svc llega (rechaza, sin web); 5432, SSH a ubu-fw y puerta de enlace de la VLAN 30 sin respuesta y registrados con `IN=wg-hue`. Capturas: `evidencias/redes/2026111[56]-raul-wireguard-*.png`; memoria, apartado 4.5.3.

Pruebas del 16/11 desde cli-test en la LAN de Teruel (10.3.40.50, DNS 10.255.13.1): mismos resultados que en Huesca, con registro `IN=wg-ter`. Capturas: `evidencias/redes/20261116-raul-wireguard-21..24-*.png`. Tras reiniciar ubu-fw el 16/11 los dos túneles se restablecieron solos (`20261116-raul-reinicio-02-wg-show.png`).
