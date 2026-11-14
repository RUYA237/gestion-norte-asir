. /config/lib.sh
ip link set eth1 up
case "$1" in
  2) VL="30 40 80"; ENL=10.255.12.2/30; GW=10.255.12.1 ;;
  3) VL="40 80"; ENL=10.255.13.2/30; GW=10.255.13.1 ;;
esac
for v in $VL; do vlan_if eth1 "$v" "10.$1.$v.1/24"; done
ip link set eth2 up
ip addr add "$ENL" dev eth2
ip addr add 10.255.0.$1/32 dev lo
ip route replace default via "$GW"
