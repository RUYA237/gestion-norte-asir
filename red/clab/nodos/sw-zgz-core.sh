#!/bin/bash
# sw-zgz-core: switch de núcleo del CPD de Zaragoza. Raíz de STP (prioridad 4096).
set -eu
. /config/lib-switch.sh
crear_switch 4096
troncal eth1 10 20 30 40      # hacia ubu-fw: todas las VLAN de Zaragoza
troncal eth2 10 30 40         # hacia sw-zgz-acc1: solo las VLAN de puestos
proteger_raiz eth2            # el switch de acceso nunca puede ser raíz
acceso  eth3 20               # srv-dc1 (servidores)
acceso  eth4 10               # pc-it (gestión de IT)
gestion 10 10.1.10.2/24 10.1.10.1
echo "sw-zgz-core configurado"
