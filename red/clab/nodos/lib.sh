vlan_if() {
  ip link add link "$1" name "$1.$2" type vlan id "$2"
  ip link set "$1.$2" up
  ip addr add "$3" dev "$1.$2"
}
sw_crear() {
  ip link add br0 type bridge vlan_filtering 1 vlan_default_pvid 0 stp_state 1 priority "$1" forward_delay 400
  ip link set br0 up
}
sw_troncal() {
  local p=$1; shift
  ip link set "$p" master br0
  for v in "$@"; do bridge vlan add dev "$p" vid "$v"; done
  ip link set "$p" up
}
sw_acceso() {
  ip link set "$1" master br0
  bridge vlan add dev "$1" vid "$2" pvid untagged
  bridge link set dev "$1" guard on
  ip link set "$1" up
}
sw_raiz_no() {
  bridge link set dev "$1" root_block on
}
