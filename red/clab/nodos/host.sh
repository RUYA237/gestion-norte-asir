ip link set eth1 up
ip addr add "$1" dev eth1
ip route replace default via "$2"
[ -n "${3:-}" ] && setsid -f nc -lk "$3" >/dev/null 2>&1
exit 0
