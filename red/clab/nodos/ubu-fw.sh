. /config/lib.sh
ip link set eth1 up
for v in 10 20 30 40 50 60 70 80; do vlan_if eth1 "$v" "10.1.$v.1/24"; done
ip link set wan up
ip addr add 203.0.113.2/30 dev wan
ip route replace default via 203.0.113.1
ip addr add 10.255.0.1/32 dev lo
ip link set eth2 up
ip addr add 10.255.12.1/30 dev eth2
ip link set eth3 up
ip addr add 10.255.13.1/30 dev eth3
ip route add 10.2.0.0/16 via 10.255.12.2
ip route add 10.3.0.0/16 via 10.255.13.2
