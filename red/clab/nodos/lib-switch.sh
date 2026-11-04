#!/bin/bash
# Funciones comunes de los switches de la maqueta.
# Un switch es un puente Linux con filtrado de VLAN 802.1Q (vlan_filtering).

# crear_switch PRIORIDAD_STP
#   vlan_default_pvid 0: ningún puerto pertenece a una VLAN por defecto. No existe
#   "VLAN nativa": una trama sin etiqueta que llega a un troncal se descarta.
#   stp_state 1: STP activo contra bucles. forward_delay 400 = 4 s (en centésimas).
crear_switch() {
  ip link add br0 type bridge vlan_filtering 1 vlan_default_pvid 0 \
     stp_state 1 priority "$1" forward_delay 400
  ip link set br0 up
}

# troncal PUERTO VLAN...  -> el puerto lleva solo esas VLAN, todas etiquetadas
troncal() {
  local p=$1; shift
  ip link set "$p" master br0
  for v in "$@"; do bridge vlan add dev "$p" vid "$v"; done
  ip link set "$p" up
}

# acceso PUERTO VLAN  -> el equipo conectado entra sin etiqueta en esa VLAN y no
#   puede elegir otra. guard on = BPDU guard: si alguien conecta un switch, el
#   puerto se desactiva.
acceso() {
  ip link set "$1" master br0
  bridge vlan add dev "$1" vid "$2" pvid untagged
  bridge link set dev "$1" guard on
  ip link set "$1" up
}

# proteger_raiz PUERTO  -> root guard: por ese puerto no se acepta otro switch raíz
proteger_raiz() { bridge link set dev "$1" root_block on; }

# gestion VLAN IP/MÁSCARA PUERTA  -> dirección de administración del switch
gestion() {
  bridge vlan add dev br0 vid "$1" self
  ip link add link br0 name gestion type vlan id "$1"
  ip addr add "$2" dev gestion
  ip link set gestion up
  ip route replace default via "$3" dev gestion
}
