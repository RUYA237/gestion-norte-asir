#!/bin/bash
# sw-hue: switch de la sede de Huesca.
set -eu
. /config/lib-switch.sh
crear_switch 4096
troncal eth1 10 30 40 80      # hacia rt-hue
acceso  eth2 30               # pc-lab-hue (Laboral)
acceso  eth3 40               # pc-fis-hue (Fiscal)
acceso  eth4 80               # pc-inv-hue (Wi-Fi de visitas)
gestion 10 10.2.10.2/24 10.2.10.1
echo "sw-hue configurado"
