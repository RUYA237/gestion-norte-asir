#!/bin/bash
N=clab-gestion-norte
x() { echo; echo "### $1: $2"; docker exec "$N-$1" bash -c "$2"; }
echo "===== P1 switches: VLAN, STP y guards"
x zgz-n1 "bridge vlan show"
x zgz-n1 "bridge -d link show | grep -E 'master br0|root_block|guard'"
x zgz-a1 "bridge -d link show | grep -E 'master br0|state'"
x sw-hue1 "bridge vlan show"
echo "===== P2 Zaragoza: puerta de enlace, servidor y otra VLAN"
x pc-lab-zgz "ping -c2 -W2 10.1.30.1; nc -zv -w2 10.1.20.10 445; ping -c2 -W2 10.1.40.50"
echo "===== P3 rutas entre sedes"
x ubu-fw "ip route"
x rt-hue "ip route"
x rt-ter "ip route"
echo "===== P4 sedes a srv-dc1"
x pc-lab-hue "ping -c2 -W2 10.1.20.10; nc -zv -w2 10.1.20.10 445"
x pc-fis-ter "ping -c2 -W2 10.1.20.10; nc -zv -w2 10.1.20.10 445"
echo "===== P5 salida a Internet"
x pc-lab-hue "ping -c2 -W2 8.8.8.8"
x pc-inv-ter "ping -c2 -W2 8.8.8.8"
echo "===== Los 12 equipos de prueba llegan a srv-dc1"
for h in pc-it pc-lab-zgz pc-fis-zgz pc-adm-zgz pc-atn-zgz prn-zgz pc-inv-zgz pc-lab-hue pc-fis-hue pc-inv-hue pc-fis-ter pc-inv-ter; do
  if docker exec "$N-$h" ping -c1 -W2 10.1.20.10 >/dev/null 2>&1; then echo "$h OK"; else echo "$h FALLO"; fi
done
