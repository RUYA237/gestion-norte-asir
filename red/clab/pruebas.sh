#!/bin/bash
# Pruebas de la maqueta. Uso: sudo ./pruebas.sh [número]   (sin número, todas)
# Cada bloque es una captura para la memoria.
L=clab-gestion-norte
x() { local n=$1; shift; echo "\$ [$n] $*"; docker exec "$L-$n" "$@"; echo; }
t() { echo; echo "=================== $* ==================="; }

p1() { t "P1 Switches: VLAN por puerto, troncales y STP"
  x sw-zgz-core bridge vlan show
  x sw-zgz-core bridge -d link show
  x sw-zgz-acc1 bridge vlan show; }

p2() { t "P2 Zaragoza: entre VLAN solo pasa lo que permite ubu-fw"
  x pc-lab-zgz ping -c2 -W1 10.1.30.1
  x pc-lab-zgz nc -zvw2 10.1.20.10 445
  x pc-lab-zgz ping -c2 -W1 10.1.40.50
  x pc-it ping -c2 -W1 10.1.20.10
  x ubu-fw nft list chain inet filtro forward; }

p3() { t "P3 OSPF: vecinos y rutas aprendidas"
  x ubu-fw vtysh -c "show ip ospf neighbor"
  x rt-hue vtysh -c "show ip route ospf"
  x ubu-fw wg show; }

p4() { t "P4 Sedes: Huesca y Teruel llegan a los servidores por el túnel y nada más"
  x pc-lab-hue nc -zvw2 10.1.20.10 445
  x pc-fis-ter nc -zvw2 10.1.20.10 445
  x pc-lab-hue ping -c2 -W1 10.1.40.50
  x pc-lab-hue ping -c2 -W1 10.2.40.50
  x pc-it ping -c2 -W1 10.2.10.2; }

p5() { t "P5 Internet: empresa por ubu-fw; invitados por la fibra local y aislados"
  x pc-lab-hue nc -zvw2 9.9.9.9 443
  x pc-lab-hue traceroute -n -T -p 443 -w1 -q1 9.9.9.9
  x pc-inv-hue nc -zvw2 9.9.9.9 443
  x pc-inv-hue traceroute -n -T -p 443 -w1 -q1 9.9.9.9
  x pc-inv-hue nc -zvw2 10.1.20.10 445
  x rt-hue nft list chain inet filtro forward; }

p6() { t "P6 Corte de la fibra de Zaragoza: OSPF pasa al 4G"
  x rt-hue vtysh -c "show ip route 10.1.20.0/24"
  x pc-lab-hue traceroute -n -T -p 445 -w1 -q1 10.1.20.10
  echo ">>> Se corta la fibra (wan de ubu-fw) a las $(date +%T)"
  docker exec $L-ubu-fw ip link set wan down
  sleep 12
  x rt-hue vtysh -c "show ip route 10.1.20.0/24"
  x pc-lab-hue traceroute -n -T -p 445 -w1 -q1 10.1.20.10
  x pc-lab-hue nc -zvw2 10.1.20.10 445
  x pc-lab-hue nc -zvw2 9.9.9.9 443
  echo ">>> Vuelve la fibra a las $(date +%T)"
  docker exec $L-ubu-fw ip link set wan up
  sleep 15
  x rt-hue vtysh -c "show ip route 10.1.20.0/24"; }

if [ -n "$1" ]; then "p$1"; else for i in 1 2 3 4 5 6; do "p$i"; done; fi
