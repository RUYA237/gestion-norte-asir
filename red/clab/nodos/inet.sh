ip link set eth1 up
ip addr add 203.0.113.1/30 dev eth1
ip addr add 8.8.8.8/32 dev lo
ip route add 10.0.0.0/8 via 203.0.113.2
