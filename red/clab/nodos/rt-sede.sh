#!/bin/bash
# Router de sede (rt-hue o rt-ter). Uso: rt-sede.sh NOMBRE NUMERO_DE_SEDE
#   rt-sede.sh rt-hue 2   |   rt-sede.sh rt-ter 3
# Crea las VLAN de la sede, los dos túneles hasta ubu-fw y la salida local de invitados.
set -eu
. /config/lib-router.sh
n=$1; s=$2
preparar

# 1. VLAN de la sede sobre el troncal que llega del switch
vlans troncal 10 30 40 80

# 2. Túneles hasta ubu-fw: por la fibra de Zaragoza y por su línea 4G.
#    persistent-keepalive: la sede llama cada 5 s para que el túnel esté siempre listo.
case $s in
  2) pf=51820; pm=51821 ;;
  3) pf=51822; pm=51823 ;;
esac
tunel wg-zgz-f "$n" ubu-fw endpoint 203.0.113.2:$pf persistent-keepalive 5
tunel wg-zgz-m "$n" ubu-fw endpoint 198.51.100.2:$pm persistent-keepalive 5

# 3. Invitados (VLAN 80): única red que sale directa a Internet por la fibra local.
#    Usa su propia tabla (80); el resto de VLAN usa la ruta por defecto que llega por
#    OSPF desde ubu-fw, es decir, el túnel.
ip rule add from 10.$s.80.0/24 lookup 80 priority 100
ip route add unreachable default metric 4000 table 80

# 4. Firewall de la sede: no enruta entre sus VLAN, todo va al túnel
nft -f /config/nftables.nft

# 5. FRR
arrancar_frr
echo "$n configurado"
