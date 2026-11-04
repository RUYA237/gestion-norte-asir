#!/bin/bash
# sw-ter: switch de la sede de Teruel.
set -eu
. /config/lib-switch.sh
crear_switch 4096
troncal eth1 10 30 40 80      # hacia rt-ter
acceso  eth2 40               # pc-fis-ter (Fiscal)
gestion 10 10.3.10.2/24 10.3.10.1
echo "sw-ter configurado"
