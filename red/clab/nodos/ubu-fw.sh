#!/bin/bash
# ubu-fw en la maqueta: router entre VLAN (troncal 802.1Q), extremo de los túneles de
# las sedes, OSPF y salida a Internet con dos líneas (fibra principal y 4G de respaldo).
# Las direcciones IP y las rutas están en frr.conf; aquí solo se crean las interfaces.
set -eu
. /config/lib-router.sh
preparar

# 1. VLAN de Zaragoza sobre el troncal que llega de sw-zgz-core
vlans troncal 10 20 30 40

# 2. Túneles WireGuard: uno por sede y por línea. Escucha en 51820-51823/udp.
#    fwmark marca los paquetes cifrados de cada túnel para mandarlos por su línea.
tunel wg-hue-f ubu-fw rt-hue listen-port 51820 fwmark 0x3
tunel wg-hue-m ubu-fw rt-hue listen-port 51821 fwmark 0x4
tunel wg-ter-f ubu-fw rt-ter listen-port 51822 fwmark 0x3
tunel wg-ter-m ubu-fw rt-ter listen-port 51823 fwmark 0x4

# 3. Enrutamiento por marca: la tabla 3 sale por la fibra y la 4 por el 4G.
#    Si la línea cae, su tabla se queda en "unreachable" y el túnel muere en lugar
#    de irse por la otra línea: así OSPF detecta la caída y cambia de túnel.
ip rule add fwmark 0x3 lookup 3 priority 100
ip rule add fwmark 0x4 lookup 4 priority 101
ip route add unreachable default metric 4000 table 3
ip route add unreachable default metric 4000 table 4

# 4. Firewall (misma política que el ubu-fw real, con conjuntos para las tres sedes)
nft -f /config/nftables.nft

# 5. FRR: direcciones, rutas estáticas y OSPF
arrancar_frr
echo "ubu-fw configurado"
