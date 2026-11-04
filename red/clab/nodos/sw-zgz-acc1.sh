#!/bin/bash
# sw-zgz-acc1: switch de acceso de una planta de Zaragoza (en producción hay tres).
set -eu
. /config/lib-switch.sh
crear_switch 32768
troncal eth1 10 30 40         # subida al núcleo
acceso  eth2 30               # pc-lab-zgz (Laboral)
acceso  eth3 40               # pc-fis-zgz (Fiscal)
gestion 10 10.1.10.3/24 10.1.10.1
echo "sw-zgz-acc1 configurado"
